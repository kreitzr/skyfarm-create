# === Makefile for SkyFarm Create ===

# Run all tests
test:
	pytest tests

# Run unit tests only
test-unit:
	pytest tests/unit

# Run integration tests (requires container running on localhost)
test-integration:
	pytest tests/integration

# Build the Docker image (clean, no cache)
build:
	docker build --no-cache -t skyfarm-create:local -f apps/docker/Dockerfile .

# Run the container with GPU, volume, and env file
run:
	docker run --rm --gpus all -p 8000:8000 -p 8188:8188 --env-file .env -v comfyui_persistent:/workspace skyfarm-create:local

# Clean Docker image (optional)
clean:
	docker rmi skyfarm-create:local || true

# Lint with Ruff
lint:
	ruff check apps/ tests/

# Auto-format with Black
format:
	black apps/ tests/
