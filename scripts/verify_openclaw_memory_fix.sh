#!/usr/bin/env bash
set -uo pipefail

# Run this against the real machine state. Sandboxed runs may report false
# EPERM errors for ~/.openclaw/memory/lancedb-pro.

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

stats_log="$tmpdir/memory-pro-stats.log"
help_log="$tmpdir/memory-pro-help.log"
doctor_log="$tmpdir/doctor.log"

run_capture() {
  local label="$1"
  local logfile="$2"
  shift 2

  echo "==> $label"
  if "$@" >"$logfile" 2>&1; then
    echo "exit=0" >>"$logfile"
  else
    local status=$?
    echo "exit=$status" >>"$logfile"
  fi
  cat "$logfile"
  echo
}

check_forbidden() {
  local logfile="$1"
  shift
  local failed=0

  for pattern in "$@"; do
    if grep -Fq "$pattern" "$logfile"; then
      echo "FATAL: found forbidden pattern in $(basename "$logfile"): $pattern" >&2
      failed=1
    fi
  done

  return "$failed"
}

forbidden_patterns=(
  "Config validation failed"
  "No active memory plugin is registered"
  "Bundled plugin public surface access blocked"
  "invalid config: embedding"
  "unknown command 'memory-pro'"
)

run_capture "openclaw memory-pro stats" "$stats_log" openclaw memory-pro stats
run_capture "openclaw memory-pro --help" "$help_log" openclaw memory-pro --help
run_capture "openclaw doctor --non-interactive" "$doctor_log" openclaw doctor --non-interactive

failed=0

if ! check_forbidden "$stats_log" "${forbidden_patterns[@]}"; then
  failed=1
fi

if ! check_forbidden "$help_log" "${forbidden_patterns[@]}"; then
  failed=1
fi

if ! check_forbidden "$doctor_log" "${forbidden_patterns[@]}"; then
  failed=1
fi

if ! grep -Fq "exit=0" "$stats_log"; then
  echo "FATAL: openclaw memory-pro stats did not exit cleanly" >&2
  failed=1
fi

if ! grep -Fq "exit=0" "$help_log"; then
  echo "FATAL: openclaw memory-pro --help did not exit cleanly" >&2
  failed=1
fi

if ! grep -Fq "exit=0" "$doctor_log"; then
  echo "FATAL: openclaw doctor --non-interactive did not exit cleanly" >&2
  failed=1
fi

if ! grep -Fq "Doctor complete." "$doctor_log"; then
  echo "FATAL: doctor did not reach completion" >&2
  failed=1
fi

if ! grep -Fq "Memory Statistics:" "$stats_log"; then
  echo "FATAL: memory-pro stats did not print statistics" >&2
  failed=1
fi

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "PASS: OpenClaw memory repair acceptance checks passed."
