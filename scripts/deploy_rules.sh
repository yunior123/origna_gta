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
  # Deploy Firestore rules, indexes, and hosting (always)
  firebase deploy --only firestore:rules,firestore:indexes,hosting --project "$PROJECT"
  # Deploy storage rules separately — gracefully skip if Firebase Storage not provisioned
  storage_out=$(firebase deploy --only storage --project "$PROJECT" 2>&1) || storage_exit=$?
  if echo "$storage_out" | grep -q "Firebase Storage has not been set up"; then
    echo "⚠️  [$ENV_NAME] Firebase Storage not provisioned — skipping (deny-all default applies)"
  elif [ "${storage_exit:-0}" -ne 0 ]; then
    echo "$storage_out"
    exit "${storage_exit}"
  fi
done

echo ""
echo "Recording deployed versions..."
python3 "$REPO_ROOT/scripts/record_deploy_version.py" --env=dev     --component=all
python3 "$REPO_ROOT/scripts/record_deploy_version.py" --env=staging --component=all
python3 "$REPO_ROOT/scripts/record_deploy_version.py" --env=prod    --component=all

echo ""
echo "✓ Rules, indexes, storage, and hosting deployed to all environments"
