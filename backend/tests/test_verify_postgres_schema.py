import pytest
from sqlalchemy import create_engine, inspect, text
from app.core.config import settings

def test_verify_postgresql_schema():
    """
    Connects directly to PostgreSQL and inspects the database schema metadata
    to verify that all required tables, columns, indexes, foreign keys, and constraints
    are actually present in PostgreSQL.
    """
    engine = create_engine(settings.DATABASE_URL)
    inspector = inspect(engine)

    # 1. Verify Table List
    tables = inspector.get_table_names()
    expected_tables = {
        "users",
        "expenses",
        "investments",
        "documents",
        "reminders",
        "financial_goals",
        "goal_scenarios",
        "goal_scenario_changes",
        "alembic_version",
    }
    for table in expected_tables:
        assert table in tables, f"Expected table '{table}' not found in PostgreSQL tables: {tables}"

    # 2. Verify Primary Keys & Column Types
    for table in ["users", "expenses", "investments", "documents", "reminders", "financial_goals", "goal_scenarios", "goal_scenario_changes"]:
        pk = inspector.get_pk_constraint(table)
        assert len(pk["constrained_columns"]) > 0, f"Table '{table}' missing primary key"

    # 3. Verify Foreign Keys
    fks_expenses = inspector.get_foreign_keys("expenses")
    assert any(fk["referred_table"] == "users" for fk in fks_expenses)

    fks_investments = inspector.get_foreign_keys("investments")
    assert any(fk["referred_table"] == "users" for fk in fks_investments)

    fks_documents = inspector.get_foreign_keys("documents")
    assert any(fk["referred_table"] == "users" for fk in fks_documents)

    fks_reminders = inspector.get_foreign_keys("reminders")
    assert any(fk["referred_table"] == "users" for fk in fks_reminders)

    fks_goals = inspector.get_foreign_keys("financial_goals")
    assert any(fk["referred_table"] == "users" for fk in fks_goals)

    fks_scenarios = inspector.get_foreign_keys("goal_scenarios")
    assert any(fk["referred_table"] == "users" for fk in fks_scenarios)

    fks_changes = inspector.get_foreign_keys("goal_scenario_changes")
    ref_tables = {fk["referred_table"] for fk in fks_changes}
    assert "goal_scenarios" in ref_tables and "financial_goals" in ref_tables

    # 4. Verify Unique Constraints & Indexes
    uqs_reminders = inspector.get_unique_constraints("reminders")
    uq_names = [uq["name"] for uq in uqs_reminders]
    assert "uq_auto_reminder_source_entity" in uq_names, f"Missing unique constraint on reminders: {uq_names}"

    # 5. Verify Check Constraints in pg_catalog
    with engine.connect() as conn:
        result = conn.execute(text("SELECT conname FROM pg_constraint WHERE contype = 'c';")).fetchall()
        constraint_names = {row[0] for row in result}
        expected_constraints = {
            "ck_expense_amount_positive",
            "ck_expense_category_valid",
            "ck_investment_monthly_contribution_non_negative",
            "ck_investment_total_paid_non_negative",
            "ck_investment_total_installments_non_negative",
            "ck_investment_installments_paid_non_negative",
            "ck_investment_installments_paid_lte_total",
            "ck_document_category_valid",
            "ck_reminder_category_valid",
            "ck_reminder_priority_valid",
            "ck_reminder_source_valid",
            "ck_financial_goal_target_amount_non_negative",
            "ck_financial_goal_current_amount_non_negative",
            "ck_financial_goal_monthly_contribution_non_negative",
            "ck_financial_goal_priority_valid",
            "ck_goal_scenario_change_operation_valid",
        }
        for ck in expected_constraints:
            assert ck in constraint_names, f"Expected PostgreSQL check constraint '{ck}' not found in database!"

    print("PostgreSQL schema verification successful! All tables, PKs, FKs, indexes, and constraints exist.")
