# AgentOps

**Un agente autónomo de AWS Bedrock que monitorea y opera infraestructura real, con límites de seguridad y trazabilidad completa.**

## El problema que resuelve

Un ingeniero de guardia recibe alertas de varios sistemas (CI/CD, contenedores, logs) y tiene que investigar y actuar manualmente. **AgentOps hace ese primer diagnóstico y ejecuta acciones seguras predefinidas, con un humano aprobando lo riesgoso.**

## Arquitectura

```
MonitorJobs (cron)
    ↓ detecta problema
    ↓ POST /alert
Operator (FastAPI + Bedrock)
    ↓ analiza con Bedrock
    ↓ decide acción según riesgo
    → acción autónoma (bajo riesgo)
    → solicita aprobación (alto riesgo)
    → OpenTelemetry → CloudWatch/Jaeger
```

### Servicios

| Servicio | Stack | Puerto | Función |
|----------|-------|--------|---------|
| **API** | Node.js + Express | 3000 | Aplicación monitoreada |
| **MonitorJobs** | Alpine + Cron + Curl | — | Health checks, métricas de contenedor |
| **Operator** | Python + FastAPI + Bedrock | 8000 | Agente autónomo que diagnostica y actúa |

## Alcance MVP

### Fuentes de monitoreo

- **GitHub Actions**: estado de workflows/pipelines (éxito/fallo, logs de error)
- **Contenedores Docker**: estado (up/down), CPU/memoria, logs recientes
- **Health checks de API**: latencia y errores en `/health`

### Acciones del agente

| Riesgo | Acción | Modo |
|--------|--------|------|
| Bajo | Reiniciar contenedor caído | Autónoma |
| Bajo | Re-lanzar workflow de GitHub Actions | Autónoma |
| Alto | Escalar recursos / apagar servicio | Humano-in-the-loop |

## Pilares técnicos

### Action Groups con permisos por nivel de riesgo

Cada acción pasa por clasificación: lectura (libre), escritura de bajo riesgo (autónoma), escritura de alto riesgo (requiere confirmación). Implementado como lógica en Lambdas, no en el prompt.

### Guardrails de Bedrock

Bloquean que el agente ejecute acciones fuera del set permitido. Todo pasa por funciones tipadas y parametrizadas — nunca comandos shell arbitrarios.

### Observabilidad con OpenTelemetry

Cada decisión genera una traza: qué preguntó, qué tool llamó, parámetros usados, tiempo de ejecución, éxito/fallo. Va a CloudWatch o Jaeger/Grafana.

## Quick Start

```bash
# Levantar todos los servicios
docker compose up -d

# Verificar
curl http://localhost:3000          # API
curl http://localhost:8000/health   # Operator
docker compose logs -f monitor      # Logs del monitor
```

## Estructura

```
AgentOperator/
├── docker-compose.yml
├── .env                    # Variables sensibles (no commitear)
├── API/                    # Express - health check endpoint
├── MonitorJobs/            # Cron - health checks + métricas de contenedor
└── Operator/               # FastAPI - agente Bedrock (mock por ahora)
    ├── main.py
    ├── bedrock_agent.py
    ├── schemas.py
    └── Dockerfile
```

## Demo

Escenario guionado:
1. Tumbar intencionalmente un contenedor
2. MonitorJobs lo detecta en el siguiente chequeo
3. Operator diagnostica la causa (revisa logs)
4. Decide reiniciar (bajo riesgo → autónoma)
5. Registra todo en la traza de OpenTelemetry

## Fuera de alcance (MVP)

- Auto-scaling real
- Múltiples clouds
- Chat multi-turno complejo
- Gestión de secretos avanzada

El foco es la calidad del ciclo: **detectar → decidir → actuar → registrar**.

## Stack

- **Runtime**: Docker Compose
- **API**: Node.js 20 + Express
- **Monitor**: Alpine + Cron + Curl + Docker CLI
- **Agent**: Python 3.12 + FastAPI + boto3 (Bedrock)
- **Observabilidad**: OpenTelemetry → CloudWatch/Jaeger
