use ob_core::Error;
use ob_core::config::DatabaseConfig;
use ob_core::ports::db_store::DatabaseStore;
use crate::pg_store::PgDatabaseStore;

/// Database client wrapping the PostgreSQL adapter.
///
/// This is the primary database interface used by all handler state types.
/// It delegates all operations to `PgDatabaseStore` which implements the
/// `DatabaseStore` trait.
#[derive(Clone)]
pub struct DatabaseClient {
    pub(crate) inner: PgDatabaseStore,
}

impl DatabaseClient {
    /// Create a database client for testing.
    /// On first call per process, truncates all tables for a clean slate.
    /// Uses the local PostgreSQL instance.
    pub async fn new_mem() -> Self {
        let url = std::env::var("OB_TEST_DATABASE_URL")
            .unwrap_or_else(|_| "postgres://orignabase:orignabase_dev@127.0.0.1:5432/orignabase".to_string());
        let inner = PgDatabaseStore::connect(&url).await.unwrap();

        // Truncate all tables once per test process to clear stale data.
        // This runs exactly once (the first new_mem() call), not per-test.
        // Uses a separate thread+runtime because call_once is synchronous
        // but we need to await async database operations.
        {
            use std::sync::atomic::{AtomicBool, Ordering};
            static DID_TRUNCATE: AtomicBool = AtomicBool::new(false);
            if !DID_TRUNCATE.swap(true, Ordering::SeqCst) {
                // First call — truncate all tables
                let tables_result = sqlx::query_as::<_, (String,)>(
                    "SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename NOT LIKE 'pg_%' AND tablename NOT LIKE '_sqlx%'"
                )
                .fetch_all(inner.pool())
                .await;

                if let Ok(rows) = tables_result {
                    for (table,) in &rows {
                        let sql = format!("TRUNCATE TABLE \"{}\" CASCADE", table);
                        let _ = sqlx::query(&sql).execute(inner.pool()).await;
                    }
                    eprintln!("[test-setup] Truncated {} tables", rows.len());
                } else {
                    eprintln!("[test-setup] Failed to list tables for truncation");
                }
            }
        }

        Self { inner }
    }

    /// Connect to PostgreSQL using the provided config.
    pub async fn connect(config: &DatabaseConfig) -> ob_core::Result<Self> {
        let inner = PgDatabaseStore::connect(&config.url)
            .await
            .map_err(|e| Error::Database(format!("Connection failed: {e}")))?;

        tracing::info!("Connected to PostgreSQL at {}", config.url);

        Ok(Self { inner })
    }

    /// Get a reference to the underlying PgDatabaseStore.
    pub fn inner(&self) -> &PgDatabaseStore {
        &self.inner
    }

    /// Execute a query with a timeout to prevent long-running queries from blocking.
    pub async fn query_with_timeout(&self, query: &str, timeout_secs: u64) -> ob_core::Result<()> {
        tokio::time::timeout(
            std::time::Duration::from_secs(timeout_secs),
            self.inner.query_raw(query),
        )
        .await
        .map_err(|_| {
            Error::Database(format!(
                "Query timeout exceeded ({}s). Query may be too complex or resource-intensive.",
                timeout_secs
            ))
        })?
        .map(|_| ())?;
        Ok(())
    }
}
