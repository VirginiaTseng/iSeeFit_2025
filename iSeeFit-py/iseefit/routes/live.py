from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import sys
from pathlib import Path

# Add parent directory to Python path
parent_dir = Path(__file__).parent.parent
sys.path.append(str(parent_dir))


router = APIRouter(prefix="/live", tags=["live"])

@router.post("/show", response_model=str)
async def show(userId: str):
    
    
    return "Hello, World!"