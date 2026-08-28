from pydantic import BaseModel


class AlertRequest(BaseModel):
    service: str
    status: str
    detail: str


class AlertResponse(BaseModel):
    received: bool
    message: str
