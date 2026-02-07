"""
Global configuration options for Firebase Cloud Functions
Optimized for FREE TIER - minimal resource usage, reasonable timeouts
"""
from firebase_functions import options

# Default: 256MB memory, 60s timeout (Firebase defaults - FREE TIER friendly)
DEFAULT_OPTIONS = {}

# Webhooks: 256MB memory, 90s timeout (Stripe retries on timeout, need margin)
WEBHOOK_OPTIONS = {
    'timeout_sec': 90,
}

# Cron jobs: 256MB memory, 300s timeout (batch processing up to 500 orders)
CRON_OPTIONS = {
    'timeout_sec': 300,
}
