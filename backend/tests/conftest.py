"""
Pytest configuration and fixtures for backend tests.
"""
import pytest
from typing import Generator
from fastapi.testclient import TestClient


@pytest.fixture
def test_client() -> Generator:
    """
    Create a test client for the FastAPI application.
    """
    from app.main import app

    with TestClient(app) as client:
        yield client


@pytest.fixture
def test_db():
    """
    Create a test database session.
    TODO: Implement database fixtures when needed.
    """
    pass
