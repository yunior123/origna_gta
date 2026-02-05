"""
Global configuration options for Firebase Cloud Functions
Applies to all functions to ensure they can start properly
"""

from firebase_functions import options

# Default options for all Cloud Functions
# These help prevent Container Healthcheck failures
DEFAULT_OPTIONS = {
    'timeout_sec': 540,  # 9 minutes (max for gen2)
    'memory': options.MemoryOption.GB_1,  # 1GB memory
    'min_instances': 0,  # Scale to zero when not in use
    'max_instances': 100,  # Prevent runaway costs
    'cpu': 1,  # 1 vCPU
}

# Options for HTTP webhook endpoints (need to respond quickly)
WEBHOOK_OPTIONS = {
    'timeout_sec': 60,  # 1 minute for webhooks
    'memory': options.MemoryOption.MB_512,
    'min_instances': 0,
    'max_instances': 100,
    'cpu': 1,
}

# Options for scheduled/background jobs
CRON_OPTIONS = {
    'timeout_sec': 540,  # 9 minutes
    'memory': options.MemoryOption.GB_1,
    'min_instances': 0,  # Only run when scheduled
    'max_instances': 1,  # Only one instance at a time
    'cpu': 1,
}

# CORS configuration for callable functions
CORS_CONFIG = options.CorsOptions(
    cors_origins=["*"],  # Allow all origins (adjust for production)
    cors_methods=["POST", "OPTIONS"],
)
