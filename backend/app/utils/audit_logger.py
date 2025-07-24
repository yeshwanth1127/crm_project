from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy.inspection import inspect
from backend.app import models
import json

def serialize_model(model):
    """
    Converts SQLAlchemy model to a clean dictionary of DB columns only.
    Handles datetime conversion. Excludes internal attributes like _sa_instance_state.
    """
    if model is None:
        return None

    return {
        column.key: (
            getattr(model, column.key).isoformat()
            if isinstance(getattr(model, column.key), datetime)
            else getattr(model, column.key)
        )
        for column in inspect(model).mapper.column_attrs
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
    # Clean model instances to safe dicts
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
        device_info=device_info,
        timestamp=datetime.utcnow()
    )

    try:
        db.add(log)
        db.commit()
    except Exception as e:
        db.rollback()
        raise e
