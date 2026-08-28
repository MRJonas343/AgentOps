#!/bin/bash

WEBHOOK_URL="${WEBHOOK_URL:-}"
OPERATOR_URL="${OPERATOR_URL:-}"
SERVICE="$1"
STATUS="${2:-down}"
DETAIL="$3"

echo "[ALERT] $SERVICE - $STATUS - $DETAIL"

# Notificar al Operator
if [ -n "$OPERATOR_URL" ]; then
  curl -s -X POST "$OPERATOR_URL/alert" \
    -H "Content-Type: application/json" \
    -d "{\"service\": \"$SERVICE\", \"status\": \"$STATUS\", \"detail\": \"$DETAIL\"}" \
    > /dev/null 2>&1
fi

# Webhook (Slack, Discord, etc.)
if [ -n "$WEBHOOK_URL" ]; then
  curl -s -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "{\"text\": \"⚠️ MonitorJobs alert: $SERVICE - $STATUS - $DETAIL\"}" \
    > /dev/null 2>&1
fi
