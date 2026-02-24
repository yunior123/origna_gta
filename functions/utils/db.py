"""Shared Firestore client utilities — single source of truth for db/firestore access."""

_db = None
_firestore = None


def get_db():
    """Get Firestore client (lazy initialization, shared singleton)."""
    global _db, _firestore
    if _db is None:
        from firebase_admin import firestore as fs

        _firestore = fs
        _db = fs.client()
    return _db


def get_firestore():
    """Get Firestore module (lazy initialization, shared singleton)."""
    global _firestore
    if _firestore is None:
        from firebase_admin import firestore as fs

        _firestore = fs
    return _firestore


def get_server_timestamp():
    """Get Firestore SERVER_TIMESTAMP sentinel."""
    return get_firestore().SERVER_TIMESTAMP


def get_delete_field():
    """Get Firestore DELETE_FIELD sentinel."""
    return get_firestore().DELETE_FIELD
