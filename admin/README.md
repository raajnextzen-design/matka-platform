# Admin Dashboard

React, TypeScript and Vite administration UI for the Matka Platform FastAPI backend. This is a separate application from the Python service and calls only routes already implemented by the backend. It contains no wagering, deposit or payout workflows.

## Requirements

- Node.js 20.19+ or 22.12+ (tested with Node 24)
- npm 10+
- The FastAPI backend running at `http://127.0.0.1:8000`

## Start the backend

From the repository root, in one terminal:

```bash
source .venv/bin/activate
export JWT_SECRET="$(python -c 'import secrets; print(secrets.token_urlsafe(48))')"
export ADMIN_EMAIL="admin@example.com"
export ADMIN_PASSWORD="change-this-local-password"
uvicorn app.main:app --reload
```

Use a password of at least 12 characters. These are shell environment variables, not frontend credentials; choose your own password and do not commit it. If the backend was already initialized with another admin, use that account. The backend only bootstraps the first admin and does not rotate its password on restart.

## Install and run the dashboard

In a second terminal:

```bash
cd admin
npm ci
cp .env.example .env.local
npm run dev -- --host 0.0.0.0
```

Open `http://localhost:5173`. The Vite development server proxies `/api` and `/health` to `VITE_API_PROXY_TARGET`, which defaults to `http://127.0.0.1:8000`. Set that value in `admin/.env.local` if FastAPI is listening elsewhere. The `.env.local` file is ignored by Git.

Sign in with the bootstrapped administrator account. Login uses `POST /api/auth/login`; the dashboard then checks `GET /api/auth/session` and requires the returned `role` to be `admin`.

## Build and type-check

```bash
cd admin
npm run typecheck
npm run build
```

The production output is written to `admin/dist`. To preview it locally, run `npm run preview` from `admin/`.

## Authentication and production deployment

The prototype stores only the bearer token in tab-scoped `sessionStorage`; it never stores the password. It reads the JWT expiry claim, signs out at expiry, and clears the session when a protected API request returns 401. Browser JavaScript can access session storage, so an XSS vulnerability could expose the token. A production deployment should use HTTPS, a strict Content Security Policy, and consider a backend-supported Secure, HttpOnly, SameSite cookie session.

The backend currently has no CORS configuration. The local Vite proxy avoids cross-origin calls during development. For production, serve the dashboard and API through the same origin/reverse proxy, or configure and review a restrictive CORS allowlist in the backend before setting `VITE_API_BASE_URL` to a separate API origin. Never put secrets in a `VITE_*` variable; those values are compiled into browser code.

## Backend contract used

- `POST /api/auth/login` and `GET /api/auth/session`
- `GET/POST /api/admin/markets`, `PATCH /api/admin/markets/{market_id}`
- `GET/POST /api/admin/markets/{market_id}/schedules`, `PATCH/DELETE /api/admin/schedules/{schedule_id}`
- `GET/POST /api/admin/results`, `PATCH/DELETE /api/admin/results/{result_id}`
- `GET /api/admin/audit-logs?limit=100`
- `GET /health`

The UI uses the backend's current result and schedule fields (`result_date`, `value`, `weekday`, `opens_at`, `closes_at`, and `is_active`). The admin API already exposes all required dashboard operations; no endpoints were invented or added for this frontend.