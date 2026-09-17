#!/usr/bin/env bash
# Run SweetPotatOs unit tests.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

FAIL=0
run() {
  local name="$1"
  shift
  echo "== ${name} =="
  if "$@"; then
    echo
  else
    echo
    FAIL=1
  fi
}

run "autotile_lib" lua "${ROOT}/tests/test_autotile_lib.lua"
run "materialize" bash "${ROOT}/tests/test_materialize.sh"
run "update_channel" bash "${ROOT}/tests/test_update_channel.sh"
run "smoke-check" bash "${ROOT}/scripts/smoke-check.sh"

if [[ "${FAIL}" -eq 0 ]]; then
  echo "ALL TESTS PASSED"
  exit 0
fi
echo "SOME TESTS FAILED"
exit 1
