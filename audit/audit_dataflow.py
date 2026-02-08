#!/usr/bin/env python3
"""Data flow & schema consistency audit: schema sync → models → serialization → rules → repositories.
Enriched with Firestore and Algolia documentation."""
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from common import run_enriched_audit
from prompt_dataflow import DATAFLOW_AUDIT_PROMPT

DATAFLOW_FILES = [
    # Schema sources of truth
    "functions/schema_constants.py",
    "origna_gta/lib/core/schema/schema_constants.dart",
    "docs/database_schema.json",
    # Pydantic models (backend)
    "functions/models/base.py",
    "functions/models/user.py",
    "functions/models/product.py",
    "functions/models/order.py",
    # Freezed models (frontend)
    "origna_gta/lib/models/generated/base_models.dart",
    "origna_gta/lib/models/generated/user_models.dart",
    "origna_gta/lib/models/generated/product_models.dart",
    "origna_gta/lib/models/generated/order_models.dart",
    # Repositories (data access layer)
    "origna_gta/lib/core/repositories/auth_repository.dart",
    "origna_gta/lib/core/repositories/product_repository.dart",
    "origna_gta/lib/core/repositories/order_repository.dart",
    "origna_gta/lib/core/repositories/user_repository.dart",
    "origna_gta/lib/core/repositories/cart_repository.dart",
    # Firestore rules & indexes
    "firestore.rules",
    "firestore.indexes.json",
    # Algolia sync
    "functions/algolia_service.py",
    "CLAUDE.md",
]

def main():
    run_enriched_audit(
        audit_type="data_flow",
        prompt=DATAFLOW_AUDIT_PROMPT,
        file_paths=DATAFLOW_FILES,
        prefix="dataflow",
        workflow_name="Data Flow & Schema",
        emoji="🔄",
    )

if __name__ == "__main__":
    main()
