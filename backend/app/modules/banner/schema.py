from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel
from pydantic import ConfigDict
from pydantic import Field
from pydantic import model_validator

class BannerBase(BaseModel):
    """
    Common banner fields.
    """

    title: str = Field(
        ...,
        max_length=200,
    )

    subtitle: str | None = Field(
        default=None,
        max_length=500,
    )

    image_url: str

    redirect_url: str | None = None

    display_order: int = 0

    is_active: bool = True

    # Scheduling

    starts_at: datetime | None = None

    ends_at: datetime | None = None

    # Campaign

    campaign_name: str | None = Field(
        default=None,
        max_length=150,
    )

    # Priority

    priority: int = 0


class BannerCreate(BannerBase):
    """
    Create banner request.
    """
    @model_validator(mode="after")
    def validate_schedule(self):
        if (
            self.starts_at is not None
            and self.ends_at is not None
            and self.ends_at <= self.starts_at
        ):
            raise ValueError(
                "ends_at must be later than starts_at."
            )

        if self.priority < 0:
            raise ValueError(
                "priority cannot be negative."
            )

        return self


class BannerUpdate(BaseModel):
    """
    Update banner request.
    """

    title: str | None = None
    subtitle: str | None = None
    image_url: str | None = None
    redirect_url: str | None = None
    is_active: bool | None = None

    starts_at: datetime | None = None
    ends_at: datetime | None = None

    campaign_name: str | None = None
    display_order: int = Field(default=0, ge=0)

    priority: int = Field(default=0, ge=0) 

    @model_validator(mode="after")
    def validate_schedule(self):
        if (
            self.starts_at is not None
            and self.ends_at is not None
            and self.ends_at <= self.starts_at
        ):
            raise ValueError(
                "ends_at must be later than starts_at."
            )

        if self.priority is not None and self.priority < 0:
            raise ValueError(
                "priority cannot be negative."
            )

        return self

class BannerResponse(BannerBase):
    """
    Banner response.
    """

    model_config = ConfigDict(
        from_attributes=True,
    )

    id: UUID


class BannerListResponse(BaseModel):
    """
    Banner list response.
    """

    items: list[BannerResponse]