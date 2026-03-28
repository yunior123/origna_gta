import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';

const BASE_URL = __ENV.BASE_URL || 'https://api.dev.orignagta.ca';
const BUYER_EMAIL = __ENV.BUYER_EMAIL || 'e2e-buyer@test.origna.ca';
const BUYER_PASSWORD = __ENV.BUYER_PASSWORD || 'REDACTED_TEST_PASSWORD';
const PRODUCT_ID = __ENV.PRODUCT_ID || 'e2e_product_test_seller';

const checkout500s = new Counter('checkout_500s');
const checkoutFailures = new Counter('checkout_failures');
const checkoutErrorRate = new Rate('checkout_error_rate');
const checkoutLatency = new Trend('checkout_latency_ms', true);

export const options = {
  scenarios: {
    checkout_stress: {
      executor: 'constant-vus',
      vus: 50,
      duration: '60s',
    },
  },
  thresholds: {
    checkout_500s: ['count==0'],
    checkout_error_rate: ['rate<0.05'],
  },
};

function login() {
  const response = http.post(
    `${BASE_URL}/auth/login`,
    JSON.stringify({
      email: BUYER_EMAIL,
      password: BUYER_PASSWORD,
    }),
    {
      headers: {
        'Content-Type': 'application/json',
      },
      tags: { name: 'auth_login' },
    },
  );

  const ok = check(response, {
    'login status 200': (r) => r.status === 200,
  });

  if (!ok) {
    checkoutFailures.add(1);
    checkoutErrorRate.add(1);
    return null;
  }

  const body = response.json();
  return body?.access_token || null;
}

function fetchProduct(token) {
  const response = http.post(
    `${BASE_URL}/graphql`,
    JSON.stringify({
      query: 'query GetProduct($collection: String!, $id: String!) { get(collection: $collection, id: $id) }',
      variables: {
        collection: 'products',
        id: PRODUCT_ID,
      },
    }),
    {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      tags: { name: 'graphql_get_product' },
    },
  );

  const body = response.json();
  return body?.data?.get || null;
}

function buildCheckoutPayload(product) {
  const productId = String(product?.id || PRODUCT_ID).includes(':')
    ? String(product.id).split(':', 2)[1]
    : String(product?.id || PRODUCT_ID);
  const priceCents = Number(product?.priceCents || Math.round(Number(product?.price || 19.99) * 100));

  return {
    userId: 'e2e-buyer',
    items: [
      {
        productId,
        name: String(product?.name || product?.title || 'Checkout Stress Product'),
        price: Number(product?.price || priceCents / 100),
        quantity: 1,
        sellerId: product?.sellerId || null,
        imageUrls: Array.isArray(product?.imageUrls) && product.imageUrls.length > 0
          ? product.imageUrls
          : ['https://pub-f9698d0f50d146bcac0e2dc9eb09de57.r2.dev/dev/products/samples/digital-1.jpg'],
        isDigital: Boolean(product?.isDigital),
      },
    ],
    subtotalCents: priceCents,
    eulaAccepted: Boolean(product?.isDigital),
    shippingAddress: {
      street: '100 King St W',
      apartment: '',
      city: 'Toronto',
      state: 'ON',
      postalCode: 'M5X 1A9',
      country: 'Canada',
      phoneNumber: '+14165550000',
    },
  };
}

export function setup() {
  const token = login();
  if (!token) {
    throw new Error('checkout stress setup failed: login returned no access token');
  }

  const product = fetchProduct(token);
  return {
    token,
    product,
  };
}

export default function (data) {
  const token = data?.token || login();
  if (!token) {
    return;
  }

  const payload = buildCheckoutPayload(data?.product);
  const start = Date.now();
  const response = http.post(
    `${BASE_URL}/api/checkout/session`,
    JSON.stringify(payload),
    {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      tags: { name: 'checkout_session' },
    },
  );
  const elapsed = Date.now() - start;
  checkoutLatency.add(elapsed);

  const ok = check(response, {
    'checkout no 500': (r) => r.status < 500,
    'checkout accepted or rejected gracefully': (r) => [200, 400, 401, 403, 409, 422, 429].includes(r.status),
  });

  if (response.status >= 500) {
    checkout500s.add(1);
  }

  if (!ok) {
    checkoutFailures.add(1);
    checkoutErrorRate.add(1);
  } else {
    checkoutErrorRate.add(0);
  }

  sleep(1);
}
