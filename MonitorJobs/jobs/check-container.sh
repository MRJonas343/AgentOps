#!/bin/bash

CONTAINER="${API_CONTAINER:-agentoperator-api-1}"
LOG_LINES="${LOG_LINES:-20}"

echo "========== Container Status: $CONTAINER =========="

# Status (up/down)
STATUS=$(docker inspect -f '{{.State.Status}}' "$CONTAINER" 2>/dev/null)
RUNNING=$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)
UPTIME=$(docker inspect -f '{{.State.StartedAt}}' "$CONTAINER" 2>/dev/null)

echo "[STATUS] $STATUS (running=$RUNNING, since=$UPTIME)"

# CPU / Memory
STATS=$(docker stats --no-stream --format "CPU={{.CPUPerc}} MEM={{.MemUsage}} ({{.MemPerc}})" "$CONTAINER" 2>/dev/null)
echo "[STATS] $STATS"

# Recent logs
echo "[LOGS] Last $LOG_LINES lines:"
docker logs --tail "$LOG_LINES" "$CONTAINER" 2>&1

echo "=================================================="
