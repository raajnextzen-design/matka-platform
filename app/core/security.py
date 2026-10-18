import os
from datetime import datetime, timedelta, timezone

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError, VerifyMismatchError

password_hasher = PasswordHasher()
ALGORITHM = "HS256"


def hash_password(password: str) -> str:
    return password_hasher.hash(password)


def verify_password(password: str, hashed_password: str) -> bool:
    try:
        return password_hasher.verify(hashed_password, password)
    except (InvalidHashError, VerificationError, VerifyMismatchError):
        return False


def create_access_token(user_id: int) -> str:
    secret = os.getenv("JWT_SECRET", "")
    if len(secret) < 32:
        raise RuntimeError("JWT_SECRET must contain at least 32 characters")
    expires_at = datetime.now(timezone.utc) + timedelta(
        minutes=int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))
    )
    return jwt.encode({"sub": str(user_id), "exp": expires_at}, secret, algorithm=ALGORITHM)


def decode_access_token(token: str) -> int | None:
    secret = os.getenv("JWT_SECRET", "")
    if len(secret) < 32:
        return None
    try:
        subject = jwt.decode(token, secret, algorithms=[ALGORITHM]).get("sub")
        return int(subject)
    except (jwt.InvalidTokenError, TypeError, ValueError):
        return None