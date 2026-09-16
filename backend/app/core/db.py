# backend/app/core/db.py

from sqlmodel import Session, create_engine, select

from app import crud
from app.core.config import settings
from app.models import User, UserCreate

engine = create_engine(
    str(settings.DATABASE_URL),
    pool_pre_ping=True,
)


def init_db(session: Session) -> None:
    """Initialize required application data in an already-migrated database."""
    user = session.exec(
        select(User).where(User.email == settings.FIRST_SUPERUSER)
    ).first()

    if user:
        return

    user_in = UserCreate(
        email=settings.FIRST_SUPERUSER,
        password=settings.FIRST_SUPERUSER_PASSWORD,
        is_superuser=True,
    )
    crud.create_user(session=session, user_create=user_in)