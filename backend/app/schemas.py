from pydantic import BaseModel

class OnboardingSchema(BaseModel):
    company_name: str
    company_size: str
    crm_type: str
