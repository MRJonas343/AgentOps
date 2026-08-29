# AgentOps — Milestones & Implementation Roadmap

Each step should be an independent commit/PR, verifiable before moving to the next. Do not skip steps.

## Phase 0 — Infrastructure & Communication ✅

- [x] **0.1** Create project structure (API, MonitorJobs, Operator directories)
- [x] **0.2** API service: Express with `/health` and `/` endpoints
- [x] **0.3** MonitorJobs: Alpine + cron + curl health checks
- [x] **0.4** MonitorJobs: container status monitoring (CPU/memory/logs via Docker socket)
- [x] **0.5** Operator: FastAPI with `/alert` endpoint (mock)
- [x] **0.6** Docker Compose orchestration
- [x] **0.7** Communication: MonitorJobs → Operator via POST /alert
- [x] **0.8** README and AGENTS.md documentation
- [x] **0.9** GitHub repo created and pushed

## Phase 1 — Bedrock Agent Bootstrap (no connection yet)

- [ ] **1.1** Create/configure AWS account with Bedrock access; enable Claude model in chosen region
- [ ] **1.2** Install `boto3` in Operator container; configure AWS credentials via env vars (`.env`, never committed)
- [ ] **1.3** Create basic Bedrock Agent (console or script) with simple system prompt ("You are an operations agent that diagnoses before acting..."), no Action Groups yet
- [ ] **1.4** Write standalone test script (`test_agent.py`) that invokes the agent with a manual prompt and prints the response. Verify plumbing works before touching FastAPI

## Phase 2 — Connect Agent to Alert Flow

- [ ] **2.1** Modify Operator endpoint to forward alerts to Bedrock Agent instead of just printing
- [ ] **2.2** Implement `invoke_agent` call in `bedrock_agent.py` with alert context
- [ ] **2.3** Test end-to-end: MonitorJobs detects issue → Operator receives → Bedrock responds
- [ ] **2.4** Add basic error handling and retry logic for Bedrock API calls

## Phase 3 — Action Groups with Return Control

- [ ] **3.1** Define Action Group schema in Bedrock (get_container_metrics, get_health_status, restart_container, get_container_logs)
- [ ] **3.2** Implement Return Control handler in FastAPI: receive action request from Bedrock → execute locally → return result
- [ ] **3.3** Implement read-only actions: `get_container_metrics`, `get_health_status`, `get_container_logs`
- [ ] **3.4** Implement low-risk action: `restart_container`
- [ ] **3.5** Test Return Control flow end-to-end

## Phase 4 — Risk Classification Engine

- [ ] **4.1** Create risk classification module in Operator (risk levels: read, low, high)
- [ ] **4.2** Implement action execution gate: read → execute, low → execute + log, high → save as pending
- [ ] **4.3** Implement pending actions store (JSON file or SQLite)
- [ ] **4.4** Add approval endpoint: `POST /approve/<action_id>` to approve high-risk actions
- [ ] **4.5** Test risk classification with all action types

## Phase 5 — Observability with OpenTelemetry

- [ ] **5.1** Add OpenTelemetry SDK to Operator container
- [ ] **5.2** Add Jaeger container to docker-compose for local tracing
- [ ] **5.3** Instrument Bedrock calls: trace invocation, action requests, responses
- [ ] **5.4** Instrument action execution: trace each action with parameters and result
- [ ] **5.5** Add trace context to all log messages
- [ ] **5.6** Verify traces appear in Jaeger UI

## Phase 6 — GitHub Actions Integration

- [ ] **6.1** Add GitHub REST API client to Operator
- [ ] **6.2** Implement `get_workflow_status` action (read)
- [ ] **6.3** Implement `rerun_workflow` action (high risk — requires approval)
- [ ] **6.4** Add GitHub Actions monitoring job to MonitorJobs
- [ ] **6.5** Test GitHub Actions flow end-to-end

## Phase 7 — Production Hardening

- [ ] **7.1** Add rate limiting to Operator endpoints
- [ ] **7.2** Add authentication to approval endpoint (API key or JWT)
- [ ] **7.3** Add structured logging (JSON format)
- [ ] **7.4** Add health checks for all containers
- [ ] **7.5** Add docker-compose profiles for dev/prod
- [ ] **7.6** Write deployment documentation

## Phase 8 — Demo & Portfolio

- [ ] **8.1** Create demo script that simulates the full flow
- [ ] **8.2** Record demo video/GIF
- [ ] **8.3** Update README with demo instructions
- [ ] **8.4** Add architecture diagram (ASCII or image)

---

## Current Status

**Phase:** 0 — Infrastructure & Communication
**Progress:** 9/9 tasks completed
**Next:** Phase 1 — Bedrock Agent Bootstrap
