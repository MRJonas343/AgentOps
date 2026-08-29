# AgentOps — AGENTS.md

## Project Overview

AgentOps is an autonomous AWS Bedrock agent that monitors Docker container infrastructure and executes corrective actions autonomously when risk is low, requesting human approval when risk is high. The goal is to demonstrate a production-grade "agentic ops" pattern: detect → diagnose → decide → act → full trace (observability).

## Architecture

### Current State (MVP)

Three Docker containers orchestrated via docker-compose:

1. **API** (`./API/`) — Node.js Express app with `/health` and `/` endpoints. Simulates the monitored application.
2. **MonitorJobs** (`./MonitorJobs/`) — Alpine container running cron jobs that perform health checks, container status monitoring (CPU/memory/logs), and alert the Operator when issues are detected.
3. **Operator** (`./Operator/`) — Python FastAPI service that receives alerts and will integrate with AWS Bedrock for autonomous diagnosis and action.

### Target Architecture

```
monitor (alert) → agent (FastAPI) → Bedrock Agent (with Guardrails)
                                            ↓
                                  Action Groups (Return Control)
                                   ↓          ↓           ↓
                            Docker API   GitHub API   Health checks
                                            ↓
                              OpenTelemetry → Jaeger/CloudWatch
```

**Key Architecture Decision:** Action Groups use Bedrock's **Return Control** mode, not Lambda. The `agent` container (FastAPI) receives Bedrock's request to call function X with parameters, executes it locally, and returns the result in a second `invoke_agent` call. This avoids deploying Lambda for a 100% local Docker project.

## Data Flow

```
MonitorJobs (cron every 1-5 min)
    ↓ detects issue
    ↓ POST /alert to Operator
Operator (FastAPI)
    ↓ receives alert
    ↓ invokes Bedrock Agent (future)
    ↓ Bedrock returns action request (Return Control)
    ↓ Operator executes action locally
    ↓ returns result to Bedrock
    ↓ Bedrock decides next step
    → OpenTelemetry trace recorded
```

## Risk Model

Each function/tool the agent can invoke is classified in the agent's code (not in Bedrock's schema):

| Level | Example | Behavior |
|-------|---------|----------|
| **Read** | `get_container_metrics`, `get_health_status` | Always executes, no restriction |
| **Low risk (autonomous)** | `restart_container` | Executes directly, recorded in trace |
| **High risk (requires approval)** | `stop_container`, `rerun_workflow` in prod | Not executed: saved as "pending approval", notified, executes only after manual approval |

## Key Files

### API Service
- `API/src/index.js` — Express server with `/health` and `/` routes
- `API/Dockerfile` — Node 20 Alpine, production deps only

### MonitorJobs Service
- `MonitorJobs/jobs/check-api.sh` — Health check against API `/health` endpoint
- `MonitorJobs/jobs/check-container.sh` — Docker container status, CPU/memory, recent logs
- `MonitorJobs/notify.sh` — Alert dispatcher (calls Operator + optional webhook)
- `MonitorJobs/crontab` — Schedule: check-api every 1 min, check-container every 5 min
- `MonitorJobs/Dockerfile` — Alpine + curl + bash + docker-cli

### Operator Service
- `Operator/main.py` — FastAPI app with `/health` and `/alert` endpoints
- `Operator/bedrock_agent.py` — Bedrock integration (currently mock, prints received alerts)
- `Operator/schemas.py` — Pydantic models for alert requests/responses
- `Operator/actions.py` — Action execution logic (future)
- `Operator/Dockerfile` — Python 3.12 slim + FastAPI + uvicorn

### Infrastructure
- `docker-compose.yml` — Orchestrates all three services
- `.env` — Environment variables (WEBHOOK_URL, AWS credentials when ready)
- `.gitignore` — Excludes .env, node_modules, .atl

## Environment Variables

| Variable | Service | Description |
|----------|---------|-------------|
| `PORT` | API | Server port (default: 3000) |
| `API_URL` | MonitorJobs | URL to reach the API service |
| `API_CONTAINER` | MonitorJobs | Docker container name to inspect |
| `OPERATOR_URL` | MonitorJobs | URL to reach the Operator service |
| `WEBHOOK_URL` | MonitorJobs | Optional webhook for alerts (Slack/Discord) |
| `AWS_ACCESS_KEY_ID` | Operator | AWS credentials (future) |
| `AWS_SECRET_ACCESS_KEY` | Operator | AWS credentials (future) |
| `AWS_REGION` | Operator | AWS region for Bedrock (future) |

## Conventions

- **Language**: All code, comments, commit messages, documentation, and technical artifacts MUST be written in English. This is a hard rule — no exceptions for any file in the repository.
- Shell scripts use `#!/bin/bash` with `set -e` not required (cron jobs should be resilient)
- Python follows FastAPI patterns with Pydantic schemas
- Docker images use specific Alpine/Node/Python versions (no `latest`)
- All services expose `/health` for self-monitoring
- Alerts flow from MonitorJobs → Operator via HTTP POST with JSON body
- Risk classification is done in Python code, not in Bedrock schemas

## Development

```bash
# Start all services
docker compose up -d

# Rebuild a specific service
docker compose up -d --build operator

# View logs
docker compose logs -f monitor
docker compose logs -f operator

# Test Operator alert endpoint
curl -X POST http://localhost:8000/alert \
  -H "Content-Type: application/json" \
  -d '{"service":"api","status":"down","detail":"HTTP 503"}'
```

## Next Steps

See `MILESTONES.md` for the full implementation roadmap.
