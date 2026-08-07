from __future__ import annotations

from uuid import UUID

from pydantic import BaseModel
from pydantic import ConfigDict
from pydantic import Field


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


class BannerCreate(BannerBase):
    """
    Create banner request.
    """

    pass


class BannerUpdate(BaseModel):
    """
    Update banner request.
    """

    title: str | None = None

    subtitle: str | None = None

    image_url: str | None = None

    redirect_url: str | None = None

    display_order: int | None = None

    is_active: bool | None = None


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