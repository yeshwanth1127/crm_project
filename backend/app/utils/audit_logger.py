from datetime import datetime
from sqlalchemy.orm import Session
from backend.app import models

def serialize_model(model):
    if model is None:
        return None
    return {
        key: (
            value.isoformat() if isinstance(value, datetime) else value
        )
        for key, value in vars(model).items()
        if not key.startswith("_")
    }


def log_audit(
    db: Session,
    user_id: int,
    company_id: int,
    role: str,
    action: str,
    resource_type: str,
    resource_id: int,
    before_data: any = None,
    after_data: any = None,
    ip_address: str = None,
    device_info: str = None
):
    # Serialize model instances to clean dict
    if hasattr(before_data, "__table__"):
        before_data = serialize_model(before_data)
    if hasattr(after_data, "__table__"):
        after_data = serialize_model(after_data)

    log = models.AuditLog(
        user_id=user_id,
        company_id=company_id,
        role=role,
        action=action,
        resource_type=resource_type,
        resource_id=resource_id,
        before_data=before_data,
        after_data=after_data,
        ip_address=ip_address,
        device_info=device_info
    )
    try:
        db.add(log)
        db.commit()
    except Exception as e:
        db.rollback()
        raise e
