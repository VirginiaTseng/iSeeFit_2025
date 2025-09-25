"""
iSeeFit Backend API Main Application
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import sys
from pathlib import Path

# Add parent directory to Python path
parent_dir = Path(__file__).parent.parent
sys.path.append(str(parent_dir))

from config.database import Base, engine
from routes import auth, meals, workouts, recommendations, weight, live, food_analysis

# Create database tables
Base.metadata.create_all(bind=engine)

# Create FastAPI app
app = FastAPI(
    title="iSeeFit Backend API",
    description="AI-powered fitness and nutrition tracking backend",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router)
app.include_router(meals.router)
app.include_router(workouts.router)
app.include_router(recommendations.router)
app.include_router(weight.router)
app.include_router(live.router)
app.include_router(food_analysis.router)

@app.get("/")
async def root():
    return {
        "message": "iSeeFit Backend API",
        "version": "1.0.0",
        "docs": "/docs"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
