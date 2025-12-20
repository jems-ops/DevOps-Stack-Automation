"""Pydantic schemas for deployment API."""
from datetime import datetime
from typing import Optional, Dict, Any
from pydantic import BaseModel, Field, UUID4
from enum import Enum


class DeploymentStatusEnum(str, Enum):
    """Deployment status enum."""
    PENDING = "pending"
    RUNNING = "running"
    SUCCESS = "success"
    FAILED = "failed"
    CANCELLED = "cancelled"


class DeploymentCreate(BaseModel):
    """Schema for creating a new deployment."""
    app_type: str = Field(..., description="Application type (jenkins, sonarqube, artifactory, nexus)")
    configuration: Dict[str, Any] = Field(..., description="SAML configuration parameters")
    created_by: Optional[str] = Field(None, description="Username or user ID")

    model_config = {
        "json_schema_extra": {
            "example": {
                "app_type": "jenkins",
                "configuration": {
                    "keycloak_url": "https://keycloak.local",
                    "jenkins_url": "https://jenkins.local",
                    "realm": "master",
                },
                "created_by": "admin"
            }
        }
    }


class DeploymentResponse(BaseModel):
    """Schema for deployment response."""
    id: UUID4
    app_type: str
    status: DeploymentStatusEnum
    configuration: Dict[str, Any]
    playbook_output: Optional[str] = None
    error_message: Optional[str] = None
    ansible_stats: Optional[Dict[str, Any]] = None
    created_at: datetime
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    created_by: Optional[str] = None
    duration_seconds: Optional[float] = None

    model_config = {
        "from_attributes": True,
        "json_schema_extra": {
            "example": {
                "id": "123e4567-e89b-12d3-a456-426614174000",
                "app_type": "jenkins",
                "status": "success",
                "configuration": {
                    "keycloak_url": "https://keycloak.local",
                    "jenkins_url": "https://jenkins.local",
                },
                "created_at": "2024-01-20T10:00:00",
                "completed_at": "2024-01-20T10:05:00",
                "duration_seconds": 300.0
            }
        }
    }


class DeploymentList(BaseModel):
    """Schema for deployment list response."""
    deployments: list[DeploymentResponse]
    total: int
    page: int
    page_size: int

    model_config = {
        "json_schema_extra": {
            "example": {
                "deployments": [],
                "total": 10,
                "page": 1,
                "page_size": 20
            }
        }
    }


class DeploymentUpdate(BaseModel):
    """Schema for updating deployment status."""
    status: Optional[DeploymentStatusEnum] = None
    playbook_output: Optional[str] = None
    error_message: Optional[str] = None
    ansible_stats: Optional[Dict[str, Any]] = None
