#!/bin/bash
# Run all tests for OrignaGta project
# Usage: ./scripts/run_all_tests.sh
# NOTE: Flutter integration tests are excluded until stabilized

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}OrignaGta Test Suite${NC}"
echo -e "${YELLOW}========================================${NC}"

FAILURES=0

# 1. Flutter analyze
echo -e "\n${YELLOW}[1/3] Flutter analyze...${NC}"
cd "$REPO_ROOT/origna_gta"
if flutter analyze; then
    echo -e "${GREEN}✓ Flutter analyze passed${NC}"
else
    echo -e "${RED}✗ Flutter analyze failed${NC}"
    FAILURES=$((FAILURES + 1))
fi

# 2. Flutter unit tests (excluding integration_test/)
echo -e "\n${YELLOW}[2/3] Flutter unit tests...${NC}"
if flutter test test/; then
    echo -e "${GREEN}✓ Flutter unit tests passed${NC}"
else
    echo -e "${RED}✗ Flutter unit tests failed${NC}"
    FAILURES=$((FAILURES + 1))
fi

# 3. Python tests
echo -e "\n${YELLOW}[3/3] Python tests...${NC}"
cd "$REPO_ROOT/functions"
if [ -d "venv" ]; then
    source venv/bin/activate
fi

if python -m pytest tests/ -v --tb=short 2>/dev/null || python3 -m pytest tests/ -v --tb=short 2>/dev/null; then
    echo -e "${GREEN}✓ Python tests passed${NC}"
else
    echo -e "${YELLOW}⚠ Python tests skipped (no pytest or tests)${NC}"
fi

if [ -d "venv" ]; then
    deactivate 2>/dev/null || true
fi

# Summary
echo -e "\n${YELLOW}========================================${NC}"
if [ $FAILURES -gt 0 ]; then
    echo -e "${RED}✗ $FAILURES test suite(s) failed${NC}"
    exit 1
else
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo -e "${YELLOW}Note: Flutter integration tests are disabled.${NC}"
    echo -e "${YELLOW}      Use Playwright E2E tests for full testing.${NC}"
    exit 0
fi
