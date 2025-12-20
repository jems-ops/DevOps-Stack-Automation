"""Pydantic schemas for application API."""
from typing import Dict, Any, Optional
from pydantic import BaseModel, Field


class ApplicationConfigField(BaseModel):
    """Schema for application configuration field."""
    name: str
    label: str
    type: str = Field(..., description="Field type: text, url, select, checkbox, password")
    required: bool = True
    default: Optional[Any] = None
    help_text: Optional[str] = None
    options: Optional[list[str]] = None  # For select fields


class ApplicationResponse(BaseModel):
    """Schema for application response."""
    id: str
    name: str
    display_name: str
    description: str
    icon_url: Optional[str] = None
    is_active: bool = True
    config_fields: list[ApplicationConfigField]
    default_config: Dict[str, Any] = {}

    model_config = {
        "json_schema_extra": {
            "example": {
                "id": "jenkins",
                "name": "jenkins",
                "display_name": "Jenkins",
                "description": "Jenkins CI/CD automation server",
                "is_active": True,
                "config_fields": [
                    {
                        "name": "jenkins_url",
                        "label": "Jenkins URL",
                        "type": "url",
                        "required": True,
                        "help_text": "Full URL to your Jenkins instance"
                    },
                    {
                        "name": "keycloak_url",
                        "label": "Keycloak URL",
                        "type": "url",
                        "required": True
                    },
                    {
                        "name": "realm",
                        "label": "Keycloak Realm",
                        "type": "text",
                        "required": True,
                        "default": "master"
                    }
                ],
                "default_config": {
                    "realm": "master",
                    "auto_user_creation": True
                }
            }
        }
    }


class ApplicationListResponse(BaseModel):
    """Schema for list of applications."""
    applications: list[ApplicationResponse]
    total: int

    model_config = {
        "json_schema_extra": {
            "example": {
                "applications": [],
                "total": 4
            }
        }
    }
