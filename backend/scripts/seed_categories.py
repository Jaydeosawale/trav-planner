from __future__ import annotations

import asyncio

from sqlalchemy import select

from app.database.session import SessionLocal
from app.modules.category.model import Category


CATEGORY_TREE = {
    "Accommodation": [
        "Hotels",
        "Resorts",
        "Hostels",
        "Homestays",
        "Guest Houses",
    ],
    "Food & Dining": [
        "Restaurants",
        "Cafes",
        "Bakeries",
        "Street Food",
        "Fine Dining",
    ],
    "Attractions": [
        "Historical Places",
        "Museums",
        "Monuments",
        "Beaches",
        "Waterfalls",
        "Viewpoints",
        "Religious Places",
    ],
    "Activities": [
        "Adventure",
        "Trekking",
        "Water Sports",
        "Wildlife",
        "Shopping",
        "Entertainment",
    ],
    "Nature": [
        "National Parks",
        "Wildlife Sanctuaries",
        "Lakes",
        "Mountains",
        "Gardens & Parks",
    ],
    "Transportation": [
        "Airports",
        "Railway Stations",
        "Bus Stations",
        "Car Rental",
    ],
}


def make_slug(name: str) -> str:
    return (
        name.lower()
        .replace("&", "and")
        .replace(" ", "-")
    )


async def seed_categories() -> None:
    async with SessionLocal() as db:
        try:
            root_order = 1

            for parent_name, children in CATEGORY_TREE.items():

                result = await db.execute(
                    select(Category).where(
                        Category.name == parent_name,
                        Category.is_deleted.is_(False),
                    )
                )

                parent = result.scalar_one_or_none()

                if parent is None:
                    parent = Category(
                        name=parent_name,
                        slug=make_slug(parent_name),
                        display_order=root_order,
                        is_featured=True,
                        is_active=True,
                    )

                    db.add(parent)
                    await db.flush()

                    print(f"Created parent: {parent_name}")
                else:
                    print(f"Exists: {parent_name}")

                child_order = 1

                for child_name in children:

                    result = await db.execute(
                        select(Category).where(
                            Category.name == child_name,
                            Category.is_deleted.is_(False),
                        )
                    )

                    child = result.scalar_one_or_none()

                    if child is None:
                        child = Category(
                            name=child_name,
                            slug=make_slug(child_name),
                            parent_id=parent.id,
                            display_order=child_order,
                            is_featured=False,
                            is_active=True,
                        )

                        db.add(child)

                        print(
                            f"  Created child: {child_name}"
                        )
                    else:
                        print(
                            f"  Exists: {child_name}"
                        )

                    child_order += 1

                root_order += 1

            await db.commit()

            print()
            print("Category seed completed successfully.")

        except Exception:
            await db.rollback()
            raise


if __name__ == "__main__":
    asyncio.run(seed_categories())
