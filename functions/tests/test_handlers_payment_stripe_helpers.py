from datetime import UTC, datetime, timedelta
from unittest.mock import Mock, patch

import pytest
from firebase_functions import https_fn

from config import CATEGORY_TAX_CODE_MAP
from schema_constants import Collections, Fields


class _FakeProtoTimestamp:
    """Mimic protobuf timestamp objects that expose ToDatetime()."""

    def __init__(self, dt: datetime):
        self._dt = dt

    def ToDatetime(self) -> datetime:  # noqa: N802 (matches protobuf API)
        return self._dt


def _build_seller_db(seller_data: dict | None, profile_data: dict | None, seller_exists: bool = True, profile_exists: bool = True):
    db = Mock()

    seller_doc = Mock()
    seller_doc.exists = seller_exists
    seller_doc.to_dict.return_value = seller_data or {}

    profile_doc = Mock()
    profile_doc.exists = profile_exists
    profile_doc.to_dict.return_value = profile_data or {}

    def _collection_side_effect(name):
        coll = Mock()
        if name == Collections.USERS:
            coll.document.return_value.get.return_value = seller_doc
        elif name == Collections.SELLER_PROFILES:
            coll.document.return_value.get.return_value = profile_doc
        return coll

    db.collection.side_effect = _collection_side_effect
    return db


class TestPaymentStripeHelpers:
    @patch("utils.premium_check.is_premium_authoritative", return_value=True)
    @patch("handlers.payment_stripe.get_db")
    def test_check_premium_from_sub_uses_authoritative_service(self, mock_get_db, mock_is_premium):
        from handlers.payment_stripe import _check_premium_from_sub

        db = Mock()
        mock_get_db.return_value = db
        assert _check_premium_from_sub("buyer_1") is True
        mock_is_premium.assert_called_once_with("buyer_1", db=db)

    def test_get_tax_code_for_category_returns_mapping(self):
        from handlers.payment_stripe import get_tax_code_for_category

        key, val = next(iter(CATEGORY_TAX_CODE_MAP.items()))
        assert get_tax_code_for_category(key) == val
        assert get_tax_code_for_category("unknown-category") is None

    @patch("handlers.payment_stripe.RateLimiter")
    @patch("handlers.payment_stripe.get_db")
    def test_get_rate_limiter_lazy_singleton(self, mock_get_db, mock_rate_limiter):
        from handlers import payment_stripe

        payment_stripe._rate_limiter = None
        mock_get_db.return_value = Mock()
        rl_instance = Mock()
        mock_rate_limiter.return_value = rl_instance

        first = payment_stripe.get_rate_limiter()
        second = payment_stripe.get_rate_limiter()

        assert first is rl_instance
        assert second is rl_instance
        mock_rate_limiter.assert_called_once()
        payment_stripe._rate_limiter = None

    def test_ensure_stripe_key_sets_key_when_missing(self):
        from handlers import payment_stripe

        original_key = payment_stripe.stripe.api_key
        payment_stripe.stripe.api_key = ""
        try:
            with patch("handlers.payment_stripe.get_stripe_secret_key", return_value="STRIPE_SECRET_KEY_REDACTED"):
                payment_stripe.ensure_stripe_key()
            assert payment_stripe.stripe.api_key == "STRIPE_SECRET_KEY_REDACTED"
        finally:
            payment_stripe.stripe.api_key = original_key

    def test_coupon_not_expired_handles_none_and_protobuf_timestamps(self):
        from handlers.payment_stripe import _coupon_not_expired

        assert _coupon_not_expired({Fields.EXPIRES_AT: None}) is True

        future = datetime.now(UTC) + timedelta(days=1)
        past = datetime.now(UTC) - timedelta(days=1)
        assert _coupon_not_expired({Fields.EXPIRES_AT: _FakeProtoTimestamp(future)}) is True
        assert _coupon_not_expired({Fields.EXPIRES_AT: _FakeProtoTimestamp(past)}) is False

    @patch("handlers.payment_stripe.get_db")
    def test_coupon_within_limits_blocks_total_and_per_user_caps(self, mock_get_db):
        from handlers.payment_stripe import _coupon_within_limits

        # Global cap reached -> no Firestore read needed.
        assert (
            _coupon_within_limits(
                {
                    Fields.MAX_USES_TOTAL: 10,
                    Fields.USED_COUNT: 10,
                },
                "buyer_1",
            )
            is False
        )

        db = Mock()
        mock_get_db.return_value = db
        use_doc = Mock()
        use_doc.exists = True
        use_doc.to_dict.return_value = {"useCount": 2}
        db.collection.return_value.document.return_value.collection.return_value.document.return_value.get.return_value = use_doc

        assert (
            _coupon_within_limits(
                {
                    Fields.COUPON_CODE: "SAVE10",
                    Fields.MAX_USES_TOTAL: 100,
                    Fields.USED_COUNT: 1,
                    Fields.MAX_USES_PER_USER: 2,
                },
                "buyer_1",
            )
            is False
        )

    @patch("handlers.payment_stripe.get_db")
    def test_coupon_within_limits_allows_when_user_under_cap(self, mock_get_db):
        from handlers.payment_stripe import _coupon_within_limits

        db = Mock()
        mock_get_db.return_value = db
        use_doc = Mock()
        use_doc.exists = True
        use_doc.to_dict.return_value = {"useCount": 1}
        db.collection.return_value.document.return_value.collection.return_value.document.return_value.get.return_value = use_doc

        assert (
            _coupon_within_limits(
                {
                    Fields.COUPON_CODE: "SAVE10",
                    Fields.MAX_USES_TOTAL: 100,
                    Fields.USED_COUNT: 1,
                    Fields.MAX_USES_PER_USER: 2,
                },
                "buyer_1",
            )
            is True
        )

    def test_coupon_seller_allowed_and_min_order_checks(self):
        from handlers.payment_stripe import _coupon_min_order_met, _coupon_seller_allowed

        assert _coupon_seller_allowed({Fields.SELLER_ID: None}, {"seller_a"}) is True
        assert _coupon_seller_allowed({Fields.SELLER_ID: "seller_a"}, {"seller_a"}) is True
        assert _coupon_seller_allowed({Fields.SELLER_ID: "seller_b"}, {"seller_a"}) is False

        assert _coupon_min_order_met({Fields.MIN_ORDER_CENTS: None}, 1000) is True
        assert _coupon_min_order_met({Fields.MIN_ORDER_CENTS: 1000}, 1000) is True
        assert _coupon_min_order_met({Fields.MIN_ORDER_CENTS: 1500}, 1000) is False

    @patch("handlers.payment_stripe.get_db")
    def test_get_seller_stripe_snapshot_reads_private_subcollection(self, mock_get_db):
        from handlers.payment_stripe import _get_seller_stripe_snapshot

        db = Mock()
        mock_get_db.return_value = db
        snap = Mock()
        snap.exists = True
        snap.to_dict.return_value = {
            Fields.SELLER_STRIPE_ACCOUNTS: {"seller_1": "acct_1"},
        }
        db.collection.return_value.document.return_value.collection.return_value.document.return_value.get.return_value = snap

        out = _get_seller_stripe_snapshot("order_1", {})
        assert out == {"seller_1": "acct_1"}

    @patch("handlers.payment_stripe.get_db")
    def test_get_seller_stripe_snapshot_returns_empty_on_exception(self, mock_get_db):
        from handlers.payment_stripe import _get_seller_stripe_snapshot

        mock_get_db.side_effect = RuntimeError("db down")
        assert _get_seller_stripe_snapshot("order_1", {}) == {}

    @patch("handlers.payment_stripe.get_db")
    def test_assert_seller_active_rejects_not_found_and_suspended(self, mock_get_db):
        from handlers.payment_stripe import _assert_seller_active

        mock_get_db.return_value = _build_seller_db(None, None, seller_exists=False)
        with pytest.raises(https_fn.HttpsError) as not_found:
            _assert_seller_active("seller_missing")
        assert not_found.value.code == "not-found"

        mock_get_db.return_value = _build_seller_db({Fields.SUSPENDED: True}, {})
        with pytest.raises(https_fn.HttpsError) as suspended:
            _assert_seller_active("seller_suspended")
        assert suspended.value.code == "permission-denied"

    @patch("handlers.payment_stripe.get_db")
    def test_assert_seller_active_requires_onboarding_flags_when_enabled(self, mock_get_db):
        from handlers.payment_stripe import _assert_seller_active

        base_seller = {Fields.SUSPENDED: False}

        mock_get_db.return_value = _build_seller_db(base_seller, {Fields.ONBOARDING_COMPLETED: False})
        with pytest.raises(https_fn.HttpsError) as missing_onboarding:
            _assert_seller_active("seller_1", require_approval=True)
        assert missing_onboarding.value.code == "failed-precondition"

        mock_get_db.return_value = _build_seller_db(
            base_seller,
            {Fields.ONBOARDING_COMPLETED: True, Fields.CHARGES_ENABLED: False, Fields.PAYOUTS_ENABLED: True},
        )
        with pytest.raises(https_fn.HttpsError) as missing_charges:
            _assert_seller_active("seller_1", require_approval=True)
        assert missing_charges.value.code == "failed-precondition"

        mock_get_db.return_value = _build_seller_db(
            base_seller,
            {Fields.ONBOARDING_COMPLETED: True, Fields.CHARGES_ENABLED: True, Fields.PAYOUTS_ENABLED: False},
        )
        with pytest.raises(https_fn.HttpsError) as missing_payouts:
            _assert_seller_active("seller_1", require_approval=True)
        assert missing_payouts.value.code == "failed-precondition"

    @patch("handlers.payment_stripe.get_db")
    def test_assert_seller_active_returns_data_when_approval_not_required(self, mock_get_db):
        from handlers.payment_stripe import _assert_seller_active

        seller_data = {Fields.SUSPENDED: False, "displayName": "Seller"}
        mock_get_db.return_value = _build_seller_db(seller_data, None)
        assert _assert_seller_active("seller_1", require_approval=False) == seller_data

    def test_sanitize_metadata_keeps_primitives_and_stringifies_complex_types(self):
        from handlers.payment_stripe import sanitize_metadata

        out = sanitize_metadata(
            {
                "s": "text",
                "i": 1,
                "f": 1.5,
                "b": True,
                "n": None,
                "obj": {"k": "v"},
                "list": [1, 2, 3],
            }
        )

        assert out["s"] == "text"
        assert out["i"] == 1
        assert out["f"] == 1.5
        assert out["b"] is True
        assert out["n"] is None
        assert isinstance(out["obj"], str)
        assert isinstance(out["list"], str)
        assert sanitize_metadata("not-a-dict") == {}
