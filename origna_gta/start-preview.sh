#!/bin/bash
# Widget preview launcher — always use this instead of `flutter widget-preview start` directly.
# Ensures correct working directory regardless of where the script is invoked from.
cd "$(dirname "$0")"
flutter widget-preview start
