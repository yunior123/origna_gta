#!/bin/bash
set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"

"$REPO_ROOT/scripts/deploy_rules.sh"
"$REPO_ROOT/scripts/pre_push_validation.sh"
