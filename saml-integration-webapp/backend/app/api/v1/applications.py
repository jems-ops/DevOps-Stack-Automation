"""Applications API endpoints."""
from fastapi import APIRouter, HTTPException
from app.schemas.application import ApplicationListResponse, ApplicationResponse, ApplicationConfigField

router = APIRouter()

# Hardcoded application definitions based on your Ansible roles
APPLICATIONS = {
    "jenkins": ApplicationResponse(
        id="jenkins",
        name="jenkins",
        display_name="Jenkins",
        description="Jenkins CI/CD automation server with SAML SSO integration",
        is_active=True,
        config_fields=[
            ApplicationConfigField(
                name="jenkins_url",
                label="Jenkins URL",
                type="url",
                required=True,
                help_text="Full URL to your Jenkins instance (e.g., https://jenkins.local)"
            ),
            ApplicationConfigField(
                name="keycloak_url",
                label="Keycloak URL",
                type="url",
                required=True,
                help_text="Full URL to your Keycloak instance (e.g., https://keycloak.local)"
            ),
            ApplicationConfigField(
                name="realm",
                label="Keycloak Realm",
                type="text",
                required=True,
                default="master",
                help_text="Keycloak realm name"
            ),
        ],
        default_config={
            "realm": "master",
        }
    ),
    "sonarqube": ApplicationResponse(
        id="sonarqube",
        name="sonarqube",
        display_name="SonarQube",
        description="SonarQube code quality and security analysis platform",
        is_active=True,
        config_fields=[
            ApplicationConfigField(
                name="sonarqube_url",
                label="SonarQube URL",
                type="url",
                required=True,
                help_text="Full URL to your SonarQube instance"
            ),
            ApplicationConfigField(
                name="keycloak_url",
                label="Keycloak URL",
                type="url",
                required=True,
                help_text="Full URL to your Keycloak instance"
            ),
            ApplicationConfigField(
                name="realm",
                label="Keycloak Realm",
                type="text",
                required=True,
                default="master",
            ),
        ],
        default_config={
            "realm": "master",
        }
    ),
    "artifactory": ApplicationResponse(
        id="artifactory",
        name="artifactory",
        display_name="JFrog Artifactory",
        description="JFrog Artifactory universal artifact repository",
        is_active=True,
        config_fields=[
            ApplicationConfigField(
                name="artifactory_url",
                label="Artifactory URL",
                type="url",
                required=True,
                help_text="Full URL to your Artifactory instance"
            ),
            ApplicationConfigField(
                name="keycloak_url",
                label="Keycloak URL",
                type="url",
                required=True,
                help_text="Full URL to your Keycloak instance"
            ),
            ApplicationConfigField(
                name="realm",
                label="Keycloak Realm",
                type="text",
                required=True,
                default="master",
            ),
        ],
        default_config={
            "realm": "master",
        }
    ),
    "nexus": ApplicationResponse(
        id="nexus",
        name="nexus",
        display_name="Nexus Repository",
        description="Sonatype Nexus Repository Manager",
        is_active=True,
        config_fields=[
            ApplicationConfigField(
                name="nexus_url",
                label="Nexus URL",
                type="url",
                required=True,
                help_text="Full URL to your Nexus instance"
            ),
            ApplicationConfigField(
                name="keycloak_url",
                label="Keycloak URL",
                type="url",
                required=True,
                help_text="Full URL to your Keycloak instance"
            ),
            ApplicationConfigField(
                name="realm",
                label="Keycloak Realm",
                type="text",
                required=True,
                default="master",
            ),
        ],
        default_config={
            "realm": "master",
        }
    ),
}


@router.get("/", response_model=ApplicationListResponse)
async def list_applications():
    """
    List all supported applications for SAML integration.

    Returns a list of all applications that can be configured with SAML SSO
    through this API.
    """
    apps = list(APPLICATIONS.values())
    return ApplicationListResponse(
        applications=apps,
        total=len(apps)
    )


@router.get("/{app_id}", response_model=ApplicationResponse)
async def get_application(app_id: str):
    """
    Get details for a specific application.

    Returns configuration schema and default values for the specified application.
    """
    if app_id not in APPLICATIONS:
        raise HTTPException(
            status_code=404,
            detail=f"Application '{app_id}' not found. Supported applications: {', '.join(APPLICATIONS.keys())}"
        )

    return APPLICATIONS[app_id]
