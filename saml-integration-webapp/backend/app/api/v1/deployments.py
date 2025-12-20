"""Deployments API endpoints."""
from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from datetime import datetime
from typing import Optional
import uuid

from app.database import get_db
from app.models.deployment import Deployment, DeploymentStatus
from app.schemas.deployment import (
    DeploymentCreate,
    DeploymentResponse,
    DeploymentList,
)
from app.services.ansible_runner import ansible_service
from app.api.v1.applications import APPLICATIONS

router = APIRouter()


async def execute_deployment(deployment_id: uuid.UUID, db: AsyncSession):
    """Execute deployment in background."""
    # Get deployment
    result = await db.execute(
        select(Deployment).where(Deployment.id == deployment_id)
    )
    deployment = result.scalar_one_or_none()

    if not deployment:
        return

    try:
        # Update status to running
        deployment.status = DeploymentStatus.RUNNING
        deployment.started_at = datetime.utcnow()
        await db.commit()

        # Execute Ansible playbook
        result = await ansible_service.run_saml_integration(
            app_type=deployment.app_type,
            configuration=deployment.configuration
        )

        # Update deployment with results
        deployment.status = DeploymentStatus.SUCCESS if result["status"] == "successful" else DeploymentStatus.FAILED
        deployment.playbook_output = result.get("stdout", "")
        deployment.ansible_stats = result.get("stats", {})
        deployment.completed_at = datetime.utcnow()

        if result["status"] != "successful":
            deployment.error_message = f"Ansible playbook failed with return code {result['rc']}"

    except Exception as e:
        deployment.status = DeploymentStatus.FAILED
        deployment.error_message = str(e)
        deployment.completed_at = datetime.utcnow()

    await db.commit()


@router.post("/", response_model=DeploymentResponse, status_code=201)
async def create_deployment(
    deployment: DeploymentCreate,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
):
    """
    Create a new SAML integration deployment.

    This endpoint creates a new deployment and queues it for execution in the background.
    The deployment will execute the Ansible playbook to configure SAML SSO for the specified application.
    """
    # Validate app_type
    if deployment.app_type not in APPLICATIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid app_type. Supported: {', '.join(APPLICATIONS.keys())}"
        )

    # Create deployment record
    db_deployment = Deployment(
        app_type=deployment.app_type,
        configuration=deployment.configuration,
        created_by=deployment.created_by,
        status=DeploymentStatus.PENDING,
    )

    db.add(db_deployment)
    await db.commit()
    await db.refresh(db_deployment)

    # Queue background task
    background_tasks.add_task(execute_deployment, db_deployment.id, db)

    return DeploymentResponse.model_validate(db_deployment)


@router.get("/", response_model=DeploymentList)
async def list_deployments(
    page: int = 1,
    page_size: int = 20,
    app_type: Optional[str] = None,
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
):
    """
    List all deployments with optional filtering.

    Filter by app_type and/or status. Results are paginated.
    """
    # Build query
    query = select(Deployment).order_by(Deployment.created_at.desc())

    # Apply filters
    if app_type:
        query = query.where(Deployment.app_type == app_type)
    if status:
        query = query.where(Deployment.status == DeploymentStatus(status))

    # Get total count
    count_query = select(func.count()).select_from(query.subquery())
    total_result = await db.execute(count_query)
    total = total_result.scalar()

    # Apply pagination
    offset = (page - 1) * page_size
    query = query.offset(offset).limit(page_size)

    # Execute query
    result = await db.execute(query)
    deployments = result.scalars().all()

    return DeploymentList(
        deployments=[DeploymentResponse.model_validate(d) for d in deployments],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/{deployment_id}", response_model=DeploymentResponse)
async def get_deployment(
    deployment_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """
    Get details for a specific deployment.

    Returns all information about a deployment including configuration,
    status, and execution logs.
    """
    result = await db.execute(
        select(Deployment).where(Deployment.id == deployment_id)
    )
    deployment = result.scalar_one_or_none()

    if not deployment:
        raise HTTPException(status_code=404, detail="Deployment not found")

    return DeploymentResponse.model_validate(deployment)


@router.delete("/{deployment_id}", status_code=204)
async def cancel_deployment(
    deployment_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """
    Cancel a running deployment.

    Note: This only updates the status. The actual Ansible process may continue.
    """
    result = await db.execute(
        select(Deployment).where(Deployment.id == deployment_id)
    )
    deployment = result.scalar_one_or_none()

    if not deployment:
        raise HTTPException(status_code=404, detail="Deployment not found")

    if deployment.is_finished:
        raise HTTPException(
            status_code=400,
            detail="Cannot cancel a finished deployment"
        )

    deployment.status = DeploymentStatus.CANCELLED
    deployment.completed_at = datetime.utcnow()
    await db.commit()

    return None
