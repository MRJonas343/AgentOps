def process_alert(service: str, status: str, detail: str) -> str:
    # TODO: integrar Bedrock
    message = f"[MOCK] Recibido alerta de '{service}': {status} - {detail}"
    print(message)
    return message
