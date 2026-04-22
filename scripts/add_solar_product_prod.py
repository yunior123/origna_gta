#!/usr/bin/env python3
"""Safe entrypoint for adding the solar product to production.

This script intentionally avoids embedded private keys or hardcoded auth.
Use the maintained Bun workflow instead:

  ADMIN_EMAIL=... ADMIN_PASSWORD=... bun scripts/add_hybrid_solar_system.ts

The TypeScript script uses the same OrignaBase auth flow as the E2E suite and
is the supported production insertion path for this product.
"""

from __future__ import annotations

import os
import subprocess
import sys


def main() -> int:
    missing = [
        key for key in ("ADMIN_EMAIL", "ADMIN_PASSWORD") if not os.getenv(key)
    ]
    if missing:
        print(
            "Missing required environment variables: "
            + ", ".join(missing)
            + ".",
            file=sys.stderr,
        )
        print(
            "Run with: ADMIN_EMAIL=... ADMIN_PASSWORD=... "
            "bun scripts/add_hybrid_solar_system.ts",
            file=sys.stderr,
        )
        return 1

    command = ["bun", "scripts/add_hybrid_solar_system.ts"]
    completed = subprocess.run(command, check=False)
    return completed.returncode


if __name__ == "__main__":
    raise SystemExit(main())
