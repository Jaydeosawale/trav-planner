"""
Create the first admin user.

Development/bootstrap utility.
Do not expose this through an API endpoint.
"""

from __future__ import annotations

import asyncio
import getpass

from passlib.context import CryptContext
from sqlalchemy import select

from app.database.session import SessionLocal
from app.modules.auth.model import User


password_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto",
)


async def create_admin() -> None:
    print("=" * 50)
    print("Trav Planner - Create Admin")
    print("=" * 50)

    email = input("Admin email: ").strip().lower()
    full_name = input("Admin full name: ").strip()
    password = getpass.getpass("Admin password: ")
    confirm_password = getpass.getpass("Confirm password: ")

    if not email:
        print("ERROR: Email is required.")
        return

    if not full_name:
        print("ERROR: Full name is required.")
        return

    if not password:
        print("ERROR: Password is required.")
        return

    if password != confirm_password:
        print("ERROR: Passwords do not match.")
        return

    if len(password) < 8:
        print("ERROR: Password must be at least 8 characters.")
        return

    async with SessionLocal() as db:
        result = await db.execute(
            select(User).where(User.email == email)
        )

        existing_user = result.scalar_one_or_none()

        if existing_user is not None:
            print()
            print("A user with this email already exists.")

            if existing_user.role == "admin":
                print("This user is already an admin.")
                return

            promote = input(
                "Promote this existing user to admin? [y/N]: "
            ).strip().lower()

            if promote != "y":
                print("No changes made.")
                return

            existing_user.role = "admin"
            existing_user.is_active = True

            await db.commit()

            print()
            print("Existing user promoted to admin successfully.")
            return

        admin = User(
            email=email,
            password_hash=password_context.hash(password),
            full_name=full_name,
            is_active=True,
            role="admin",
        )

        db.add(admin)

        await db.commit()
        await db.refresh(admin)

        print()
        print("Admin created successfully.")
        print(f"Email: {admin.email}")
        print(f"Name:  {admin.full_name}")
        print(f"Role:  {admin.role}")


if __name__ == "__main__":
    asyncio.run(create_admin())
