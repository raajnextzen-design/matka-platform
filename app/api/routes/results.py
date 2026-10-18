from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import Market, PublishedResult
from app.schemas import ResultOut

router = APIRouter()


@router.get("/history", response_model=list[ResultOut])
def result_history(
    market_id: int | None = Query(default=None, gt=0),
    before: date | None = None,
    limit: int = Query(default=100, ge=1, le=100),
    database: Session = Depends(get_db),
):
    cutoff = before or date.today()
    statement = select(PublishedResult).where(PublishedResult.result_date < cutoff)
    if market_id is not None:
        statement = statement.where(PublishedResult.market_id == market_id)
    statement = statement.order_by(
        PublishedResult.result_date.desc(), PublishedResult.id.desc()
    ).limit(limit)
    return database.scalars(statement).all()


@router.get("", response_model=list[ResultOut])
def list_results(
    market_id: int | None = Query(default=None, gt=0),
    limit: int = Query(default=50, ge=1, le=100),
    database: Session = Depends(get_db),
):
    statement = select(PublishedResult).join(Market).where(Market.is_active.is_(True))
    if market_id is not None:
        statement = statement.where(PublishedResult.market_id == market_id)
    statement = statement.order_by(
        PublishedResult.result_date.desc(), PublishedResult.id.desc()
    ).limit(limit)
    return database.scalars(statement).all()


@router.get("/{result_id}", response_model=ResultOut)
def get_result(result_id: int, database: Session = Depends(get_db)):
    result = database.get(PublishedResult, result_id)
    if result is None:
        raise HTTPException(status_code=404, detail="Result not found")
    market = database.get(Market, result.market_id)
    if market is None or not market.is_active:
        raise HTTPException(status_code=404, detail="Result not found")
    return result