import json
import httpx
import runpod
import os
from firebase_admin import credentials, auth
from dotenv import load_dotenv

load_dotenv()
firebase_cred_path = os.getenv("FIREBASE_CRED_PATH", "firebase-adminsdk.json")
cred = credentials.Certificate(firebase_cred_path)
firebase_admin.initialize_app(cred)

def handler(event):
    method = event.get("method", "POST").upper()

    if method == "OPTIONS":
        return _cors_response(204, "")

    headers = event.get("headers", {})
    auth_header = headers.get("authorization") or headers.get("Authorization")

    if not auth_header or not auth_header.startswith("Bearer "):
        return _cors_response(401, {"error": "Missing or invalid Authorization header"})

    id_token = auth_header.split("Bearer ")[1]

    try:
        decoded_token = auth.verify_id_token(id_token)
        user_email = decoded_token.get("email")
    except Exception as e:
        return _cors_response(403, {"error": f"Authentication failed: {str(e)}"})

    workflow = event.get("input", {}).get("workflow")
    if not workflow:
        return _cors_response(400, {"error": "Missing workflow in input."})

    try:
        response = httpx.post("http://localhost:8188/prompt", json=workflow, timeout=30)
        result = response.json()
    except Exception as e:
        return _cors_response(502, {"error": f"Failed to contact ComfyUI: {str(e)}"})

    return _cors_response(200, {
        "user": user_email,
        "result": result
    })

def _cors_response(status, body):
    return {
        "statusCode": status,
        "headers": {
            "Access-Control-Allow-Origin": "http://localhost:8080",
            "Access-Control-Allow-Headers": "Content-Type, Authorization",
            "Access-Control-Allow-Methods": "POST, OPTIONS",
            "Access-Control-Allow-Credentials": "true",
            "Content-Type": "application/json"
        },
        "body": json.dumps(body) if isinstance(body, dict) else body
    }

if __name__ == "__main__":
    runpod.serverless.start({
        "handler": handler
    })