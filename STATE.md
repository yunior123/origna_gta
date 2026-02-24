# STATE.md

 "feeRate": PLATFORM_FEE_RATIO,  # TODO: use Fields.FEE_RATE when added to schema_constants
            Fields.CREATED_AT: get_server_timestamp(),


2.    fee_rate = PLATFORM_FEE_RATIO  # TODO: use Fields.FEE_RATE when added to schema_constants

                sellers_total = {}

3. improve comments  # AUDIT FIX (MEDIUM-030): Block disabling a provider with active authorized orders.
        # Without this, orders paid but not yet captured would be stranded because
        # capture_payment() checks require_provider_enabled() first.
        from schema_constants import PaymentStatusValues as PSV

4.fix warning here    if coupon_seller_id is not None:
        if not isinstance(seller_ids, list) or coupon_seller_id not in seller_ids:
            raise https_fn.HttpsError("failed-precondition", "Coupon invalid or unavailable")

5. fix warnings    except requests.Timeout:
        raise https_fn.HttpsError("deadline-exceeded", "Address lookup timed out")
    except requests.HTTPError as e:
        raise https_fn.HttpsError("internal", f"Address service error: {e}")
    except Exception as e:
        raise https_fn.HttpsError("internal", f"Unexpected error: {e}")

6. improve comments     # Cancel all pending/confirmed orders (with safety limit)
        # NOTE: Use denormalized sellerIds field (not nested items.sellerId which Firestore doesn't support)
        orders = (
            get_db()

7. no need to use env keys for staging, remove that shit /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/functions/.env.orignagta-staging

8. make sure that env variables and service account keys are only used locally, they cannot be in the cloud