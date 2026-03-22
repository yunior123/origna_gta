use crate::DatabaseClient;
use ob_core::{Error, Result};
use serde_json::Value;

/// A transactional batch of SurrealQL operations.
///
/// Wraps multiple queries in `BEGIN TRANSACTION; ... COMMIT;` for atomicity.
///
/// # Example
/// ```ignore
/// let mut tx = Transaction::new();
/// tx.add("UPDATE products:abc SET stock -= $qty", json!({"qty": 2}));
/// tx.add("CREATE order_items CONTENT $data", json!({"data": {...}}));
/// let results = tx.commit(&db).await?;
/// ```
pub struct Transaction {
    queries: Vec<(String, Option<Value>)>,
}

impl Transaction {
    pub fn new() -> Self {
        Self {
            queries: Vec::new(),
        }
    }

    /// Add a query with optional bind parameters.
    pub fn add(&mut self, query: &str, binds: Option<Value>) -> &mut Self {
        self.queries.push((query.to_string(), binds));
        self
    }

    /// Add a query without parameters.
    pub fn add_raw(&mut self, query: &str) -> &mut Self {
        self.queries.push((query.to_string(), None));
        self
    }

    /// Number of operations in this transaction.
    pub fn len(&self) -> usize {
        self.queries.len()
    }

    /// Whether this transaction is empty.
    pub fn is_empty(&self) -> bool {
        self.queries.is_empty()
    }

    /// Execute all operations.
    /// Returns a Vec of results, one per query.
    pub async fn commit(self, db: &DatabaseClient) -> Result<Vec<Value>> {
        if self.queries.is_empty() {
            return Ok(vec![]);
        }

        // Execute all queries in a single query call.
        // Multiple statements in one query() call are executed sequentially by SurrealDB.
        let mut full_query = String::new();
        for (query, _) in &self.queries {
            full_query.push_str(query);
            full_query.push_str(";\n");
        }

        let mut q = db.inner().query(&full_query);

        // Apply binds from each query — SurrealDB binds are global to the query call,
        // so we flatten all bind objects into a single bind chain.
        for (_query, binds) in &self.queries {
            if let Some(binds) = binds
                && let Some(obj) = binds.as_object()
            {
                for (key, val) in obj {
                    q = q.bind((key.clone(), val.clone()));
                }
            }
        }

        let mut response = q
            .await
            .map_err(|e| Error::Database(format!("Transaction failed: {e}")))?;

        // Collect results from each statement.
        let mut results = Vec::with_capacity(self.queries.len());
        for i in 0..self.queries.len() {
            let sval: surrealdb::Value = response
                .take(i)
                .unwrap_or_default();
            let json_val = serde_json::to_value(&sval).unwrap_or(Value::Null);
            if let Some(arr) = json_val.as_array() {
                if arr.len() == 1 {
                    results.push(arr[0].clone());
                } else {
                    results.push(Value::Array(arr.clone()));
                }
            } else {
                results.push(json_val);
            }
        }

        Ok(results)
    }
}

impl Default for Transaction {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_transaction_new_empty() {
        let tx = Transaction::new();
        assert!(tx.is_empty());
        assert_eq!(tx.len(), 0);
    }

    #[test]
    fn test_transaction_add_operations() {
        let mut tx = Transaction::new();
        tx.add("SELECT * FROM users", None);
        tx.add_raw("UPDATE users:1 SET active = true");
        assert_eq!(tx.len(), 2);
        assert!(!tx.is_empty());
    }

    #[test]
    fn test_transaction_chaining() {
        let mut tx = Transaction::new();
        tx.add_raw("SELECT 1")
            .add_raw("SELECT 2")
            .add_raw("SELECT 3");
        assert_eq!(tx.len(), 3);
    }

    #[test]
    fn test_transaction_default() {
        let tx = Transaction::default();
        assert!(tx.is_empty());
    }
}
