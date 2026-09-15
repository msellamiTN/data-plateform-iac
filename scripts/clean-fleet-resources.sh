#!/usr/bin/env bash
# ============================================================
# clean-fleet-resources.sh — instructor cleanup
#
# Default (safe): suspends every STARTED learner warehouse (APPxx_*).
# --drop        : drops learner-prefixed objects (databases, warehouses,
#                 resource monitors, roles). Requires --force.
# --what-if     : print the SQL without executing.
#
# Usage:
#   ./scripts/clean-fleet-resources.sh                  # suspend only
#   ./scripts/clean-fleet-resources.sh --drop --what-if # preview drops
#   ./scripts/clean-fleet-resources.sh --drop --force   # full cleanup
# ============================================================

set -uo pipefail

connection="${SNOWFLAKE_CONNECTION:-training}"
drop=false
force=false
whatif=false
prefixes=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --drop) drop=true; shift ;;
    --force) force=true; shift ;;
    --what-if) whatif=true; shift ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) prefixes+=("$1"); shift ;;
  esac
done
if [[ ${#prefixes[@]} -eq 0 ]]; then
  prefixes=(APP01 APP02 APP03 APP04 APP05 APP06 APP07 APP08 APP09 APP10 APP11)
fi

echo ""
echo "============================================================"
echo " Fleet Cleanup — instructor"
echo "============================================================"
if [[ "$drop" == true ]]; then
  echo "  Mode       : DROP (destructive)"
else
  echo "  Mode       : SUSPEND warehouses only"
fi
echo "  Connection : $connection"
echo "  Prefixes   : ${prefixes[*]}"
[[ "$whatif" == true ]] && echo "  WhatIf     : no statement will be executed"
echo ""

if ! command -v snow >/dev/null 2>&1; then
  echo "[FAIL] snow CLI not found in PATH" >&2
  exit 1
fi

run_sql() {
  local sql="$1"
  if [[ "$whatif" == true ]]; then
    echo "       [WhatIf] $sql"
  else
    snow sql -c "$connection" -q "$sql" >/dev/null 2>&1
  fi
}

# 1. Suspend running learner warehouses
echo "[1/3] Scanning running warehouses..."
started=$(snow sql -c "$connection" -q "SHOW WAREHOUSES LIKE '%APP%'" --format=json 2>/dev/null \
  | python -c "import sys,json
try:
  rows=json.load(sys.stdin)
except Exception:
  rows=[]
for r in rows:
  if str(r.get('state','')).upper()=='STARTED':
    print(r['name'])" 2>/dev/null)

if [[ -z "$started" ]]; then
  echo "[OK]   No learner warehouse is running"
else
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    run_sql "ALTER WAREHOUSE \"$name\" SUSPEND"
    echo "[OK]   Suspended $name"
  done <<< "$started"
fi

if [[ "$drop" != true ]]; then
  echo ""
  echo "Done (suspend-only). Use --drop --what-if to preview, then --drop --force."
  exit 0
fi

# 2. Guard
if [[ "$force" != true && "$whatif" != true ]]; then
  echo ""
  echo "[FAIL] --drop is destructive. Preview with --drop --what-if, then re-run with --drop --force." >&2
  exit 1
fi

# 3. Drop learner-prefixed objects
echo ""
echo "[2/3] Collecting learner-prefixed objects..."

drop_kind() {
  local show_sql="$1" kind="$2"
  snow sql -c "$connection" -q "$show_sql" --format=json 2>/dev/null \
    | python -c "import sys,json
try:
  rows=json.load(sys.stdin)
except Exception:
  rows=[]
for r in rows: print(r['name'])" 2>/dev/null \
    | while IFS= read -r name; do
        match=false
        for p in "${prefixes[@]}"; do
          case "$name" in "$p"*|*"$p"*|DB_"$p"*|ROLE_"$p"*) match=true ;; esac
        done
        if [[ "$match" == true ]]; then
          run_sql "DROP $kind IF EXISTS \"$name\""
          echo "[OK]   Dropped $kind $name"
        fi
      done
}

drop_kind "SHOW DATABASES LIKE 'APP%'" "DATABASE"
drop_kind "SHOW WAREHOUSES LIKE '%APP%'" "WAREHOUSE"
drop_kind "SHOW RESOURCE MONITORS LIKE '%APP%'" "RESOURCE MONITOR"
drop_kind "SHOW ROLES LIKE 'ROLE_APP%'" "ROLE"

echo ""
echo "============================================================"
echo " Fleet cleanup complete"
echo "============================================================"
echo ""
