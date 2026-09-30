#!/usr/bin/env bash
# Runs every headless test. Fails on a failed check or on ANY engine script error.
# Usage: tests/run_all.sh [path-to-godot]   (from the game folder or anywhere)
set -u
GODOT="${1:-${GODOT:-godot}}"
cd "$(dirname "$0")/.."
status=0
for t in run_tests smoke; do
  out="$("$GODOT" --headless --path . --script "res://tests/$t.gd" 2>&1)"
  code=$?
  echo "$out" | grep -E "FAIL|passed|Passed|FAILED" | grep -v "^  ok" | tail -5
  # the save-file test deliberately reads a broken JSON file
  if echo "$out" | grep -E "SCRIPT ERROR|Parse Error|Invalid call|Invalid access" ; then status=1; fi
  if [ $code -ne 0 ]; then status=1; fi
done
[ $status -eq 0 ] && echo "ALL GREEN" || echo "TESTS FAILED"
exit $status
