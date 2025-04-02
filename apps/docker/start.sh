#!/bin/bash
set -e

COMFY_DIR="/app/ComfyUI"
BACKEND_DIR="/app/backend"

# Ensure /workspace structure exists
mkdir -p /workspace/models /workspace/input /workspace/output
rm -rf "$COMFY_DIR/models" "$COMFY_DIR/input" "$COMFY_DIR/output"

ln -s /workspace/models "$COMFY_DIR/models"
ln -s /workspace/input "$COMFY_DIR/input"
ln -s /workspace/output "$COMFY_DIR/output"

# Start ComfyUI in background
cd "$COMFY_DIR"
python3 main.py --listen 0.0.0.0 --port 8188
echo "[RP] [URL] http://0.0.0.0:8188"

# # Optional wait to ensure Comfy is up
# sleep 5

# # Start FastAPI backend
# cd "$BACKEND_DIR"
# uvicorn local_dev_server:app --host 0.0.0.0 --port 8000
