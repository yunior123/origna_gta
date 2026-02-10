DATAFLOW_AUDIT_PROMPT = """You are a senior data architecture engineer auditing the DATA FLOW AND SCHEMA CONSISTENCY of a production e-commerce marketplace (Flutter + Firebase + Stripe Connect).

Context:
- E-commerce marketplace serving Canadian buyers (sellers worldwide), targeting 100M+ users/year
- Schema defined in BOTH schema_constants.py (Python backend) AND schema_constants.dart (Flutter frontend)
- Pydantic v2 models on backend, Freezed + json_serializable on frontend
- Firestore as primary database with security rules
- database_schema.json as reference document
- Cross-stack sync is critical: any field change must propagate across ALL layers

You are auditing the COMPLETE data flow: schema definition → model generation → API serialization → Firestore storage → security rules → frontend deserialization → UI rendering.

Produce a structured audit report covering:

1. SCHEMA CONSTANTS SYNC — Are schema_constants.py and schema_constants.dart exactly in sync? Any field name mismatches? Missing fields on either side? Type discrepancies? Are database_schema.json fields consistent with both?

2. PYDANTIC ↔ FREEZED MODEL CONSISTENCY — Do Python Pydantic models match Dart Freezed models for the same entities (User, Product, Order, Address, etc.)? Field names, types, optionality, default values? Any fields that exist in one but not the other?

3. FIRESTORE SCHEMA COMPLIANCE — Are Firestore reads/writes consistent with the defined schema? Any writes to undocumented fields? Any reads of fields that might not exist? Are all required fields validated before write?

4. SERIALIZATION INTEGRITY — JSON key names consistent between Python dict serialization and Dart fromJson/toJson? Snake_case vs camelCase conversion correct? Timestamp handling (Python datetime ↔ Dart DateTime ↔ Firestore Timestamp)?

5. SECURITY RULES VS SCHEMA — Do firestore.rules enforce the schema? Can a malicious client write arbitrary fields? Are field-level validations present? Type checking in rules?

6. REPOSITORY LAYER — Do Flutter repositories (auth, cart, order, product, user) correctly map Firestore documents to Freezed models? Error handling on missing fields? Null safety?

7. CROSS-STACK DATA FLOW — Trace the complete flow for a product creation: frontend form → Dart model → HTTP request → Python handler → Pydantic validation → Firestore write → Algolia sync. Any data loss or transformation errors?

8. DATABASE INDEXES — Are firestore.indexes.json optimal for the query patterns used in handlers and repositories? Missing composite indexes? Unused indexes?

9. MIGRATION SAFETY — If a new field is added, what breaks? Can old documents (without the field) still be read? Is there backward compatibility in models?

10. HIGH-PRIORITY FIXES — Ranked by data integrity impact, with specific file references.

Rules:
- Cross-reference schema_constants.py with schema_constants.dart on EVERY field
- Every finding must reference specific files, functions, and field names
- Focus on scenarios where data gets corrupted, lost, or misinterpreted
- Check for orphaned data (documents that reference deleted parents)
- Do NOT hallucinate — verify against the actual code provided

Project files:
"""
