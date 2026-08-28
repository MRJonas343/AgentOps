from fastapi import FastAPI
from schemas import AlertRequest, AlertResponse
from bedrock_agent import process_alert

app = FastAPI(title="Operator Agent")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/alert", response_model=AlertResponse)
def receive_alert(req: AlertRequest):
    result = process_alert(req.service, req.status, req.detail)
    return AlertResponse(received=True, message=result)
