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
    title="Florence Chatbot Service",
    description="AI-powered health chatbot microservice for the Florence Digital Health Platform",
    version="1.0.0",
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
    logger.info("Florence Chatbot Service Starting")
    logger.info("=" * 60)
    logger.info(f"Service URL: http://{settings.service_host}:{settings.service_port}")
    logger.info(f"Data Service URL: {settings.data_service_url}")
    logger.info(f"DeepSeek Model: {settings.deepseek_model}")
    logger.info(f"Health Context Days: {settings.health_context_days}")
    logger.info("=" * 60)


@app.on_event("shutdown")
async def shutdown_event():
    """Run tasks on application shutdown."""
    logger.info("Florence Chatbot Service Shutting Down")


@app.get("/")
async def root():
    """Root endpoint with service information."""
    return {
        "service": "Florence Chatbot Service",
        "version": "1.0.0",
        "status": "operational",
        "endpoints": {
            "chat": "/chat/message",
            "history": "/chat/history",
            "clear_history": "/chat/history (DELETE)",
            "health": "/chat/health",
            "docs": "/docs",
        }
    }


@app.get("/health")
async def health_check():
    """Global health check endpoint."""
    return {
        "status": "healthy",
        "service": "florence-chatbot",
        "version": "1.0.0"
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
