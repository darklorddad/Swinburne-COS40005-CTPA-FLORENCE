from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from config import settings

# --- Feature Imports ---
# As you add features (Chat, Risk, etc.), import their routers here
from features.nutrition.router import router as nutrition_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS - Allow everything for simplicity in this setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Register Routes ---
# This structure keeps main.py clean. 
# It just aggregates modules.
app.include_router(nutrition_router, prefix="/nutrition", tags=["Nutrition"])

@app.get("/")
def root():
    return {
        "service": settings.PROJECT_NAME, 
        "status": "operational",
        "documentation": "/docs"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
