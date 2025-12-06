"""
Florence Chatbot Microservice

A dedicated multi-tenant Python service for AI-powered health chatbot functionality.
This service handles chat logic and LLM interaction while maintaining strict user isolation.
"""
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from config import settings
from routers import chat_router

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Create FastAPI application
app = FastAPI(
    title="Florence LLM Chatbot Service",
    version=settings.app_version,
    docs_url="/docs",
    redoc_url="/redoc",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(chat_router)


@app.on_event("startup")
async def startup_event():
    """Run tasks on application startup."""
    logger.info("=" * 60)
    logger.info("Florence LLM Chatbot Service Starting")
    logger.info("=" * 60)
    logger.info(f"Service URL: http://{settings.service_host}:{settings.service_port}")
    logger.info(f"Data Service URL: {settings.data_service_url}")
    logger.info(f"LLM Model: {settings.llm_model}")
    logger.info("=" * 60)


@app.on_event("shutdown")
async def shutdown_event():
    """Run tasks on application shutdown."""
    logger.info("Florence LLM Chatbot Service Shutting Down")


@app.get("/")
async def root():
    """Root endpoint with service information."""
    return {
        "service": "Florence LLM Chatbot Service",
        "version": settings.app_version,
        "status": "operational",
        "documentation": "/docs"
    }


@app.get("/health")
async def health_check():
    """Global health check endpoint."""
    return {
        "status": "healthy",
        "service": "florence-llm-chatbot-service",
        "version": settings.app_version
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host=settings.service_host,
        port=settings.service_port,
        reload=True,
        log_level="info"
    )
