from fastapi.testclient import TestClient


def test_health_endpoint(client: TestClient):
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["database"] == "connected"
    assert "last_ingestion_at" in data
    assert "last_projection_at" in data
    assert "X-Request-ID" in response.headers
