"""
Pytest configuration file
Loads environment variables from .env file before running tests
"""

import os
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

def pytest_configure(config):
    """Load environment variables from .env file before tests run"""
    env_file = Path(__file__).parent.parent / '.env'
    
    if env_file.exists():
        print(f"\n📁 Loading environment from: {env_file}")
        with open(env_file, 'r') as f:
            for line in f:
                line = line.strip()
                # Skip empty lines and comments
                if not line or line.startswith('#'):
                    continue
                
                # Parse key=value pairs
                if '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip()
                    
                    # Remove quotes if present
                    if (value.startswith('"') and value.endswith('"')) or \
                       (value.startswith("'") and value.endswith("'")):
                        value = value[1:-1]
                    
                    # Set environment variable if not already set
                    if key not in os.environ:
                        os.environ[key] = value
                        
        # Verify Algolia credentials are loaded
        algolia_app_id = os.environ.get('ALGOLIA_APP_ID', '')
        algolia_write_key = os.environ.get('ALGOLIA_WRITE_API_KEY', '')
        
        if algolia_app_id and algolia_write_key:
            print(f"✅ Algolia credentials loaded: APP_ID={algolia_app_id[:4]}...")
        else:
            print("⚠️ Algolia credentials not found in .env")
    else:
        print(f"\n⚠️ No .env file found at {env_file}")
