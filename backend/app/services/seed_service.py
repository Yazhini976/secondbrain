import uuid
import logging
from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Dict, Any
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.expense import Expense
from app.models.investment import Investment
from app.models.document import Document
from app.models.reminder import Reminder
from app.models.financial_goal import FinancialGoal
from app.models.goal_scenario import GoalScenario
from app.models.goal_scenario_change import GoalScenarioChange

logger = logging.getLogger("second_brain.seed_service")


def seed_user_dummy_data(db: Session, user_id: uuid.UUID, force: bool = False) -> Dict[str, Any]:
    """
    Seeds comprehensive dummy data into PostgreSQL database for a specific user.
    Includes Expenses, Investments, Documents, Reminders, Financial Goals, and Goal Scenarios.
    
    If force is False and the user already has data, skips seeding.
    """
    if not force:
        has_expenses = db.query(Expense).filter_by(user_id=user_id).first() is not None
        has_documents = db.query(Document).filter_by(user_id=user_id).first() is not None
        has_investments = db.query(Investment).filter_by(user_id=user_id).first() is not None
        has_goals = db.query(FinancialGoal).filter_by(user_id=user_id).first() is not None

        if has_expenses or has_documents or has_investments or has_goals:
            logger.info(f"User {user_id} already has data in database. Skipping dummy data seed.")
            return {"status": "skipped", "message": "User already has existing data"}

    logger.info(f"Seeding dummy data into database for user_id={user_id} (force={force})")

    # If force, clear existing data
    if force:
        db.query(Reminder).filter_by(user_id=user_id).delete()
        db.query(GoalScenario).filter_by(user_id=user_id).delete()
        db.query(FinancialGoal).filter_by(user_id=user_id).delete()
        db.query(Document).filter_by(user_id=user_id).delete()
        db.query(Investment).filter_by(user_id=user_id).delete()
        db.query(Expense).filter_by(user_id=user_id).delete()
        db.commit()

    # 1. EXPENSES
    # Categories: 'Food & Dining', 'Transport', 'Shopping', 'Bills & Utilities', 'Other'
    expenses_data = [
        # September 2026 (Current Month)
        ("Swiggy Dinner", Decimal("450.00"), "Food & Dining", date(2026, 9, 27), "Biryani combo with drinks"),
        ("Blue Tokai Coffee", Decimal("280.00"), "Food & Dining", date(2026, 9, 26), "Cappuccino and sourdough toast"),
        ("Uber to Office", Decimal("380.00"), "Transport", date(2026, 9, 25), "Morning peak commute"),
        ("Airtel Fiber Broadband", Decimal("1179.00"), "Bills & Utilities", date(2026, 9, 24), "Monthly 200 Mbps plan"),
        ("Supermarket Grocery", Decimal("2350.00"), "Food & Dining", date(2026, 9, 22), "Weekly provisions and dairy"),
        ("Apollo Pharmacy", Decimal("620.00"), "Other", date(2026, 9, 21), "Vitamins and first aid supplies"),
        ("Amazon Electronics", Decimal("3499.00"), "Shopping", date(2026, 9, 20), "ANC Wireless Earbuds"),
        ("Zomato Lunch", Decimal("360.00"), "Food & Dining", date(2026, 9, 18), "Healthy salad bowl"),
        ("Book Store", Decimal("499.00"), "Other", date(2026, 9, 16), "Psychology of Money book"),
        ("Namma Metro Recharge", Decimal("500.00"), "Transport", date(2026, 9, 15), "Smart card monthly topup"),
        ("Decathlon Sports Gear", Decimal("1200.00"), "Shopping", date(2026, 9, 14), "Running shoes and water bottle"),
        ("Cafe Coffee Day", Decimal("180.00"), "Food & Dining", date(2026, 9, 12), "Cold coffee with colleagues"),
        ("BESCOM Electricity Bill", Decimal("1450.00"), "Bills & Utilities", date(2026, 9, 10), "Electricity bill for August"),
        ("Shell Petrol Station", Decimal("1800.00"), "Transport", date(2026, 9, 8), "Full tank petrol for car"),
        ("Water Utility Bill", Decimal("350.00"), "Bills & Utilities", date(2026, 9, 7), "Apartment water charges"),
        ("Zara Casual Wear", Decimal("2850.00"), "Shopping", date(2026, 9, 5), "Casual shirts"),
        ("Jio Postpaid Bill", Decimal("799.00"), "Bills & Utilities", date(2026, 9, 3), "Family plan mobile postpaid"),
        ("Ola Cab Ride", Decimal("420.00"), "Transport", date(2026, 9, 2), "Airport transit"),
        
        # August 2026 (Previous Month)
        ("Cult.fit Membership", Decimal("2500.00"), "Other", date(2026, 8, 28), "Monthly fitness pack"),
        ("Groceries Nature Basket", Decimal("3100.00"), "Food & Dining", date(2026, 8, 22), "Organic groceries"),
        ("IKEA Home Decor", Decimal("4200.00"), "Shopping", date(2026, 8, 15), "Study lamp and desk organizer"),
        ("HP Petrol Pump", Decimal("1750.00"), "Transport", date(2026, 8, 10), "Fuel refill"),
        ("Electricity Bill", Decimal("1380.00"), "Bills & Utilities", date(2026, 8, 8), "July bill payment"),
        ("Weekend Dining", Decimal("1650.00"), "Food & Dining", date(2026, 8, 2), "Dinner with family"),
    ]

    for merchant, amount, category, tx_date, notes in expenses_data:
        exp = Expense(
            user_id=user_id,
            merchant=merchant,
            amount=amount,
            category=category,
            transaction_date=tx_date,
            notes=notes,
        )
        db.add(exp)

    # 2. INVESTMENTS
    investments_list = [
        Investment(
            user_id=user_id,
            name="HDFC Top 100 Index Fund (SIP)",
            type="Mutual Fund",
            monthly_contribution=Decimal("5000.00"),
            total_paid=Decimal("60000.00"),
            total_installments=36,
            installments_paid=12,
            start_date=date(2025, 9, 5),
            next_due=date(2026, 10, 5), # On Track
            maturity_date=date(2028, 9, 5),
            notes="Nifty 50 large cap index SIP auto-debited on 5th",
        ),
        Investment(
            user_id=user_id,
            name="Parag Parikh Flexi Cap Fund",
            type="SIP",
            monthly_contribution=Decimal("7500.00"),
            total_paid=Decimal("90000.00"),
            total_installments=24,
            installments_paid=12,
            start_date=date(2025, 9, 1),
            next_due=date(2026, 10, 1), # Due Soon (within 7 days of 2026-09-28)
            maturity_date=date(2027, 9, 1),
            notes="Diversified equity with global US equity exposure",
        ),
        Investment(
            user_id=user_id,
            name="Tanishq Golden Harvest Scheme",
            type="Gold Scheme",
            monthly_contribution=Decimal("3000.00"),
            total_paid=Decimal("30000.00"),
            total_installments=11,
            installments_paid=10,
            start_date=date(2025, 11, 25),
            next_due=date(2026, 9, 25), # Overdue (due 3 days ago)
            maturity_date=date(2026, 10, 25),
            notes="10 months installment scheme for jewellery purchase bonus",
        ),
        Investment(
            user_id=user_id,
            name="SBI 1-Year Recurring Deposit",
            type="Recurring Deposit",
            monthly_contribution=Decimal("10000.00"),
            total_paid=Decimal("120000.00"),
            total_installments=12,
            installments_paid=12, # Completed!
            start_date=date(2025, 9, 15),
            next_due=None,
            maturity_date=date(2026, 9, 15),
            notes="Emergency fund RD completed at 6.8% per annum",
        ),
        Investment(
            user_id=user_id,
            name="NPS Tier-1 Pension Scheme",
            type="Retirement",
            monthly_contribution=Decimal("4000.00"),
            total_paid=Decimal("48000.00"),
            total_installments=60,
            installments_paid=12,
            start_date=date(2025, 9, 10),
            next_due=date(2026, 10, 10), # On Track
            maturity_date=date(2030, 9, 10),
            notes="National Pension System for Section 80CCD tax deduction",
        ),
    ]
    for inv in investments_list:
        db.add(inv)
    db.flush()

    # 3. DOCUMENTS
    docs_list = [
        Document(
            user_id=user_id,
            title="Aadhaar Card (UIDAI)",
            category="Identity",
            description="Government UID national identity card",
            issue_date=date(2020, 4, 10),
            expiry_date=None, # Active
            file_name="aadhaar_card_front_back.pdf",
            file_type="application/pdf",
            file_size=420000,
            notes="Mobile number and address linked and verified",
        ),
        Document(
            user_id=user_id,
            title="Passport (Republic of India)",
            category="Identity",
            description="Regular 36-page passport booklet",
            issue_date=date(2018, 6, 15),
            expiry_date=date(2028, 6, 14), # Active
            file_name="passport_scan.pdf",
            file_type="application/pdf",
            file_size=1050000,
            notes="Bangalore RPO passport",
        ),
        Document(
            user_id=user_id,
            title="Honda City Vehicle Insurance",
            category="Vehicle",
            description="HDFC ERGO Comprehensive Motor Package Policy",
            issue_date=date(2025, 10, 5),
            expiry_date=date(2026, 10, 5), # Expiring Soon (7 days)
            file_name="vehicle_insurance_policy.pdf",
            file_type="application/pdf",
            file_size=650000,
            notes="Policy No: POL-984210, IDV: Rs. 7,50,000",
        ),
        Document(
            user_id=user_id,
            title="Star Health Optima Family Insurance",
            category="Insurance",
            description="Family floater comprehensive health cover of Rs. 10 Lakhs",
            issue_date=date(2026, 3, 1),
            expiry_date=date(2027, 2, 28), # Active
            file_name="health_insurance_card.pdf",
            file_type="application/pdf",
            file_size=512000,
            notes="Cashless TPA card and cashless hospital list",
        ),
        Document(
            user_id=user_id,
            title="Apartment Rental Agreement",
            category="Property",
            description="11-month residential lease agreement for Flat 302",
            issue_date=date(2025, 8, 1),
            expiry_date=date(2026, 7, 1), # Expired (2 months ago)
            file_name="rental_agreement_signed.pdf",
            file_type="application/pdf",
            file_size=1850000,
            notes="Need to contact landlord for renewal agreement",
        ),
        Document(
            user_id=user_id,
            title="Permanent Account Number (PAN Card)",
            category="Financial",
            description="Income Tax Department PAN card",
            issue_date=date(2017, 2, 14),
            expiry_date=None, # Active
            file_name="pan_card_original.pdf",
            file_type="application/pdf",
            file_size=320000,
            notes="Verified with NSDL & Demat account",
        ),
    ]
    for doc in docs_list:
        db.add(doc)
    db.flush()

    # 4. REMINDERS
    car_ins_doc = next(d for d in docs_list if "Vehicle Insurance" in d.title)
    gold_inv = next(i for i in investments_list if "Golden Harvest" in i.name)
    sip_inv = next(i for i in investments_list if "Parag Parikh" in i.name)

    reminders_list = [
        Reminder(
            user_id=user_id,
            title="Renew Vehicle Insurance Policy",
            description="HDFC ERGO Comprehensive Motor Policy expires on Oct 5. Compare quotes and renew.",
            due_at=datetime(2026, 10, 5, 10, 0, tzinfo=timezone.utc),
            category="Document",
            priority="High",
            is_completed=False,
            source="documentExpiry",
            linked_entity_type="document",
            linked_entity_id=car_ins_doc.id,
        ),
        Reminder(
            user_id=user_id,
            title="Pay Gold Scheme Installment #11",
            description="Tanishq Golden Harvest installment #11 of Rs. 3,000 was due on Sep 25.",
            due_at=datetime(2026, 9, 25, 18, 0, tzinfo=timezone.utc),
            category="Investment",
            priority="High",
            is_completed=False,
            source="investmentDue",
            linked_entity_type="investment",
            linked_entity_id=gold_inv.id,
        ),
        Reminder(
            user_id=user_id,
            title="Parag Parikh SIP Auto-Debit Balance Check",
            description="Keep bank balance >= Rs. 7,500 for monthly SIP execution on Oct 1.",
            due_at=datetime(2026, 10, 1, 9, 0, tzinfo=timezone.utc),
            category="Investment",
            priority="Medium",
            is_completed=False,
            source="investmentDue",
            linked_entity_type="investment",
            linked_entity_id=sip_inv.id,
        ),
        Reminder(
            user_id=user_id,
            title="Dentist Checkup & Cleaning",
            description="Scheduled cleaning appointment at Indiranagar dental clinic.",
            due_at=datetime(2026, 9, 29, 17, 30, tzinfo=timezone.utc),
            category="Personal",
            priority="Medium",
            is_completed=False,
            source="manual",
        ),
        Reminder(
            user_id=user_id,
            title="Submit Electricity Meter Reading",
            description="Uploaded meter photo on BESCOM utility portal.",
            due_at=datetime(2026, 9, 20, 12, 0, tzinfo=timezone.utc),
            category="Other",
            priority="Low",
            is_completed=True,
            source="manual",
        ),
    ]
    for rem in reminders_list:
        db.add(rem)

    # 5. FINANCIAL GOALS
    goals_list = [
        FinancialGoal(
            user_id=user_id,
            name="Emergency Fund (6 Months Expenses)",
            category="Savings",
            target_amount=Decimal("300000.00"),
            current_amount=Decimal("180000.00"),
            deadline=date(2027, 3, 31),
            monthly_contribution=Decimal("15000.00"),
            priority="High",
            is_active=True,
        ),
        FinancialGoal(
            user_id=user_id,
            name="Japan Autumn Vacation 2027",
            category="Travel",
            target_amount=Decimal("250000.00"),
            current_amount=Decimal("75000.00"),
            deadline=date(2027, 10, 15),
            monthly_contribution=Decimal("12000.00"),
            priority="Medium",
            is_active=True,
        ),
        FinancialGoal(
            user_id=user_id,
            name="Electric Vehicle Down Payment",
            category="Vehicle",
            target_amount=Decimal("400000.00"),
            current_amount=Decimal("120000.00"),
            deadline=date(2027, 12, 31),
            monthly_contribution=Decimal("18000.00"),
            priority="High",
            is_active=True,
        ),
    ]
    for goal in goals_list:
        db.add(goal)
    db.flush()

    # 6. GOAL SCENARIO
    emergency_goal = goals_list[0]
    vacation_goal = goals_list[1]
    scenario = GoalScenario(
        user_id=user_id,
        name="Accelerate Emergency Fund",
        description="Prioritize emergency safety cushion by reallocating surplus from vacation savings",
        status="active",
        base_plan_reference="Standard Plan",
        scenario_payload={"strategy": "safety_first", "timeline_months": 6},
        feasibility_result={"is_feasible": True, "monthly_surplus_required": 15000},
    )
    db.add(scenario)
    db.flush()

    change_1 = GoalScenarioChange(
        scenario_id=scenario.id,
        goal_id=emergency_goal.id,
        operation="INCREASE_CONTRIBUTION",
        old_value={"monthly_contribution": "15000.00"},
        new_value={"monthly_contribution": "20000.00"},
    )
    change_2 = GoalScenarioChange(
        scenario_id=scenario.id,
        goal_id=vacation_goal.id,
        operation="DECREASE_CONTRIBUTION",
        old_value={"monthly_contribution": "12000.00"},
        new_value={"monthly_contribution": "7000.00"},
    )
    db.add(change_1)
    db.add(change_2)

    db.commit()
    logger.info(f"Successfully seeded dummy data for user_id={user_id}")

    return {
        "status": "seeded",
        "counts": {
            "expenses": len(expenses_data),
            "investments": len(investments_list),
            "documents": len(docs_list),
            "reminders": len(reminders_list),
            "goals": len(goals_list),
            "scenarios": 1,
        },
    }
