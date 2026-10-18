from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.core.security import create_access_token, hash_password, verify_password
from app.db import get_db
from app.models import User
from app.schemas import LoginRequest, TokenOut, UserCreate, UserOut

router = APIRouter()


@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def register(payload: UserCreate, database: Session = Depends(get_db)):
    email = str(payload.email).strip().lower()
    if database.scalar(select(User).where(User.email == email)):
        raise HTTPException(status_code=409, detail="An account with this email already exists")
    user = User(email=email, password_hash=hash_password(payload.password), role="user")
    database.add(user)
    database.commit()
    database.refresh(user)
    return user


@router.post("/login", response_model=TokenOut)
def login(payload: LoginRequest, database: Session = Depends(get_db)):
    email = str(payload.email).strip().lower()
    user = database.scalar(select(User).where(User.email == email))
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email or password is incorrect",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return TokenOut(access_token=create_access_token(user.id))


@router.get("/session", response_model=UserOut)
def current_session(user: User = Depends(get_current_user)):
    return user