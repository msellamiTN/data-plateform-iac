#!/usr/bin/env bash
# ============================================================
# test-fleet-readiness.sh — instructor dashboard
# Probes Snowflake for all learner-prefixed objects (APP01..APP11)
# and prints a per-learner summary table. Read-only, non-destructive.
#
# Usage:
#   ./scripts/test-fleet-readiness.sh
#   ./scripts/test-fleet-readiness.sh APP01 APP02 APP03
# ============================================================

set -uo pipefail

connection="${SNOWFLAKE_CONNECTION:-training}"
prefixes=("${@:-}")
if [[ ${#prefixes[@]} -eq 0 || -z "${prefixes[0]:-}" ]]; then
  prefixes=(APP01 APP02 APP03 APP04 APP05 APP06 APP07 APP08 APP09 APP10 APP11)
fi

echo ""
echo "============================================================"
echo " Fleet Readiness — instructor dashboard"
echo "============================================================"
echo "  Connection : $connection"
echo "  Prefixes   : ${prefixes[*]}"
echo ""

if ! command -v snow >/dev/null 2>&1; then
  echo "[FAIL] snow CLI not found in PATH" >&2
  exit 1
fi

whoami=$(snow sql -c "$connection" -q "SELECT CURRENT_USER() || ' / ' || CURRENT_ROLE()" 2>/dev/null)
if [[ $? -ne 0 || -z "$whoami" ]]; then
  echo "[FAIL] Snowflake connection '$connection' failed. Run new-snowflake-connection.sh first." >&2
  exit 1
fi
echo "[OK]   Connected: $whoami"
echo ""

printf '%-8s %10s %11s %10s %9s\n' "PREFIX" "DATABASES" "WAREHOUSES" "WH_STARTED" "MONITORS"
printf '%-8s %10s %11s %10s %9s\n' "------" "---------" "----------" "----------" "--------"

total_started=0
for p in "${prefixes[@]}"; do
  dbs=$(snow sql -c "$connection" -q "SHOW DATABASES LIKE '${p}%'" --format=json 2>/dev/null | grep -c '"name"' || true)
  whs=$(snow sql -c "$connection" -q "SHOW WAREHOUSES LIKE '%${p}%'" --format=json 2>/dev/null | grep -c '"name"' || true)
  whon=$(snow sql -c "$connection" -q "SHOW WAREHOUSES LIKE '%${p}%'" --format=json 2>/dev/null | grep -c '"state": *"STARTED"' || true)
  rms=$(snow sql -c "$connection" -q "SHOW RESOURCE MONITORS LIKE '%${p}%'" --format=json 2>/dev/null | grep -c '"name"' || true)
  printf '%-8s %10s %11s %10s %9s\n' "$p" "$dbs" "$whs" "$whon" "$rms"
  total_started=$((total_started + whon))
done

echo ""
if [[ $total_started -gt 0 ]]; then
  echo "[WARN] $total_started warehouse(s) STARTED across the fleet — suspend them:"
  snow sql -c "$connection" -q "SHOW WAREHOUSES LIKE '%APP%'" --format=json 2>/dev/null \
    | grep -B0 -A0 '"state": *"STARTED"' >/dev/null
  echo "       Run: ./scripts/clean-fleet-resources.sh (suspend-only default)"
else
  echo "[OK]   No warehouse running — zero idle credit burn"
fi
echo ""
echo "Tip: learners with 0 databases are likely blocked or not started."
echo ""
