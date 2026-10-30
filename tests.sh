#!/bin/bash
# Simple tests for byebye. Safe to run: only uses --help, bad flags and --dry-run.

cd "$(dirname "$0")" || exit 1
pass=0
fail=0

check() {
  local name="$1" expected="$2"
  shift 2
  "$@" >/dev/null 2>&1
  local code=$?
  if [ "$code" -eq "$expected" ]; then
    echo "PASS  $name"
    pass=$((pass + 1))
  else
    echo "FAIL  $name (expected exit $expected, got $code)"
    fail=$((fail + 1))
  fi
}

check "help exits 0"                    0 ./byebye.sh --help
check "unknown flag exits 2"            2 ./byebye.sh --nonsense
check "--except without a list exits 2" 2 ./byebye.sh --except
check "--delay with text exits 2"       2 ./byebye.sh --delay abc
check "dry run exits 0"                 0 ./byebye.sh --dry-run
check "dry run with --except exits 0"   0 ./byebye.sh --dry-run --except "Spotify,Notes"
check "dry run with --restart exits 0"  0 ./byebye.sh --dry-run --restart
check "dry run with --sleep exits 0"    0 ./byebye.sh --dry-run --sleep

echo
echo "Passed: $pass   Failed: $fail"
[ "$fail" -eq 0 ]
