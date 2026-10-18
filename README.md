# Matka Platform Backend

A local-first FastAPI backend foundation using SQLite and SQLAlchemy. It provides user registration/login, public market schedules and published results, user profiles/favourites, and environment-configured admin management. All initial data is synthetic. Wagering, deposits, and cash payouts are not implemented.

The React/TypeScript administration dashboard is maintained separately in [`admin/`](admin/README.md).

The Flutter Android client and hosted APK build instructions are in [`mobile/`](mobile/README.md).

## Requirements

- Python 3.11 or newer (tested with Python 3.14)
- `pip` and `venv`
- No PostgreSQL server, paid API, or external service is needed for local development

## Setup

From the repository root:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

Set a unique local JWT signing key and an initial admin account. These values stay in the shell environment and must not be committed:

```bash
export JWT_SECRET="$(python -c 'import secrets; print(secrets.token_urlsafe(48))')"
export ADMIN_EMAIL="admin@example.com"
export ADMIN_PASSWORD="change-this-local-password"
```

The SQLite database defaults to `./matka.db`. To choose another SQLite path, set `DATABASE_URL`, for example `export DATABASE_URL="sqlite:///./data/matka.db"` (create the `data` directory first). The server creates the schema at startup and creates the initial administrator only when both admin variables are set. There are no default admin credentials.

Start the API:

```bash
uvicorn app.main:app --reload
```

Open `http://127.0.0.1:8000/docs` for interactive API documentation and `http://127.0.0.1:8000/health` for the health check.

## API overview

- `POST /api/auth/register` registers a regular user; clients cannot assign themselves admin access.
- `POST /api/auth/login` returns a bearer access token. Send it as `Authorization: Bearer <token>`.
- `GET /api/users/me` returns the signed-in profile.
- `GET /api/markets`, `GET /api/markets/{market_id}`, and `GET /api/markets/{market_id}/schedules` list active markets and schedules.
- `GET /api/results` lists published results; `GET /api/results/history` returns historical published results; `GET /api/results/{result_id}` fetches one published result.
- `GET /api/users/me/favourites`, `PUT /api/users/me/favourites/{market_id}`, and `DELETE /api/users/me/favourites/{market_id}` manage the user's favourite markets.
- `/api/admin/*` market, schedule, and result management routes require a token for the bootstrapped admin. `GET /api/admin/audit-logs` lists administrator mutation events.

Errors use the shape `{"error":{"code":"...","message":"...","details":...}}`. Request validation returns HTTP 422; duplicate or conflicting data returns HTTP 409. Dates use ISO `YYYY-MM-DD`; times use 24-hour time strings.

## Tests

```bash
source .venv/bin/activate
pytest -q
```

Tests use an isolated in-memory SQLite database and synthetic users, markets, schedules, and results. They do not need admin environment variables or network services.

## Security and operational limitations

- Set a long, random `JWT_SECRET` and strong admin password outside source control. Rotate/revoke tokens by rotating the signing key; token revocation and refresh tokens are not implemented.
- Passwords are hashed with Argon2id through `argon2-cffi`. Authentication currently has no rate limiting, email verification, password reset, or account lockout.
- Schema creation uses SQLAlchemy `create_all`; use a migration tool such as Alembic before evolving a production database. SQLite is for the initial single-instance development MVP; PostgreSQL can be configured through `DATABASE_URL` after adding its driver.
- Add HTTPS, restrictive CORS, structured operational logging, backups, monitoring, and reviewed deployment configuration before exposing this API publicly.
- The admin account is bootstrapped from environment variables at startup; credentials are used only to create the first account and are not updated on subsequent starts.
- Result values and schedules are informational only. No real-money betting, deposits, or payouts exist in this project.