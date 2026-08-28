#!/bin/bash

API_URL="${API_URL:-http://host.docker.internal:3000}"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$API_URL/health" 2>/dev/null)

if [ "$RESPONSE" = "200" ]; then
  echo "[OK] $(date -Iseconds) API is healthy (HTTP $RESPONSE)"
else
  echo "[FAIL] $(date -Iseconds) API unhealthy (HTTP $RESPONSE)"
  /app/notify.sh "api" "down" "HTTP $RESPONSE"
fi
