"""
Mock Stripe module for E2E testing

This module replaces the real stripe module when running in emulator mode.
It proxies requests to a local mock Stripe server.
"""

import json
import requests
from typing import Dict, Any, Optional

MOCK_STRIPE_URL = "http://localhost:4242"

class MockStripeResponse:
    def __init__(self, data: Dict[str, Any]):
        self._data = data

    def __getattr__(self, name):
        return self._data.get(name)

    def __getitem__(self, key):
        return self._data[key]

    def __contains__(self, key):
        return key in self._data

    def get(self, key, default=None):
        return self._data.get(key, default)

    def __repr__(self):
        return f"MockStripeResponse({self._data})"

class MockStripeAccountAPI:
    @staticmethod
    def create(**kwargs):
        try:
            response = requests.post(f"{MOCK_STRIPE_URL}/v1/accounts", json=kwargs)
            response.raise_for_status()
            return MockStripeResponse(response.json())
        except requests.RequestException:
            # Fallback to mock response if server not available
            return MockStripeResponse({
                'id': f'acct_mock_{hash(str(kwargs)) % 10000:04d}',
                'object': 'account',
                'business_type': kwargs.get('business_type', 'individual'),
                'capabilities': {'card_payments': {'requested': True}, 'transfers': {'requested': True}},
                'charges_enabled': False,
                'country': 'CA',
                'created': 1640995200,
                'default_currency': 'cad',
                'details_submitted': False,
                'email': kwargs.get('email', 'test@example.com'),
                'payouts_enabled': False,
                'requirements': {'currently_due': [], 'eventually_due': [], 'past_due': [], 'pending_verification': []},
                'type': 'express'
            })

class MockStripeAccountLinkAPI:
    @staticmethod
    def create(**kwargs):
        try:
            response = requests.post(f"{MOCK_STRIPE_URL}/v1/account_links", json=kwargs)
            response.raise_for_status()
            return MockStripeResponse(response.json())
        except requests.RequestException:
            # Fallback to mock response
            return MockStripeResponse({
                'object': 'account_link',
                'created': 1640995200,
                'expires_at': 1640998800,
                'url': 'http://localhost:5005/seller/onboarding-success?mock=true'
            })

class MockStripeCheckoutSessionAPI:
    @staticmethod
    def create(**kwargs):
        try:
            response = requests.post(f"{MOCK_STRIPE_URL}/v1/checkout/sessions", json=kwargs)
            response.raise_for_status()
            return MockStripeResponse(response.json())
        except requests.RequestException:
            # Fallback to mock response
            return MockStripeResponse({
                'id': f'cs_test_mock_{hash(str(kwargs)) % 10000:04d}',
                'object': 'checkout.session',
                'amount_total': kwargs.get('line_items', [{}])[0].get('amount', 5000),
                'currency': kwargs.get('currency', 'cad'),
                'customer': None,
                'customer_email': kwargs.get('customer_email', 'buyer@test.com'),
                'line_items': kwargs.get('line_items', [{
                    'amount_total': 5000,
                    'currency': 'cad',
                    'description': 'Test Product',
                    'price': {'id': 'price_test_123', 'object': 'price'},
                    'quantity': 1
                }]),
                'livemode': False,
                'mode': 'payment',
                'payment_intent': f'pi_mock_{hash(str(kwargs)) % 10000:04d}',
                'payment_status': 'paid',
                'status': 'complete',
                'success_url': kwargs.get('success_url', 'http://localhost:5005/payment-success?session_id={CHECKOUT_SESSION_ID}'),
                'url': f'http://localhost:5005/payment-success?mock=true&session_id=cs_test_mock_{hash(str(kwargs)) % 10000:04d}'
            })

    @staticmethod
    def retrieve(session_id):
        try:
            response = requests.get(f"{MOCK_STRIPE_URL}/v1/checkout/sessions/{session_id}")
            response.raise_for_status()
            return MockStripeResponse(response.json())
        except requests.RequestException:
            # Fallback to mock response
            return MockStripeResponse({
                'id': session_id,
                'object': 'checkout.session',
                'amount_total': 5000,
                'currency': 'cad',
                'customer_email': 'buyer@test.com',
                'line_items': [{
                    'amount_total': 5000,
                    'currency': 'cad',
                    'description': 'Test Product',
                    'quantity': 1
                }],
                'livemode': False,
                'mode': 'payment',
                'payment_status': 'paid',
                'status': 'complete'
            })

class MockStripeCheckoutAPI:
    def __init__(self):
        self.Session = MockStripeCheckoutSessionAPI

class MockStripeAPI:
    def __init__(self):
        self.Account = MockStripeAccountAPI
        self.AccountLink = MockStripeAccountLinkAPI
        self.Checkout = MockStripeCheckoutAPI()

# Create mock instance
mock_stripe = MockStripeAPI()

# Export the mock as 'stripe' so it can replace the real stripe module
stripe = mock_stripe