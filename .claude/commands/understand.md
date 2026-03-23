Analyze the origna_gta codebase using the understand-codebase skill.

Run a full architecture scan of this monorepo (Flutter frontend in `origna_gta/`, Rust backend in `orignabase/`, E2E tests in `e2e-agent-browser/`).

Produce:
1. File inventory by language and type
2. Module map with purpose and dependencies
3. Layer diagram (Screens → ViewModels → Services → OrignaBase SDK → SurrealDB/Meilisearch/Stripe)
4. Dependency graph with critical paths
5. Circular dependency check
6. Guided tour for a new developer joining this project
7. Key patterns and non-obvious conventions

Reference `docs/REPO_MAP.md` for existing architecture documentation and validate/extend it.

Skip generated files (*.g.dart, *.freezed.dart), build/, target/, node_modules/, .dart_tool/.
