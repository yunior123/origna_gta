use crate::SearchClient;
use serde_json::{Value, json};
use tokio::sync::mpsc;

/// Change event received from the realtime dispatcher for search sync.
#[derive(Debug, Clone)]
pub struct SearchSyncEvent {
    pub action: SearchAction,
    pub index: String,
    pub document_id: String,
    pub data: Value,
}

#[derive(Debug, Clone)]
pub enum SearchAction {
    Upsert,
    Delete,
}

/// Background task that syncs database changes to Meilisearch.
pub struct SearchSyncer {
    client: SearchClient,
    receiver: mpsc::Receiver<SearchSyncEvent>,
}

impl SearchSyncer {
    pub fn new(client: SearchClient) -> (Self, mpsc::Sender<SearchSyncEvent>) {
        let (tx, rx) = mpsc::channel(1024);
        (
            Self {
                client,
                receiver: rx,
            },
            tx,
        )
    }

    /// Run the sync loop — batches events and flushes to Meilisearch.
    pub async fn run(mut self) {
        if self.client.is_enabled() {
            tracing::info!("Search syncer started");
        } else {
            tracing::info!("Search syncer disabled; no search backend configured");
        }

        while let Some(event) = self.receiver.recv().await {
            match event.action {
                SearchAction::Upsert => {
                    let payload = normalize_document_for_indexing(&event.document_id, &event.data);
                    if let Err(e) = self.client.upsert_documents(&event.index, &[payload]).await {
                        tracing::error!(
                            index = %event.index,
                            doc_id = %event.document_id,
                            "Search sync upsert failed: {e}"
                        );
                    }
                }
                SearchAction::Delete => {
                    if let Err(e) = self
                        .client
                        .delete_document(&event.index, &sanitize_document_id(&event.document_id))
                        .await
                    {
                        tracing::error!(
                            index = %event.index,
                            doc_id = %event.document_id,
                            "Search sync delete failed: {e}"
                        );
                    }
                }
            }
        }

        tracing::info!("Search syncer stopped");
    }
}

fn sanitize_document_id(document_id: &str) -> String {
    document_id
        .chars()
        .map(|ch| {
            if ch.is_ascii_alphanumeric() || ch == '-' || ch == '_' {
                ch
            } else {
                '_'
            }
        })
        .collect()
}

fn normalize_document_for_indexing(document_id: &str, data: &Value) -> Value {
    let search_id = sanitize_document_id(document_id);
    match data {
        Value::Object(map) => {
            let mut normalized = map.clone();
            normalized.insert("id".to_string(), Value::String(search_id));
            normalized.insert(
                "record_id".to_string(),
                Value::String(document_id.to_string()),
            );
            Value::Object(normalized)
        }
        _ => json!({
            "id": search_id,
            "record_id": document_id,
            "value": data,
        }),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_search_action_debug_and_clone() {
        let upsert = SearchAction::Upsert;
        let delete = SearchAction::Delete;

        // Debug
        assert_eq!(format!("{:?}", upsert), "Upsert");
        assert_eq!(format!("{:?}", delete), "Delete");

        // Clone
        let cloned = upsert.clone();
        assert!(matches!(cloned, SearchAction::Upsert));
    }

    #[test]
    fn test_search_sync_event_construction() {
        let event = SearchSyncEvent {
            action: SearchAction::Upsert,
            index: "products".to_string(),
            document_id: "prod_123".to_string(),
            data: serde_json::json!({"id": "prod_123", "title": "Widget"}),
        };

        assert!(matches!(event.action, SearchAction::Upsert));
        assert_eq!(event.index, "products");
        assert_eq!(event.document_id, "prod_123");
        assert_eq!(event.data["title"], "Widget");
    }

    #[test]
    fn test_search_sync_event_clone() {
        let event = SearchSyncEvent {
            action: SearchAction::Delete,
            index: "users".to_string(),
            document_id: "u_1".to_string(),
            data: Value::Null,
        };
        let cloned = event.clone();
        assert_eq!(cloned.index, "users");
        assert_eq!(cloned.document_id, "u_1");
        assert!(matches!(cloned.action, SearchAction::Delete));
    }

    #[test]
    fn test_search_syncer_channel_capacity() {
        let config = crate::SearchConfig::default();
        let client = SearchClient::new(config, reqwest::Client::new());
        let (_syncer, tx) = SearchSyncer::new(client);

        // Channel should have capacity (1024 as defined)
        assert_eq!(tx.capacity(), 1024);
    }

    #[test]
    fn test_sanitize_document_id_replaces_invalid_characters() {
        assert_eq!(sanitize_document_id("products:abc/123"), "products_abc_123");
    }

    #[test]
    fn test_normalize_document_for_indexing_preserves_record_id() {
        let normalized = normalize_document_for_indexing(
            "products:abc123",
            &serde_json::json!({"id": "products:abc123", "title": "Widget"}),
        );
        assert_eq!(normalized["id"], "products_abc123");
        assert_eq!(normalized["record_id"], "products:abc123");
        assert_eq!(normalized["title"], "Widget");
    }

    // ── sanitize_document_id additional tests ──

    #[test]
    fn test_sanitize_document_id_empty_string() {
        assert_eq!(sanitize_document_id(""), "");
    }

    #[test]
    fn test_sanitize_document_id_pure_alphanumeric() {
        assert_eq!(sanitize_document_id("abc123"), "abc123");
    }

    #[test]
    fn test_sanitize_document_id_with_dashes_and_underscores() {
        assert_eq!(sanitize_document_id("my-id_123"), "my-id_123");
    }

    #[test]
    fn test_sanitize_document_id_all_special_chars() {
        assert_eq!(sanitize_document_id("::///"), "_____");
    }

    #[test]
    fn test_sanitize_document_id_with_spaces() {
        assert_eq!(sanitize_document_id("my doc id"), "my_doc_id");
    }

    #[test]
    fn test_sanitize_document_id_with_dots() {
        assert_eq!(sanitize_document_id("file.name.ext"), "file_name_ext");
    }

    #[test]
    fn test_sanitize_document_id_surrogate_pair() {
        let result = sanitize_document_id("doc😀");
        assert!(result.starts_with("doc_"));
    }

    // ── normalize_document_for_indexing additional tests ──

    #[test]
    fn test_normalize_document_with_null_data() {
        let normalized = normalize_document_for_indexing("doc_1", &Value::Null);
        assert_eq!(normalized["id"], "doc_1");
        assert_eq!(normalized["record_id"], "doc_1");
        assert_eq!(normalized["value"], Value::Null);
    }

    #[test]
    fn test_normalize_document_with_string_data() {
        let normalized = normalize_document_for_indexing(
            "doc_2",
            &Value::String("hello".to_string()),
        );
        assert_eq!(normalized["id"], "doc_2");
        assert_eq!(normalized["record_id"], "doc_2");
        assert_eq!(normalized["value"], "hello");
    }

    #[test]
    fn test_normalize_document_with_number_data() {
        let normalized = normalize_document_for_indexing(
            "doc_3",
            &serde_json::json!(42),
        );
        assert_eq!(normalized["id"], "doc_3");
        assert_eq!(normalized["value"], 42);
    }

    #[test]
    fn test_normalize_document_with_array_data() {
        let data = serde_json::json!([1, 2, 3]);
        let normalized = normalize_document_for_indexing("doc_4", &data);
        assert_eq!(normalized["id"], "doc_4");
        assert_eq!(normalized["value"], serde_json::json!([1, 2, 3]));
    }

    #[test]
    fn test_normalize_document_with_boolean_data() {
        let normalized = normalize_document_for_indexing("doc_5", &Value::Bool(true));
        assert_eq!(normalized["id"], "doc_5");
        assert_eq!(normalized["value"], true);
    }

    #[test]
    fn test_normalize_document_object_preserves_existing_fields() {
        let data = serde_json::json!({
            "title": "Widget",
            "price": 999,
            "tags": ["sale", "new"]
        });
        let normalized = normalize_document_for_indexing("prod:1", &data);
        assert_eq!(normalized["id"], "prod_1");
        assert_eq!(normalized["record_id"], "prod:1");
        assert_eq!(normalized["title"], "Widget");
        assert_eq!(normalized["price"], 999);
        assert_eq!(normalized["tags"].as_array().unwrap().len(), 2);
    }

    #[test]
    fn test_normalize_document_overwrites_existing_id() {
        let data = serde_json::json!({"id": "old_id", "title": "Test"});
        let normalized = normalize_document_for_indexing("new:id", &data);
        assert_eq!(normalized["id"], "new_id");
        assert_eq!(normalized["record_id"], "new:id");
    }

    #[test]
    fn test_sanitize_document_id_preserves_case() {
        assert_eq!(sanitize_document_id("MyDocID"), "MyDocID");
    }

    #[test]
    fn test_sanitize_document_id_numeric() {
        assert_eq!(sanitize_document_id("12345"), "12345");
    }
}
