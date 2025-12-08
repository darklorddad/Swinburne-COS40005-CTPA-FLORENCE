from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from config import settings

# Import Feature Routers
from features.nutrition.router import router as nutrition_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.APP_VERSION,
    docs_url="/docs",
    redoc_url="/redoc"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register Features
app.include_router(nutrition_router, prefix="/nutrition", tags=["Nutrition"])

@app.get("/")
def root():
    return {
        "service": settings.PROJECT_NAME, 
        "version": settings.APP_VERSION,
        "env": settings.APP_ENV,
        "status": "operational"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
