#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$REPO_ROOT"

echo "Deploying Firestore rules, indexes, storage rules, and hosting to all environments..."

for PROJECT in orignagta-dev orignagta-staging orignagta; do
  ENV_NAME="${PROJECT##*-}"
  [[ "$PROJECT" == "orignagta" ]] && ENV_NAME="prod"
  echo ""
  echo "→ [$ENV_NAME] $PROJECT"
  firebase deploy --only firestore:rules,firestore:indexes,storage,hosting --project "$PROJECT"
done

echo ""
echo "Recording deployed versions..."
python3 "$REPO_ROOT/scripts/record_deploy_version.py" --env=dev     --component=all
python3 "$REPO_ROOT/scripts/record_deploy_version.py" --env=staging --component=all
python3 "$REPO_ROOT/scripts/record_deploy_version.py" --env=prod    --component=all

echo ""
echo "✓ Rules, indexes, storage, and hosting deployed to all environments"
