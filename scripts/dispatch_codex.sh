#!/bin/bash

# Agent 1: OrignaVentures Tiers & Contracts
nohup /opt/homebrew/bin/opencode run -m opencode/mimo-v2-pro-free "In origna_ventures/: 1) Update service tiers to Service 1, Service 2, Service 3. 2) Add 1000 CAD to Service 2 and explicitly include '20 human tester = 20x1h of work -> 20 h of QA testing'. 3) Ensure the 3 tiers are directly on the home view for quick payment. 4) Remove contract signing features, replace with policy links. Modify flutter code only." > /tmp/codex-batch1-output.log 2>&1 &

# Agent 2: UI/UX & Theming
nohup /opt/homebrew/bin/opencode run -m opencode/mimo-v2-pro-free "In origna_gta/ and origna_ventures/: 1) Match the splash theme of origna_gta with orignaventures (resolve blue vs red+green discrepancy to feel premium). 2) Embed OrignaVentures logo and company specs into origna_gta (e.g. settings/about view). 3) Implement a manual language selector if not already present. 4) Audit and fix Spanish translations across the board. Modify flutter code only." > /tmp/codex-batch2-output.log 2>&1 &

# Agent 3: Testing & Code Audits
nohup /opt/homebrew/bin/opencode run -m opencode/mimo-v2-pro-free "In origna_gta/ and orignabase/ and e2e/: 1) Audit all app code for remnants of seller onboarding (since it is disabled). 2) Ensure payment endpoints function correctly with seller onboarding disabled. 3) Fix any missing semantic labels to aid E2E testing. 4) Identify gaps in live tests and E2E coverage and add test skeletons/implementations. Modify rust/flutter/ts code." > /tmp/codex-batch3-output.log 2>&1 &

echo "Dispatched 3 parallel codex agents."
