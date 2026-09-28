"""add category and is_active to financial_goals

Revision ID: a2b3c4d5e6f7
Revises: f1ac52790be1
Create Date: 2026-09-28 16:40:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'a2b3c4d5e6f7'
down_revision = 'f1ac52790be1'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('financial_goals', sa.Column('category', sa.String(length=50), nullable=False, server_default='Other'))
    op.add_column('financial_goals', sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'))


def downgrade() -> None:
    op.drop_column('financial_goals', 'is_active')
    op.drop_column('financial_goals', 'category')
