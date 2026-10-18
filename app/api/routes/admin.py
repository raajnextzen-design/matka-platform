from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.dependencies import require_admin
from app.db import get_db
from app.models import AuditLog, Market, MarketSchedule, PublishedResult, User
from app.schemas import (
    AuditLogOut,
    MarketCreate,
    MarketOut,
    MarketUpdate,
    ResultCreate,
    ResultOut,
    ResultUpdate,
    ScheduleCreate,
    ScheduleOut,
    ScheduleUpdate,
)

router = APIRouter()


def record_audit(
    database: Session,
    actor: User,
    action: str,
    resource_type: str,
    resource_id: int | None,
    details: dict | None = None,
):
    database.add(
        AuditLog(
            actor_user_id=actor.id,
            action=action,
            resource_type=resource_type,
            resource_id=str(resource_id) if resource_id is not None else None,
            details=details,
        )
    )


@router.get("/audit-logs", response_model=list[AuditLogOut])
def list_audit_logs(
    _: User = Depends(require_admin),
    limit: int = Query(default=50, ge=1, le=100),
    database: Session = Depends(get_db),
):
    return database.scalars(
        select(AuditLog).order_by(AuditLog.created_at.desc(), AuditLog.id.desc()).limit(limit)
    ).all()


@router.get("/markets", response_model=list[MarketOut])
def admin_list_markets(
    _: User = Depends(require_admin), database: Session = Depends(get_db)
):
    return database.scalars(select(Market).order_by(Market.name)).all()


@router.post("/markets", response_model=MarketOut, status_code=status.HTTP_201_CREATED)
def create_market(
    payload: MarketCreate,
    actor: User = Depends(require_admin),
    database: Session = Depends(get_db),
):
    market = Market(**payload.model_dump())
    database.add(market)
    database.flush()
    record_audit(database, actor, "market.created", "market", market.id, payload.model_dump())
    database.commit()
    database.refresh(market)
    return market


@router.patch("/markets/{market_id}", response_model=MarketOut)
def update_market(
    market_id: int,
    payload: MarketUpdate,
    actor: User = Depends(require_admin),
    database: Session = Depends(get_db),
):
    market = database.get(Market, market_id)
    if market is None:
        raise HTTPException(status_code=404, detail="Market not found")
    updates = payload.model_dump(exclude_unset=True)
    if not updates:
        raise HTTPException(status_code=422, detail="At least one field is required")
    for field, value in updates.items():
        setattr(market, field, value)
    record_audit(database, actor, "market.updated", "market", market.id, updates)
    database.commit()
    database.refresh(market)
    return market


@router.delete("/markets/{market_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_market(
    market_id: int,
    actor: User = Depends(require_admin),
    database: Session = Depends(get_db),
):
    market = database.get(Market, market_id)
    if market is None:
        raise HTTPException(status_code=404, detail="Market not found")
    record_audit(database, actor, "market.deleted", "market", market.id)
    database.delete(market)
    database.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/markets/{market_id}/schedules", response_model=list[ScheduleOut])
def admin_list_schedules(
    market_id: int,
    _: User = Depends(require_admin),
    database: Session = Depends(get_db),
):
    if database.get(Market, market_id) is None:
        raise HTTPException(status_code=404, detail="Market not found")
    return database.scalars(
        select(MarketSchedule)
        .where(MarketSchedule.market_id == market_id)
        .order_by(MarketSchedule.weekday)
    ).all()


@router.post(
    "/markets/{market_id}/schedules",
    response_model=ScheduleOut,
    status_code=status.HTTP_201_CREATED,
)
def create_schedule(
    market_id: int,
    payload: ScheduleCreate,
    actor: User = Depends(require_admin),
    database: Session = Depends(get_db),
):
    if database.get(Market, market_id) is None:
        raise HTTPException(status_code=404, detail="Market not found")
    schedule = MarketSchedule(market_id=market_id, **payload.model_dump())
    database.add(schedule)
    database.flush()
    record_audit(
        database,
        actor,
        "schedule.created",
        "schedule",
        schedule.id,
        payload.model_dump(mode="json"),
    )
    database.commit()
    database.refresh(schedule)
    return schedule


@router.delete("/schedules/{schedule_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_schedule(
    schedule_id: int,
    actor: User = Depends(require_admin),
    database: Session = Depends(get_db),
):
    schedule = database.get(MarketSchedule, schedule_id)
    if schedule is None:
        raise HTTPException(status_code=404, detail="Schedule not found")
    record_audit(database, actor, "schedule.deleted", "schedule", schedule.id)
    database.delete(schedule)
    database.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.patch("/schedules/{schedule_id}", response_model=ScheduleOut)
def update_schedule(
    schedule_id: int,
    payload: ScheduleUpdate,
    actor: User = Depends(require_admin),
    database: Session = Depends(get_db),
):
    schedule = database.get(MarketSchedule, schedule_id)
    if schedule is None:
        raise HTTPException(status_code=404, detail="Schedule not found")
    updates = payload.model_dump(exclude_unset=True)
    if not updates:
        raise HTTPException(status_code=422, detail="At least one field is required")
    opens_at = updates.get("opens_at", schedule.opens_at)
    closes_at = updates.get("closes_at", schedule.closes_at)
    if closes_at <= opens_at:
        raise HTTPException(status_code=422, detail="closes_at must be later than opens_at")
    for field, value in updates.items():
        setattr(schedule, field, value)
    record_audit(
        database,
        actor,
        "schedule.updated",
        "schedule",
        schedule.id,
        payload.model_dump(exclude_unset=True, mode="json"),
    )
    database.commit()
    database.refresh(schedule)
    return schedule


@router.get("/results", response_model=list[ResultOut])
def admin_list_results(
    _: User = Depends(require_admin), database: Session = Depends(get_db)
):
    return database.scalars(
        select(PublishedResult).order_by(PublishedResult.result_date.desc())
    ).all()


@router.post("/results", response_model=ResultOut, status_code=status.HTTP_201_CREATED)
def publish_result(
    payload: ResultCreate,
    actor: User = Depends(require_admin),
    database: Session = Depends(get_db),
):
    if database.get(Market, payload.market_id) is None:
        raise HTTPException(status_code=404, detail="Market not found")
    result = PublishedResult(**payload.model_dump())
    database.add(result)
    database.flush()
    record_audit(database, actor, "result.published", "result", result.id, payload.model_dump(mode="json"))
    database.commit()
    database.refresh(result)
    return result


@router.patch("/results/{result_id}", response_model=ResultOut)
def update_result(
    result_id: int,
    payload: ResultUpdate,
    actor: User = Depends(require_admin),
    database: Session = Depends(get_db),
):
    result = database.get(PublishedResult, result_id)
    if result is None:
        raise HTTPException(status_code=404, detail="Result not found")
    updates = payload.model_dump(exclude_unset=True)
    if not updates:
        raise HTTPException(status_code=422, detail="At least one field is required")
    for field, value in updates.items():
        setattr(result, field, value)
    record_audit(
        database,
        actor,
        "result.updated",
        "result",
        result.id,
        payload.model_dump(exclude_unset=True, mode="json"),
    )
    database.commit()
    database.refresh(result)
    return result


@router.delete("/results/{result_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_result(
    result_id: int,
    actor: User = Depends(require_admin),
    database: Session = Depends(get_db),
):
    result = database.get(PublishedResult, result_id)
    if result is None:
        raise HTTPException(status_code=404, detail="Result not found")
    record_audit(database, actor, "result.deleted", "result", result.id)
    database.delete(result)
    database.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)