from datetime import date, datetime, time
from typing import Any

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator, model_validator


class ORMModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)


class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class UserOut(ORMModel):
    id: int
    email: EmailStr
    role: str
    created_at: datetime


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"


class MarketCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    slug: str = Field(min_length=2, max_length=80, pattern=r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
    description: str | None = Field(default=None, max_length=500)
    is_active: bool = True

    @field_validator("name")
    @classmethod
    def name_must_not_be_blank(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("must not be blank")
        return value.strip()


class MarketUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=120)
    slug: str | None = Field(default=None, min_length=2, max_length=80, pattern=r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
    description: str | None = Field(default=None, max_length=500)
    is_active: bool | None = None

    @field_validator("name", "slug", mode="before")
    @classmethod
    def reject_null_required_fields(cls, value):
        if value is None:
            raise ValueError("must not be null")
        return value


class MarketOut(ORMModel):
    id: int
    name: str
    slug: str
    description: str | None
    is_active: bool
    created_at: datetime


class ScheduleCreate(BaseModel):
    weekday: int = Field(ge=0, le=6)
    opens_at: time
    closes_at: time
    is_active: bool = True

    @model_validator(mode="after")
    def closing_time_must_follow_opening(self):
        if self.closes_at <= self.opens_at:
            raise ValueError("closes_at must be later than opens_at")
        return self


class ScheduleUpdate(BaseModel):
    weekday: int | None = Field(default=None, ge=0, le=6)
    opens_at: time | None = None
    closes_at: time | None = None
    is_active: bool | None = None

    @field_validator("weekday", "opens_at", "closes_at", "is_active", mode="before")
    @classmethod
    def reject_null_values(cls, value):
        if value is None:
            raise ValueError("must not be null")
        return value


class ScheduleOut(ORMModel):
    id: int
    market_id: int
    weekday: int
    opens_at: time
    closes_at: time
    is_active: bool


class ResultCreate(BaseModel):
    market_id: int = Field(gt=0)
    result_date: date
    value: str = Field(min_length=1, max_length=64)

    @field_validator("value")
    @classmethod
    def value_must_not_be_blank(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("must not be blank")
        return value.strip()


class ResultUpdate(BaseModel):
    result_date: date | None = None
    value: str | None = Field(default=None, min_length=1, max_length=64)

    @field_validator("result_date", "value", mode="before")
    @classmethod
    def reject_null_fields(cls, value):
        if value is None:
            raise ValueError("must not be null")
        return value

    @field_validator("value")
    @classmethod
    def value_must_not_be_blank(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("must not be blank")
        return value.strip()


class ResultOut(ORMModel):
    id: int
    market_id: int
    result_date: date
    value: str
    published_at: datetime


class AuditLogOut(ORMModel):
    id: int
    actor_user_id: int | None
    action: str
    resource_type: str
    resource_id: str | None
    details: dict[str, Any] | None
    created_at: datetime