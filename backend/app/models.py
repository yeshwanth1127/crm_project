from sqlalchemy import Column, Integer, String
from .database import Base

class Organization(Base):
    __tablename__ = "organizations"

    id = Column(Integer, primary_key=True, index=True)
    company_name = Column(String, nullable=False)      # ✅ Added company name
    company_size = Column(String, nullable=False)
    crm_type = Column(String, nullable=False)
