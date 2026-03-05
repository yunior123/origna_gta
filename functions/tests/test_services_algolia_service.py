from datetime import UTC, datetime
from unittest.mock import Mock, patch

from schema_constants import Fields, ProductLifecycleStatusValues


def _client_cm(client: Mock) -> Mock:
    cm = Mock()
    cm.__enter__ = Mock(return_value=client)
    cm.__exit__ = Mock(return_value=None)
    return cm


class TestAlgoliaFormatting:
    @patch("services.algolia_service._log_sync_failure")
    def test_format_product_for_algolia_invalid_data_returns_empty(self, mock_log_failure):
        from services.algolia_service import format_product_for_algolia

        out = format_product_for_algolia("prod_bad", {})
        assert out == {}
        assert mock_log_failure.called

    def test_format_product_for_algolia_valid_data_maps_expected_fields(self):
        from services.algolia_service import format_product_for_algolia

        product = {
            Fields.NAME: "Premium Keyboard",
            Fields.DESCRIPTION: "Mechanical keyboard for coding and gaming",
            Fields.PRICE: 99.99,
            Fields.CATEGORY_ID: 2,
            Fields.SELLER_ID: "seller_1",
            Fields.IMAGE_URLS: ["https://cdn.example.com/kb.jpg"],
            Fields.STOCK_QUANTITY: 8,
            Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ACTIVE,
            Fields.KEYWORDS: ["keyboard", "mechanical"],
            Fields.IS_LOCAL_DELIVERY_ONLY: True,
            Fields.SELLER_ADDRESS: {
                Fields.STREET: "1 Queen St",
                Fields.CITY: "Toronto",
                Fields.STATE: "ON",
                Fields.POSTAL_CODE: "M5H 2N2",
                Fields.COUNTRY: "Canada",
            },
            Fields.CREATED_AT: datetime.now(UTC),
        }

        out = format_product_for_algolia("prod_1", product)

        assert out["objectID"] == "prod_1"
        assert out[Fields.PRICE_CENTS] == 9999
        assert out["availableInCanada"] is True
        assert out[Fields.NAME] == "Premium Keyboard"


class TestAlgoliaSyncOps:
    @patch("services.algolia_service.delete_product")
    def test_index_product_skips_delete_when_never_active(self, mock_delete):
        from services.algolia_service import index_product

        ok = index_product("prod_1", {Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.DRAFT})
        assert ok is True
        mock_delete.assert_not_called()

    @patch("services.algolia_service.delete_product")
    def test_index_product_deletes_when_previously_active(self, mock_delete):
        from services.algolia_service import index_product

        ok = index_product(
            "prod_1",
            {
                Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.PAUSED,
                "_previousLifecycleStatus": ProductLifecycleStatusValues.ACTIVE,
            },
        )
        assert ok is True
        mock_delete.assert_called_once_with("prod_1")

    @patch("services.algolia_service._get_index_name", return_value="products_test")
    @patch("services.algolia_service.format_product_for_algolia", return_value={"objectID": "prod_1"})
    @patch("services.algolia_service._get_algolia_client")
    def test_index_product_success(self, mock_get_client, _mock_format, _mock_index_name):
        from services.algolia_service import index_product

        client = Mock()
        mock_get_client.return_value = _client_cm(client)

        ok = index_product("prod_1", {Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ACTIVE})
        assert ok is True
        client.save_object.assert_called_once()

    @patch("services.algolia_service.format_product_for_algolia", return_value={"objectID": "prod_1"})
    @patch("services.algolia_service._get_algolia_client", side_effect=RuntimeError("no creds"))
    def test_index_product_runtime_error_returns_false(self, _mock_client, _mock_format):
        from services.algolia_service import index_product

        ok = index_product("prod_1", {Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ACTIVE})
        assert ok is False

    @patch("services.algolia_service._log_sync_failure")
    @patch("services.algolia_service._get_index_name", return_value="products_test")
    @patch("services.algolia_service.format_product_for_algolia", return_value={"objectID": "prod_1"})
    @patch("services.algolia_service._get_algolia_client")
    def test_index_product_logs_failure_after_retries(self, mock_get_client, _mock_format, _mock_index_name, mock_log_failure):
        from services.algolia_service import index_product

        client = Mock()
        client.save_object.side_effect = Exception("algolia down")
        mock_get_client.return_value = _client_cm(client)

        ok = index_product("prod_1", {Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ACTIVE}, max_retries=2)
        assert ok is False
        mock_log_failure.assert_called_once()

    @patch("services.algolia_service._get_index_name", return_value="products_test")
    @patch("services.algolia_service._get_algolia_client")
    def test_partial_update_product_success(self, mock_get_client, _mock_index_name):
        from services.algolia_service import partial_update_product

        client = Mock()
        mock_get_client.return_value = _client_cm(client)

        ok = partial_update_product("prod_1", {Fields.STOCK_QUANTITY: 4})
        assert ok is True
        client.partial_update_object.assert_called_once()

    def test_batch_partial_update_products_empty_is_noop(self):
        from services.algolia_service import batch_partial_update_products

        assert batch_partial_update_products([], {Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.PAUSED}) is True

    @patch("services.algolia_service._get_algolia_client", side_effect=RuntimeError("no creds"))
    def test_batch_partial_update_products_runtime_error_returns_false(self, _mock_client):
        from services.algolia_service import batch_partial_update_products

        ok = batch_partial_update_products(["p1"], {Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.PAUSED})
        assert ok is False

    @patch("services.algolia_service._log_sync_failure")
    @patch("services.algolia_service._get_algolia_client")
    def test_delete_product_logs_failure_after_retries(self, mock_get_client, mock_log_failure):
        from services.algolia_service import delete_product

        client = Mock()
        client.delete_object.side_effect = Exception("delete failed")
        mock_get_client.return_value = _client_cm(client)

        ok = delete_product("prod_1", max_retries=2)
        assert ok is False
        mock_log_failure.assert_called_once()

    @patch("services.algolia_service._get_index_name", return_value="products_test")
    @patch("services.algolia_service._get_algolia_client")
    def test_get_index_stats_returns_hits(self, mock_get_client, _mock_index_name):
        from services.algolia_service import get_index_stats

        client = Mock()
        client.search_single_index.return_value = Mock(nb_hits=42)
        mock_get_client.return_value = _client_cm(client)

        assert get_index_stats() == 42

    @patch("services.algolia_service.format_product_for_algolia", side_effect=lambda pid, data: {"objectID": pid})
    @patch("services.algolia_service._get_algolia_client")
    def test_batch_index_products_indexes_only_active_products(self, mock_get_client, _mock_format):
        from services.algolia_service import batch_index_products

        client = Mock()
        mock_get_client.return_value = _client_cm(client)
        products = [
            ("p1", {Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ACTIVE}),
            ("p2", {Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.DRAFT}),
        ]

        success, failure = batch_index_products(products)
        assert success == 1
        assert failure == 0
        client.save_objects.assert_called_once()

    @patch("services.algolia_service._get_algolia_client", side_effect=RuntimeError("no creds"))
    def test_configure_algolia_index_runtime_error_returns_false(self, _mock_client):
        from services.algolia_service import configure_algolia_index

        assert configure_algolia_index() is False

    @patch("services.algolia_service._get_index_name", return_value="products_test")
    @patch("services.algolia_service._get_algolia_client")
    def test_configure_algolia_index_success(self, mock_get_client, _mock_index_name):
        from services.algolia_service import configure_algolia_index

        client = Mock()
        mock_get_client.return_value = _client_cm(client)
        assert configure_algolia_index() is True
        client.set_settings.assert_called_once()

    @patch("services.algolia_service._log_sync_failure")
    @patch("services.algolia_service._get_algolia_client")
    def test_delete_products_from_algolia_logs_each_failure(self, mock_get_client, mock_log_failure):
        from services.algolia_service import delete_products_from_algolia

        client = Mock()
        client.delete_objects.side_effect = Exception("boom")
        mock_get_client.return_value = _client_cm(client)

        deleted = delete_products_from_algolia(["p1", "p2"])
        assert deleted == 0
        assert mock_log_failure.call_count == 2
