# AgentOps — AGENTS.md

## Project Overview

AgentOps is an autonomous AWS Bedrock agent that monitors and operates real infrastructure with safety limits and full traceability. It detects issues, diagnoses causes, and executes safe pre-defined actions — with human approval for high-risk operations.

## Architecture

Three Docker containers orchestrated via docker-compose:

1. **API** (`./API/`) — Node.js Express app with `/health` and `/` endpoints. This is the application being monitored.
2. **MonitorJobs** (`./MonitorJobs/`) — Alpine container running cron jobs that perform health checks, container status monitoring (CPU/memory/logs), and alert the Operator when issues are detected.
3. **Operator** (`./Operator/`) — Python FastAPI service that receives alerts and will integrate with AWS Bedrock for autonomous diagnosis and action.

## Data Flow

```
MonitorJobs (cron every 1-5 min)
    ↓ detects issue
    ↓ POST /alert to Operator
Operator (FastAPI)
    ↓ analyzes with Bedrock (mock for now)
    ↓ decides action based on risk level
    → autonomous action (low risk)
    → request human approval (high risk)
```

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
- `Operator/Dockerfile` — Python 3.12 slim + FastAPI + uvicorn

### Infrastructure
- `docker-compose.yml` — Orchestrates all three services
- `.env` — Environment variables (WEBHOOK_URL, AWS credentials when ready)
- `.gitignore` — Excludes .env, node_modules

## Environment Variables

| Variable | Service | Description |
|----------|---------|-------------|
| `PORT` | API | Server port (default: 3000) |
| `API_URL` | MonitorJobs | URL to reach the API service |
| `API_CONTAINER` | MonitorJobs | Docker container name to inspect |
| `OPERATOR_URL` | MonitorJobs | URL to reach the Operator service |
| `WEBHOOK_URL` | MonitorJobs | Optional webhook for alerts (Slack/Discord) |

## Conventions

- **Language**: All code, comments, commit messages, documentation, and technical artifacts MUST be written in English. This is a hard rule — no exceptions for any file in the repository.
- Shell scripts use `#!/bin/bash` with `set -e` not required (cron jobs should be resilient)
- Python follows FastAPI patterns with Pydantic schemas
- Docker images use specific Alpine/Node/Python versions (no `latest`)
- All services expose `/health` for self-monitoring
- Alerts flow from MonitorJobs → Operator via HTTP POST with JSON body

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

## Risk Classification (for future Bedrock integration)

| Risk Level | Actions | Mode |
|------------|---------|------|
| Low | Read logs, check status, health checks | Autonomous |
| Medium | Restart container, re-run workflow | Autonomous |
| High | Scale resources, stop service, modify config | Human-in-the-loop |

## Next Steps

- Integrate real AWS Bedrock in `bedrock_agent.py`
- Add OpenTelemetry tracing
- Implement action execution in `actions.py`
- Add GitHub Actions monitoring
- Human approval flow for high-risk actions
