FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

# Copy version control files
COPY apps/docker/.comfy-version /app/.comfy-version
COPY apps/docker/.node-versions /app/.node-versions

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    ffmpeg \
    libgl1 \
    && apt-get clean

# Install Python dependencies from pinned ComfyUI version
RUN COMFY_HASH=$(cat /app/.comfy-version) && \
    git clone https://github.com/comfyanonymous/ComfyUI.git /tmp/comfy && \
    cd /tmp/comfy && \
    git checkout "$COMFY_HASH" && \
    pip install --upgrade pip && \
    pip install -r requirements.txt && \
    rm -rf /tmp/comfy

# Clone ComfyUI into final location
RUN COMFY_HASH=$(cat /app/.comfy-version) && \
    git clone https://github.com/comfyanonymous/ComfyUI.git /app/ComfyUI && \
    cd /app/ComfyUI && \
    git checkout "$COMFY_HASH"

# Install custom nodes directly into ComfyUI
RUN set -eux; \
    while IFS="|" read -r NODE_NAME NODE_URL NODE_VER || [ -n "$NODE_NAME" ]; do \
        # Skip comments or empty lines
        if echo "$NODE_NAME" | grep -qE '^#|^$'; then continue; fi; \
        echo "📦 Installing $NODE_NAME from $NODE_URL @ $NODE_VER"; \
        git clone "$NODE_URL" /app/ComfyUI/custom_nodes/"$NODE_NAME"; \
        cd /app/ComfyUI/custom_nodes/"$NODE_NAME"; \
        git checkout "$NODE_VER"; \
    done < /app/.node-versions

# Install Python dependencies from all custom node requirements.txt
RUN find /app/ComfyUI/custom_nodes -name "requirements.txt" | while read reqfile; do \
    echo "📦 Installing Python dependencies from $reqfile"; \
    pip install -r "$reqfile"; \
done

# Pre-fetch ComfyRegistry cache
# RUN python3 -c "import sys; sys.path.insert(0, '/app/ComfyUI/custom_nodes/ComfyUI-Manager'); import comfy_registry.registry as r; r.fetch_all(force=True)"

# Add the launch script
COPY apps/docker/start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Declare workspace volume
VOLUME ["/workspace"]

# Expose ComfyUI web interface
EXPOSE 8188

# # Copy backend code and install dependencies
# COPY apps/backend /app/backend
# COPY apps/backend/requirements.txt /app/backend/requirements.txt
# COPY apps/backend/firebase-adminsdk.json /app/backend/firebase-adminsdk.json
# RUN pip install -r /app/backend/requirements.txt

# Launch!
CMD ["/app/start.sh"]
