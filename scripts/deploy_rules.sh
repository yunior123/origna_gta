#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$REPO_ROOT"

echo "Deploying Firestore rules, indexes, and hosting headers..."

firebase deploy --only firestore:rules,firestore:indexes,hosting

echo "✓ Firestore rules, indexes, and hosting deployed"
