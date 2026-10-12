from fastapi.testclient import TestClient


def test_error_shape_on_404(client: TestClient):
    response = client.get("/api/v1/non_existent_route")
    assert response.status_code == 404
    data = response.json()
    assert "error" in data
    err = data["error"]
    assert err["code"] == "NOT_FOUND"
    assert "message" in err
    assert "request_id" in err
    assert err["request_id"] != ""
    assert "X-Request-ID" in response.headers
