from dotenv import load_dotenv
import os
from fastapi import FastAPI, Request, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Dict, Any
import httpx
import time
import firebase_admin
from firebase_admin import credentials, auth
import firebase_admin
from firebase_admin import auth, credentials

# Load Firebase Admin SDK
load_dotenv()
firebase_cred_path = os.getenv("FIREBASE_CRED_PATH", "firebase-adminsdk.json")
cred = credentials.Certificate(firebase_cred_path)
firebase_admin.initialize_app(cred)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8080"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

class WorkflowRequest(BaseModel):
    input: Dict[str, Any]

@app.post("/run")
async def run_workflow(request: WorkflowRequest, authorization: Optional[str] = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")

    token = authorization.split("Bearer ")[1]
    try:
        decoded_token = auth.verify_id_token(token)
        user_email = decoded_token.get("email")
    except Exception as e:
        raise HTTPException(status_code=403, detail=f"Authentication failed: {str(e)}")

    workflow = request.input.get("workflow")
    if not workflow:
        raise HTTPException(status_code=400, detail="Missing 'workflow' in input")

    # Submit to ComfyUI
    try:
        submit_response = httpx.post("http://localhost:8188/prompt", json={"prompt": workflow}, timeout=10)
        submit_data = submit_response.json()
        prompt_id = submit_data.get("prompt_id")
        if not prompt_id:
            raise Exception("No prompt_id returned")
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Failed to submit workflow to ComfyUI: {str(e)}")

    # Poll for results (simple wait + fetch instead of aggressive polling)
    time.sleep(2)  # Give ComfyUI time to run

    try:
        history_response = httpx.get(f"http://localhost:8188/history/{prompt_id}", timeout=10)
        history_data = history_response.json()
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Failed to fetch results from ComfyUI: {str(e)}")

    return {
        "user": user_email,
        "prompt_id": prompt_id,
        "result": history_data
    }