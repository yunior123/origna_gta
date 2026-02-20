"""
Unit tests for handlers/users.py
Focusing on buyer address book operations.
"""

from unittest.mock import MagicMock, Mock, patch

import pytest
from firebase_functions import https_fn

from schema_constants import Collections, Fields


class TestBuyerAddressHandlers:
    @patch("handlers.users.get_db")
    def test_add_buyer_address_first_is_default(self, mock_get_db):
        from handlers.users import add_buyer_address

        # Mock DB
        mock_db = Mock()
        mock_get_db.return_value = mock_db

        mock_addresses_ref = Mock()
        # No existing addresses
        mock_addresses_ref.get.return_value = []

        mock_batch = Mock()
        mock_db.batch.return_value = mock_batch

        mock_new_ref = Mock()
        mock_new_ref.id = "address_123"
        mock_addresses_ref.document.return_value = mock_new_ref

        mock_user_doc_ref = Mock()
        mock_user_doc_ref.collection.return_value = mock_addresses_ref

        mock_users_collection = Mock()
        mock_users_collection.document.return_value = mock_user_doc_ref

        mock_db.collection.return_value = mock_users_collection

        mock_request = Mock()
        mock_request.auth = Mock(uid="buyer_123")
        mock_request.data = {
            "street": "123 Main St",
            "city": "Toronto",
            "state": "ON",
            "postalCode": "M5V 2H1",
            "country": "CA",
        }

        result = add_buyer_address(mock_request)

        assert result["success"] is True
        assert result[Fields.ADDRESS_ID] == "address_123"

        # Verify it was added with isDefault=True and batch was used
        mock_batch.set.assert_called_once()
        added_data = mock_batch.set.call_args[0][1]
        assert added_data[Fields.IS_DEFAULT] is True
        mock_batch.commit.assert_called_once()

    @patch("handlers.users.get_db")
    def test_add_buyer_address_limit_exceeded(self, mock_get_db):
        from handlers.users import add_buyer_address

        mock_db = Mock()
        mock_get_db.return_value = mock_db

        mock_addresses_ref = Mock()
        # Exceed limit
        mock_addresses_ref.get.return_value = [Mock() for _ in range(10)]

        mock_user_doc_ref = Mock()
        mock_user_doc_ref.collection.return_value = mock_addresses_ref
        mock_users_collection = Mock()
        mock_users_collection.document.return_value = mock_user_doc_ref
        mock_db.collection.return_value = mock_users_collection

        mock_request = Mock()
        mock_request.auth = Mock(uid="buyer_123")
        mock_request.data = {
            "street": "123 Main St",
            "city": "Toronto",
            "state": "ON",
            "postalCode": "M5V 2H1",
            "country": "CA",
        }

        with pytest.raises(https_fn.HttpsError) as exc:
            add_buyer_address(mock_request)

        assert exc.value.code == "resource-exhausted"
        assert "10 addresses" in str(exc.value.message)

    @patch("handlers.users.get_db")
    def test_update_buyer_address_invalid_id(self, mock_get_db):
        from handlers.users import update_buyer_address

        mock_request = Mock()
        mock_request.auth = Mock(uid="buyer_123")
        mock_request.data = {
            # Missing addressId
            "street": "123 Main St",
            "city": "Toronto",
            "state": "ON",
            "postalCode": "M5V 2H1",
            "country": "CA",
        }

        with pytest.raises(https_fn.HttpsError) as exc:
            update_buyer_address(mock_request)

        assert exc.value.code == "invalid-argument"
        assert "addressId" in str(exc.value.message)

    @patch("handlers.users.get_db")
    def test_delete_buyer_address_promotes_default(self, mock_get_db):
        from handlers.users import delete_buyer_address

        mock_db = Mock()
        mock_get_db.return_value = mock_db

        mock_batch = Mock()
        mock_db.batch.return_value = mock_batch

        mock_addresses_ref = Mock()
        mock_address_ref = Mock()

        mock_doc = Mock()
        mock_doc.id = "address_123"
        mock_doc.exists = True
        mock_doc.to_dict.return_value = {Fields.IS_DEFAULT: True}
        mock_address_ref.get.return_value = mock_doc

        # Second address to promote
        mock_other_doc = Mock()
        mock_other_doc.id = "address_456"
        mock_other_doc.reference = Mock()
        mock_addresses_ref.get.return_value = [mock_doc, mock_other_doc]
        mock_addresses_ref.document.return_value = mock_address_ref

        mock_user_doc_ref = Mock()
        mock_user_doc_ref.collection.return_value = mock_addresses_ref
        mock_users_collection = Mock()
        mock_users_collection.document.return_value = mock_user_doc_ref
        mock_db.collection.return_value = mock_users_collection

        mock_request = Mock()
        mock_request.auth = Mock(uid="buyer_123")
        mock_request.data = {Fields.ADDRESS_ID: "address_123"}

        result = delete_buyer_address(mock_request)

        assert result["success"] is True
        mock_batch.delete.assert_called_once_with(mock_address_ref)
        # Should have updated the other doc to default
        mock_batch.update.assert_called_once_with(mock_other_doc.reference, {Fields.IS_DEFAULT: True})
        mock_batch.commit.assert_called_once()

    @patch("handlers.users.get_db")
    def test_set_default_buyer_address(self, mock_get_db):
        from handlers.users import set_default_buyer_address

        mock_db = Mock()
        mock_get_db.return_value = mock_db

        mock_batch = Mock()
        mock_db.batch.return_value = mock_batch

        mock_addresses_ref = Mock()
        mock_address_ref = Mock()

        mock_doc = Mock()
        mock_doc.exists = True
        mock_address_ref.get.return_value = mock_doc

        mock_doc_1 = Mock()
        mock_doc_1.id = "address_123"
        mock_doc_1.reference = Mock()

        mock_doc_2 = Mock()
        mock_doc_2.id = "address_456"
        mock_doc_2.reference = Mock()
        mock_doc_2.to_dict.return_value = {Fields.IS_DEFAULT: True}

        mock_addresses_ref.get.return_value = [mock_doc_1, mock_doc_2]
        mock_addresses_ref.document.return_value = mock_address_ref

        mock_user_doc_ref = Mock()
        mock_user_doc_ref.collection.return_value = mock_addresses_ref
        mock_users_collection = Mock()
        mock_users_collection.document.return_value = mock_user_doc_ref
        mock_db.collection.return_value = mock_users_collection

        mock_request = Mock()
        mock_request.auth = Mock(uid="buyer_123")
        mock_request.data = {Fields.ADDRESS_ID: "address_123"}

        result = set_default_buyer_address(mock_request)

        assert result["success"] is True

        # Verify batch updates: set 123 to True, 456 to False
        assert mock_batch.update.call_count == 2

        calls = mock_batch.update.call_args_list
        assert calls[0][0][0] == mock_doc_1.reference
        assert calls[0][0][1] == {Fields.IS_DEFAULT: True}

        assert calls[1][0][0] == mock_doc_2.reference
        assert calls[1][0][1] == {Fields.IS_DEFAULT: False}

        mock_batch.commit.assert_called_once()
