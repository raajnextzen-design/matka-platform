
from datetime import date


def create_user(client, email="player@example.com", password="secure-pass-123"):
    return client.post(
        "/api/auth/register",
        json={"email": email, "password": password},
    )


def create_market(client, headers, slug="morning-market"):
    return client.post(
        "/api/admin/markets",
        headers=headers,
        json={
            "name": "Morning Market",
            "slug": slug,
            "description": "Synthetic fixture",
        },
    )


def test_health_registration_login_and_profile(client):
    health = client.get("/health")

    assert health.status_code == 200

    data = health.json()
    assert data["status"] == "ok"
    assert data["database_type"] in {"sqlite", "postgresql"}
    assert data["database_connection"] == "ok"

    invalid = client.post(
        "/api/auth/register",
        json={"email": "not-an-email", "password": "short"},
    )
    assert invalid.status_code == 422
    assert invalid.json()["error"]["code"] == "VALIDATION_ERROR"

    registered = create_user(client)
    assert registered.status_code == 201
    assert registered.json()["role"] == "user"
    assert "password" not in registered.json()
    assert create_user(client).status_code == 409

    bad_login = client.post(
        "/api/auth/login",
        json={
            "email": "player@example.com",
            "password": "wrong-password",
        },
    )
    assert bad_login.status_code == 401
    assert bad_login.json()["error"]["code"] == "HTTP_ERROR"

    logged_in = client.post(
        "/api/auth/login",
        json={
            "email": "player@example.com",
            "password": "secure-pass-123",
        },
    )
    assert logged_in.status_code == 200

    headers = {
        "Authorization": f"Bearer {logged_in.json()['access_token']}"
    }

    session = client.get("/api/auth/session", headers=headers)
    assert session.status_code == 200
    assert session.json()["email"] == "player@example.com"

    assert client.get("/api/users/me", headers=headers).status_code == 200

    unauthorized = client.get("/api/users/me")
    assert unauthorized.status_code == 401
    assert unauthorized.headers["www-authenticate"] == "Bearer"


def test_public_market_schedules_and_admin_market_management(
    client, admin_headers
):
    assert client.get("/api/admin/markets").status_code == 401
    assert client.get("/api/admin/audit-logs").status_code == 401

    player = create_user(client)
    assert player.status_code == 201

    token_response = client.post(
        "/api/auth/login",
        json={
            "email": "player@example.com",
            "password": "secure-pass-123",
        },
    )
    assert token_response.status_code == 200

    token = token_response.json()["access_token"]
    player_headers = {"Authorization": f"Bearer {token}"}

    assert (
        client.get(
            "/api/admin/markets",
            headers=player_headers,
        ).status_code
        == 403
    )

    created = create_market(client, admin_headers)
    assert created.status_code == 201

    market_id = created.json()["id"]

    markets = client.get("/api/markets")
    assert markets.status_code == 200
    assert markets.json()[0]["slug"] == "morning-market"

    assert client.get(f"/api/markets/{market_id}").status_code == 200
    assert (
        client.get("/api/markets/999").json()["error"]["code"]
        == "NOT_FOUND"
    )
    assert (
        client.get(
            "/api/admin/markets",
            headers=admin_headers,
        ).status_code
        == 200
    )

    schedule = client.post(
        f"/api/admin/markets/{market_id}/schedules",
        headers=admin_headers,
        json={
            "weekday": 1,
            "opens_at": "09:00:00",
            "closes_at": "10:00:00",
        },
    )
    assert schedule.status_code == 201

    schedule_id = schedule.json()["id"]

    public_schedules = client.get(
        f"/api/markets/{market_id}/schedules"
    )
    assert public_schedules.status_code == 200
    assert public_schedules.json()[0]["weekday"] == 1

    assert (
        client.get(
            f"/api/admin/markets/{market_id}/schedules",
            headers=admin_headers,
        ).status_code
        == 200
    )

    updated_schedule = client.patch(
        f"/api/admin/schedules/{schedule_id}",
        headers=admin_headers,
        json={"opens_at": "08:00:00"},
    )
    assert updated_schedule.status_code == 200
    assert updated_schedule.json()["opens_at"] == "08:00:00"

    invalid_update = client.patch(
        f"/api/admin/schedules/{schedule_id}",
        headers=admin_headers,
        json={"opens_at": "11:00:00"},
    )
    assert invalid_update.status_code == 422

    invalid_schedule = client.post(
        f"/api/admin/markets/{market_id}/schedules",
        headers=admin_headers,
        json={
            "weekday": 7,
            "opens_at": "11:00",
            "closes_at": "10:00",
        },
    )
    assert invalid_schedule.status_code == 422

    conflict = client.post(
        f"/api/admin/markets/{market_id}/schedules",
        headers=admin_headers,
        json={
            "weekday": 1,
            "opens_at": "11:00",
            "closes_at": "12:00",
        },
    )
    assert conflict.status_code == 409

    assert (
        client.delete(
            f"/api/admin/schedules/{schedule_id}",
            headers=admin_headers,
        ).status_code
        == 204
    )

    updated = client.patch(
        f"/api/admin/markets/{market_id}",
        headers=admin_headers,
        json={"name": "Updated Market"},
    )
    assert updated.status_code == 200
    assert updated.json()["name"] == "Updated Market"

    assert (
        client.patch(
            f"/api/admin/markets/{market_id}",
            headers=admin_headers,
            json={},
        ).status_code
        == 422
    )

    assert (
        client.patch(
            f"/api/admin/markets/{market_id}",
            headers=admin_headers,
            json={"name": None},
        ).status_code
        == 422
    )

    deactivated = client.patch(
        f"/api/admin/markets/{market_id}",
        headers=admin_headers,
        json={"is_active": False},
    )
    assert deactivated.status_code == 200

    assert client.get("/api/markets").json() == []
    assert client.get(f"/api/markets/{market_id}").status_code == 404

    assert (
        client.delete(
            f"/api/admin/markets/{market_id}",
            headers=admin_headers,
        ).status_code
        == 204
    )

    assert (
        client.delete(
            "/api/admin/markets/999",
            headers=admin_headers,
        ).status_code
        == 404
    )

    audit_response = client.get(
        "/api/admin/audit-logs",
        headers=admin_headers,
    )
    assert audit_response.status_code == 200

    market_actions = {
        entry["action"] for entry in audit_response.json()
    }
    assert {
        "market.created",
        "market.updated",
        "market.deleted",
        "schedule.created",
        "schedule.updated",
        "schedule.deleted",
    } <= market_actions

    assert (
        client.get(
            "/api/admin/audit-logs",
            headers=admin_headers,
            params={"limit": 101},
        ).status_code
        == 422
    )


def test_result_publish_history_update_and_delete(
    client, admin_headers
):
    market_response = create_market(
        client,
        admin_headers,
        slug="results-market",
    )
    assert market_response.status_code == 201

    market_id = market_response.json()["id"]

    payload = {
        "market_id": market_id,
        "result_date": "2020-01-02",
        "value": "123-45-678",
    }

    created = client.post(
        "/api/admin/results",
        headers=admin_headers,
        json=payload,
    )
    assert created.status_code == 201

    result_id = created.json()["id"]

    results = client.get("/api/results")
    assert results.status_code == 200
    assert results.json()[0]["value"] == "123-45-678"

    assert client.get(f"/api/results/{result_id}").status_code == 200

    history = client.get("/api/results/history")
    assert history.status_code == 200
    assert history.json()[0]["id"] == result_id

    assert (
        client.get(
            "/api/results/history",
            params={"market_id": market_id},
        ).status_code
        == 200
    )

    assert (
        client.get(
            "/api/admin/results",
            headers=admin_headers,
        ).status_code
        == 200
    )

    duplicate = client.post(
        "/api/admin/results",
        headers=admin_headers,
        json=payload,
    )
    assert duplicate.status_code == 409

    assert (
        client.get(
            "/api/results",
            params={"limit": 101},
        ).status_code
        == 422
    )

    assert client.get("/api/results/999").status_code == 404

    changed = client.patch(
        f"/api/admin/results/{result_id}",
        headers=admin_headers,
        json={
            "result_date": date(2020, 1, 3).isoformat(),
            "value": "234-56-789",
        },
    )
    assert changed.status_code == 200
    assert changed.json()["value"] == "234-56-789"

    assert (
        client.patch(
            f"/api/admin/results/{result_id}",
            headers=admin_headers,
            json={},
        ).status_code
        == 422
    )

    assert (
        client.patch(
            f"/api/admin/results/{result_id}",
            headers=admin_headers,
            json={"value": " "},
        ).status_code
        == 422
    )

    assert (
        client.delete(
            f"/api/admin/results/{result_id}",
            headers=admin_headers,
        ).status_code
        == 204
    )

    assert (
        client.delete(
            f"/api/admin/results/{result_id}",
            headers=admin_headers,
        ).status_code
        == 404
    )

    audit_response = client.get(
        "/api/admin/audit-logs",
        headers=admin_headers,
    )
    assert audit_response.status_code == 200

    result_actions = {
        entry["action"]
        for entry in audit_response.json()
        if entry["resource_type"] == "result"
    }
    assert {
        "result.published",
        "result.updated",
        "result.deleted",
    } <= result_actions


def test_favourites_require_auth_and_are_idempotent(
    client, admin_headers
):
    market_response = create_market(
        client,
        admin_headers,
        slug="favourites-market",
    )
    assert market_response.status_code == 201

    market_id = market_response.json()["id"]

    assert client.get("/api/users/me/favourites").status_code == 401

    registered = create_user(client)
    assert registered.status_code == 201

    login_response = client.post(
        "/api/auth/login",
        json={
            "email": "player@example.com",
            "password": "secure-pass-123",
        },
    )
    assert login_response.status_code == 200

    token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    first_add = client.put(
        f"/api/users/me/favourites/{market_id}",
        headers=headers,
    )
    assert first_add.status_code == 200

    second_add = client.put(
        f"/api/users/me/favourites/{market_id}",
        headers=headers,
    )
    assert second_add.status_code == 200

    favourites = client.get(
        "/api/users/me/favourites",
        headers=headers,
    )
    assert favourites.status_code == 200
    assert len(favourites.json()) == 1

    assert (
        client.put(
            "/api/users/me/favourites/999",
            headers=headers,
        ).status_code
        == 404
    )

    assert (
        client.delete(
            f"/api/users/me/favourites/{market_id}",
            headers=headers,
        ).status_code
        == 204
    )

    assert (
        client.delete(
            f"/api/users/me/favourites/{market_id}",
            headers=headers,
        ).status_code
        == 404
    )
