#!/bin/bash
set -e

# ════════════════════════════════════════════════════════════════════
# OrignaGTA Security Tests Runner
# ════════════════════════════════════════════════════════════════════
# Run comprehensive security test suite to verify all critical fixes

cd "$(dirname "$0")"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}OrignaGTA — Security Fixes E2E Test Suite${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
echo ""

# Check environment
if [ -z "$ENVIRONMENT" ]; then
  echo -e "${YELLOW}[INFO] ENVIRONMENT not set, defaulting to 'dev'${NC}"
  ENVIRONMENT="dev"
fi

if [ -z "$E2E_TARGET_URL" ]; then
  echo -e "${YELLOW}[INFO] E2E_TARGET_URL not set, defaulting to 'https://dev.orignagta.ca'${NC}"
  E2E_TARGET_URL="https://dev.orignagta.ca"
fi

export ENVIRONMENT
export E2E_TARGET_URL

echo -e "${GREEN}[✓] Environment: ${ENVIRONMENT}${NC}"
echo -e "${GREEN}[✓] Target URL: ${E2E_TARGET_URL}${NC}"
echo ""

# Run tests
echo -e "${BLUE}Running Security Auth Fixes (16 tests)...${NC}"
if bun test specs/phase1-api/security-auth-fixes.spec.ts; then
  echo -e "${GREEN}[✓] Auth fixes tests PASSED${NC}"
else
  echo -e "${RED}[✗] Auth fixes tests FAILED${NC}"
  exit 1
fi

echo ""
echo -e "${BLUE}Running Security Payment Fixes (13 tests)...${NC}"
if bun test specs/phase1-api/security-payment-fixes.spec.ts; then
  echo -e "${GREEN}[✓] Payment fixes tests PASSED${NC}"
else
  echo -e "${RED}[✗] Payment fixes tests FAILED${NC}"
  exit 1
fi

echo ""
echo -e "${BLUE}Running Security Data Fixes (15 tests)...${NC}"
if bun test specs/phase1-api/security-data-fixes.spec.ts; then
  echo -e "${GREEN}[✓] Data fixes tests PASSED${NC}"
else
  echo -e "${RED}[✗] Data fixes tests FAILED${NC}"
  exit 1
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}[✓] ALL SECURITY TESTS PASSED (44 tests)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
