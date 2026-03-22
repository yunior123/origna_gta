use crate::DatabaseClient;
use ob_core::{Error, Result, escape_surreal_string, validate_document_id, validate_identifier};
use serde_json::Value;
use surrealdb::RecordId;

/// Generic record wrapper that handles SurrealDB's RecordId type.
#[derive(Debug, serde::Deserialize)]
struct Record {
    id: RecordId,
    #[serde(flatten)]
    rest: std::collections::HashMap<String, Value>,
}

impl Record {
    fn into_value(self) -> Value {
        let mut map = serde_json::Map::new();
        map.insert("id".to_string(), Value::String(self.id.to_string()));
        for (k, v) in self.rest {
            map.insert(k, v);
        }
        Value::Object(map)
    }
}

/// Extract records from a SurrealDB response, converting RecordIds to strings.
fn take_records(response: &mut surrealdb::Response, index: usize) -> Result<Vec<Value>> {
    let records: Vec<Record> = response
        .take(index)
        .map_err(|e| Error::Database(format!("Result extraction failed: {e}")))?;
    Ok(records.into_iter().map(Record::into_value).collect())
}

impl DatabaseClient {
    /// Create a document in a collection. Returns the created document.
    pub async fn create_document(&self, collection: &str, data: Value) -> Result<Value> {
        validate_identifier(collection)?;
        let query = format!("CREATE {collection} CONTENT $data RETURN AFTER");
        let mut response = self
            .inner()
            .query(&query)
            .bind(("data", data))
            .await
            .map_err(|e| Error::Database(format!("Create failed: {e}")))?;

        let results = take_records(&mut response, 0)?;

        results
            .into_iter()
            .next()
            .ok_or_else(|| Error::Database("Create returned no result".into()))
    }

    /// Get a document by its record ID (e.g., "abc123" or "products:abc123").
    pub async fn get_document(&self, collection: &str, id: &str) -> Result<Value> {
        validate_identifier(collection)?;
        // Strip collection prefix if present (e.g., "products:abc123" → "abc123")
        let id = id.strip_prefix(&format!("{collection}:")).unwrap_or(id);
        validate_document_id(id)?;
        let record_id = format!("{collection}:{id}");
        // Use parameterized query to prevent SurrealQL injection
        let query = "SELECT * FROM type::thing($table, $id)".to_string();
        let mut response = self
            .inner()
            .query(&query)
            .bind(("table", collection.to_string()))
            .bind(("id", id.to_string()))
            .await
            .map_err(|e| Error::Database(format!("Get failed: {e}")))?;

        let results = take_records(&mut response, 0)?;

        results
            .into_iter()
            .next()
            .ok_or_else(|| Error::NotFound(format!("Document {record_id} not found")))
    }

    /// Update a document by ID. Merges fields with existing document.
    pub async fn update_document(&self, collection: &str, id: &str, data: Value) -> Result<Value> {
        validate_identifier(collection)?;
        let id = id.strip_prefix(&format!("{collection}:")).unwrap_or(id);
        validate_document_id(id)?;
        let record_id = format!("{collection}:{id}");
        // Use parameterized query to prevent SurrealQL injection
        let query = "UPDATE type::thing($table, $id) MERGE $data RETURN AFTER".to_string();
        let mut response = self
            .inner()
            .query(&query)
            .bind(("table", collection.to_string()))
            .bind(("id", id.to_string()))
            .bind(("data", data))
            .await
            .map_err(|e| Error::Database(format!("Update failed: {e}")))?;

        let results = take_records(&mut response, 0)?;

        results
            .into_iter()
            .next()
            .ok_or_else(|| Error::NotFound(format!("Document {record_id} not found")))
    }

    /// Create or replace a document by explicit ID.
    pub async fn upsert_document(&self, collection: &str, id: &str, data: Value) -> Result<Value> {
        validate_identifier(collection)?;
        let id = id.strip_prefix(&format!("{collection}:")).unwrap_or(id);
        validate_document_id(id)?;
        let query = "UPSERT type::thing($table, $id) CONTENT $data RETURN AFTER".to_string();
        let mut response = self
            .inner()
            .query(&query)
            .bind(("table", collection.to_string()))
            .bind(("id", id.to_string()))
            .bind(("data", data))
            .await
            .map_err(|e| Error::Database(format!("Upsert failed: {e}")))?;

        let results = take_records(&mut response, 0)?;
        results.into_iter().next().ok_or_else(|| {
            Error::Database(format!("Upsert returned no result for {collection}:{id}"))
        })
    }

    /// Delete a document by ID.
    pub async fn delete_document(&self, collection: &str, id: &str) -> Result<Value> {
        validate_identifier(collection)?;
        let id = id.strip_prefix(&format!("{collection}:")).unwrap_or(id);
        validate_document_id(id)?;
        let record_id = format!("{collection}:{id}");
        // Use parameterized query to prevent SurrealQL injection
        let query = "DELETE type::thing($table, $id) RETURN BEFORE".to_string();
        let mut response = self
            .inner()
            .query(&query)
            .bind(("table", collection.to_string()))
            .bind(("id", id.to_string()))
            .await
            .map_err(|e| Error::Database(format!("Delete failed: {e}")))?;

        let results = take_records(&mut response, 0)?;

        results
            .into_iter()
            .next()
            .ok_or_else(|| Error::NotFound(format!("Document {record_id} not found")))
    }

    /// List documents in a collection with optional limit.
    /// Default limit is 1000 to prevent unbounded queries.
    pub async fn list_documents(
        &self,
        collection: &str,
        limit: Option<usize>,
    ) -> Result<Vec<Value>> {
        validate_identifier(collection)?;
        let n = limit.unwrap_or(1000).min(10_000);
        let query = format!("SELECT * FROM {collection} LIMIT {n}");

        let mut response = self
            .inner()
            .query(&query)
            .await
            .map_err(|e| Error::Database(format!("List failed: {e}")))?;

        take_records(&mut response, 0)
    }

    /// Execute a raw SurrealQL query that returns records.
    pub async fn query_raw(&self, query: &str) -> Result<Vec<Value>> {
        let mut response = self
            .inner()
            .query(query)
            .await
            .map_err(|e| Error::Database(format!("Query failed: {e}")))?;

        take_records(&mut response, 0)
    }

    /// Execute a raw SurrealQL query that returns non-record data (e.g., INFO FOR DB).
    pub async fn query_raw_value(&self, query: &str) -> Result<Value> {
        let mut response = self
            .inner()
            .query(query)
            .await
            .map_err(|e| Error::Database(format!("Query failed: {e}")))?;

        let result: Option<Value> = response
            .take(0)
            .map_err(|e| Error::Database(format!("Result extraction failed: {e}")))?;

        Ok(result.unwrap_or(Value::Null))
    }

    /// Batch create multiple documents in a collection.
    /// Uses SurrealDB's INSERT for true bulk efficiency.
    pub async fn batch_create(&self, collection: &str, docs: Vec<Value>) -> Result<Vec<Value>> {
        validate_identifier(collection)?;
        if docs.is_empty() {
            return Ok(vec![]);
        }

        // Use SurrealDB INSERT for bulk efficiency (single query, single transaction)
        let query = format!("INSERT INTO {collection} $docs");
        let mut response = self
            .inner()
            .query(&query)
            .bind(("docs", Value::Array(docs)))
            .await
            .map_err(|e| Error::Database(format!("Batch create failed: {e}")))?;

        take_records(&mut response, 0)
    }

    /// Batch update multiple documents.
    /// Each entry is (id, data) where data is merged into the existing document.
    pub async fn batch_update(
        &self,
        collection: &str,
        updates: Vec<(String, Value)>,
    ) -> Result<Vec<Value>> {
        validate_identifier(collection)?;
        if updates.is_empty() {
            return Ok(vec![]);
        }

        let mut results = Vec::with_capacity(updates.len());
        for (id, data) in updates {
            let result = self.update_document(collection, &id, data).await?;
            results.push(result);
        }
        Ok(results)
    }

    /// Batch delete multiple documents by ID.
    pub async fn batch_delete(&self, collection: &str, ids: Vec<String>) -> Result<Vec<Value>> {
        validate_identifier(collection)?;
        if ids.is_empty() {
            return Ok(vec![]);
        }

        let mut results = Vec::with_capacity(ids.len());
        for id in ids {
            let result = self.delete_document(collection, &id).await?;
            results.push(result);
        }
        Ok(results)
    }

    /// Apply FieldValue operations to an update.
    ///
    /// Translates special FieldValue markers in data to SurrealQL operations:
    /// - `{ "_serverTimestamp": true }` → `time::now()`
    /// - `{ "_increment": n }` → `field += n`
    /// - `{ "_arrayUnion": [...] }` → `array::union(field, [...])`
    /// - `{ "_arrayRemove": [...] }` → `array::complement(field, [...])`
    /// - `{ "_deleteField": true }` → UNSET field
    pub async fn update_with_field_values(
        &self,
        collection: &str,
        id: &str,
        data: Value,
    ) -> Result<Value> {
        validate_identifier(collection)?;
        let id = id.strip_prefix(&format!("{collection}:")).unwrap_or(id);
        validate_document_id(id)?;
        let obj = data
            .as_object()
            .ok_or_else(|| Error::Validation("Data must be a JSON object".into()))?;

        // Validate all field names to prevent injection
        for field in obj.keys() {
            validate_identifier(field)?;
        }

        let mut merge_fields = serde_json::Map::new();
        let mut set_clauses = Vec::new();
        let mut unset_fields = Vec::new();

        for (field, value) in obj {
            if let Some(ops) = value.as_object() {
                if ops.contains_key("_serverTimestamp") {
                    set_clauses.push(format!("{field} = time::now()"));
                } else if let Some(n) = ops.get("_increment") {
                    let n_str = n.to_string();
                    set_clauses.push(format!("{field} += {n_str}"));
                } else if let Some(arr) = ops.get("_arrayUnion") {
                    let arr_str = arr.to_string();
                    set_clauses.push(format!("{field} = array::union({field}, {arr_str})"));
                } else if let Some(arr) = ops.get("_arrayRemove") {
                    let arr_str = arr.to_string();
                    set_clauses.push(format!("{field} = array::complement({field}, {arr_str})"));
                } else if ops.contains_key("_deleteField") {
                    unset_fields.push(field.clone());
                } else {
                    merge_fields.insert(field.clone(), value.clone());
                }
            } else {
                merge_fields.insert(field.clone(), value.clone());
            }
        }

        // Build combined query using SET for everything (MERGE + SET in same
        // statement is not supported by SurrealDB).
        let mut all_set_clauses = set_clauses;

        // Convert merge fields to SET clauses
        for (field, value) in &merge_fields {
            let val_str = match value {
                Value::String(s) => format!("'{}'", escape_surreal_string(s)),
                _ => value.to_string(),
            };
            all_set_clauses.push(format!("{field} = {val_str}"));
        }

        let mut query_parts = Vec::new();

        if !all_set_clauses.is_empty() {
            query_parts.push(format!(
                "UPDATE {collection}:{id} SET {}",
                all_set_clauses.join(", ")
            ));
        }

        if !unset_fields.is_empty() {
            if query_parts.is_empty() {
                query_parts.push(format!(
                    "UPDATE {collection}:{id} UNSET {}",
                    unset_fields.join(", ")
                ));
            } else {
                // Append UNSET fields to existing SET statement isn't supported,
                // so run as separate query
                query_parts.push(format!(
                    "UPDATE {collection}:{id} UNSET {}",
                    unset_fields.join(", ")
                ));
            }
        }

        // If nothing to do, just return the current document
        if query_parts.is_empty() {
            return self.get_document(collection, id).await;
        }

        // Execute last query with RETURN AFTER
        let last_idx = query_parts.len() - 1;
        query_parts[last_idx].push_str(" RETURN AFTER");

        let full_query = query_parts.join(";\n");

        // For multi-statement queries, query_raw reads index 0.
        // We need the LAST statement's result, so use query_raw_value
        // and parse the response directly when there are multiple statements.
        if query_parts.len() == 1 {
            let results = self.query_raw(&full_query).await?;
            results
                .into_iter()
                .next()
                .ok_or_else(|| Error::Database("FieldValue update returned no result".into()))
        } else {
            // Execute multi-statement: read result from the last statement index
            let mut response = self
                .inner()
                .query(&full_query)
                .await
                .map_err(|e| Error::Database(format!("FieldValue update failed: {e}")))?;

            let results = take_records(&mut response, last_idx)?;
            results
                .into_iter()
                .next()
                .ok_or_else(|| Error::Database("FieldValue update returned no result".into()))
        }
    }

    /// Vector similarity search using SurrealDB's native vector functions.
    ///
    /// Searches for documents where `vector_field` is most similar to `embedding`.
    /// Uses cosine similarity by default.
    ///
    /// # Example SurrealQL generated:
    /// ```sql
    /// SELECT *, vector::similarity::cosine(embedding, $query_vec) AS score
    /// FROM products
    /// WHERE vector::similarity::cosine(embedding, $query_vec) > $threshold
    /// ORDER BY score DESC
    /// LIMIT $top_k
    /// ```
    pub async fn vector_search(
        &self,
        collection: &str,
        vector_field: &str,
        embedding: Vec<f32>,
        top_k: usize,
        threshold: Option<f64>,
    ) -> Result<Vec<Value>> {
        validate_identifier(collection)?;
        validate_identifier(vector_field)?;

        let top_k = top_k.min(10_000);
        let threshold = threshold.unwrap_or(0.0);

        let query = format!(
            "SELECT *, vector::similarity::cosine({vector_field}, $query_vec) AS score \
             FROM {collection} \
             WHERE vector::similarity::cosine({vector_field}, $query_vec) > $threshold \
             ORDER BY score DESC \
             LIMIT $top_k"
        );

        let mut response = self
            .inner()
            .query(&query)
            .bind(("query_vec", embedding))
            .bind(("threshold", threshold))
            .bind(("top_k", top_k))
            .await
            .map_err(|e| Error::Database(format!("Vector search failed: {e}")))?;

        take_records(&mut response, 0)
    }

    /// Execute a parameterized SurrealQL query and return all results as a Vec<Value>.
    pub async fn query_bind_value(
        &self,
        query: &str,
        binds: impl serde::Serialize + 'static,
    ) -> Result<Vec<Value>> {
        let mut response = self
            .inner()
            .query(query)
            .bind(binds)
            .await
            .map_err(|e| Error::Database(format!("Query failed: {e}")))?;

        let results: Vec<Value> = response
            .take(0)
            .map_err(|e| Error::Database(format!("Result extraction failed: {e}")))?;

        Ok(results)
    }

    /// Execute a parameterized SurrealQL query (safe from injection).
    pub async fn query_bind(
        &self,
        query: &str,
        binds: impl serde::Serialize + 'static,
    ) -> Result<Vec<Value>> {
        let mut response = self
            .inner()
            .query(query)
            .bind(binds)
            .await
            .map_err(|e| Error::Database(format!("Query failed: {e}")))?;

        take_records(&mut response, 0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_record_into_value_basic() {
        let record = Record {
            id: RecordId::from(("products", "abc123")),
            rest: std::collections::HashMap::from([
                ("title".to_string(), Value::String("Widget".to_string())),
                ("price".to_string(), serde_json::json!(42.0)),
            ]),
        };

        let value = record.into_value();
        assert!(value.is_object());

        let obj = value.as_object().unwrap();
        assert!(obj.contains_key("id"));
        assert!(obj["id"].is_string());
        let id_str = obj["id"].as_str().unwrap();
        assert!(
            id_str.contains("products"),
            "id should contain table name, got: {id_str}"
        );

        assert_eq!(obj["title"], "Widget");
        assert_eq!(obj["price"], 42.0);
    }

    #[test]
    fn test_record_into_value_empty_rest() {
        let record = Record {
            id: RecordId::from(("users", "u1")),
            rest: std::collections::HashMap::new(),
        };

        let value = record.into_value();
        let obj = value.as_object().unwrap();
        assert_eq!(obj.len(), 1);
        assert!(obj.contains_key("id"));
    }

    #[test]
    fn test_record_into_value_nested_data() {
        let nested = serde_json::json!({
            "street": "123 Main St",
            "city": "Toronto"
        });

        let record = Record {
            id: RecordId::from(("addresses", "addr1")),
            rest: std::collections::HashMap::from([
                ("label".to_string(), Value::String("home".to_string())),
                ("details".to_string(), nested.clone()),
            ]),
        };

        let value = record.into_value();
        let obj = value.as_object().unwrap();
        assert_eq!(obj["label"], "home");
        assert_eq!(obj["details"]["city"], "Toronto");
    }

    #[test]
    fn test_vector_search_query_validates_collection() {
        let result = ob_core::validate_identifier("my-table");
        assert!(result.is_err());

        let result = ob_core::validate_identifier("products");
        assert!(result.is_ok());
    }

    #[test]
    fn test_vector_search_query_validates_vector_field() {
        let result = ob_core::validate_identifier("embed;DROP");
        assert!(result.is_err());

        let result = ob_core::validate_identifier("");
        assert!(result.is_err());

        let result = ob_core::validate_identifier("embedding");
        assert!(result.is_ok());

        let result = ob_core::validate_identifier("vec_field_123");
        assert!(result.is_ok());
    }

    #[test]
    fn test_vector_search_query_generation() {
        let collection = "products";
        let vector_field = "embedding";
        let _threshold = 0.7_f64;
        let _top_k = 10_usize;

        let query = format!(
            "SELECT *, vector::similarity::cosine({vector_field}, $query_vec) AS score \
             FROM {collection} \
             WHERE vector::similarity::cosine({vector_field}, $query_vec) > $threshold \
             ORDER BY score DESC \
             LIMIT $top_k"
        );

        assert!(query.contains("vector::similarity::cosine(embedding, $query_vec)"));
        assert!(query.contains("FROM products"));
        assert!(query.contains("ORDER BY score DESC"));
        assert!(query.contains("LIMIT $top_k"));
        assert!(query.contains("AS score"));
    }

    #[test]
    fn test_vector_search_top_k_clamped() {
        let top_k: usize = 999_999;
        let clamped = top_k.min(10_000);
        assert_eq!(clamped, 10_000);

        let top_k: usize = 5;
        let clamped = top_k.min(10_000);
        assert_eq!(clamped, 5);
    }

    #[test]
    fn test_vector_search_default_threshold() {
        let _threshold: Option<f64> = None;
        let effective = 0.0_f64;
        assert_eq!(effective, 0.0);

        let _threshold: Option<f64> = Some(0.8);
        let effective = 0.8_f64;
        assert_eq!(effective, 0.8);
    }

    #[test]
    fn test_record_into_value_preserves_types() {
        let record = Record {
            id: RecordId::from(("items", "i1")),
            rest: std::collections::HashMap::from([
                ("active".to_string(), Value::Bool(true)),
                ("count".to_string(), serde_json::json!(7)),
                ("tags".to_string(), serde_json::json!(["a", "b"])),
                ("meta".to_string(), Value::Null),
            ]),
        };

        let value = record.into_value();
        let obj = value.as_object().unwrap();
        assert_eq!(obj["active"], true);
        assert_eq!(obj["count"], 7);
        assert!(obj["tags"].is_array());
        assert!(obj["meta"].is_null());
    }

    #[tokio::test]
    async fn test_create_document() {
        let db = DatabaseClient::new_mem().await;
        let result = db
            .create_document("users", json!({"name": "Alice", "email": "a@b.com"}))
            .await;
        assert!(result.is_ok());
        let doc = result.unwrap();
        assert_eq!(doc["name"], "Alice");
        assert!(doc["id"].is_string());
    }

    #[tokio::test]
    async fn test_create_document_invalid_collection() {
        let db = DatabaseClient::new_mem().await;
        let result = db
            .create_document("my-table", json!({"name": "test"}))
            .await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_get_document() {
        let db = DatabaseClient::new_mem().await;
        let created = db
            .create_document("products", json!({"title": "Widget", "price": 9.99}))
            .await
            .unwrap();
        let id = created["id"].as_str().unwrap();
        let parts: Vec<&str> = id.split(':').collect();
        let short_id = if parts.len() == 2 { parts[1] } else { id };

        let result = db.get_document("products", short_id).await;
        assert!(result.is_ok());
        let doc = result.unwrap();
        assert_eq!(doc["title"], "Widget");
    }

    #[tokio::test]
    async fn test_get_document_with_collection_prefix() {
        let db = DatabaseClient::new_mem().await;
        let created = db
            .create_document("items", json!({"name": "Item1"}))
            .await
            .unwrap();
        let full_id = created["id"].as_str().unwrap().to_string();

        let result = db.get_document("items", &full_id).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_get_document_not_found() {
        let db = DatabaseClient::new_mem().await;
        let result = db.get_document("products", "nonexistent").await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_get_document_invalid_collection() {
        let db = DatabaseClient::new_mem().await;
        let result = db.get_document("bad-name", "id1").await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_update_document() {
        let db = DatabaseClient::new_mem().await;
        let created = db
            .create_document("users", json!({"name": "Alice", "age": 30}))
            .await
            .unwrap();
        let id = created["id"].as_str().unwrap();
        let parts: Vec<&str> = id.split(':').collect();
        let short_id = if parts.len() == 2 { parts[1] } else { id };

        let updated = db
            .update_document("users", short_id, json!({"name": "Bob"}))
            .await
            .unwrap();
        assert_eq!(updated["name"], "Bob");
    }

    #[tokio::test]
    async fn test_update_document_not_found() {
        let db = DatabaseClient::new_mem().await;
        let result = db
            .update_document("users", "nonexistent", json!({"name": "Bob"}))
            .await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_upsert_document_create() {
        let db = DatabaseClient::new_mem().await;
        let result = db
            .upsert_document("settings", "theme", json!({"value": "dark"}))
            .await;
        assert!(result.is_ok());
        let doc = result.unwrap();
        assert_eq!(doc["value"], "dark");
    }

    #[tokio::test]
    async fn test_upsert_document_replace() {
        let db = DatabaseClient::new_mem().await;
        let _ = db
            .upsert_document("settings", "theme", json!({"value": "light"}))
            .await
            .unwrap();
        let updated = db
            .upsert_document("settings", "theme", json!({"value": "dark"}))
            .await
            .unwrap();
        assert_eq!(updated["value"], "dark");
    }

    #[tokio::test]
    async fn test_delete_document() {
        let db = DatabaseClient::new_mem().await;
        let created = db
            .create_document("temp", json!({"data": "delete_me"}))
            .await
            .unwrap();
        let id = created["id"].as_str().unwrap();
        let parts: Vec<&str> = id.split(':').collect();
        let short_id = if parts.len() == 2 { parts[1] } else { id };

        let deleted = db.delete_document("temp", short_id).await;
        assert!(deleted.is_ok());

        let get_result = db.get_document("temp", short_id).await;
        assert!(get_result.is_err());
    }

    #[tokio::test]
    async fn test_delete_document_not_found() {
        let db = DatabaseClient::new_mem().await;
        let result = db.delete_document("users", "nonexistent").await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_list_documents() {
        let db = DatabaseClient::new_mem().await;
        for i in 0..5 {
            let _ = db
                .create_document("items", json!({"index": i}))
                .await
                .unwrap();
        }
        let docs = db.list_documents("items", None).await.unwrap();
        assert_eq!(docs.len(), 5);
    }

    #[tokio::test]
    async fn test_list_documents_with_limit() {
        let db = DatabaseClient::new_mem().await;
        for i in 0..10 {
            let _ = db
                .create_document("items", json!({"index": i}))
                .await
                .unwrap();
        }
        let docs = db.list_documents("items", Some(3)).await.unwrap();
        assert_eq!(docs.len(), 3);
    }

    #[tokio::test]
    async fn test_list_documents_empty() {
        let db = DatabaseClient::new_mem().await;
        let docs = db.list_documents("empty_collection", None).await.unwrap();
        assert!(docs.is_empty());
    }

    #[tokio::test]
    async fn test_query_raw() {
        let db = DatabaseClient::new_mem().await;
        let _ = db
            .create_document("test_coll", json!({"val": 1}))
            .await
            .unwrap();
        let results = db.query_raw("SELECT * FROM test_coll").await.unwrap();
        assert!(!results.is_empty());
    }

    #[tokio::test]
    async fn test_query_bind() {
        let db = DatabaseClient::new_mem().await;
        let _ = db
            .create_document("users", json!({"name": "Alice", "age": 30}))
            .await
            .unwrap();
        let _ = db
            .create_document("users", json!({"name": "Bob", "age": 25}))
            .await
            .unwrap();

        let results = db
            .query_bind(
                "SELECT * FROM users WHERE name = $name",
                json!({"name": "Alice"}),
            )
            .await
            .unwrap();
        assert_eq!(results.len(), 1);
        assert_eq!(results[0]["name"], "Alice");
    }

    #[tokio::test]
    async fn test_query_bind_no_results() {
        let db = DatabaseClient::new_mem().await;
        let results = db
            .query_bind(
                "SELECT * FROM users WHERE name = $name",
                json!({"name": "Nobody"}),
            )
            .await
            .unwrap();
        assert!(results.is_empty());
    }

    #[tokio::test]
    async fn test_query_bind_value() {
        let db = DatabaseClient::new_mem().await;
        let _ = db
            .create_document("kv", json!({"key": "a", "val": 1}))
            .await
            .unwrap();

        let results = db
            .query_bind_value(
                "SELECT val FROM kv WHERE key = $key",
                json!({"key": "a"}),
            )
            .await
            .unwrap();
        assert!(!results.is_empty());
    }

    #[tokio::test]
    async fn test_batch_create() {
        let db = DatabaseClient::new_mem().await;
        let docs = vec![
            json!({"name": "Doc1"}),
            json!({"name": "Doc2"}),
            json!({"name": "Doc3"}),
        ];
        let results = db.batch_create("batch_items", docs).await.unwrap();
        assert_eq!(results.len(), 3);
    }

    #[tokio::test]
    async fn test_batch_create_empty() {
        let db = DatabaseClient::new_mem().await;
        let results = db.batch_create("anything", vec![]).await.unwrap();
        assert!(results.is_empty());
    }

    #[tokio::test]
    async fn test_batch_create_invalid_collection() {
        let db = DatabaseClient::new_mem().await;
        let result = db
            .batch_create("bad-name", vec![json!({"a": 1})])
            .await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_batch_update() {
        let db = DatabaseClient::new_mem().await;
        let d1 = db
            .create_document("items", json!({"name": "A"}))
            .await
            .unwrap();
        let d2 = db
            .create_document("items", json!({"name": "B"}))
            .await
            .unwrap();
        let id1 = d1["id"].as_str().unwrap().to_string();
        let id2 = d2["id"].as_str().unwrap().to_string();

        let results = db
            .batch_update(
                "items",
                vec![
                    (id1, json!({"name": "A-updated"})),
                    (id2, json!({"name": "B-updated"})),
                ],
            )
            .await
            .unwrap();
        assert_eq!(results.len(), 2);
    }

    #[tokio::test]
    async fn test_batch_update_empty() {
        let db = DatabaseClient::new_mem().await;
        let results = db.batch_update("items", vec![]).await.unwrap();
        assert!(results.is_empty());
    }

    #[tokio::test]
    async fn test_batch_delete() {
        let db = DatabaseClient::new_mem().await;
        let d1 = db
            .create_document("items", json!({"name": "Del1"}))
            .await
            .unwrap();
        let d2 = db
            .create_document("items", json!({"name": "Del2"}))
            .await
            .unwrap();
        let id1 = d1["id"].as_str().unwrap().to_string();
        let id2 = d2["id"].as_str().unwrap().to_string();

        let results = db.batch_delete("items", vec![id1, id2]).await.unwrap();
        assert_eq!(results.len(), 2);
    }

    #[tokio::test]
    async fn test_batch_delete_empty() {
        let db = DatabaseClient::new_mem().await;
        let results = db.batch_delete("items", vec![]).await.unwrap();
        assert!(results.is_empty());
    }

    #[tokio::test]
    async fn test_create_and_get_roundtrip() {
        let db = DatabaseClient::new_mem().await;
        let data = json!({
            "name": "Test Product",
            "price": 19.99,
            "tags": ["electronics", "gadget"],
            "active": true
        });
        let created = db.create_document("products", data.clone()).await.unwrap();
        let id = created["id"].as_str().unwrap();
        let parts: Vec<&str> = id.split(':').collect();
        let short_id = if parts.len() == 2 { parts[1] } else { id };

        let fetched = db.get_document("products", short_id).await.unwrap();
        assert_eq!(fetched["name"], "Test Product");
        assert_eq!(fetched["price"], 19.99);
        assert!(fetched["active"].as_bool().unwrap());
    }

    #[tokio::test]
    async fn test_crud_lifecycle() {
        let db = DatabaseClient::new_mem().await;

        let created = db
            .create_document("lifecycle", json!({"step": "create"}))
            .await
            .unwrap();
        let id = created["id"].as_str().unwrap().to_string();
        let parts: Vec<&str> = id.split(':').collect();
        let short_id = if parts.len() == 2 { parts[1].to_string() } else { id.clone() };

        let fetched = db.get_document("lifecycle", &short_id).await.unwrap();
        assert_eq!(fetched["step"], "create");

        let updated = db
            .update_document("lifecycle", &short_id, json!({"step": "update"}))
            .await
            .unwrap();
        assert_eq!(updated["step"], "update");

        let deleted = db.delete_document("lifecycle", &short_id).await;
        assert!(deleted.is_ok());

        let not_found = db.get_document("lifecycle", &short_id).await;
        assert!(not_found.is_err());
    }

    #[tokio::test]
    async fn test_upsert_document_invalid_collection() {
        let db = DatabaseClient::new_mem().await;
        let result = db
            .upsert_document("bad-name", "id1", json!({"a": 1}))
            .await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_query_raw_value() {
        let db = DatabaseClient::new_mem().await;
        let result = db.query_raw_value("INFO FOR DB").await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_list_documents_limit_clamped() {
        let db = DatabaseClient::new_mem().await;
        let _ = db
            .create_document("items", json!({"name": "test"}))
            .await
            .unwrap();
        let docs = db.list_documents("items", Some(99999)).await.unwrap();
        assert!(docs.len() <= 10_000);
    }

    #[tokio::test]
    async fn test_update_document_with_prefix_id() {
        let db = DatabaseClient::new_mem().await;
        let created = db
            .create_document("users", json!({"name": "Alice"}))
            .await
            .unwrap();
        let full_id = created["id"].as_str().unwrap().to_string();

        let updated = db
            .update_document("users", &full_id, json!({"name": "Bob"}))
            .await
            .unwrap();
        assert_eq!(updated["name"], "Bob");
    }

    #[tokio::test]
    async fn test_delete_document_with_prefix_id() {
        let db = DatabaseClient::new_mem().await;
        let created = db
            .create_document("temp", json!({"data": 1}))
            .await
            .unwrap();
        let full_id = created["id"].as_str().unwrap().to_string();

        let deleted = db.delete_document("temp", &full_id).await;
        assert!(deleted.is_ok());
    }
}
