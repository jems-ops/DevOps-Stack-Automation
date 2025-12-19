"""FastAPI main application."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.config import settings
# from app.database import engine, Base
# from app.api.v1 import applications, deployments, environments, auth


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events."""
    # Startup
    print(f"🚀 Starting {settings.APP_NAME} v{settings.APP_VERSION}")
    print(f"📁 Ansible Project Root: {settings.ANSIBLE_PROJECT_ROOT}")

    # TODO: Initialize database
    # async with engine.begin() as conn:
    #     await conn.run_sync(Base.metadata.create_all)

    # TODO: Initialize Redis connection
    # TODO: Start background tasks

    yield

    # Shutdown
    print("👋 Shutting down...")
    # TODO: Cleanup tasks


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="API for deploying SAML SSO integrations to DevOps applications",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
    }


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "message": f"Welcome to {settings.APP_NAME}",
        "version": settings.APP_VERSION,
        "docs": "/docs",
    }


# TODO: Include routers
# app.include_router(
#     applications.router,
#     prefix=f"{settings.API_V1_PREFIX}/applications",
#     tags=["applications"],
# )
# app.include_router(
#     deployments.router,
#     prefix=f"{settings.API_V1_PREFIX}/deployments",
#     tags=["deployments"],
# )
# app.include_router(
#     environments.router,
#     prefix=f"{settings.API_V1_PREFIX}/environments",
#     tags=["environments"],
# )
# app.include_router(
#     auth.router,
#     prefix=f"{settings.API_V1_PREFIX}/auth",
#     tags=["authentication"],
# )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
    )
