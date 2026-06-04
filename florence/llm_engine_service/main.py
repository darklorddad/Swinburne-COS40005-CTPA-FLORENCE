from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from config import settings

# Import Feature Routers
from features.nutrition.router import router as nutrition_router
from features.recommendations.router import router as recommendations_router
from features.activity.router import router as activity_router
from features.biometrics.router import router as biometrics_router
from features.insights.router import router as insights_router
from features.simulator.router import router as simulator_router

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
app.include_router(recommendations_router, prefix="/recommendations", tags=["Recommendations"])
app.include_router(activity_router, prefix="/activity", tags=["Activity"])
app.include_router(biometrics_router, prefix="/biometrics", tags=["Biometrics"])
app.include_router(insights_router, prefix="/insights", tags=["Insights"])
app.include_router(simulator_router, prefix="/simulator", tags=["Simulator"])

@app.get("/")
def root():
    return {
        "service": settings.PROJECT_NAME, 
        "version": settings.APP_VERSION,
        "status": "operational",
        "documentation": "/docs"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
