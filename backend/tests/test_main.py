"""
Basic tests for the main application.
"""
import pytest
from fastapi.testclient import TestClient


def test_health_endpoint(test_client: TestClient):
    """
    Test the health check endpoint.
    """
    response = test_client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert "status" in data or "message" in data


def test_root_endpoint(test_client: TestClient):
    """
    Test the root endpoint.
    """
    response = test_client.get("/")
    # Should return 200 or 404 depending on implementation
    assert response.status_code in [200, 404, 307]


def test_api_docs(test_client: TestClient):
    """
    Test that API docs are accessible.
    """
    response = test_client.get("/docs")
    assert response.status_code == 200
