#!/usr/bin/env bash
# discord-notify.sh — send a message to a Discord webhook
# Usage: bash discord-notify.sh <type> <status> <message>
# Requires: DISCORD_WEBHOOK_URL env var

TYPE="${1:-maintenance}"
STATUS="${2:-INFO}"
MESSAGE="${3:-No message}"

WEBHOOK_URL="${DISCORD_WEBHOOK_URL}"
if [ -z "$WEBHOOK_URL" ]; then
    echo "[discord-notify] DISCORD_WEBHOOK_URL not set — skipping"
    exit 0
fi

# Color by status
case "$STATUS" in
    PASS|pass|OK|ok)      COLOR=3066993 ;;   # green
    FAIL|fail|ERROR|error) COLOR=15158332 ;;  # red
    WARN|warn)             COLOR=16776960 ;;  # yellow
    *)                     COLOR=3447003 ;;   # blue
esac

TITLE="[${TYPE}] ${STATUS}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

PAYLOAD=$(printf '{"embeds":[{"title":"%s","description":"%s","color":%d,"timestamp":"%s"}]}' \
    "$TITLE" "$MESSAGE" "$COLOR" "$TIMESTAMP")

curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$WEBHOOK_URL" \
    --max-time 5 \
    > /dev/null 2>&1

exit 0
