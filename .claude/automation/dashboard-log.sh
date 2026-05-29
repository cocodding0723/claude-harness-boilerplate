#!/usr/bin/env bash
# dashboard-log.sh — append a log entry to the dashboard API
# Usage: bash dashboard-log.sh <type> <json_payload>
# Requires: DASHBOARD_API env var (default: http://localhost:4000)

TYPE="${1:-sentinel}"
PAYLOAD="${2:-{}}"

API_URL="${DASHBOARD_API:-http://localhost:4000}"

curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "${API_URL}/api/logs/${TYPE}" \
    --max-time 5 \
    > /dev/null 2>&1

exit 0
