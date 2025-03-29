# SkyFarm Create

**SkyFarm Create** is a full-stack, serverless-ready image generation platform that connects a Firebase-authenticated frontend to a ComfyUI backend workflow engine. Built for creative flexibility and cloud scalability, it enables users to generate AI art through customizable workflows.

---

## 🎯 Purpose

SkyFarm Create is designed to:

- Accept user input via a secure, authenticated web interface
- Submit AI workflow prompts to a locally or remotely hosted [ComfyUI](https://github.com/comfyanonymous/ComfyUI) engine
- Return generated images or errors to the frontend
- Support local development and serverless GPU execution (e.g. RunPod)
- Enable future scaling for multi-user, cloud-native deployment

---

## 🧱 Project Structure

```
skyfarm-create/
├── apps/
│   ├── backend/            # FastAPI server & RunPod handler
│   ├── docker/             # Dockerfile, startup script
│   └── frontend/           # Static frontend (served via S3 or locally)
├── workspace/              # Mounted volume for ComfyUI input/output/models
├── .env                    # Local environment variables (not committed)
├── .gitignore
├── Dockerfile              # Docker build config (referenced from apps/docker)
└── README.md
```

---

## ⚙️ Local Development

### 🔧 Prerequisites

- Docker (with NVIDIA GPU support)
- Python 3.10+ (optional for local dev outside container)
- Firebase Admin SDK key (not committed)
- GitHub CLI (`gh`) for repo management (optional)

### 🐳 Build Docker Image

From project root:

```bash
docker build -t skyfarm-create:local --no-cache -f apps/docker/Dockerfile .
```

### ▶️ Run With GPU & Persistent Volume

```bash
docker run --rm --gpus all -p 8000:8000 -p 8188:8188 --env-file .env -v comfyui_persistent:/workspace skyfarm-create:local
```

- Backend API: `http://localhost:8000`
- ComfyUI UI/API: `http://localhost:8188`

---

## 🔐 Authentication

All `/run` requests require a valid Firebase ID token in the `Authorization` header:

```http
Authorization: Bearer <token>
```

Backend validates token using the Firebase Admin SDK before submitting the workflow to ComfyUI.

---

## 📤 Submitting Workflows

POST to `/run`:

```json
{
  "input": {
    "workflow": {
      "prompt": [ /* your ComfyUI workflow JSON */ ]
    }
  }
}
```

Response includes:
- `user`: Authenticated user email
- `prompt_id`: ComfyUI prompt ID
- `result`: Full workflow output or error

---

## ☁️ Cloud/Serverless Ready

The backend includes a `rp_handler.py` that supports RunPod serverless GPU execution. It uses the same logic as local development but adapts to event-based triggers.

---

## 📌 TODO / Roadmap

- 🔄 Frontend integration with live preview
- 🔒 Secure Firebase secrets via mounted volumes or GitHub Actions
- ☁️ Terraform-based cloud deployment (S3, CloudFront, Route53)
- 🧪 Add test suite for backend validation
- 🧰 Frontend UI for workflow creation & history

---

## 📝 License

TBD — currently private and not open-source.

---

## 🙋‍♂️ Author

Created by [@kreitzr](https://github.com/kreitzr) — built for artists, creators, and cloud-native nerds.