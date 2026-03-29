use ob_core::Error;
use ob_core::config::DatabaseConfig;
use ob_core::ports::db_store::DatabaseStore;
use crate::pg_store::PgDatabaseStore;
use std::sync::Once;

/// Database client wrapping the PostgreSQL adapter.
///
/// This is the primary database interface used by all handler state types.
/// It delegates all operations to `PgDatabaseStore` which implements the
/// `DatabaseStore` trait.
#[derive(Clone)]
pub struct DatabaseClient {
    pub(crate) inner: PgDatabaseStore,
}

/// One-time truncation guard: clears all tables at the start of a test run.
static TRUNCATE_ONCE: Once = Once::new();

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
        TRUNCATE_ONCE.call_once(|| {
            let pool = inner.pool().clone();
            // Spawn a blocking task since call_once is synchronous
            std::thread::spawn(move || {
                let rt = tokio::runtime::Runtime::new().unwrap();
                rt.block_on(async {
                    let _ = sqlx::query(
                        "DO $$ DECLARE r RECORD; BEGIN \
                         FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename NOT LIKE 'pg_%') LOOP \
                         EXECUTE 'TRUNCATE TABLE ' || quote_ident(r.tablename) || ' CASCADE'; \
                         END LOOP; END $$;"
                    )
                    .execute(&pool)
                    .await;
                });
            }).join().ok();
        });

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
