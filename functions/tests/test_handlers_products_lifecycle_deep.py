import base64
import importlib
import sys
from unittest.mock import Mock, patch

import pytest
from firebase_functions import https_fn
from pydantic import BaseModel, ValidationError

from config import Environment
from schema_constants import (
    Collections,
    Fields,
    ProductLifecycleStatusValues,
    UserRoleValues,
)


def _snap(data=None, *, exists=True, doc_id=None):
    snap = Mock()
    snap.exists = exists
    snap.to_dict.return_value = {} if data is None else data
    snap.id = doc_id or "doc_1"
    snap.reference = Mock()
    return snap


def _req(uid: str, data: dict):
    req = Mock()
    req.auth = Mock(uid=uid)
    req.data = data
    return req


def _decorator_passthrough(*args, **kwargs):
    if len(args) == 1 and callable(args[0]) and not kwargs:
        return args[0]

    def _decorator(func):
        return func

    return _decorator


@pytest.fixture(autouse=True)
def _reload_products_module_with_firestore_passthrough():
    ff = sys.modules["firebase_functions"]
    if not hasattr(ff, "firestore_fn"):
        ff.firestore_fn = Mock()
    ff.firestore_fn.on_document_created = _decorator_passthrough
    ff.firestore_fn.on_document_updated = _decorator_passthrough
    ff.firestore_fn.on_document_deleted = _decorator_passthrough

    import handlers.products as products

    importlib.reload(products)
    yield


class _FakeProductCreate:
    def __init__(self, **kwargs):
        self._payload = dict(kwargs)

    def model_dump(self, exclude_none=True):
        return dict(self._payload)


class TestCreateProductAtomicDeep:
    @patch("handlers.products.create_success_response", side_effect=lambda payload: {"success": True, **payload})
    @patch("handlers.products._derive_ship_from_fields", return_value={Fields.SHIP_FROM_COUNTRY: "Canada"})
    @patch("handlers.products.ProductCreate", _FakeProductCreate)
    @patch("handlers.products.get_server_timestamp", return_value="ts")
    @patch("utils.helpers.geocode_address")
    @patch("handlers.products.RateLimiter")
    @patch("handlers.products.get_db")
    @patch("handlers.products.CURRENT_ENV", Environment.EMULATOR)
    def test_create_product_atomic_success_with_test_image_urls(
        self,
        mock_get_db,
        mock_rl_cls,
        mock_geocode,
        _mock_ts,
        _mock_resp,
        _mock_ship_from,
    ):
        from handlers.products import create_product_atomic

        mock_geocode.return_value = (
            True,
            "",
            {
                Fields.STREET: "1 Main St",
                Fields.CITY: "Toronto",
                Fields.STATE: "ON",
                Fields.POSTAL_CODE: "M5V2T6",
                Fields.COUNTRY: "Canada",
                Fields.LATITUDE: 43.65,
                Fields.LONGITUDE: -79.38,
                "apartment": "",
            },
        )
        mock_rl_cls.return_value.check_rate_limit.return_value = (True, "")

        user_doc = _snap({Fields.ROLES: [UserRoleValues.SELLER], Fields.SUSPENDED: False})
        profile_doc = _snap({Fields.ONBOARDING_COMPLETED: True})
        product_ref = Mock()
        product_ref.id = "prod_new_1"
        sku_collision_ref = Mock()

        users_col = Mock()
        users_col.document.return_value.get.return_value = user_doc
        profiles_col = Mock()
        profiles_col.document.return_value.get.return_value = profile_doc
        products_col = Mock()
        products_col.document.return_value = product_ref
        skus_col = Mock()
        skus_col.document.return_value = sku_collision_ref

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.USERS: users_col,
            Collections.SELLER_PROFILES: profiles_col,
            Collections.PRODUCTS: products_col,
            Collections.SELLER_SKUS: skus_col,
        }[name]
        mock_get_db.return_value = db

        req = _req(
            "seller_1",
            {
                "productData": {
                    Fields.NAME: "Fresh Apples",
                    Fields.DESCRIPTION: "Ontario apples",
                    Fields.PRICE: 12.99,
                    Fields.CATEGORY_ID: 1,
                    Fields.STOCK_QUANTITY: 5,
                    Fields.SELLER_SKU: "APPLE-1",
                    Fields.IS_DIGITAL: False,
                    Fields.SELLER_ADDRESS: {
                        Fields.STREET: "1 Main St",
                        Fields.CITY: "Toronto",
                        Fields.STATE: "ON",
                        Fields.POSTAL_CODE: "M5V2T6",
                        Fields.COUNTRY: "Canada",
                    },
                },
                "images": [],
                "testImageUrls": ["https://cdn.test/products/a.jpg"],
            },
        )

        out = create_product_atomic(req)
        assert out["success"] is True
        assert out[Fields.PRODUCT_ID] == "prod_new_1"
        assert out["imageUrls"] == ["https://cdn.test/products/a.jpg"]
        product_ref.set.assert_called_once()

    @patch("handlers.products._derive_ship_from_fields", return_value={})
    @patch("handlers.products.get_server_timestamp", return_value="ts")
    @patch("utils.helpers.geocode_address")
    @patch("handlers.products.RateLimiter")
    @patch("handlers.products.get_db")
    @patch("handlers.products.CURRENT_ENV", Environment.EMULATOR)
    def test_create_product_atomic_validation_error_cleans_up_sku_doc(
        self,
        mock_get_db,
        mock_rl_cls,
        mock_geocode,
        _mock_ts,
        _mock_ship_from,
    ):
        from handlers import products

        class _FailModel(BaseModel):
            qty: int

        try:
            _FailModel(qty="x")
        except ValidationError as ve:
            validation_error = ve

        mock_geocode.return_value = (
            True,
            "",
            {
                Fields.STREET: "1 Main St",
                Fields.CITY: "Toronto",
                Fields.STATE: "ON",
                Fields.POSTAL_CODE: "M5V2T6",
                Fields.COUNTRY: "Canada",
                Fields.LATITUDE: 43.65,
                Fields.LONGITUDE: -79.38,
                "apartment": "",
            },
        )
        mock_rl_cls.return_value.check_rate_limit.return_value = (True, "")

        user_doc = _snap({Fields.ROLES: [UserRoleValues.SELLER], Fields.SUSPENDED: False})
        profile_doc = _snap({Fields.ONBOARDING_COMPLETED: True})
        product_ref = Mock()
        product_ref.id = "prod_new_2"
        sku_collision_ref = Mock()

        users_col = Mock()
        users_col.document.return_value.get.return_value = user_doc
        profiles_col = Mock()
        profiles_col.document.return_value.get.return_value = profile_doc
        products_col = Mock()
        products_col.document.return_value = product_ref
        skus_col = Mock()
        skus_col.document.return_value = sku_collision_ref

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.USERS: users_col,
            Collections.SELLER_PROFILES: profiles_col,
            Collections.PRODUCTS: products_col,
            Collections.SELLER_SKUS: skus_col,
        }[name]
        mock_get_db.return_value = db

        req = _req(
            "seller_1",
            {
                "productData": {
                    Fields.NAME: "Fresh Apples",
                    Fields.DESCRIPTION: "Ontario apples",
                    Fields.PRICE: 12.99,
                    Fields.CATEGORY_ID: 1,
                    Fields.STOCK_QUANTITY: 5,
                    Fields.SELLER_SKU: "APPLE-2",
                    Fields.IS_DIGITAL: False,
                    Fields.SELLER_ADDRESS: {
                        Fields.STREET: "1 Main St",
                        Fields.CITY: "Toronto",
                        Fields.STATE: "ON",
                        Fields.POSTAL_CODE: "M5V2T6",
                        Fields.COUNTRY: "Canada",
                    },
                },
                "images": [],
                "testImageUrls": ["https://cdn.test/products/a.jpg"],
            },
        )

        with patch("handlers.products.ProductCreate", side_effect=validation_error):
            with pytest.raises(https_fn.HttpsError) as exc:
                products.create_product_atomic(req)
        assert exc.value.code == "invalid-argument"
        sku_collision_ref.delete.assert_called_once()

    @patch("handlers.products.CURRENT_ENV", Environment.EMULATOR)
    @patch("handlers.products._derive_ship_from_fields", return_value={})
    @patch("handlers.products.ProductCreate", _FakeProductCreate)
    @patch("handlers.products.get_server_timestamp", return_value="ts")
    @patch("handlers.products._get_cached_s3_client")
    @patch("handlers.products.RateLimiter")
    @patch("handlers.products.get_db")
    def test_create_product_atomic_firestore_write_failure_cleans_r2_objects(
        self,
        mock_get_db,
        mock_rl_cls,
        mock_get_s3,
        _mock_ts,
        _mock_ship_from,
    ):
        from handlers import products

        mock_rl_cls.return_value.check_rate_limit.return_value = (True, "")
        s3 = Mock()
        mock_get_s3.return_value = s3

        user_doc = _snap({Fields.ROLES: [UserRoleValues.ADMIN], Fields.SUSPENDED: False})
        product_ref = Mock()
        product_ref.id = "prod_new_3"
        product_ref.set.side_effect = RuntimeError("db down")

        users_col = Mock()
        users_col.document.return_value.get.return_value = user_doc
        profiles_col = Mock()
        products_col = Mock()
        products_col.document.return_value = product_ref
        skus_col = Mock()

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.USERS: users_col,
            Collections.SELLER_PROFILES: profiles_col,
            Collections.PRODUCTS: products_col,
            Collections.SELLER_SKUS: skus_col,
        }.get(name, Mock())
        mock_get_db.return_value = db

        png_magic = next(iter(products.BusinessRules.IMAGE_MAGIC_BYTES.keys()))
        req = _req(
            "admin_1",
            {
                "productData": {
                    Fields.NAME: "Fresh Apples",
                    Fields.DESCRIPTION: "Ontario apples",
                    Fields.PRICE: 12.99,
                    Fields.CATEGORY_ID: 1,
                    Fields.STOCK_QUANTITY: 5,
                    Fields.IS_DIGITAL: False,
                    Fields.SELLER_ADDRESS: {
                        Fields.CITY: "Toronto",
                        Fields.STATE: "ON",
                        Fields.COUNTRY: "Canada",
                    },
                },
                "images": [{"data": base64.b64encode(png_magic + b"abc").decode("ascii"), "contentType": "image/png"}],
            },
        )

        with pytest.raises(https_fn.HttpsError) as exc:
            products.create_product_atomic(req)
        assert exc.value.code == "internal"
        s3.delete_object.assert_called()


class TestProductTriggerLifecycleDeep:
    @patch("handlers.products._notify_admins_new_product")
    @patch("handlers.products._derive_ship_from_fields", return_value={Fields.SHIP_FROM_COUNTRY: "Canada"})
    @patch("handlers.products._generate_product_slug", return_value="fresh-apples-abc12345")
    @patch("handlers.products.validate_image_magic_bytes", return_value=True)
    @patch("handlers.products.get_db")
    def test_on_product_created_applies_internal_fixes_and_notifies_admins(
        self,
        mock_get_db,
        _mock_magic,
        _mock_slug,
        _mock_ship_from,
        mock_notify_admins,
    ):
        from handlers import products

        seller_doc = _snap({Fields.SUSPENDED: False})
        product_ref = Mock()
        products_query = Mock()
        products_query.where.return_value = products_query
        products_query.limit.return_value = products_query
        products_query.get.return_value = []

        users_col = Mock()
        users_col.document.return_value.get.return_value = seller_doc
        products_col = Mock()
        products_col.where.return_value = products_query
        products_col.document.return_value = product_ref

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.USERS: users_col,
            Collections.PRODUCTS: products_col,
        }[name]
        mock_get_db.return_value = db

        product_data = {
            Fields.SELLER_ID: "seller_1",
            Fields.SELLER_SKU: "SKU-123",
            Fields.NAME: "<b>Fresh Apples</b>",
            Fields.DESCRIPTION: "<i>Sweet</i>",
            Fields.PRICE: 10.0,
            Fields.COMPARE_AT_PRICE: 10.6,
            Fields.HAS_VARIANTS: False,
            Fields.STOCK_QUANTITY: 3,
            Fields.SELLER_ADDRESS: {
                Fields.COUNTRY: "Canada",
                Fields.LATITUDE: 43.65,
                Fields.LONGITUDE: -79.38,
                Fields.STREET: "1 Main",
                Fields.CITY: "Toronto",
                Fields.POSTAL_CODE: "M5V2T6",
            },
            Fields.CATEGORY_ID: 1,
            Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ACTIVE,
            Fields.IS_DIGITAL: False,
            Fields.IS_LOCAL_DELIVERY_ONLY: False,
            Fields.DELIVERY_OPTIONS: [],
            Fields.IMAGE_URLS: [f"{products.CDN_BASE_URL}/products/a.jpg"],
        }

        event = Mock()
        event.params = {Fields.PRODUCT_ID: "prod_1"}
        event.data = Mock()
        event.data.to_dict.return_value = product_data

        with patch("utils.helpers.sanitized_text", side_effect=lambda s: s.replace("<", "").replace(">", "")):
            products.on_product_created(event)

        product_ref.update.assert_called()
        mock_notify_admins.assert_called_once()

    @patch("handlers.products._track_price_history")
    @patch("handlers.products._fire_back_in_stock_notifications")
    @patch("handlers.products.algolia_partial_update")
    @patch("handlers.products.get_db")
    def test_on_product_updated_stock_only_change_uses_partial_index(
        self,
        mock_get_db,
        mock_algolia_partial,
        mock_back_in_stock,
        mock_track_price,
    ):
        from handlers.products import on_product_updated

        products_col = Mock()
        products_col.document.return_value = Mock()
        db = Mock()
        db.collection.return_value = products_col
        mock_get_db.return_value = db

        before = {
            Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ACTIVE,
            Fields.STOCK_QUANTITY: 0,
            Fields.PRICE: 10.0,
            Fields.NAME: "Fresh Apples",
        }
        after = {
            Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ACTIVE,
            Fields.STOCK_QUANTITY: 4,
            Fields.PRICE: 10.0,
            Fields.NAME: "Fresh Apples",
        }

        event = Mock()
        event.params = {Fields.PRODUCT_ID: "prod_2"}
        event.data = Mock()
        event.data.before.to_dict.return_value = before
        event.data.after.to_dict.return_value = after

        on_product_updated(event)

        mock_algolia_partial.assert_called_once_with("prod_2", {Fields.STOCK_QUANTITY: 4})
        mock_back_in_stock.assert_called_once()
        mock_track_price.assert_called_once()

    @patch("handlers.products._cleanup_orphaned_variant_subscriptions")
    @patch("handlers.products._fire_back_in_stock_notifications")
    @patch("handlers.products._track_price_history")
    @patch("handlers.products.index_product")
    @patch("handlers.products.get_db")
    def test_on_product_updated_full_validation_path_indexes_active_product(
        self,
        mock_get_db,
        mock_index_product,
        mock_track_price,
        mock_back_in_stock,
        mock_cleanup_orphans,
    ):
        from handlers.products import on_product_updated

        seller_doc = _snap({Fields.SUSPENDED: False})
        product_ref = Mock()
        users_col = Mock()
        users_col.document.return_value.get.return_value = seller_doc
        products_col = Mock()
        products_col.document.return_value = product_ref

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.USERS: users_col,
            Collections.PRODUCTS: products_col,
        }[name]
        mock_get_db.return_value = db

        before = {
            Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ACTIVE,
            Fields.SELLER_ID: "seller_1",
            Fields.NAME: "<b>Fresh Apples</b>",
            Fields.DESCRIPTION: "<i>Sweet</i>",
            Fields.PRICE: 10.0,
            Fields.COMPARE_AT_PRICE: 11.0,
            Fields.STOCK_QUANTITY: 5,
            Fields.SELLER_ADDRESS: {
                Fields.COUNTRY: "Canada",
                Fields.LATITUDE: 43.65,
                Fields.LONGITUDE: -79.38,
                Fields.STREET: "1 Main",
                Fields.CITY: "Toronto",
                Fields.POSTAL_CODE: "M5V2T6",
            },
            Fields.WAREHOUSE_IDS: [],
            Fields.IS_DIGITAL: False,
            Fields.SHIP_FROM_COUNTRY: "Canada",
        }
        after = dict(before)
        after[Fields.PRICE] = 9.5
        after[Fields.COMPARE_AT_PRICE] = 10.5
        after[Fields.NAME] = "<b>Fresh Apples 2</b>"

        event = Mock()
        event.params = {Fields.PRODUCT_ID: "prod_22"}
        event.data = Mock()
        event.data.before.to_dict.return_value = before
        event.data.after.to_dict.return_value = after

        with patch("utils.helpers.sanitized_text", side_effect=lambda s: s.replace("<", "").replace(">", "")):
            on_product_updated(event)

        product_ref.update.assert_called()
        mock_track_price.assert_called_once()
        mock_back_in_stock.assert_called_once()
        mock_cleanup_orphans.assert_called_once()
        mock_index_product.assert_called_once()

    @patch("handlers.products.algolia_delete_product")
    @patch("handlers.products.get_db")
    def test_on_product_deleted_cleans_stock_notifications_in_batches(self, mock_get_db, mock_algolia_delete):
        from handlers.products import on_product_deleted

        sub_doc = _snap({}, doc_id="sub_1")
        stock_query = Mock()
        stock_query.where.return_value = stock_query
        stock_query.limit.return_value = stock_query
        stock_query.stream.side_effect = [[sub_doc], []]

        db = Mock()
        db.collection.side_effect = lambda name: stock_query if name == Collections.STOCK_NOTIFICATIONS else Mock()
        batch = Mock()
        db.batch.return_value = batch
        mock_get_db.return_value = db

        event = Mock()
        event.params = {Fields.PRODUCT_ID: "prod_3"}

        on_product_deleted(event)

        mock_algolia_delete.assert_called_once_with("prod_3")
        batch.delete.assert_called_once_with(sub_doc.reference)
        batch.commit.assert_called_once()

    @patch("services.email_task.enqueue_email_task")
    @patch("handlers.products.get_db")
    def test_notify_admins_new_product_only_emails_admins_with_addresses(self, mock_get_db, mock_enqueue):
        from handlers.products import _notify_admins_new_product

        admin_with_email = _snap({Fields.EMAIL: "admin1@example.com"}, doc_id="admin_1")
        admin_without_email = _snap({}, doc_id="admin_2")
        admin_query = Mock()
        admin_query.where.return_value = admin_query
        admin_query.limit.return_value = admin_query
        admin_query.get.return_value = [admin_with_email, admin_without_email]

        db = Mock()
        db.collection.return_value = admin_query
        mock_get_db.return_value = db

        _notify_admins_new_product(
            "prod_4",
            {
                Fields.NAME: "Keyboard",
                Fields.SELLER_ID: "seller_1",
                Fields.IS_DIGITAL: False,
                Fields.PRICE: 49.99,
            },
        )

        mock_enqueue.assert_called_once()
        assert mock_enqueue.call_args.kwargs["to_email"] == "admin1@example.com"

    @patch("services.email_task.enqueue_email_task")
    def test_send_product_approval_and_rejection_email_language_branches(self, mock_enqueue):
        from handlers.products import _send_product_approval_email, _send_product_rejection_email

        _send_product_approval_email("seller@example.com", "Produit", "prod_1", lang="fr")
        _send_product_rejection_email("seller@example.com", "Product", "Invalid listing", lang="en")

        assert mock_enqueue.call_count == 2
        subjects = [c.kwargs["subject"] for c in mock_enqueue.call_args_list]
        assert any("Votre produit" in s for s in subjects)
        assert any("Product review update" in s for s in subjects)

    @patch("services.push_service.send_push_notifications_batch", return_value=2)
    @patch("handlers.products.get_db")
    def test_notify_premium_users_new_product_paginates(self, mock_get_db, mock_push_batch):
        from handlers.products import _notify_premium_users_new_product

        u1 = _snap({}, doc_id="u1")
        u2 = _snap({}, doc_id="u2")
        query = Mock()
        query.where.return_value = query
        query.limit.return_value = query
        query.start_after.return_value = query
        query.stream.side_effect = [[u1, u2], []]

        db = Mock()
        db.collection.return_value = query
        mock_get_db.return_value = db

        _notify_premium_users_new_product(
            {Fields.NAME: "Fresh Apples", Fields.IMAGE_URLS: ["https://cdn.example.com/img.jpg"]},
            "prod_5",
        )

        mock_push_batch.assert_called_once()
        assert mock_push_batch.call_args.kwargs["user_ids"] == ["u1", "u2"]
        assert mock_push_batch.call_args.kwargs["image_url"] == "https://cdn.example.com/img.jpg"
