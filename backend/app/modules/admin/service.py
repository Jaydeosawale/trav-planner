"""
Admin dashboard service.
"""

from __future__ import annotations

from sqlalchemy import func
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.auth.model import User
from app.modules.banner.model import Banner
from app.modules.city.model import City
from app.modules.destination.model import Destination
from app.modules.place.model import Place
from app.modules.planner.model import Planner


class AdminService:
    """
    Service for admin dashboard and administration operations.
    """

    @staticmethod
    async def get_dashboard(
        db: AsyncSession,
    ) -> dict:
        """
        Return aggregated Admin Dashboard statistics.
        """

        # ======================================================
        # USERS
        # ======================================================

        total_users = await db.scalar(
            select(func.count(User.id))
        )

        active_users = await db.scalar(
            select(func.count(User.id)).where(
                User.is_active.is_(True)
            )
        )

        inactive_users = await db.scalar(
            select(func.count(User.id)).where(
                User.is_active.is_(False)
            )
        )

        admin_users = await db.scalar(
            select(func.count(User.id)).where(
                User.role.in_(["admin", "super_admin"])
            )
        )

        normal_users = await db.scalar(
            select(func.count(User.id)).where(
                User.role == "user"
            )
        )

        # ======================================================
        # BANNERS
        # ======================================================

        total_banners = await db.scalar(
            select(func.count(Banner.id)).where(
                Banner.is_deleted.is_(False)
            )
        )

        active_banners = await db.scalar(
            select(func.count(Banner.id)).where(
                Banner.is_deleted.is_(False),
                Banner.is_active.is_(True),
            )
        )

        # ======================================================
        # DESTINATIONS
        # ======================================================

        total_destinations = await db.scalar(
            select(func.count(Destination.id)).where(
                Destination.is_deleted.is_(False)
            )
        )

        active_destinations = await db.scalar(
            select(func.count(Destination.id)).where(
                Destination.is_deleted.is_(False),
                Destination.is_active.is_(True),
            )
        )

        featured_destinations = await db.scalar(
            select(func.count(Destination.id)).where(
                Destination.is_deleted.is_(False),
                Destination.is_active.is_(True),
                Destination.is_featured.is_(True),
            )
        )

        # ======================================================
        # CITIES
        # ======================================================

        total_cities = await db.scalar(
            select(func.count(City.id)).where(
                City.is_deleted.is_(False)
            )
        )

        active_cities = await db.scalar(
            select(func.count(City.id)).where(
                City.is_deleted.is_(False),
                City.is_active.is_(True),
            )
        )

        # ======================================================
        # PLACES
        # ======================================================

        total_places = await db.scalar(
            select(func.count(Place.id)).where(
                Place.is_deleted.is_(False)
            )
        )

        active_places = await db.scalar(
            select(func.count(Place.id)).where(
                Place.is_deleted.is_(False),
                Place.is_active.is_(True),
            )
        )

        featured_places = await db.scalar(
            select(func.count(Place.id)).where(
                Place.is_deleted.is_(False),
                Place.is_active.is_(True),
                Place.is_featured.is_(True),
            )
        )

        # ======================================================
        # PLANNERS / TRAVEL PLANS
        # ======================================================

        total_plans = await db.scalar(
            select(func.count(Planner.id)).where(
                Planner.is_deleted.is_(False)
            )
        )

        draft_plans = await db.scalar(
            select(func.count(Planner.id)).where(
                Planner.is_deleted.is_(False),
                Planner.status == "draft",
            )
        )

        planned_plans = await db.scalar(
            select(func.count(Planner.id)).where(
                Planner.is_deleted.is_(False),
                Planner.status == "planned",
            )
        )

        completed_plans = await db.scalar(
            select(func.count(Planner.id)).where(
                Planner.is_deleted.is_(False),
                Planner.status == "completed",
            )
        )

        cancelled_plans = await db.scalar(
            select(func.count(Planner.id)).where(
                Planner.is_deleted.is_(False),
                Planner.status == "cancelled",
            )
        )

        # ======================================================
        # RECENT PLANS
        # ======================================================

        recent_result = await db.execute(
            select(Planner)
            .where(
                Planner.is_deleted.is_(False)
            )
            .order_by(
                Planner.created_at.desc()
            )
            .limit(5)
        )

        recent_plans = recent_result.scalars().all()

        recent_plan_data = [
            {
                "id": str(plan.id),
                "title": plan.title,
                "user_id": str(plan.user_id),
                "destination_id": str(plan.destination_id),
                "start_date": plan.start_date.isoformat(),
                "end_date": plan.end_date.isoformat(),
                "travelers": plan.travelers,
                "status": plan.status,
                "created_at": (
                    plan.created_at.isoformat()
                    if plan.created_at
                    else None
                ),
            }
            for plan in recent_plans
        ]

        # ======================================================
        # RESPONSE
        # ======================================================

        return {
            "users": {
                "total": total_users or 0,
                "active": active_users or 0,
                "inactive": inactive_users or 0,
                "admins": admin_users or 0,
                "normal_users": normal_users or 0,
            },
            "content": {
                "banners": {
                    "total": total_banners or 0,
                    "active": active_banners or 0,
                },
                "destinations": {
                    "total": total_destinations or 0,
                    "active": active_destinations or 0,
                    "featured": featured_destinations or 0,
                },
                "cities": {
                    "total": total_cities or 0,
                    "active": active_cities or 0,
                },
                "places": {
                    "total": total_places or 0,
                    "active": active_places or 0,
                    "featured": featured_places or 0,
                },
            },
            "trips": {
                "total": total_plans or 0,
                "draft": draft_plans or 0,
                "planned": planned_plans or 0,
                "completed": completed_plans or 0,
                "cancelled": cancelled_plans or 0,
            },
            "recent_plans": recent_plan_data,
        }
