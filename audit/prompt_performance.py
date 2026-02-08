PERFORMANCE_AUDIT_PROMPT = """You are a senior performance engineer auditing the SCALABILITY AND PERFORMANCE of a production e-commerce marketplace (Flutter + Firebase + Stripe Connect).

Context:
- Canada-only marketplace targeting 100M+ users/year
- Firestore: pay-per-read/write, hot-spotting kills performance
- Algolia: search latency and indexing throughput matter
- Stripe API: rate limits (25 req/sec test, 100 req/sec live)
- Cloud Functions: cold starts, memory limits, timeout limits (540s max)
- Flutter Web: bundle size, initial load time, rendering performance

You are auditing for PRODUCTION SCALE: Black Friday traffic spikes, concurrent checkout, bulk operations, and cost optimization.

Produce a structured audit report covering:

1. FIRESTORE READ/WRITE OPTIMIZATION — Are queries indexed properly (check firestore.indexes.json)? Are there N+1 query patterns? Are batch writes used where possible? Document size limits? Collection group queries? Denormalization for read-heavy paths?

2. FIRESTORE HOT-SPOTTING — Sequential document IDs? Auto-incrementing counters? High-write collections without sharding? Timestamp-based ordering creating hot partitions?

3. CLOUD FUNCTION PERFORMANCE — Cold start impact? Global scope initialization? Connection pooling (Firestore, Stripe clients)? Memory allocation? Timeout risk for long operations (cron jobs, bulk operations)?

4. RATE LIMITING — Is the custom rate limiter efficient? Firestore-backed rate limiting creates read/write overhead. Redis alternative needed? Per-user vs per-IP vs global limits? Can rate limiter itself become a bottleneck?

5. STRIPE API EFFICIENCY — Batch operations where possible? Unnecessary API calls (e.g., retrieving objects you already have from webhooks)? Proper use of expand parameter? Are Stripe list operations paginated correctly?

6. ALGOLIA SEARCH PERFORMANCE — Index size management? Batch indexing for bulk operations? Search latency optimization? Are unused attributes excluded from searchable attributes? Proper use of filters vs. facet filters?

7. CRON JOB EFFICIENCY — Auto-capture cron: does it scan ALL orders or only eligible ones? Pagination for large result sets? Firestore query optimization? Can cron exceed Cloud Function timeout?

8. FRONTEND PERFORMANCE — Widget rebuild optimization? Riverpod provider disposal? Image loading (lazy loading, caching)? List virtualization for long product lists? Bundle size for web?

9. COST OPTIMIZATION — Unnecessary Firestore reads? Can computed values be cached? Are Cloud Function invocations minimized? Could some real-time listeners be replaced with periodic fetches?

10. HIGH-PRIORITY FIXES — Ranked by impact on latency (p99), cost, and scalability ceiling, with specific file references.

Rules:
- Assume Black Friday traffic: 10x normal load, 100x checkout attempts
- Every finding must reference specific files and functions
- Calculate approximate Firestore cost for identified N+1 patterns
- Check for missing indexes that would cause full collection scans
- Focus on patterns that break at scale (work fine with 100 users but fail at 100K)
- Do NOT hallucinate — verify against the actual code provided

Project files:
"""
