//! PostgreSQL adapter implementing `DatabaseStore`.
//!
//! Uses sqlx with connection pooling. Stores documents as JSONB rows
//! with a standard schema: `id UUID, data JSONB, created_at, updated_at`.

use ob_core::ports::db_store::{AppResult, DatabaseStore};
use serde_json::Value;
use sqlx::postgres::{PgPool, PgPoolOptions};
use sqlx::Row;

/// PostgreSQL adapter for the DatabaseStore trait.
///
/// Documents are stored as JSONB `data` column rows, allowing the same
/// document-oriented API while gaining ACID
/// transactions, mature tooling, and PostgreSQL ecosystem access.
#[derive(Clone)]
pub struct PgDatabaseStore {
    pool: PgPool,
}

impl PgDatabaseStore {
    /// Connect to PostgreSQL with the given connection string.
    pub async fn connect(database_url: &str) -> AppResult<Self> {
        let pool = PgPoolOptions::new()
            .max_connections(20)
            .min_connections(2)
            .acquire_timeout(std::time::Duration::from_secs(10))
            .connect(database_url)
            .await
            .map_err(|e| ob_core::Error::Database(format!("PostgreSQL connection failed: {e}")))?;

        tracing::info!("Connected to PostgreSQL");
        Ok(Self { pool })
    }

    /// Create from an existing pool (useful for testing).
    pub fn from_pool(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Get a reference to the underlying pool.
    pub fn pool(&self) -> &PgPool {
        &self.pool
    }

    /// Ensure a collection table exists. Creates it on first access.
    async fn ensure_table(&self, collection: &str) -> AppResult<()> {
        let table = sanitize_table_name(collection)?;
        sqlx::query(&format!(
            r#"
            CREATE TABLE IF NOT EXISTS {table} (
                id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
                data JSONB NOT NULL DEFAULT '{{}}'::jsonb,
                created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
            )
            "#
        ))
        .execute(&self.pool)
        .await
        .map_err(|e| ob_core::Error::Database(format!("Failed to create table {table}: {e}")))?;

        // Migrate legacy tables (from SQL migrations) to the PgDatabaseStore schema.
        // Legacy tables have explicit columns (user_id, email, etc.) and UUID id columns.
        // PgDatabaseStore stores everything in a JSONB `data` column, so we need to:
        // 1. Drop all foreign key constraints on this table
        // 2. Convert id from UUID to TEXT (for string-based IDs like "user_1")
        // 3. Drop extra columns that are NOT NULL (they'd block inserts into just id+data)
        // 4. Add the data column if missing
        sqlx::query(&format!(
            r#"
            DO $$ DECLARE
                r RECORD;
            BEGIN
                -- Drop all foreign key constraints ON this table
                FOR r IN
                    SELECT conname FROM pg_constraint
                    JOIN pg_class ON pg_constraint.conrelid = pg_class.oid
                    WHERE pg_class.relname = '{table}' AND contype = 'f'
                LOOP
                    BEGIN
                        EXECUTE 'ALTER TABLE {table} DROP CONSTRAINT ' || quote_ident(r.conname);
                    EXCEPTION WHEN OTHERS THEN NULL;
                    END;
                END LOOP;

                -- Drop all foreign key constraints REFERENCING this table (from other tables)
                FOR r IN
                    SELECT pg_class.relname AS src_table, pg_constraint.conname
                    FROM pg_constraint
                    JOIN pg_class ON pg_constraint.conrelid = pg_class.oid
                    JOIN pg_class AS ref ON pg_constraint.confrelid = ref.oid
                    WHERE ref.relname = '{table}' AND pg_constraint.contype = 'f'
                LOOP
                    BEGIN
                        EXECUTE 'ALTER TABLE ' || quote_ident(r.src_table) || ' DROP CONSTRAINT ' || quote_ident(r.conname);
                    EXCEPTION WHEN OTHERS THEN NULL;
                    END;
                END LOOP;

                -- Convert id column from UUID to TEXT if needed
                BEGIN
                    IF EXISTS (
                        SELECT 1 FROM information_schema.columns
                        WHERE table_name = '{table}' AND column_name = 'id' AND data_type = 'uuid'
                    ) THEN
                        ALTER TABLE {table} ALTER COLUMN id TYPE TEXT USING id::TEXT;
                    END IF;
                EXCEPTION WHEN OTHERS THEN NULL;
                END;

                -- Add data column if missing
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1 FROM information_schema.columns
                        WHERE table_name = '{table}' AND column_name = 'data'
                    ) THEN
                        ALTER TABLE {table} ADD COLUMN data JSONB NOT NULL DEFAULT '{{}}'::jsonb;
                    END IF;
                EXCEPTION WHEN OTHERS THEN NULL;
                END;

                -- Drop extra columns that have NOT NULL constraints (would block id+data inserts)
                FOR r IN
                    SELECT column_name FROM information_schema.columns
                    WHERE table_name = '{table}'
                      AND column_name NOT IN ('id', 'data', 'created_at', 'updated_at')
                      AND is_nullable = 'NO'
                LOOP
                    BEGIN
                        EXECUTE 'ALTER TABLE {table} DROP COLUMN IF EXISTS ' || quote_ident(r.column_name);
                    EXCEPTION WHEN OTHERS THEN NULL;
                    END;
                END LOOP;
            END $$;
            "#
        ))
        .execute(&self.pool)
        .await
        .map_err(|e| {
            ob_core::Error::Database(format!("Failed to migrate table {table}: {e}"))
        })?;

        // Ensure the updated_at trigger exists
        sqlx::query(&format!(
            r#"
            DO $$ BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM pg_trigger WHERE tgname = '{table}_set_updated_at'
                ) THEN
                    CREATE TRIGGER {table}_set_updated_at
                        BEFORE UPDATE ON {table}
                        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
                END IF;
            END $$;
            "#
        ))
        .execute(&self.pool)
        .await
        .map_err(|e| {
            ob_core::Error::Database(format!("Failed to create trigger for {table}: {e}"))
        })?;

        Ok(())
    }
}

/// Sanitize a collection name for use as a PostgreSQL table name.
/// Must be alphanumeric + underscores only.
fn sanitize_table_name(name: &str) -> AppResult<String> {
    ob_core::validate_identifier(name)?;
    Ok(name.to_string())
}

/// Serialize a JSONB Value to a string for sqlx binding (preserves JSON encoding).
fn json_to_string(val: &Value) -> String {
    serde_json::to_string(val).unwrap_or_else(|_| "{}".to_string())
}

/// Extract raw text from a Value for `data->>` comparisons (no JSON quotes).
/// `data->>` returns unquoted text, so binding `"\"hello\""` would fail to match `"hello"`.
fn json_to_text(val: &Value) -> String {
    match val {
        Value::String(s) => s.clone(),
        Value::Null => String::new(),
        other => other.to_string(),
    }
}

// ── SurrealDB → PostgreSQL Translation Layer ───────────────────────────────
//
// Handles both raw queries (query_raw) and parameterised queries (query_bind).
// The goal is mechanical: turn SurrealQL into valid PostgreSQL while keeping the
// same semantics so existing handler code and tests keep working.

/// Pre-process a raw SurrealDB query (no bind params) into valid PostgreSQL.
/// Used by `query_raw` which passes SQL directly to PG.
pub(crate) fn translate_surreal_raw(query: &str) -> String {
    let mut q = query.to_string();

    // ── 1. CREATE table CONTENT { ... } ────────────────────────────────
    // Pattern: CREATE table_name CONTENT { json_body }
    // Also:    CREATE table_name:id CONTENT { json_body }
    // Also:    CREATE table_name SET field = val, field2 = val2
    if let Some(create_idx) = q.to_uppercase().find("CREATE ") {
        let after_create = &q[create_idx + 7..];

        // CREATE ... SET field = val, field2 = val2
        if let Some(set_idx) = after_create.to_uppercase().find(" SET ") {
            let table_part = after_create[..set_idx].trim();
            let (table, explicit_id) = parse_surreal_table_id(table_part);
            let set_clause = after_create[set_idx + 4..].trim();
            // Remove trailing RETURN AFTER
            let set_clause = set_clause
                .trim_end()
                .strip_suffix("RETURN AFTER")
                .unwrap_or(set_clause)
                .trim_end();

            // Parse SET pairs into JSON
            let pairs = parse_set_pairs(set_clause);
            let mut obj = serde_json::Map::new();
            for (k, v) in &pairs {
                obj.insert(k.clone(), parse_surreal_literal(v));
            }
            let id = explicit_id
                .unwrap_or_else(|| uuid::Uuid::new_v4().to_string());
            obj.insert("id".to_string(), Value::String(id.clone()));
            let data = serde_json::to_string(&Value::Object(obj)).unwrap_or_default();
            q = format!(
                "INSERT INTO {table} (id, data) VALUES ('{id}', '{data}'::jsonb) ON CONFLICT (id) DO UPDATE SET data = EXCLUDED.data, updated_at = now() RETURNING id, data::TEXT, created_at, updated_at"
            );
            return q;
        }

        // CREATE ... CONTENT { ... }
        if let Some(content_idx) = after_create.to_uppercase().find("CONTENT ") {
            let table_part = after_create[..content_idx].trim();
            let (table, explicit_id) = parse_surreal_table_id(table_part);
            let body_start = content_idx + 8;
            let body = after_create[body_start..].trim();
            // Remove trailing RETURN AFTER
            let body = body
                .trim_end()
                .strip_suffix("RETURN AFTER")
                .unwrap_or(body)
                .trim_end();

            // Parse the JSON body
            let mut data: Value = serde_json::from_str(body).unwrap_or(Value::Object(Default::default()));
            if let Some(obj) = data.as_object_mut() {
                let id = explicit_id
                    .unwrap_or_else(|| obj.get("id").and_then(|v| v.as_str()).map(String::from)
                        .unwrap_or_else(|| uuid::Uuid::new_v4().to_string()));
                obj.insert("id".to_string(), Value::String(id.clone()));
                let data_str = serde_json::to_string(&data).unwrap_or_default();
                q = format!(
                    "INSERT INTO {table} (id, data) VALUES ('{id}', '{data_str}'::jsonb) RETURNING id, data::TEXT, created_at, updated_at"
                );
            }
            return q;
        }
    }

    // ── 2. DELETE table:id ──────────────────────────────────────────────
    if let Some(del_idx) = q.to_uppercase().find("DELETE ") {
        let after = &q[del_idx + 7..].trim();
        let after = after.strip_prefix("FROM ").unwrap_or(after).trim();
        if after.contains(':') {
            let parts: Vec<&str> = after.splitn(2, ':').collect();
            if parts.len() == 2 {
                let table = parts[0].trim();
                let id = parts[1].trim().trim_matches('\'').trim_matches('"');
                q = format!("DELETE FROM {table} WHERE id = '{id}' RETURNING id, data::TEXT, created_at, updated_at");
                return q;
            }
        }
    }

    // ── 3. SELECT * FROM table:id ──────────────────────────────────────
    if q.to_uppercase().contains("FROM ") {
        // Replace table:id references in FROM clause
        let upper = q.to_uppercase();
        if let Some(from_idx) = upper.find("FROM ") {
            let after_from = &q[from_idx + 5..];
            let end = after_from.find(|c: char| c.is_whitespace() || c == ';').unwrap_or(after_from.len());
            let table_ref = &after_from[..end];
            if table_ref.contains(':') && !table_ref.contains("::") {
                let parts: Vec<&str> = table_ref.splitn(2, ':').collect();
                if parts.len() == 2 {
                    let table = parts[0];
                    let id = parts[1].trim_matches('\'').trim_matches('"');
                    let before = &q[..from_idx + 5];
                    let after_ref = &after_from[end..];
                    // Check if WHERE already exists
                    if after_ref.to_uppercase().contains("WHERE") {
                        q = format!("{before}{table}{after_ref}").replace(
                            "WHERE",
                            &format!("WHERE id = '{id}' AND"),
                        );
                    } else {
                        q = format!("{before}{table} WHERE id = '{id}'{after_ref}");
                    }
                }
            }
        }
    }

    // ── 4. Rewrite bare field references in WHERE ──────────────────────
    q = rewrite_bare_fields_in_where(&q);

    // ── 5. Remove RETURN AFTER → RETURNING * ───────────────────────────
    q = q.replace("RETURN AFTER", "RETURNING id, data::TEXT, created_at, updated_at");

    // ── 6. SurrealDB NONE → PostgreSQL IS NULL ────────────────────────
    q = q.replace("= NONE", "IS NULL");

    q
}

/// Translate a SurrealDB-style query with named bind parameters into
/// PostgreSQL-compatible SQL with positional `$1, $2, ...` parameters.
///
/// This is the core compatibility layer that lets existing handler code
/// written for SurrealDB run against PostgreSQL without rewriting every
/// query. It handles:
///
/// - Named `$param` → positional `$N` rewriting
/// - `type::thing('table', $id)` → bare `$id`
/// - `CREATE ... CONTENT $data` → `INSERT INTO ... (id, data) VALUES (...)`
/// - `UPSERT` → `INSERT ... ON CONFLICT DO UPDATE`
/// - `UPDATE ... MERGE $data` → `UPDATE ... SET data = data || $data::jsonb`
/// - `= NONE` → `IS NULL`
/// - Bare field references → `data->>'field'` JSONB extraction
///
/// # Arguments
/// - `query`: SurrealQL string with `$named` placeholders.
/// - `binds`: JSON object mapping parameter names to values.
///
/// # Returns
/// `(translated_sql, ordered_values)` ready for `sqlx::query` binding.
///
/// # Errors
/// Returns `Error::Database` if `binds` is not a JSON object.
pub(crate) fn translate_surreal_to_pg(query: &str, binds: Value) -> AppResult<(String, Vec<Value>)> {
    let obj = binds
        .as_object()
        .ok_or_else(|| ob_core::Error::Database("Binds must be a JSON object".into()))?;

    let pairs: Vec<(String, Value)> = obj
        .iter()
        .map(|(k, v)| (k.clone(), v.clone()))
        .collect();

    let mut pg_query = query.to_string();

    // ── Phase 1: SurrealDB structural rewrites ─────────────────────────

    // type::thing('table', $id) → just use table WHERE id = $id
    // Pattern: type::thing('table', $param) or type::thing($table, $param)
    while pg_query.contains("type::thing(") {
        if let Some(start) = pg_query.find("type::thing(") {
            let after = &pg_query[start + 12..];
            if let Some(close) = after.find(')') {
                let args = &after[..close];
                let _full_match = &pg_query[start..start + 12 + close + 1];
                // Parse arguments: ('table', $id) or ($table, $id)
                let parts: Vec<&str> = args.splitn(2, ',').collect();
                if parts.len() == 2 {
                    let id_param = parts[1].trim().trim_matches('\'').trim_matches('"');
                    // Replace the entire type::thing(...) with just the id param
                    pg_query = format!(
                        "{}{}{}",
                        &pg_query[..start],
                        id_param,
                        &pg_query[start + 12 + close + 1..]
                    );
                } else {
                    break; // Can't parse, stop
                }
            } else {
                break;
            }
        } else {
            break;
        }
    }

    // CREATE type::thing($table, $id) CONTENT $data RETURN AFTER
    // → INSERT INTO $table (id, data) VALUES ($id, $data::jsonb) RETURNING *
    if pg_query.to_uppercase().starts_with("CREATE ") && pg_query.to_uppercase().contains("CONTENT ") {
        // Extract the table from binds
        let table = pairs.iter()
            .find(|(k, _)| k == "table")
            .and_then(|(_, v)| v.as_str())
            .unwrap_or("unknown");
        let id_val = pairs.iter()
            .find(|(k, _)| k == "id")
            .map(|(_, v)| v.clone())
            .unwrap_or(Value::String(uuid::Uuid::new_v4().to_string()));
        let data_val = pairs.iter()
            .find(|(k, _)| k == "data")
            .map(|(_, v)| v.clone())
            .unwrap_or(Value::Object(Default::default()));

        // Merge id into data
        let mut merged = data_val.clone();
        if let Some(obj) = merged.as_object_mut()
            && let Some(id_str) = id_val.as_str() {
                obj.insert("id".to_string(), Value::String(id_str.to_string()));
            }

        let data_str = serde_json::to_string(&merged).unwrap_or_default();
        let id_str = id_val.as_str().unwrap_or("unknown");

        pg_query = format!(
            "INSERT INTO {table} (id, data) VALUES ($1, $2::jsonb) \
             ON CONFLICT (id) DO UPDATE SET data = EXCLUDED.data, updated_at = now() \
             RETURNING id, data::TEXT, created_at, updated_at"
        );
        return Ok((pg_query, vec![Value::String(id_str.to_string()), Value::String(data_str)]));
    }

    // UPSERT type::thing($table, $id) CONTENT $data RETURN AFTER
    // → INSERT ... ON CONFLICT (id) DO UPDATE SET data = EXCLUDED.data RETURNING *
    if pg_query.to_uppercase().starts_with("UPSERT ") {
        let table = pairs.iter()
            .find(|(k, _)| k == "table")
            .and_then(|(_, v)| v.as_str())
            .unwrap_or("unknown");
        let id_val = pairs.iter()
            .find(|(k, _)| k == "id")
            .map(|(_, v)| v.clone())
            .unwrap_or(Value::String(uuid::Uuid::new_v4().to_string()));
        let data_val = pairs.iter()
            .find(|(k, _)| k == "data")
            .map(|(_, v)| v.clone())
            .unwrap_or(Value::Object(Default::default()));

        let mut merged = data_val.clone();
        if let Some(obj) = merged.as_object_mut()
            && let Some(id_str) = id_val.as_str() {
                obj.insert("id".to_string(), Value::String(id_str.to_string()));
            }
        let data_str = serde_json::to_string(&merged).unwrap_or_default();
        let id_str = id_val.as_str().unwrap_or("unknown");

        pg_query = format!(
            "INSERT INTO {table} (id, data) VALUES ($1, $2::jsonb) \
             ON CONFLICT (id) DO UPDATE SET data = EXCLUDED.data, updated_at = now() \
             RETURNING id, data::TEXT, created_at, updated_at"
        );
        return Ok((pg_query, vec![Value::String(id_str.to_string()), Value::String(data_str)]));
    }

    // UPDATE ... MERGE $data RETURN AFTER → UPDATE SET data = data || $data::jsonb WHERE id = $id
    if pg_query.to_uppercase().contains("MERGE ") && pg_query.to_uppercase().contains("UPDATE ") {
        let table = pairs.iter()
            .find(|(k, _)| k == "table")
            .and_then(|(_, v)| v.as_str())
            .unwrap_or("unknown");
        let id_val = pairs.iter()
            .find(|(k, _)| k == "id")
            .map(|(_, v)| v.clone());
        let data_val = pairs.iter()
            .find(|(k, _)| k == "data")
            .map(|(_, v)| v.clone())
            .unwrap_or(Value::Object(Default::default()));

        let data_str = serde_json::to_string(&data_val).unwrap_or_default();

        if let Some(id) = id_val {
            let id_str = id.as_str().unwrap_or("unknown");
            pg_query = format!(
                "UPDATE {table} SET data = data || $1::jsonb, updated_at = now() \
                 WHERE id = $2 \
                 RETURNING id, data::TEXT, created_at, updated_at"
            );
            return Ok((pg_query, vec![Value::String(data_str), Value::String(id_str.to_string())]));
        }
    }

    // ── Phase 2: Syntax rewrites ───────────────────────────────────────
    pg_query = pg_query.replace("count()", "COUNT(*)");
    pg_query = pg_query.replace("COUNT()", "COUNT(*)");
    pg_query = pg_query.replace(" GROUP ALL", "");
    pg_query = pg_query.replace("RETURN AFTER", "RETURNING id, data::TEXT, created_at, updated_at");
    pg_query = pg_query.replace("time::now()", "now()");


    // Rewrite UPDATE table SET field1 = $p1, field2 = $p2 WHERE ...
    // → UPDATE table SET data = data || jsonb_build_object('field1', $p1, 'field2', $p2) WHERE ...
    if pg_query.to_uppercase().starts_with("UPDATE ") && pg_query.to_uppercase().contains(" SET ") {
        let upper = pg_query.to_uppercase();
        if let Some(set_idx) = upper.find(" SET ") {
            let where_idx = upper.find(" WHERE ");
            let returning_idx = upper.find(" RETURNING ");
            let set_end = where_idx.or(returning_idx).unwrap_or(pg_query.len());
            let set_clause = &pg_query[set_idx + 5..set_end];

            // Check if the SET clause uses bare field names (not data = ...)
            let trimmed_set = set_clause.trim();
            if !trimmed_set.starts_with("data") && !trimmed_set.starts_with("data ") {
                // Parse SET pairs: field1 = $p1, field2 = $p2
                let set_pairs: Vec<(&str, &str)> = trimmed_set.split(',').filter_map(|part| {
                    let part = part.trim();
                    let eq = part.find('=')?;
                    let key = part[..eq].trim();
                    let val = part[eq + 1..].trim();
                    // Skip if field is already data-> prefixed or is a standard column
                    let standard = ["id", "created_at", "updated_at", "data"];
                    if standard.contains(&key) || key.starts_with("data") {
                        return None;
                    }
                    Some((key, val))
                }).collect();

                if !set_pairs.is_empty() {
                    // Build JSONB merge: data = data || jsonb_build_object(...)
                    let jsonb_args: Vec<String> = set_pairs.iter().map(|(k, v)| {
                        format!("'{k}', {v}")
                    }).collect();
                    let new_set = format!("data = data || jsonb_build_object({}), updated_at = now()", jsonb_args.join(", "));
                    let after = &pg_query[set_end..];
                    let before = &pg_query[..set_idx + 5];
                    pg_query = format!("{before}{new_set}{after}");
                }
            }
        }
    }

    // Also rewrite bare fields in WHERE for format!-injected literal values
    // This handles: WHERE status = 'active' → WHERE data->>'status' = 'active'
    pg_query = rewrite_bare_fields_in_where(&pg_query);

    // ── Phase 3: Rewrite field references + named params ───────────────
    let standard_columns = ["id", "created_at", "updated_at", "data"];
    for (i, (name, _)) in pairs.iter().enumerate() {
        let placeholder = format!("${name}");
        let pg_placeholder = format!("${}", i + 1);

        if !standard_columns.contains(&name.as_str()) {
            let mut result = String::with_capacity(pg_query.len() + 32);
            let mut remaining = pg_query.as_str();

            while let Some(pos) = remaining.find(&placeholder) {
                let before = &remaining[..pos];
                let after = &remaining[pos + placeholder.len()..];

                let before_trimmed = before.trim_end();
                let operators = ["!=", "<>", ">=", "<=", "=", ">", "<"];
                let mut field_name = "";
                let mut field_start_idx = before.len();

                for op in &operators {
                    if let Some(op_pos) = before_trimmed.rfind(op) {
                        let after_op = &before_trimmed[op_pos + op.len()..];
                        if after_op.trim().is_empty() {
                            let field_part = before_trimmed[..op_pos].trim_end();
                            if let Some(last_ws) = field_part.rfind(char::is_whitespace) {
                                let candidate = field_part[last_ws..].trim();
                                if !candidate.is_empty()
                                    && candidate.chars().all(|c| c.is_alphanumeric() || c == '_')
                                {
                                    field_name = candidate;
                                    field_start_idx = before[..op_pos].rfind(field_name).unwrap_or(op_pos);
                                    break;
                                }
                            } else {
                                let candidate = field_part.trim();
                                if !candidate.is_empty()
                                    && candidate.chars().all(|c| c.is_alphanumeric() || c == '_')
                                {
                                    field_name = candidate;
                                    field_start_idx = before.rfind(field_name).unwrap_or(op_pos);
                                    break;
                                }
                            }
                        }
                    }
                }

                if !field_name.is_empty() && !standard_columns.contains(&field_name) {
                    let op_str = &before_trimmed[before_trimmed.rfind(field_name).unwrap_or(0) + field_name.len()..].trim();
                    result.push_str(&before[..field_start_idx]);
                    result.push_str(&format!("data->>'{field_name}' {op_str} "));
                } else {
                    result.push_str(before);
                }

                result.push_str(&pg_placeholder);
                remaining = after;
            }
            result.push_str(remaining);
            pg_query = result;
        } else {
            pg_query = pg_query.replace(&placeholder, &pg_placeholder);
        }
    }

    // SurrealDB NONE → PostgreSQL IS NULL (after field rewriting so data->> prefix is already applied)
    pg_query = pg_query.replace("= NONE", "IS NULL");

    let values: Vec<Value> = pairs.into_iter().map(|(_, v)| v).collect();
    Ok((pg_query, values))
}

// ── Helper functions for SurrealDB translation ─────────────────────────────

/// Parse a SurrealDB table reference like "orders" or "orders:abc123"
fn parse_surreal_table_id(s: &str) -> (String, Option<String>) {
    let clean = s.trim().trim_matches('\'').trim_matches('"');
    if let Some(colon) = clean.find(':') {
        let table = clean[..colon].to_string();
        let id = clean[colon + 1..].trim_matches('\'').trim_matches('"').to_string();
        (table, Some(id))
    } else {
        (clean.to_string(), None)
    }
}

/// Parse SurrealDB SET pairs: "field1 = val1, field2 = val2"
fn parse_set_pairs(s: &str) -> Vec<(String, String)> {
    let mut pairs = Vec::new();
    for part in s.split(',') {
        let part = part.trim();
        if let Some(eq) = part.find('=') {
            let key = part[..eq].trim().to_string();
            let val = part[eq + 1..].trim().to_string();
            pairs.push((key, val));
        }
    }
    pairs
}

/// Parse a SurrealDB literal value to serde_json::Value
fn parse_surreal_literal(s: &str) -> Value {
    let s = s.trim();
    // Try JSON first
    if let Ok(v) = serde_json::from_str::<Value>(s) {
        return v;
    }
    // Quoted string
    if (s.starts_with('\'') && s.ends_with('\'')) || (s.starts_with('"') && s.ends_with('"')) {
        return Value::String(s[1..s.len() - 1].to_string());
    }
    // Boolean
    if s == "true" { return Value::Bool(true); }
    if s == "false" { return Value::Bool(false); }
    // Number
    if let Ok(n) = s.parse::<i64>() {
        return Value::Number(n.into());
    }
    if let Ok(n) = s.parse::<f64>()
        && let Some(n) = serde_json::Number::from_f64(n) {
            return Value::Number(n);
        }
    Value::String(s.to_string())
}

/// Rewrite bare field names in WHERE clauses to data->>'field' for PostgreSQL JSONB.
/// Only rewrites fields that aren't already prefixed with data-> or standard columns.
fn rewrite_bare_fields_in_where(query: &str) -> String {
    let standard_columns = ["id", "created_at", "updated_at", "data"];

    // Only rewrite within WHERE clause
    let upper = query.to_uppercase();
    let where_idx = match upper.find("WHERE ") {
        Some(idx) => idx,
        None => return query.to_string(),
    };

    let before_where = &query[..where_idx + 6];
    let where_clause = &query[where_idx + 6..];

    // Find common comparison patterns: field = 'value' or field = value
    let mut result = String::with_capacity(where_clause.len() + 64);
    let mut remaining = where_clause;

    while !remaining.is_empty() {
        // Try to match: word operator value
        let trimmed = remaining.trim_start();
        let prefix_ws = remaining.len() - trimmed.len();

        // Find the next word (potential field name)
        let word_end = trimmed.find(|c: char| !c.is_alphanumeric() && c != '_').unwrap_or(trimmed.len());
        if word_end == 0 {
            // Not a word, just copy the character
            result.push_str(&remaining[..prefix_ws + 1.min(trimmed.len())]);
            remaining = &remaining[(prefix_ws + 1).min(remaining.len())..];
            continue;
        }

        let word = &trimmed[..word_end];
        let word_upper = word.to_uppercase();

        // Skip SQL keywords
        let keywords = [
            "AND", "OR", "NOT", "IN", "IS", "NULL", "LIKE", "BETWEEN", "EXISTS", "ASC", "DESC",
            "ORDER", "BY", "GROUP", "HAVING", "LIMIT", "OFFSET", "FROM", "SELECT", "INSERT",
            "UPDATE", "DELETE", "SET", "VALUES", "RETURNING", "TRUE", "FALSE", "CASE", "WHEN",
            "THEN", "ELSE", "END", "AS", "ON", "JOIN", "LEFT", "RIGHT", "INNER", "OUTER",
        ];

        if keywords.contains(&word_upper.as_str())
            || standard_columns.contains(&word.to_lowercase().as_str())
            || word.starts_with("data")
        {
            result.push_str(&remaining[..prefix_ws + word_end]);
            remaining = &remaining[prefix_ws + word_end..];
            continue;
        }

        // Check if this word is followed by an operator
        let after_word = &trimmed[word_end..];
        let after_trimmed = after_word.trim_start();
        let operators = ["!=", "<>", ">=", "<=", "=", ">", "<"];
        let mut is_comparison = false;
        for op in &operators {
            if after_trimmed.starts_with(op) {
                is_comparison = true;
                break;
            }
        }

        if is_comparison {
            // Rewrite: field → data->>'field'
            result.push_str(&remaining[..prefix_ws]);
            result.push_str(&format!("data->>'{word}'"));
            remaining = &remaining[prefix_ws + word_end..];
        } else {
            result.push_str(&remaining[..prefix_ws + word_end]);
            remaining = &remaining[prefix_ws + word_end..];
        }
    }

    format!("{before_where}{result}")
}

/// Extract the primary table name from a SQL query (FROM, DELETE FROM, UPDATE).
/// Returns None if no table name can be determined.
/// Only matches keywords at word boundaries to avoid false matches in string literals.
fn extract_table_name(query: &str) -> Option<String> {
    let lower = query.to_lowercase();

    // Try each keyword pattern, ensuring word boundaries
    let patterns: &[(&str, bool)] = &[
        ("delete from", true),  // multi-word, look for FROM after DELETE
        ("update", false),      // single keyword at statement start
        ("from", true),         // FROM in SELECT queries
    ];

    for &(keyword, is_multiword) in patterns {
        let mut search_start = 0;
        while let Some(pos) = lower[search_start..].find(keyword) {
            let abs_pos = search_start + pos;
            let after_keyword = &lower[abs_pos + keyword.len()..];

            // Check word boundary: keyword must be preceded by whitespace or start of string
            let before_ok = abs_pos == 0
                || query.as_bytes().get(abs_pos - 1).is_none_or(|b| b.is_ascii_whitespace());

            // Check word boundary: keyword must be followed by whitespace
            let after_ok = after_keyword.starts_with(|c: char| c.is_ascii_whitespace());

            if before_ok && after_ok {
                // For "update" keyword, ensure it's at the start of the statement
                // (not inside a SET clause like "SET updated_at = ...")
                if !is_multiword {
                    let before_text = &lower[..abs_pos].trim();
                    if !before_text.is_empty() && !before_text.ends_with(';') {
                        // UPDATE not at statement start — skip
                        search_start = abs_pos + keyword.len();
                        continue;
                    }
                }

                let after = &query[abs_pos + keyword.len()..].trim();
                let table = after
                    .split(|c: char| c.is_whitespace() || c == '(' || c == ';')
                    .next()
                    .unwrap_or("");
                if !table.is_empty() && table.chars().all(|c| c.is_alphanumeric() || c == '_') {
                    return Some(table.to_string());
                }
            }

            search_start = abs_pos + keyword.len();
        }
    }
    None
}

/// Bind a JSON Value to a sqlx query dynamically.
/// Numbers are bound as strings since JSONB `->>` returns text.
pub(crate) fn bind_json_value<'q>(
    q: sqlx::query::Query<'q, sqlx::Postgres, sqlx::postgres::PgArguments>,
    val: &'q Value,
) -> sqlx::query::Query<'q, sqlx::Postgres, sqlx::postgres::PgArguments> {
    match val {
        Value::Null => q.bind::<Option<String>>(None),
        Value::Bool(b) => q.bind(*b),
        Value::Number(n) => {
            // Bind as string since JSONB ->> returns text and comparisons
            // like "text >= bigint" fail in PostgreSQL
            q.bind(n.to_string())
        }
        Value::String(s) => q.bind(s.as_str()),
        Value::Array(_) | Value::Object(_) => q.bind(serde_json::to_string(val).unwrap()),
    }
}

/// Convert sqlx rows to Vec<Value> (best-effort extraction).
fn rows_to_values(rows: Vec<sqlx::postgres::PgRow>) -> AppResult<Vec<Value>> {
    use sqlx::{Column, Row};

    let mut results = Vec::with_capacity(rows.len());
    for row in &rows {
        // Try to get 'data' column — handle both JSONB (as serde_json::Value) and TEXT
        if let Ok(val) = row.try_get::<Value, _>("data") {
            let mut result = val;
            if let Some(obj) = result.as_object_mut() {
                if let Ok(id) = row.try_get::<String, _>("id") {
                    obj.insert("id".to_string(), Value::String(id));
                }
                if let Ok(ts) =
                    row.try_get::<chrono::DateTime<chrono::Utc>, _>("created_at")
                {
                    obj.insert("createdAt".to_string(), Value::String(ts.to_rfc3339()));
                }
                if let Ok(ts) =
                    row.try_get::<chrono::DateTime<chrono::Utc>, _>("updated_at")
                {
                    obj.insert("updatedAt".to_string(), Value::String(ts.to_rfc3339()));
                }
            }
            results.push(result);
            continue;
        }

        // Fallback: extract all columns as a JSON object (handles aggregate queries)
        let mut obj = serde_json::Map::new();
        for col in row.columns() {
            let name = col.name();
            // Try common types in order of likelihood
            if let Ok(v) = row.try_get::<i64, _>(name) {
                obj.insert(name.to_string(), Value::Number(v.into()));
            } else if let Ok(v) = row.try_get::<String, _>(name) {
                obj.insert(name.to_string(), Value::String(v));
            } else if let Ok(v) = row.try_get::<f64, _>(name) {
                if let Some(n) = serde_json::Number::from_f64(v) {
                    obj.insert(name.to_string(), Value::Number(n));
                }
            } else if let Ok(v) = row.try_get::<bool, _>(name) {
                obj.insert(name.to_string(), Value::Bool(v));
            }
        }
        if !obj.is_empty() {
            results.push(Value::Object(obj));
            continue;
        }

        // Last resort: try first column as string
        let val: Value = row
            .try_get::<String, _>(0)
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or(Value::Null);
        results.push(val);
    }
    Ok(results)
}

impl DatabaseStore for PgDatabaseStore {
    async fn create_document(&self, collection: &str, data: Value) -> AppResult<Value> {
        self.ensure_table(collection).await?;
        let table = sanitize_table_name(collection)?;

        let id = data
            .get("id")
            .and_then(|v| v.as_str())
            .map(|s| s.to_string())
            .unwrap_or_else(|| uuid::Uuid::new_v4().to_string());

        let data_str = json_to_string(&data);

        let row = sqlx::query(&format!(
            r#"INSERT INTO {table} (id, data) VALUES ($1, $2::jsonb)
               ON CONFLICT (id) DO UPDATE SET data = EXCLUDED.data, updated_at = now()
               RETURNING id, data::TEXT, created_at, updated_at"#
        ))
        .bind(&id)
        .bind(&data_str)
        .fetch_one(&self.pool)
        .await
        .map_err(|e| ob_core::Error::Database(format!("Create failed: {e}")))?;

        let mut result: Value = serde_json::from_str(
            row.get::<String, _>("data").as_str()
        )
        .unwrap_or(Value::Object(Default::default()));

        // Inject the id and timestamps into the result
        if let Some(obj) = result.as_object_mut() {
            obj.insert(
                "id".to_string(),
                Value::String(row.get::<String, _>("id")),
            );
            obj.insert(
                "createdAt".to_string(),
                Value::String(
                    row.get::<chrono::DateTime<chrono::Utc>, _>("created_at")
                        .to_rfc3339(),
                ),
            );
            obj.insert(
                "updatedAt".to_string(),
                Value::String(
                    row.get::<chrono::DateTime<chrono::Utc>, _>("updated_at")
                        .to_rfc3339(),
                ),
            );
        }

        Ok(result)
    }

    async fn get_document(&self, collection: &str, id: &str) -> AppResult<Value> {
        self.ensure_table(collection).await?;
        let table = sanitize_table_name(collection)?;

        // Strip collection prefix if present (e.g., "products:abc" → "abc")
        let bare_id = id
            .strip_prefix(&format!("{collection}:"))
            .unwrap_or(id);

        let row = sqlx::query(&format!(
            r#"SELECT id, data::TEXT, created_at, updated_at FROM {table} WHERE id = $1"#
        ))
        .bind(bare_id)
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| ob_core::Error::Database(format!("Get failed: {e}")))?;

        let row = row.ok_or_else(|| {
            ob_core::Error::NotFound(format!("{collection}:{bare_id} not found"))
        })?;

        let mut result: Value = serde_json::from_str(
            row.get::<String, _>("data").as_str()
        )
        .unwrap_or(Value::Object(Default::default()));

        if let Some(obj) = result.as_object_mut() {
            obj.insert("id".to_string(), Value::String(row.get("id")));
            obj.insert(
                "createdAt".to_string(),
                Value::String(
                    row.get::<chrono::DateTime<chrono::Utc>, _>("created_at")
                        .to_rfc3339(),
                ),
            );
            obj.insert(
                "updatedAt".to_string(),
                Value::String(
                    row.get::<chrono::DateTime<chrono::Utc>, _>("updated_at")
                        .to_rfc3339(),
                ),
            );
        }

        Ok(result)
    }

    async fn update_document(
        &self,
        collection: &str,
        id: &str,
        data: Value,
    ) -> AppResult<Value> {
        self.ensure_table(collection).await?;
        let table = sanitize_table_name(collection)?;
        let bare_id = id
            .strip_prefix(&format!("{collection}:"))
            .unwrap_or(id);
        let data_str = json_to_string(&data);

        let row = sqlx::query(&format!(
            r#"
            UPDATE {table}
            SET data = data || $2::jsonb
            WHERE id = $1
            RETURNING id, data::TEXT, created_at, updated_at
            "#
        ))
        .bind(bare_id)
        .bind(&data_str)
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| ob_core::Error::Database(format!("Update failed: {e}")))?;

        let row = row.ok_or_else(|| {
            ob_core::Error::NotFound(format!("{collection}:{bare_id} not found"))
        })?;

        let mut result: Value = serde_json::from_str(
            row.get::<String, _>("data").as_str()
        )
        .unwrap_or(Value::Object(Default::default()));

        if let Some(obj) = result.as_object_mut() {
            obj.insert("id".to_string(), Value::String(row.get("id")));
            obj.insert(
                "updatedAt".to_string(),
                Value::String(
                    row.get::<chrono::DateTime<chrono::Utc>, _>("updated_at")
                        .to_rfc3339(),
                ),
            );
        }

        Ok(result)
    }

    async fn upsert_document(
        &self,
        collection: &str,
        id: &str,
        data: Value,
    ) -> AppResult<Value> {
        self.ensure_table(collection).await?;
        let table = sanitize_table_name(collection)?;
        let bare_id = id
            .strip_prefix(&format!("{collection}:"))
            .unwrap_or(id);
        let data_str = json_to_string(&data);

        let row = sqlx::query(&format!(
            r#"
            INSERT INTO {table} (id, data) VALUES ($1, $2::jsonb)
            ON CONFLICT (id) DO UPDATE SET data = {table}.data || EXCLUDED.data
            RETURNING id, data::TEXT, created_at, updated_at
            "#
        ))
        .bind(bare_id)
        .bind(&data_str)
        .fetch_one(&self.pool)
        .await
        .map_err(|e| ob_core::Error::Database(format!("Upsert failed: {e}")))?;

        let mut result: Value = serde_json::from_str(
            row.get::<String, _>("data").as_str()
        )
        .unwrap_or(Value::Object(Default::default()));

        if let Some(obj) = result.as_object_mut() {
            obj.insert("id".to_string(), Value::String(row.get("id")));
            obj.insert(
                "updatedAt".to_string(),
                Value::String(
                    row.get::<chrono::DateTime<chrono::Utc>, _>("updated_at")
                        .to_rfc3339(),
                ),
            );
        }

        Ok(result)
    }

    async fn delete_document(&self, collection: &str, id: &str) -> AppResult<Value> {
        self.ensure_table(collection).await?;
        let table = sanitize_table_name(collection)?;
        let bare_id = id
            .strip_prefix(&format!("{collection}:"))
            .unwrap_or(id);

        let row = sqlx::query(&format!(
            r#"DELETE FROM {table} WHERE id = $1 RETURNING id, data::TEXT"#
        ))
        .bind(bare_id)
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| ob_core::Error::Database(format!("Delete failed: {e}")))?;

        let row = row.ok_or_else(|| {
            ob_core::Error::NotFound(format!("{collection}:{bare_id} not found"))
        })?;

        let mut result: Value = serde_json::from_str(
            row.get::<String, _>("data").as_str()
        )
        .unwrap_or(Value::Object(Default::default()));

        if let Some(obj) = result.as_object_mut() {
            obj.insert("id".to_string(), Value::String(row.get("id")));
        }

        Ok(result)
    }

    async fn list_documents(
        &self,
        collection: &str,
        limit: Option<usize>,
        offset: Option<usize>,
    ) -> AppResult<Vec<Value>> {
        self.ensure_table(collection).await?;
        let table = sanitize_table_name(collection)?;
        let n = limit.unwrap_or(1000).min(10_000) as i64;
        let o = offset.unwrap_or(0) as i64;

        let rows = sqlx::query(&format!(
            r#"SELECT id, data::TEXT, created_at, updated_at FROM {table} ORDER BY created_at DESC LIMIT $1 OFFSET $2"#
        ))
        .bind(n)
        .bind(o)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| ob_core::Error::Database(format!("List failed: {e}")))?;

        let mut results = Vec::with_capacity(rows.len());
        for row in rows {
            let mut val: Value = serde_json::from_str(
                row.get::<String, _>("data").as_str()
            )
            .unwrap_or(Value::Object(Default::default()));

            if let Some(obj) = val.as_object_mut() {
                obj.insert("id".to_string(), Value::String(row.get("id")));
                obj.insert(
                    "createdAt".to_string(),
                    Value::String(
                        row.get::<chrono::DateTime<chrono::Utc>, _>("created_at")
                            .to_rfc3339(),
                    ),
                );
                obj.insert(
                    "updatedAt".to_string(),
                    Value::String(
                        row.get::<chrono::DateTime<chrono::Utc>, _>("updated_at")
                            .to_rfc3339(),
                    ),
                );
            }
            results.push(val);
        }

        Ok(results)
    }

    async fn batch_create(
        &self,
        collection: &str,
        docs: Vec<Value>,
    ) -> AppResult<Vec<Value>> {
        if docs.is_empty() {
            return Ok(vec![]);
        }
        let mut results = Vec::with_capacity(docs.len());
        for doc in docs {
            results.push(self.create_document(collection, doc).await?);
        }
        Ok(results)
    }

    async fn batch_update(
        &self,
        collection: &str,
        updates: Vec<(String, Value)>,
    ) -> AppResult<Vec<Value>> {
        if updates.is_empty() {
            return Ok(vec![]);
        }
        let mut results = Vec::with_capacity(updates.len());
        for (id, data) in updates {
            results.push(self.update_document(collection, &id, data).await?);
        }
        Ok(results)
    }

    async fn batch_delete(
        &self,
        collection: &str,
        ids: Vec<String>,
    ) -> AppResult<Vec<Value>> {
        if ids.is_empty() {
            return Ok(vec![]);
        }
        let mut results = Vec::with_capacity(ids.len());
        for id in ids {
            results.push(self.delete_document(collection, &id).await?);
        }
        Ok(results)
    }

    async fn query_raw(&self, query: &str) -> AppResult<Vec<Value>> {
        // Translate SurrealDB raw queries to PostgreSQL
        let pg_query = translate_surreal_raw(query);

        if let Some(table) = extract_table_name(&pg_query)
            && let Err(e) = self.ensure_table(&table).await
        {
            tracing::warn!("Failed to ensure table {table}: {e}");
        }
        let rows = sqlx::query(&pg_query)
            .fetch_all(&self.pool)
            .await
            .map_err(|e| ob_core::Error::Database(format!("Query failed: {e}")))?;

        rows_to_values(rows)
    }

    async fn query_raw_value(&self, query: &str) -> AppResult<Value> {
        let pg_query = translate_surreal_raw(query);

        if let Some(table) = extract_table_name(&pg_query)
            && let Err(e) = self.ensure_table(&table).await
        {
            tracing::warn!("Failed to ensure table {table}: {e}");
        }
        let row = sqlx::query(&pg_query)
            .fetch_one(&self.pool)
            .await
            .map_err(|e| ob_core::Error::Database(format!("Query failed: {e}")))?;

        let val: Value = row
            .try_get::<String, _>(0)
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or(Value::Null);
        Ok(val)
    }

    async fn query_bind(&self, query: &str, binds: Value) -> AppResult<Vec<Value>> {
        // If binds are empty, use raw translator which handles more SurrealDB patterns
        let is_empty_binds = binds.as_object().is_some_and(|o| o.is_empty());
        if is_empty_binds {
            let pg_query = translate_surreal_raw(query);
            if let Some(table) = extract_table_name(&pg_query)
                && let Err(e) = self.ensure_table(&table).await
            {
                tracing::warn!("Failed to ensure table {table}: {e}");
            }
            let rows = sqlx::query(&pg_query)
                .fetch_all(&self.pool)
                .await
                .map_err(|e| ob_core::Error::Database(format!("Query failed: {e}")))?;
            return rows_to_values(rows);
        }

        if let Some(table) = extract_table_name(query)
            && let Err(e) = self.ensure_table(&table).await
        {
            tracing::warn!("Failed to ensure table {table}: {e}");
        }
        let (pg_query, bind_values) = translate_surreal_to_pg(query, binds)?;

        let mut q = sqlx::query(&pg_query);
        for val in &bind_values {
            q = bind_json_value(q, val);
        }

        let rows = q
            .fetch_all(&self.pool)
            .await
            .map_err(|e| ob_core::Error::Database(format!("Query failed: {e}")))?;

        rows_to_values(rows)
    }

    async fn query_bind_value(&self, query: &str, binds: Value) -> AppResult<Vec<Value>> {
        // Same as query_bind for our purposes
        self.query_bind(query, binds).await
    }

    async fn update_with_field_values(
        &self,
        collection: &str,
        id: &str,
        data: Value,
    ) -> AppResult<Value> {
        // For now, treat as a regular merge update.
        // TODO Phase 2: Translate FieldValue markers (_increment, _arrayUnion, etc.)
        // to PostgreSQL JSONB operations.
        self.update_document(collection, id, data).await
    }

    async fn update_document_cas(
        &self,
        collection: &str,
        id: &str,
        data: Value,
        check_field: &str,
        check_value: &Value,
    ) -> AppResult<Option<Value>> {
        self.ensure_table(collection).await?;
        let table = sanitize_table_name(collection)?;
        let bare_id = id
            .strip_prefix(&format!("{collection}:"))
            .unwrap_or(id);
        let data_str = json_to_string(&data);
        let check_str = json_to_string(check_value);

        let row = sqlx::query(&format!(
            r#"
            UPDATE {table}
            SET data = data || $3::jsonb
            WHERE id = $1 AND data->>'{check_field}' = $2::jsonb #>> '{{}}'
            RETURNING id, data::TEXT, created_at, updated_at
            "#
        ))
        .bind(bare_id)
        .bind(&check_str)
        .bind(&data_str)
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| ob_core::Error::Database(format!("CAS update failed: {e}")))?;

        match row {
            None => Ok(None),
            Some(row) => {
                let mut result: Value = serde_json::from_str(
                    row.get::<String, _>("data").as_str()
                )
                .unwrap_or(Value::Object(Default::default()));

                if let Some(obj) = result.as_object_mut() {
                    obj.insert("id".to_string(), Value::String(row.get("id")));
                    obj.insert(
                        "updatedAt".to_string(),
                        Value::String(
                            row.get::<chrono::DateTime<chrono::Utc>, _>("updated_at")
                                .to_rfc3339(),
                        ),
                    );
                }

                Ok(Some(result))
            }
        }
    }

    // ── Filter-based query methods ─────────────────────────────────────

    /// Find documents in `collection` where `field` matches `value`
    /// using the given SQL `operator` (`=`, `!=`, `<`, `>`, `<=`, `>=`).
    ///
    /// Field comparison uses JSONB text extraction (`data->>'field'`),
    /// so all values are compared as text. Returns up to `limit`
    /// documents (unlimited when `None`).
    async fn find_where(
        &self,
        collection: &str,
        field: &str,
        operator: &str,
        value: &Value,
        limit: Option<usize>,
    ) -> AppResult<Vec<Value>> {
        self.ensure_table(collection).await?;
        let table = sanitize_table_name(collection)?;
        let limit_clause = limit.map_or(String::new(), |l| format!(" LIMIT {l}"));
        let val_str = json_to_text(value);

        let rows = sqlx::query(&format!(
            "SELECT id, data::TEXT, created_at, updated_at FROM {table} WHERE data->>'{field}' {operator} $1{limit_clause}"
        ))
        .bind(&val_str)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| ob_core::Error::Database(format!("find_where failed: {e}")))?;

        rows_to_values(rows)
    }

    /// Find documents matching multiple field conditions combined with AND.
    ///
    /// Each filter is a `(field, operator, value)` tuple. Results can be
    /// sorted via `order_by` / `order_dir` and capped with `limit`.
    /// All comparisons use JSONB text extraction (`data->>'field'`).
    async fn find_where_multi(
        &self,
        collection: &str,
        filters: &[(String, String, Value)],
        order_by: Option<&str>,
        order_dir: Option<&str>,
        limit: Option<usize>,
    ) -> AppResult<Vec<Value>> {
        self.ensure_table(collection).await?;
        let table = sanitize_table_name(collection)?;

        let mut conditions = Vec::with_capacity(filters.len());
        let mut bind_values = Vec::with_capacity(filters.len());

        for (i, (field, operator, value)) in filters.iter().enumerate() {
            conditions.push(format!("data->>'{field}' {operator} ${}", i + 1));
            bind_values.push(json_to_text(value));
        }

        let where_clause = if conditions.is_empty() {
            String::new()
        } else {
            format!(" WHERE {}", conditions.join(" AND "))
        };

        let order_clause = order_by.map_or(String::new(), |ob| {
            let dir = order_dir.unwrap_or("ASC");
            format!(" ORDER BY data->>'{ob}' {dir}")
        });

        let limit_clause = limit.map_or(String::new(), |l| format!(" LIMIT {l}"));

        let query = format!(
            "SELECT id, data::TEXT, created_at, updated_at FROM {table}{where_clause}{order_clause}{limit_clause}"
        );

        let mut q = sqlx::query(&query);
        for val in &bind_values {
            q = q.bind(val);
        }

        let rows = q
            .fetch_all(&self.pool)
            .await
            .map_err(|e| ob_core::Error::Database(format!("find_where_multi failed: {e}")))?;

        rows_to_values(rows)
    }

    async fn count_where(
        &self,
        collection: &str,
        field: &str,
        operator: &str,
        value: &Value,
    ) -> AppResult<usize> {
        self.ensure_table(collection).await?;
        let table = sanitize_table_name(collection)?;
        let val_str = json_to_text(value);

        let row = sqlx::query(&format!(
            "SELECT COUNT(*) as cnt FROM {table} WHERE data->>'{field}' {operator} $1"
        ))
        .bind(&val_str)
        .fetch_one(&self.pool)
        .await
        .map_err(|e| ob_core::Error::Database(format!("count_where failed: {e}")))?;

        let count: i64 = row.get("cnt");
        Ok(count as usize)
    }

    async fn exists_where(
        &self,
        collection: &str,
        field: &str,
        value: &Value,
    ) -> AppResult<bool> {
        self.ensure_table(collection).await?;
        let table = sanitize_table_name(collection)?;
        let val_str = json_to_text(value);

        let row = sqlx::query(&format!(
            "SELECT EXISTS(SELECT 1 FROM {table} WHERE data->>'{field}' = $1) as exists_flag"
        ))
        .bind(&val_str)
        .fetch_one(&self.pool)
        .await
        .map_err(|e| ob_core::Error::Database(format!("exists_where failed: {e}")))?;

        let exists: bool = row.get("exists_flag");
        Ok(exists)
    }

    async fn update_where(
        &self,
        collection: &str,
        field: &str,
        operator: &str,
        field_value: &Value,
        data: Value,
    ) -> AppResult<Vec<Value>> {
        self.ensure_table(collection).await?;
        let table = sanitize_table_name(collection)?;
        let filter_str = json_to_text(field_value);
        let data_str = json_to_string(&data);

        let rows = sqlx::query(&format!(
            "UPDATE {table} SET data = data || $1::jsonb, updated_at = now() \
             WHERE data->>'{field}' {operator} $2 \
             RETURNING id, data::TEXT, created_at, updated_at"
        ))
        .bind(&data_str)
        .bind(&filter_str)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| ob_core::Error::Database(format!("update_where failed: {e}")))?;

        rows_to_values(rows)
    }

    async fn delete_where(
        &self,
        collection: &str,
        field: &str,
        operator: &str,
        value: &Value,
    ) -> AppResult<usize> {
        self.ensure_table(collection).await?;
        let table = sanitize_table_name(collection)?;
        let val_str = json_to_text(value);

        let result = sqlx::query(&format!(
            "DELETE FROM {table} WHERE data->>'{field}' {operator} $1"
        ))
        .bind(&val_str)
        .execute(&self.pool)
        .await
        .map_err(|e| ob_core::Error::Database(format!("delete_where failed: {e}")))?;

        Ok(result.rows_affected() as usize)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// These tests require a running PostgreSQL instance.
    /// Run: docker exec -i orignabase-pg psql -U orignabase -d orignabase < migrations/001_full_schema.sql
    const TEST_DB_URL: &str = "postgres://orignabase:orignabase_dev@127.0.0.1:5432/orignabase";

    async fn test_store() -> PgDatabaseStore {
        PgDatabaseStore::connect(TEST_DB_URL).await.unwrap()
    }

    #[tokio::test]
    async fn test_pg_create_and_get() {
        let store = test_store().await;
        let data = serde_json::json!({"name": "Test User", "email": "test@example.com"});
        let created = store.create_document("test_users", data).await.unwrap();
        assert!(created.get("id").is_some());

        let id = created["id"].as_str().unwrap().to_string();
        let fetched = store.get_document("test_users", &id).await.unwrap();
        assert_eq!(fetched["name"], "Test User");
        assert_eq!(fetched["email"], "test@example.com");
    }

    #[tokio::test]
    async fn test_pg_update() {
        let store = test_store().await;
        let data = serde_json::json!({"name": "Alice", "age": 30});
        let created = store.create_document("test_update", data).await.unwrap();
        let id = created["id"].as_str().unwrap().to_string();

        let updated = store
            .update_document("test_update", &id, serde_json::json!({"age": 31}))
            .await
            .unwrap();
        assert_eq!(updated["age"], 31);
        assert_eq!(updated["name"], "Alice"); // preserved
    }

    #[tokio::test]
    async fn test_pg_upsert() {
        let store = test_store().await;
        let data = serde_json::json!({"key": "theme", "value": "dark"});
        let result = store
            .upsert_document("test_config", "theme_key", data)
            .await
            .unwrap();
        assert_eq!(result["value"], "dark");

        // Upsert again with new data
        let updated = store
            .upsert_document(
                "test_config",
                "theme_key",
                serde_json::json!({"value": "light"}),
            )
            .await
            .unwrap();
        assert_eq!(updated["value"], "light");
        assert_eq!(updated["key"], "theme"); // merged from previous
    }

    #[tokio::test]
    async fn test_pg_delete() {
        let store = test_store().await;
        let data = serde_json::json!({"temp": true});
        let created = store.create_document("test_del", data).await.unwrap();
        let id = created["id"].as_str().unwrap().to_string();

        let deleted = store.delete_document("test_del", &id).await.unwrap();
        assert_eq!(deleted["temp"], true);

        let result = store.get_document("test_del", &id).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_pg_list() {
        let store = test_store().await;
        for i in 0..3 {
            store
                .create_document("test_list", serde_json::json!({"i": i}))
                .await
                .unwrap();
        }
        let docs = store.list_documents("test_list", Some(2), None).await.unwrap();
        assert_eq!(docs.len(), 2);
    }

    #[tokio::test]
    async fn test_pg_list_with_offset() {
        let store = test_store().await;
        let docs = store
            .list_documents("test_list", Some(10), Some(5))
            .await
            .unwrap();
        // Just verify it doesn't error — we can't predict exact count
        assert!(docs.len() <= 10);
    }

    #[tokio::test]
    async fn test_pg_batch_create() {
        let store = test_store().await;
        let docs = vec![
            serde_json::json!({"name": "Batch1"}),
            serde_json::json!({"name": "Batch2"}),
        ];
        let results = store.batch_create("test_batch", docs).await.unwrap();
        assert_eq!(results.len(), 2);
    }

    #[tokio::test]
    async fn test_pg_get_not_found() {
        let store = test_store().await;
        let result = store.get_document("test_404", "nonexistent").await;
        assert!(result.is_err());
        assert!(result
            .unwrap_err()
            .to_string()
            .contains("not found"));
    }

    #[test]
    fn test_translate_preserves_jsonb_refs() {
        let query =
            "SELECT * FROM known_devices WHERE user_id = $uid AND device_hash = $dh LIMIT 1";
        let binds = serde_json::json!({ "uid": "test-user", "dh": "test-hash" });
        let (pg, vals) = translate_surreal_to_pg(query, binds).unwrap();
        assert!(
            pg.contains("data->>'user_id'"),
            "Should have JSONB ref for user_id, got: {pg}"
        );
        assert!(
            pg.contains("data->>'device_hash'"),
            "Should have JSONB ref for device_hash, got: {pg}"
        );
        assert!(pg.contains("$1"), "Should have $1 positional param");
        assert!(pg.contains("$2"), "Should have $2 positional param");
        assert!(!pg.contains("$uid"), "Should not have $uid anymore");
        assert!(!pg.contains("$dh"), "Should not have $dh anymore");
        assert_eq!(vals.len(), 2);
    }

    #[test]
    fn test_translate_count_and_group_all() {
        let query = "SELECT count() FROM login_lockout WHERE email = $email AND timestamp >= $window_start GROUP ALL";
        let binds = serde_json::json!({ "email": "test@test.com", "window_start": 1000 });
        let (pg, _vals) = translate_surreal_to_pg(query, binds).unwrap();
        assert!(pg.contains("COUNT(*)"), "Should rewrite count() to COUNT(*), got: {pg}");
        assert!(!pg.contains("GROUP ALL"), "Should remove GROUP ALL, got: {pg}");
        assert!(pg.contains("data->>'email'"), "Should rewrite email to JSONB, got: {pg}");
        assert!(
            pg.contains("data->>'timestamp'"),
            "Should rewrite timestamp to JSONB, got: {pg}"
        );
    }

    #[test]
    fn test_translate_delete_with_field_rewrite() {
        let query = "DELETE FROM _email_templates WHERE name = $name";
        let binds = serde_json::json!({ "name": "test" });
        let (pg, _vals) = translate_surreal_to_pg(query, binds).unwrap();
        assert!(
            pg.contains("data->>'name'"),
            "Should rewrite name to JSONB, got: {pg}"
        );
        assert!(
            !pg.contains("FROM _email_templates WHERE data->>'FROM'"),
            "Should not rewrite FROM, got: {pg}"
        );
    }
}
