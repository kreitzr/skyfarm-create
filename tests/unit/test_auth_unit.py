import pytest
from httpx import AsyncClient
from unittest.mock import patch
from apps.backend.local_dev_server import app

@pytest.mark.asyncio
@patch("apps.backend.local_dev_server.auth.verify_id_token")
async def test_valid_token(mock_verify):
    mock_verify.return_value = {"email": "test@example.com"}

    headers = {"Authorization": "Bearer fake-token"}
    payload = {
        "input": {
            "workflow": {
                "prompt": []
            }
        }
    }

    async with AsyncClient(app=app, base_url="http://test") as ac:
        response = await ac.post("/run", json=payload, headers=headers)

    assert response.status_code != 401
    assert response.status_code != 403
    assert "user" in response.json()
