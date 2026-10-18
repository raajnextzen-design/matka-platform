from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.db import get_db
from app.models import Favorite, Market, User
from app.schemas import MarketOut, UserOut

router = APIRouter()


@router.get("/me", response_model=UserOut)
def get_profile(user: User = Depends(get_current_user)):
    return user


@router.get("/me/favourites", response_model=list[MarketOut])
def list_favourites(
    user: User = Depends(get_current_user), database: Session = Depends(get_db)
):
    statement = (
        select(Market)
        .join(Favorite, Favorite.market_id == Market.id)
        .where(Favorite.user_id == user.id)
        .order_by(Market.name)
    )
    return database.scalars(statement).all()


@router.put("/me/favourites/{market_id}", response_model=MarketOut)
def add_favourite(
    market_id: int,
    user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
):
    market = database.get(Market, market_id)
    if market is None or not market.is_active:
        raise HTTPException(status_code=404, detail="Market not found")
    favourite = database.get(Favorite, (user.id, market.id))
    if favourite is None:
        database.add(Favorite(user_id=user.id, market_id=market.id))
        database.commit()
    return market


@router.delete("/me/favourites/{market_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_favourite(
    market_id: int,
    user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
):
    favourite = database.get(Favorite, (user.id, market_id))
    if favourite is None:
        raise HTTPException(status_code=404, detail="Favourite not found")
    database.delete(favourite)
    database.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)