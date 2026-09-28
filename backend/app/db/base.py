from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """
    Base class for all SQLAlchemy 2.x declarative models in Second Brain.

    Future module models (expenses, investments, documents, reminders, goals)
    will inherit from this Base.
    """
    pass
