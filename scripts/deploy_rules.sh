#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$REPO_ROOT"

echo "Deploying Firestore rules and indexes..."

firebase deploy --only firestore:rules,firestore:indexes

echo "✓ Firestore rules and indexes deployed"
