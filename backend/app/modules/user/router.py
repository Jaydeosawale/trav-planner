"""
User travel profile and behavior API.
"""

from __future__ import annotations

from fastapi import APIRouter
from fastapi import Depends
from fastapi import Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.responses.api_response import success_response
from app.database.session import get_db
from app.dependencies.current_user import get_current_user
from app.modules.auth.model import User
from app.modules.place.schema import PlaceResponse
from app.modules.user.schema import (
    UserPlaceInteractionResponse,
    UserPlaceViewResponse,
    UserSearchHistoryCreate,
    UserSearchHistoryResponse,
    UserTravelProfileResponse,
    UserTravelProfileUpdate,
)
from app.modules.user.service import UserService


router = APIRouter()

service = UserService()


# ==========================================================
# Travel Profile
# ==========================================================

@router.get(
    "/profile",
    summary="Get current user's travel profile",
)
async def get_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get the authenticated user's travel profile.
    """

    profile = await service.get_profile(
        db,
        current_user.id,
    )

    return success_response(
        data=(
            UserTravelProfileResponse.model_validate(profile)
            if profile
            else None
        ),
        message="Travel profile retrieved successfully",
    )


@router.put(
    "/profile",
    summary="Create or update travel profile",
)
async def update_profile(
    payload: UserTravelProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Create or update the authenticated user's travel profile.
    """

    profile = await service.create_or_update_profile(
        db,
        current_user.id,
        payload,
    )

    return success_response(
        data=UserTravelProfileResponse.model_validate(
            profile,
        ),
        message="Travel profile updated successfully",
    )


# ==========================================================
# Search History
# ==========================================================

@router.post(
    "/search-history",
    summary="Record a user search",
)
async def add_search(
    payload: UserSearchHistoryCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Record a search performed by the authenticated user.
    """

    search = await service.add_search(
        db,
        current_user.id,
        payload,
    )

    return success_response(
        data=UserSearchHistoryResponse.model_validate(
            search,
        ),
        message="Search recorded successfully",
    )


@router.get(
    "/search-history",
    summary="Get current user's search history",
)
async def get_search_history(
    limit: int = Query(
        default=50,
        ge=1,
        le=100,
    ),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get recent searches of the authenticated user.
    """

    searches = await service.get_search_history(
        db,
        current_user.id,
        limit,
    )

    return success_response(
        data=[
            UserSearchHistoryResponse.model_validate(
                item,
            )
            for item in searches
        ],
        message="Search history retrieved successfully",
    )


# ==========================================================
# Likes
# ==========================================================

@router.post(
    "/places/{place_id}/like",
    summary="Like a place",
)
async def like_place(
    place_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Like a place for the authenticated user.

    Repeated requests should not create duplicate likes.
    """

    like = await service.like_place(
        db,
        current_user.id,
        place_id,
    )

    return success_response(
        data=UserPlaceInteractionResponse.model_validate(like),
        message="Place liked successfully",
    )


@router.delete(
    "/places/{place_id}/like",
    summary="Unlike a place",
)
async def unlike_place(
    place_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Remove the authenticated user's like from a place.
    """

    await service.unlike_place(
        db,
        current_user.id,
        place_id,
    )

    return success_response(
        message="Place unliked successfully",
    )


@router.get(
    "/liked-places",
    summary="Get liked places",
)
async def get_liked_places(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get places liked by the authenticated user.
    """

    places = await service.get_liked_places(
        db,
        current_user.id,
    )

    return success_response(
        data=[PlaceResponse.model_validate(place) for place in places],
        message="Liked places retrieved successfully",
    )


# ==========================================================
# Saves
# ==========================================================

@router.post(
    "/places/{place_id}/save",
    summary="Save a place",
)
async def save_place(
    place_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Save a place for the authenticated user.

    Repeated requests should not create duplicate saves.
    """

    save = await service.save_place(
        db,
        current_user.id,
        place_id,
    )

    return success_response(
        data=UserPlaceInteractionResponse.model_validate(save),
        message="Place saved successfully",
    )


@router.delete(
    "/places/{place_id}/save",
    summary="Unsave a place",
)
async def unsave_place(
    place_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Remove the authenticated user's saved place.
    """

    await service.unsave_place(
        db,
        current_user.id,
        place_id,
    )

    return success_response(
        message="Place unsaved successfully",
    )


@router.get(
    "/saved-places",
    summary="Get saved places",
)
async def get_saved_places(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get places saved by the authenticated user.
    """

    places = await service.get_saved_places(
        db,
        current_user.id,
    )

    return success_response(
        data=[PlaceResponse.model_validate(place) for place in places],
        message="Saved places retrieved successfully",
    )


# ==========================================================
# Views
# ==========================================================

@router.post(
    "/places/{place_id}/view",
    summary="Record a place view",
)
async def record_place_view(
    place_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Record that the authenticated user viewed a place.

    Multiple views are allowed and are useful as
    behavioral signals for personalization.
    """

    view = await service.record_place_view(
        db,
        current_user.id,
        place_id,
    )

    return success_response(
        data=UserPlaceViewResponse.model_validate(
            view,
        ),
        message="Place view recorded successfully",
    )
