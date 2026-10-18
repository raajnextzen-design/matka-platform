import os

os.environ["DATABASE_URL"] = "sqlite://"
os.environ["JWT_SECRET"] = "test-only-secret-that-is-at-least-32-characters-long"
os.environ["ADMIN_EMAIL"] = "admin@example.com"
os.environ["ADMIN_PASSWORD"] = "test-admin-password-is-long-enough"

import pytest
from fastapi.testclient import TestClient

from app.db import Base, engine
from app.main import app
from app import models  # noqa: F401


@pytest.fixture
def client():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    with TestClient(app) as test_client:
        yield test_client
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def admin_headers(client):
    response = client.post(
        "/api/auth/login",
        json={"email": "admin@example.com", "password": "test-admin-password-is-long-enough"},
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}