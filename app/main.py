import os
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from app import models
from app.api.routes import admin, auth, markets, results, users
from app.core.security import hash_password
from app.db import Base, SessionLocal, engine


@asynccontextmanager
async def lifespan(_: FastAPI):
    if len(os.getenv("JWT_SECRET", "")) < 32:
        raise RuntimeError("Set JWT_SECRET to a random value of at least 32 characters")
    admin_email = os.getenv("ADMIN_EMAIL", "").strip().lower()
    admin_password = os.getenv("ADMIN_PASSWORD", "")
    if bool(admin_email) != bool(admin_password):
        raise RuntimeError("Set both ADMIN_EMAIL and ADMIN_PASSWORD to bootstrap an admin")
    if admin_password and len(admin_password) < 12:
        raise RuntimeError("ADMIN_PASSWORD must contain at least 12 characters")

    Base.metadata.create_all(bind=engine)
    if admin_email:
        with SessionLocal() as database:
            existing_admin = database.scalar(select(models.User).where(models.User.email == admin_email))
            if existing_admin is None:
                database.add(
                    models.User(
                        email=admin_email,
                        password_hash=hash_password(admin_password),
                        role="admin",
                    )
                )
                database.commit()
    yield


app = FastAPI(title="Matka Platform API", version="0.1.0", lifespan=lifespan)


def error_response(
    status_code: int,
    code: str,
    message: str,
    details=None,
    headers: dict[str, str] | None = None,
) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={"error": {"code": code, "message": message, "details": details}},
        headers=headers,
    )


@app.exception_handler(RequestValidationError)
async def validation_error_handler(_: Request, exception: RequestValidationError):
    details = [
        {"location": list(error["loc"]), "message": error["msg"], "type": error["type"]}
        for error in exception.errors()
    ]
    return error_response(422, "VALIDATION_ERROR", "Request validation failed", details)


@app.exception_handler(IntegrityError)
async def integrity_error_handler(_: Request, __: IntegrityError):
    return error_response(409, "CONFLICT", "The request conflicts with existing data")


@app.exception_handler(HTTPException)
async def http_error_handler(_: Request, exception: HTTPException):
    code = "NOT_FOUND" if exception.status_code == 404 else "HTTP_ERROR"
    message = exception.detail if isinstance(exception.detail, str) else "Request failed"
    return error_response(exception.status_code, code, message, headers=exception.headers)


@app.exception_handler(Exception)
async def unexpected_error_handler(_: Request, __: Exception):
    return error_response(500, "INTERNAL_ERROR", "An unexpected error occurred")


@app.get("/health", tags=["health"])
def health_check():
    from sqlalchemy import text
    from app.db import DATABASE_URL, engine

    database_type = (
        "postgresql"
        if DATABASE_URL.startswith("postgresql")
        else "sqlite"
        if DATABASE_URL.startswith("sqlite")
        else "other"
    )

    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))

        return {
            "status": "ok",
            "database_type": database_type,
            "database_connection": "ok",
        }
    except Exception:
        return {
            "status": "error",
            "database_type": database_type,
            "database_connection": "failed",
        }


app.include_router(auth.router, prefix="/api/auth", tags=["authentication"])
app.include_router(users.router, prefix="/api/users", tags=["users"])
app.include_router(markets.router, prefix="/api/markets", tags=["markets"])
app.include_router(results.router, prefix="/api/results", tags=["results"])
app.include_router(admin.router, prefix="/api/admin", tags=["admin"])