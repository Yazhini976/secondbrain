import logging
from app.db.session import SessionLocal
from app.models.user import User
from app.services.seed_service import seed_user_dummy_data

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("seed_dev_data")


def seed_dev_data():
    db = SessionLocal()
    try:
        user = db.query(User).filter_by(external_auth_id="dev-user-001").first()
        if not user:
            print("User dev-user-001 not found, creating...")
            user = User(
                external_auth_id="dev-user-001",
                email="dev@secondbrain.app",
                display_name="Dev User",
                is_active=True,
            )
            db.add(user)
            db.commit()
            db.refresh(user)

        print(f"Seeding dummy data for user: {user.display_name} ({user.id})")
        result = seed_user_dummy_data(db, user.id, force=True)

        print("Successfully seeded all dummy data into PostgreSQL database!")
        for key, count in result.get("counts", {}).items():
            print(f"  {key.capitalize()}: {count}")

    except Exception as e:
        db.rollback()
        print(f"Error seeding data: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed_dev_data()
