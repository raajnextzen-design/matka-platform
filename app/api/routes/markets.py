from fastapi import APIRouter, Depends, HTTPException, Path
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import Market, MarketSchedule
from app.schemas import MarketOut, ScheduleOut

router = APIRouter()


@router.get("", response_model=list[MarketOut])
def list_markets(database: Session = Depends(get_db)):
    return database.scalars(
        select(Market).where(Market.is_active.is_(True)).order_by(Market.name)
    ).all()


@router.get("/{market_id}", response_model=MarketOut)
def get_market(market_id: int = Path(ge=1), database: Session = Depends(get_db)):
    market = database.get(Market, market_id)
    if market is None or not market.is_active:
        raise HTTPException(status_code=404, detail="Market not found")
    return market


@router.get("/{market_id}/schedules", response_model=list[ScheduleOut])
def get_market_schedules(market_id: int = Path(ge=1), database: Session = Depends(get_db)):
    market = database.get(Market, market_id)
    if market is None or not market.is_active:
        raise HTTPException(status_code=404, detail="Market not found")
    statement = (
        select(MarketSchedule)
        .where(MarketSchedule.market_id == market_id, MarketSchedule.is_active.is_(True))
        .order_by(MarketSchedule.weekday)
    )
    return database.scalars(statement).all()