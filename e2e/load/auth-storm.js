import http from 'k6/http';
import { check } from 'k6';

export const options = {
  vus: 10,
  duration: '30s',
};

export default function () {
  const res = http.post(
    'https://api.dev.orignagta.ca/auth/login',
    JSON.stringify({
      email: 'e2e-buyer@test.origna.ca',
      password: 'REDACTED_TEST_PASSWORD',
    }),
    {
      headers: {
        'Content-Type': 'application/json',
      },
    },
  );

  check(res, {
    'status 200': (r) => r.status === 200,
  });
}
