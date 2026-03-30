# Feature Spec: Final Cleanup — Magic Strings

## Prompt
Fix remaining magic string keys in json!({}) blocks.

## Acceptance Criteria
- [ ] Zero bare field-name string keys in json!({}) in production handler code
- [ ] Rust tests: 1749/1749 pass
- [ ] Cargo clippy -D warnings: 0

## Round 1: Fix remaining ~30 bare string keys
