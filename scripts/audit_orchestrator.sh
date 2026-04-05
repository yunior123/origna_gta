#!/bin/bash
# audit_orchestrator.sh
# Orchestrates a full codebase audit using all AI skills via free models (opencode/kilo).
# Ensures max 2 concurrent jobs to respect the 8GB RAM limit.

set -euo pipefail

SKILLS_DIR="$(pwd)/.claude/skills"
OUT_DIR="/tmp/orignagta_audits"
mkdir -p "$OUT_DIR"

echo "Starting Full Audit Orchestration with 2 concurrent workers..."
echo "Results will be saved to $OUT_DIR"

# Collect all skills
SKILLS=($(ls -1d "$SKILLS_DIR"/*/ | awk -F/ '{print $(NF-1)}'))

# Function to run a single audit
run_audit() {
    local skill=$1
    local out_file="/tmp/orignagta_audits/${skill}_audit.log"
    echo "[$skill] Starting audit..."
    
    local prompt="Read .claude/skills/$skill/SKILL.md. Execute the audit against this codebase. Output findings in P0/P1/P2 format with file:line evidence. Only output actionable fixes, no preamble."
    
    # Use opencode with free mimo model
    /opt/homebrew/bin/opencode run -m opencode/mimo-v2-pro-free "$prompt" > "$out_file" 2>&1
    
    echo "[$skill] Finished. Saved to $out_file"
}

export -f run_audit

# Run audits with 2 concurrent processes
printf "%s\n" "${SKILLS[@]}" | xargs -n 1 -P 2 -I {} bash -c 'run_audit "$@"' _ {}

echo "All audits completed. Compiling summary..."
cat "$OUT_DIR"/*_audit.log > "$OUT_DIR/full_audit_summary.md"
echo "Full summary saved to $OUT_DIR/full_audit_summary.md"
