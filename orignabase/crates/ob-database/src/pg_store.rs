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

/// Serialize a JSONB Value to a string for sqlx binding.
fn json_to_string(val: &Value) -> String {
    serde_json::to_string(val).unwrap_or_else(|_| "{}".to_string())
}

/// Translate legacy named parameters ($name) to PostgreSQL positional ($1, $2).
/// Also rewrites document field references to JSONB data column access.
/// Returns (translated_query, ordered_values).
pub(crate) fn translate_surreal_to_pg(query: &str, binds: Value) -> AppResult<(String, Vec<Value>)> {
    let obj = binds
        .as_object()
        .ok_or_else(|| ob_core::Error::Database("Binds must be a JSON object".into()))?;

    // Extract key-value pairs in insertion order
    let pairs: Vec<(String, Value)> = obj
        .iter()
        .map(|(k, v)| (k.clone(), v.clone()))
        .collect();

    let mut pg_query = query.to_string();

    // Rewrite legacy query syntax to PostgreSQL equivalents
    pg_query = pg_query.replace("count()", "COUNT(*)");
    pg_query = pg_query.replace("COUNT()", "COUNT(*)");
    if pg_query.contains(" GROUP ALL") {
        pg_query = pg_query.replace(" GROUP ALL", "");
    }

    // Rewrite document field references AND replace named params atomically.
    // For each $param, find the field name it's compared against and rewrite to JSONB access.
    let standard_columns = ["id", "created_at", "updated_at", "data"];
    for (i, (name, _)) in pairs.iter().enumerate() {
        let placeholder = format!("${name}");
        let pg_placeholder = format!("${}", i + 1);

        if !standard_columns.contains(&name.as_str()) {
            // Find each occurrence of $param and extract the field name before it
            let mut result = String::with_capacity(pg_query.len() + 32);
            let mut remaining = pg_query.as_str();

            while let Some(pos) = remaining.find(&placeholder) {
                let before = &remaining[..pos];
                let after = &remaining[pos + placeholder.len()..];

                // Extract the field name by finding the comparison operator
                // and taking the word immediately before it.
                // This avoids matching the field name elsewhere in the query (e.g. "FROM name_table").
                let before_trimmed = before.trim_end();
                let operators = ["!=", "<>", ">=", "<=", "=", ">", "<"];
                let mut field_name = "";
                let mut field_start_idx = before.len();

                for op in &operators {
                    if let Some(op_pos) = before_trimmed.rfind(op) {
                        let after_op = &before_trimmed[op_pos + op.len()..];
                        // Make sure this is truly the operator (after_op should be empty/whitespace)
                        if after_op.trim().is_empty() {
                            let field_part = before_trimmed[..op_pos].trim_end();
                            // Get the field name: text after the last whitespace
                            if let Some(last_ws) = field_part.rfind(char::is_whitespace) {
                                let candidate = field_part[last_ws..].trim();
                                if !candidate.is_empty()
                                    && candidate
                                        .chars()
                                        .all(|c| c.is_alphanumeric() || c == '_')
                                {
                                    field_name = candidate;
                                    // Find where field_name starts in `before`
                                    field_start_idx =
                                        before[..op_pos].rfind(field_name).unwrap_or(op_pos);
                                    break;
                                }
                            } else {
                                // No whitespace — the entire field_part is the field name
                                let candidate = field_part.trim();
                                if !candidate.is_empty()
                                    && candidate
                                        .chars()
                                        .all(|c| c.is_alphanumeric() || c == '_')
                                {
                                    field_name = candidate;
                                    field_start_idx =
                                        before.rfind(field_name).unwrap_or(op_pos);
                                    break;
                                }
                            }
                        }
                    }
                }

                if !field_name.is_empty() && !standard_columns.contains(&field_name) {
                    let op_str =
                        &before_trimmed[before_trimmed.rfind(field_name).unwrap_or(0) + field_name.len()..].trim();
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

    let values: Vec<Value> = pairs.into_iter().map(|(_, v)| v).collect();
    Ok((pg_query, values))
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
            r#"INSERT INTO {table} (id, data) VALUES ($1, $2::jsonb) RETURNING id, data::TEXT, created_at, updated_at"#
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
        if let Some(table) = extract_table_name(query)
            && let Err(e) = self.ensure_table(&table).await
        {
            tracing::warn!("Failed to ensure table {table}: {e}");
        }
        let rows = sqlx::query(query)
            .fetch_all(&self.pool)
            .await
            .map_err(|e| ob_core::Error::Database(format!("Query failed: {e}")))?;

        rows_to_values(rows)
    }

    async fn query_raw_value(&self, query: &str) -> AppResult<Value> {
        if let Some(table) = extract_table_name(query)
            && let Err(e) = self.ensure_table(&table).await
        {
            tracing::warn!("Failed to ensure table {table}: {e}");
        }
        let row = sqlx::query(query)
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
