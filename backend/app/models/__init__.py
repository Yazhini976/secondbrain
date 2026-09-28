"""
SQLAlchemy Models Package.
Exports Base and all database entity models for Alembic auto-detection.
"""

from app.db.base import Base
from app.models.user import User
from app.models.expense import Expense
from app.models.investment import Investment
from app.models.document import Document
from app.models.reminder import Reminder
from app.models.financial_goal import FinancialGoal
from app.models.goal_scenario import GoalScenario
from app.models.goal_scenario_change import GoalScenarioChange

__all__ = [
    "Base",
    "User",
    "Expense",
    "Investment",
    "Document",
    "Reminder",
    "FinancialGoal",
    "GoalScenario",
    "GoalScenarioChange",
]
