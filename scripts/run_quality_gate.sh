#!/usr/bin/env bash

# Strict quality gate:
# - Backend Python coverage threshold
# - Flutter test coverage threshold (unit + widget targets)
# - Real Playwright E2E smoke set
#
# Defaults intentionally set to 100 to enforce strict mode.

set -u
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

BACKEND_THRESHOLD="${BACKEND_THRESHOLD:-100}"
FLUTTER_THRESHOLD="${FLUTTER_THRESHOLD:-100}"
E2E_SPECS="${E2E_SPECS:-${E2E_SPEC:-playwright_ui/smoke-home-profile.spec.ts,playwright_ui/buyer-flow.spec.ts,playwright_ui/seller-flow.spec.ts,playwright_ui/order-lifecycle.spec.ts}}"
E2E_CONFIG="${E2E_CONFIG:-playwright.config.dev.ts}"
E2E_PROJECT="${E2E_PROJECT:-chromium}"
E2E_WORKERS="${E2E_WORKERS:-1}"
E2E_FAIL_ON_FLAKY="${E2E_FAIL_ON_FLAKY:-true}"
FLUTTER_TEST_TARGETS="${FLUTTER_TEST_TARGETS:-test/unit,test/widget,test/widget_test.dart}"
RUN_FLUTTER_GOLDENS="${RUN_FLUTTER_GOLDENS:-false}"
FLUTTER_GOLDEN_TEST_PATH="${FLUTTER_GOLDEN_TEST_PATH:-test/golden_previews_test.dart}"

RUN_BACKEND=true
RUN_FLUTTER=true
RUN_E2E=true

print_usage() {
  cat <<'EOF'
Usage: ./scripts/run_quality_gate.sh [options]

Options:
  --backend-threshold N   Backend coverage threshold (default: env BACKEND_THRESHOLD or 100)
  --flutter-threshold N   Flutter coverage threshold (default: env FLUTTER_THRESHOLD or 100)
  --flutter-targets CSV   Flutter test targets under origna_gta/ (default: test/unit,test/widget,test/widget_test.dart)
  --run-flutter-goldens   Run Flutter golden test suite (opt-in)
  --flutter-golden-test P Golden test path under origna_gta/ (default: test/golden_previews_test.dart)
  --e2e-spec PATH         Playwright spec path under e2e/ (single override, backward-compatible)
  --e2e-specs CSV         Comma-separated Playwright specs under e2e/
  --e2e-config FILE       Playwright config file under e2e/ (default: playwright.config.dev.ts)
  --e2e-project NAME      Playwright project (default: chromium)
  --e2e-workers N         Playwright workers (default: 1)
  --skip-backend          Skip backend coverage gate
  --skip-flutter          Skip Flutter coverage gate
  --skip-e2e              Skip Playwright E2E gate
  --help, -h              Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --backend-threshold)
      BACKEND_THRESHOLD="$2"
      shift 2
      ;;
    --flutter-threshold)
      FLUTTER_THRESHOLD="$2"
      shift 2
      ;;
    --flutter-targets)
      FLUTTER_TEST_TARGETS="$2"
      shift 2
      ;;
    --run-flutter-goldens)
      RUN_FLUTTER_GOLDENS=true
      shift
      ;;
    --flutter-golden-test)
      FLUTTER_GOLDEN_TEST_PATH="$2"
      shift 2
      ;;
    --e2e-spec|--e2e-specs)
      E2E_SPECS="$2"
      shift 2
      ;;
    --e2e-config)
      E2E_CONFIG="$2"
      shift 2
      ;;
    --e2e-project)
      E2E_PROJECT="$2"
      shift 2
      ;;
    --e2e-workers)
      E2E_WORKERS="$2"
      shift 2
      ;;
    --skip-backend)
      RUN_BACKEND=false
      shift
      ;;
    --skip-flutter)
      RUN_FLUTTER=false
      shift
      ;;
    --skip-e2e)
      RUN_E2E=false
      shift
      ;;
    --help|-h)
      print_usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      print_usage
      exit 2
      ;;
  esac
done

FAILURES=0

section() {
  echo
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

backend_gap_report() {
  python3 - <<'PY'
from pathlib import Path
import xml.etree.ElementTree as ET

xml_path = Path("coverage.xml")
if not xml_path.exists():
    print("No backend XML coverage report found at functions/coverage.xml")
    raise SystemExit(0)

root = ET.parse(xml_path).getroot()
rows = []
for cls in root.findall(".//class"):
    filename = cls.attrib.get("filename", "")
    lines = cls.findall("./lines/line")
    valid = len(lines)
    covered = sum(1 for line in lines if int(line.attrib.get("hits", "0")) > 0)
    if valid < 20:
        continue
    pct = (covered / valid * 100.0) if valid else 0.0
    rows.append((pct, valid, covered, filename))

rows.sort(key=lambda x: (x[0], -x[1], x[3]))
print("Lowest backend coverage files (min 20 executable lines):")
for pct, valid, covered, filename in rows[:15]:
    print(f"  - {filename}: {pct:.2f}% ({covered}/{valid})")
PY
}

flutter_gap_report() {
  python3 - <<'PY'
from pathlib import Path

lcov_path = Path("coverage_unit.info")
if not lcov_path.exists():
    print("No Flutter LCOV report found at origna_gta/coverage_unit.info")
    raise SystemExit(0)

rows = []
sf = None
lf = None
lh = None

for raw in lcov_path.read_text().splitlines():
    if raw.startswith("SF:"):
        sf = raw[3:]
        lf = None
        lh = None
    elif raw.startswith("LF:"):
        lf = int(raw[3:])
    elif raw.startswith("LH:"):
        lh = int(raw[3:])
    elif raw == "end_of_record":
        if sf is not None and lf is not None and lh is not None and lf >= 20:
            pct = (lh / lf * 100.0) if lf else 0.0
            rows.append((pct, lf, lh, sf))
        sf = None
        lf = None
        lh = None

rows.sort(key=lambda x: (x[0], -x[1], x[3]))
print("Lowest Flutter coverage files (min 20 executable lines):")
for pct, lf, lh, sf in rows[:15]:
    print(f"  - {sf}: {pct:.2f}% ({lh}/{lf})")
PY
}

check_flutter_threshold() {
  local threshold="$1"
  python3 - "$threshold" <<'PY'
import sys
from pathlib import Path

threshold = float(sys.argv[1])
lcov_path = Path("coverage_unit.info")
if not lcov_path.exists():
    print("coverage_unit.info not found", file=sys.stderr)
    raise SystemExit(2)

lf = 0
lh = 0
for line in lcov_path.read_text().splitlines():
    if line.startswith("LF:"):
        lf += int(line[3:])
    elif line.startswith("LH:"):
        lh += int(line[3:])

pct = (lh / lf * 100.0) if lf else 0.0
print(f"Flutter total line coverage: {pct:.2f}% ({lh}/{lf})")
if pct + 1e-9 < threshold:
    raise SystemExit(1)
PY
}

if [[ "$RUN_BACKEND" == true ]]; then
  section "Backend Coverage Gate (threshold: ${BACKEND_THRESHOLD}%)"
  pushd "$ROOT_DIR/functions" >/dev/null || exit 1

  if ! python3 -c "import pytest_cov" >/dev/null 2>&1; then
    echo "Installing pytest-cov..."
    python3 -m pip install pytest-cov >/dev/null 2>&1 || true
  fi

  set +e
  pytest tests/ \
    --cov=handlers \
    --cov=services \
    --cov=models \
    --cov=utils \
    --cov-report=term-missing \
    --cov-report=xml:coverage.xml \
    --cov-fail-under="$BACKEND_THRESHOLD" \
    -q
  STATUS=$?
  set -e

  backend_gap_report
  popd >/dev/null || exit 1

  if [[ $STATUS -ne 0 ]]; then
    echo "Backend coverage gate FAILED."
    FAILURES=$((FAILURES + 1))
  else
    echo "Backend coverage gate PASSED."
  fi
fi

if [[ "$RUN_FLUTTER" == true ]]; then
  section "Flutter Coverage Gate (threshold: ${FLUTTER_THRESHOLD}%)"
  pushd "$ROOT_DIR/origna_gta" >/dev/null || exit 1

  FLUTTER_TARGETS=()
  IFS=',' read -r -a RAW_FLUTTER_TARGETS <<< "$FLUTTER_TEST_TARGETS"
  for raw_target in "${RAW_FLUTTER_TARGETS[@]}"; do
    target="$(echo "$raw_target" | xargs)"
    [[ -z "$target" ]] && continue
    if [[ -e "$target" ]]; then
      FLUTTER_TARGETS+=("$target")
    else
      echo "Skipping missing Flutter target: $target"
    fi
  done

  if [[ ${#FLUTTER_TARGETS[@]} -eq 0 ]]; then
    echo "No Flutter test targets found from FLUTTER_TEST_TARGETS=$FLUTTER_TEST_TARGETS"
    FAILURES=$((FAILURES + 1))
  else
    echo "Running Flutter tests: ${FLUTTER_TARGETS[*]}"
    set +e
    flutter test "${FLUTTER_TARGETS[@]}" --coverage --coverage-path=coverage_unit.info
    TEST_STATUS=$?
    set -e

    if [[ $TEST_STATUS -ne 0 ]]; then
      echo "Flutter tests FAILED."
      FAILURES=$((FAILURES + 1))
    else
      set +e
      check_flutter_threshold "$FLUTTER_THRESHOLD"
      THRESH_STATUS=$?
      set -e
      flutter_gap_report
      if [[ $THRESH_STATUS -ne 0 ]]; then
        echo "Flutter coverage gate FAILED."
        FAILURES=$((FAILURES + 1))
      else
        echo "Flutter coverage gate PASSED."
      fi
    fi
  fi

  if [[ "$RUN_FLUTTER_GOLDENS" == "true" ]]; then
    section "Flutter Golden Gate (${FLUTTER_GOLDEN_TEST_PATH})"
    if [[ ! -e "$FLUTTER_GOLDEN_TEST_PATH" ]]; then
      echo "Flutter golden test path not found: $FLUTTER_GOLDEN_TEST_PATH"
      FAILURES=$((FAILURES + 1))
    else
      set +e
      flutter test "$FLUTTER_GOLDEN_TEST_PATH" --dart-define=RUN_GOLDENS=true
      GOLDEN_STATUS=$?
      set -e
      if [[ $GOLDEN_STATUS -ne 0 ]]; then
        echo "Flutter golden gate FAILED."
        FAILURES=$((FAILURES + 1))
      else
        echo "Flutter golden gate PASSED."
      fi
    fi
  fi

  popd >/dev/null || exit 1
fi

if [[ "$RUN_E2E" == true ]]; then
  section "Real Playwright E2E Gate (${E2E_SPECS})"
  pushd "$ROOT_DIR/e2e" >/dev/null || exit 1

  if ! command -v npx >/dev/null 2>&1; then
    echo "npx not found. Install Node.js/npm first."
    FAILURES=$((FAILURES + 1))
  else
    E2E_SPEC_ARRAY=()
    IFS=',' read -r -a RAW_E2E_SPECS <<< "$E2E_SPECS"
    for raw_spec in "${RAW_E2E_SPECS[@]}"; do
      spec="$(echo "$raw_spec" | xargs)"
      [[ -z "$spec" ]] && continue
      E2E_SPEC_ARRAY+=("$spec")
    done

    if [[ ${#E2E_SPEC_ARRAY[@]} -eq 0 ]]; then
      echo "No E2E specs configured. Set E2E_SPECS or --e2e-specs."
      FAILURES=$((FAILURES + 1))
    else
      E2E_SPEC_FAILURES=0
      for spec in "${E2E_SPEC_ARRAY[@]}"; do
        echo "Running E2E spec: $spec"
        E2E_CMD=(
          npx playwright test "$spec"
          --config="$E2E_CONFIG"
          --project="$E2E_PROJECT"
          --workers="$E2E_WORKERS"
        )
        if [[ "$E2E_FAIL_ON_FLAKY" == "true" ]]; then
          E2E_CMD+=(--fail-on-flaky-tests)
        fi
        set +e
        "${E2E_CMD[@]}"
        E2E_STATUS=$?
        set -e
        if [[ $E2E_STATUS -ne 0 ]]; then
          echo "E2E spec FAILED: $spec"
          E2E_SPEC_FAILURES=$((E2E_SPEC_FAILURES + 1))
        else
          echo "E2E spec PASSED: $spec"
        fi
      done

      if [[ $E2E_SPEC_FAILURES -ne 0 ]]; then
        echo "Real Playwright E2E gate FAILED (${E2E_SPEC_FAILURES} spec(s) failed)."
        FAILURES=$((FAILURES + 1))
      else
        echo "Real Playwright E2E gate PASSED."
      fi
    fi
  fi

  popd >/dev/null || exit 1
fi

section "Quality Gate Summary"
if [[ $FAILURES -gt 0 ]]; then
  echo "FAILED with ${FAILURES} failing gate(s)."
  exit 1
fi

echo "PASSED. All enabled quality gates succeeded."
