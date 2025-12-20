"""Deployment database model."""
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Text, JSON, Enum as SQLEnum
from sqlalchemy.types import TypeDecorator, CHAR
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
import uuid
import enum

from app.database import Base


class GUID(TypeDecorator):
    """Platform-independent GUID type. Uses PostgreSQL's UUID type, otherwise uses CHAR(36)."""
    impl = CHAR
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == 'postgresql':
            return dialect.type_descriptor(PG_UUID())
        else:
            return dialect.type_descriptor(CHAR(36))

    def process_bind_param(self, value, dialect):
        if value is None:
            return value
        elif dialect.name == 'postgresql':
            return str(value)
        else:
            if not isinstance(value, uuid.UUID):
                return str(uuid.UUID(value))
            else:
                return str(value)

    def process_result_value(self, value, dialect):
        if value is None:
            return value
        else:
            if not isinstance(value, uuid.UUID):
                value = uuid.UUID(value)
            return value


class DeploymentStatus(enum.Enum):
    """Deployment status enum."""
    PENDING = "pending"
    RUNNING = "running"
    SUCCESS = "success"
    FAILED = "failed"
    CANCELLED = "cancelled"


class Deployment(Base):
    """Deployment model for tracking SAML integration deployments."""

    __tablename__ = "deployments"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    app_type = Column(String(50), nullable=False, index=True)
    status = Column(SQLEnum(DeploymentStatus), nullable=False, default=DeploymentStatus.PENDING, index=True)

    # Configuration and results
    configuration = Column(JSON, nullable=False)  # Stores all input parameters
    playbook_output = Column(Text)  # Ansible playbook output
    error_message = Column(Text)
    ansible_stats = Column(JSON)  # Ansible execution stats

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    started_at = Column(DateTime)
    completed_at = Column(DateTime)

    # User tracking
    created_by = Column(String(100))  # Username or user ID

    def __repr__(self):
        return f"<Deployment(id={self.id}, app_type={self.app_type}, status={self.status})>"

    @property
    def duration_seconds(self):
        """Calculate deployment duration in seconds."""
        if self.started_at and self.completed_at:
            return (self.completed_at - self.started_at).total_seconds()
        return None

    @property
    def is_running(self):
        """Check if deployment is currently running."""
        return self.status == DeploymentStatus.RUNNING

    @property
    def is_finished(self):
        """Check if deployment is in a terminal state."""
        return self.status in [DeploymentStatus.SUCCESS, DeploymentStatus.FAILED, DeploymentStatus.CANCELLED]

    def to_dict(self):
        """Convert model to dictionary."""
        return {
            "id": str(self.id),
            "app_type": self.app_type,
            "status": self.status.value,
            "configuration": self.configuration,
            "playbook_output": self.playbook_output,
            "error_message": self.error_message,
            "ansible_stats": self.ansible_stats,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "created_by": self.created_by,
            "duration_seconds": self.duration_seconds,
        }
