# AgentOps

**An autonomous AWS Bedrock agent that monitors and operates real infrastructure, with safety limits and full traceability.**

## The Problem It Solves

An on-call engineer receives alerts from multiple systems (CI/CD, containers, logs) and has to investigate and act manually. **AgentOps performs the initial diagnosis and executes safe pre-defined actions, with a human approving high-risk operations.**

## Architecture

```
MonitorJobs (cron)
    ↓ detects issue
    ↓ POST /alert
Operator (FastAPI + Bedrock)
    ↓ analyzes with Bedrock
    ↓ decides action based on risk level
    → autonomous action (low risk)
    → requests approval (high risk)
    → OpenTelemetry → CloudWatch/Jaeger
```

### Services

| Service | Stack | Port | Purpose |
|---------|-------|------|---------|
| **API** | Node.js + Express | 3000 | Application being monitored |
| **MonitorJobs** | Alpine + Cron + Curl | — | Health checks, container metrics |
| **Operator** | Python + FastAPI + Bedrock | 8000 | Autonomous agent that diagnoses and acts |

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

### Action Groups with Risk-Based Permissions

Each action passes through classification: read (free), low-risk write (autonomous), high-risk write (requires confirmation). Implemented as logic in Lambdas, not in prompts.

### Bedrock Guardrails

Block the agent from executing actions outside the allowed set. Everything goes through typed, parameterized functions — never arbitrary shell commands.

### OpenTelemetry Observability

Every decision generates a trace: what it asked, which tool it called, parameters used, execution time, success/failure. Sent to CloudWatch or Jaeger/Grafana.

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
    └── Dockerfile
```

## Demo

Scripted scenario:
1. Intentionally take down a container
2. MonitorJobs detects it on the next check
3. Operator diagnoses the cause (reviews logs)
4. Decides to restart (low risk → autonomous)
5. Records everything in the OpenTelemetry trace

## Out of Scope (MVP)

- Real auto-scaling
- Multi-cloud support
- Complex multi-turn chat
- Advanced secret management

The focus is on the quality of the cycle: **detect → decide → act → record**.

## Stack

- **Runtime**: Docker Compose
- **API**: Node.js 20 + Express
- **Monitor**: Alpine + Cron + Curl + Docker CLI
- **Agent**: Python 3.12 + FastAPI + boto3 (Bedrock)
- **Observability**: OpenTelemetry → CloudWatch/Jaeger
