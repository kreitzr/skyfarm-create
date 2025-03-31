import requests

def test_missing_token():
    response = requests.post("http://localhost:8000/run", json={"input": {"workflow": {}}})
    assert response.status_code == 401
    assert "Missing or invalid Authorization header" in response.text

def test_invalid_token():
    headers = {"Authorization": "Bearer invalid.token.here"}
    response = requests.post("http://localhost:8000/run", json={"input": {"workflow": {}}}, headers=headers)
    assert response.status_code == 403
