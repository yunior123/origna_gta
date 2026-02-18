# Backend Testing Guide

## Unit Tests
Run unit tests using `pytest` to verify logic in isolation.
```bash
cd functions
pytest
```

## Integration Tests (Postman-like)
Run the API integration runner to verify deployed endpoints are reachable and responding correctly.
This script hits the actual Production URLs (or Emulator if specified).

### Usage
**Test Production:**
```bash
cd functions
python3 scripts/run_api_tests.py
```

**Test Emulator:**
```bash
cd functions
python3 scripts/run_api_tests.py --emulator
```

### Endpoints Covered
1. **Stripe Webhook**: Verifies signature protection.
2. **Airwallex Webhook**: Verifies signature protection.
3. **Create Checkout Session**: Verifies Cloud Function unauthenticated rejection.
4. **Get R2 Presigned URL**: Verifies validation logic.

### Adding New Tests
Edit `functions/scripts/run_api_tests.py` and add entries to the `tests` list.
```python
{
    "name": "My New Function",
    "endpoint": "my_function_name",
    "method": "POST",
    "body": {"data": "test"},
    "expected_status": [200]
}
```
