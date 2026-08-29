# AgentOps

**An autonomous AWS Bedrock agent that monitors Docker container infrastructure and executes corrective actions autonomously when risk is low, requesting human approval when risk is high.**

**Pitch:** An on-call engineer receives alerts from multiple systems and has to investigate and act manually. AgentOps performs the initial diagnosis and executes safe pre-defined actions, with a human approving high-risk operations.

## The Problem It Solves

An on-call engineer receives alerts from various systems (CI/CD, containers, logs) and must investigate and act manually. AgentOps performs the first diagnosis and executes safe pre-defined actions, with human approval for high-risk operations.

## Architecture

### Current State (MVP)

```
MonitorJobs (cron)
    ↓ detects issue
    ↓ POST /alert
Operator (FastAPI)
    ↓ receives alert (mock for now)
    → will integrate with Bedrock
```

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

**Key Architecture Decision:** Action Groups use Bedrock's **Return Control** mode, not Lambda. The `agent` container (FastAPI) receives Bedrock's request to call function X with parameters, executes it locally, and returns the result to the agent in a second `invoke_agent` call. This avoids deploying Lambda for a project running 100% locally in Docker.

### Services

| Service | Stack | Port | Purpose |
|---------|-------|------|---------|
| **API** | Node.js + Express | 3000 | Application being monitored (simulated) |
| **MonitorJobs** | Alpine + Cron + Curl | — | Health checks, container metrics |
| **Operator** | Python + FastAPI + Bedrock | 8000 | Autonomous agent that diagnoses and acts |

## Risk Model (Core of the Project)

Each function/tool the agent can invoke is classified in the agent's code (not in Bedrock's schema):

| Level | Example | Behavior |
|-------|---------|----------|
| **Read** | `get_container_metrics`, `get_health_status` | Always executes, no restriction |
| **Low risk (autonomous)** | `restart_container` | Executes directly, recorded in trace |
| **High risk (requires approval)** | `stop_container`, `rerun_workflow` in prod | Not executed: saved as "pending approval", notified, executes only after manual approval |

## MVP Scope

### Monitoring Sources

- **GitHub Actions**: workflow/pipeline status (success/failure, error logs)
- **Docker Containers**: status (up/down), CPU/memory, recent logs
- **API Health Checks**: latency and errors on `/health`

### Agent Actions

| Risk | Action | Mode |
|------|--------|------|
| Low | Restart crashed container | Autonomous |
| Low | Re-run failed GitHub Actions workflow | Autonomous |
| High | Scale resources / stop service | Human-in-the-loop |

## Technical Pillars

### Action Groups with Return Control

Each action passes through risk classification: read (free), low-risk write (autonomous), high-risk write (requires confirmation). Uses Bedrock's Return Control mode — no Lambda needed.

### Bedrock Guardrails

Block the agent from executing actions outside the allowed set. Everything goes through typed, parameterized functions — never arbitrary shell commands.

### OpenTelemetry Observability

Every decision generates a trace: what it asked, which tool it called, parameters used, execution time, success/failure. Sent to Jaeger (local dev) or CloudWatch (production).

## Quick Start

```bash
# Start all services
docker compose up -d

# Verify
curl http://localhost:3000          # API
curl http://localhost:8000/health   # Operator
docker compose logs -f monitor      # Monitor logs
```

## Structure

```
AgentOperator/
├── docker-compose.yml
├── .env                    # Sensitive variables (do not commit)
├── API/                    # Express - health check endpoint
├── MonitorJobs/            # Cron - health checks + container metrics
└── Operator/               # FastAPI - Bedrock agent (mock for now)
    ├── main.py
    ├── bedrock_agent.py
    ├── schemas.py
    ├── actions.py          # Action execution logic (future)
    └── Dockerfile
```

## Stack

- **Runtime**: Docker Compose
- **API**: Node.js 20 + Express
- **Monitor**: Alpine + Cron + Curl + Docker CLI
- **Agent**: Python 3.12 + FastAPI + boto3 (Bedrock)
- **Persistence**: JSON/SQLite for pending actions (Postgres if needed later)
- **Observability**: OpenTelemetry → Jaeger (dev) / CloudWatch (AWS)

## Out of Scope (MVP)

- Real auto-scaling or multi-cloud
- Complex multi-turn chat with user (flow is: alert → diagnosis → action)
- Frontend for human approval (endpoint or CLI script is enough)
- High concurrency optimization (portfolio project, not a real 24/7 system)

The focus is on the quality of the cycle: **detect → diagnose → decide → act → record**.

## Demo

Scripted scenario:
1. Intentionally take down a container
2. MonitorJobs detects it on the next check
3. Operator diagnoses the cause (reviews logs)
4. Decides to restart (low risk → autonomous)
5. Records everything in the OpenTelemetry trace
