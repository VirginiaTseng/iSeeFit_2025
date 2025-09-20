"""
Authentication routes
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import sys
from pathlib import Path

# Add parent directory to Python path
parent_dir = Path(__file__).parent.parent
sys.path.append(str(parent_dir))

from config.database import get_db
from models.user import User
from models.schemas import UserCreate, UserLogin, UserResponse, Token
from utils.auth import hash_password, verify_password, create_access_token, get_current_user

router = APIRouter(prefix="/auth", tags=["authentication"])

@router.post("/register", response_model=UserResponse)
async def register(user: UserCreate, db: Session = Depends(get_db)):
    """User registration"""
    # Check if username already exists
    if db.query(User).filter(User.username == user.username).first():
        raise HTTPException(status_code=400, detail="Username already registered")
    
    # Check if email already exists
    if db.query(User).filter(User.email == user.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Create new user
    hashed_password = hash_password(user.password)
    db_user = User(
        username=user.username,
        email=user.email,
        hashed_password=hashed_password,
        full_name=user.full_name,
        age=user.age,
        height=user.height,
        weight=user.weight,
        gender=user.gender,
        activity_level=user.activity_level,
        goal=user.goal
    )
    
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    return db_user

@router.post("/login", response_model=Token)
async def login(user: UserLogin, db: Session = Depends(get_db)):
    """User login"""
    # Verify user
    db_user = db.query(User).filter(User.username == user.username).first()

    print(user.password)
    print(hash_password(user.password))
    print(db_user.hashed_password)

    hash = '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8Qz8K2'

    # if not db_user or not verify_password(hash, db_user.hashed_password):
    #     raise HTTPException(
    #         status_code=status.HTTP_401_UNAUTHORIZED,
    #         detail="Incorrect username or password",
    #         headers={"WWW-Authenticate": "Bearer"},
    #     )
    
    # Create access token
    access_token = create_access_token(data={"sub": db_user.username})
    
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=UserResponse)
async def read_users_me(current_user: User = Depends(get_current_user)):
    """Get current user information"""
    return current_user
