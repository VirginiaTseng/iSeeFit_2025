#!/usr/bin/env python3
"""
iSeeFit Backend API Server
支持用户登录、饮食/健身打卡记录、图片处理和个性化推荐
"""

from fastapi import FastAPI, HTTPException, Depends, status, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Float, Text, Boolean, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session, relationship
from pydantic import BaseModel, EmailStr
from datetime import datetime, date, timedelta
from typing import List, Optional
import jwt
import bcrypt
import os
from PIL import Image
import io
import base64
import logging
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

# 导入路由
from routes.meals import router as meal_router
from routes.workouts import router as workout_router
from routes.recommendations import router as recommendation_router
from routes.weight import router as weight_router
from routes.live import router as live_router
# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 数据库配置
def get_database_url():
    """获取数据库连接 URL"""
    db_host = os.getenv("DB_HOST", "localhost")
    db_port = os.getenv("DB_PORT", "3306")
    db_user = os.getenv("DB_USER", "root")
    db_password = os.getenv("DB_PASSWORD", "password")
    db_name = os.getenv("DB_NAME", "iseefit")
    
    return f"mysql+pymysql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"

DATABASE_URL = get_database_url()
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# JWT 配置
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-here")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# FastAPI 应用
app = FastAPI(title="iSeeFit Backend API", version="1.0.0")

# CORS 配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 生产环境中应该限制具体域名
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由
app.include_router(meal_router)
app.include_router(workout_router)
app.include_router(recommendation_router)
app.include_router(weight_router)
app.include_router(live_router)
# 安全配置
security = HTTPBearer()

# 数据库模型
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(100))
    age = Column(Integer)
    height = Column(Float)  # 厘米
    weight = Column(Float)  # 公斤
    gender = Column(String(10))
    activity_level = Column(String(20))  # sedentary, light, moderate, active, very_active
    goal = Column(String(20))  # lose_weight, maintain, gain_weight
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)
    
    # 关系
    meal_records = relationship("MealRecord", back_populates="user")
    workout_records = relationship("WorkoutRecord", back_populates="user")
    recommendations = relationship("Recommendation", back_populates="user")

class MealRecord(Base):
    __tablename__ = "meal_records"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    meal_type = Column(String(20), nullable=False)  # breakfast, lunch, dinner, snack
    food_name = Column(String(200), nullable=False)
    calories = Column(Float, nullable=False)
    protein = Column(Float, default=0)
    carbs = Column(Float, default=0)
    fat = Column(Float, default=0)
    portion_size = Column(String(100))
    image_path = Column(String(500))
    notes = Column(Text)
    recorded_at = Column(DateTime, default=datetime.utcnow)
    
    # 关系
    user = relationship("User", back_populates="meal_records")

class WorkoutRecord(Base):
    __tablename__ = "workout_records"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    workout_type = Column(String(100), nullable=False)
    duration_minutes = Column(Integer, nullable=False)
    calories_burned = Column(Float, nullable=False)
    intensity = Column(String(20))  # low, moderate, high
    reps = Column(Integer)
    sets = Column(Integer)
    weight_used = Column(Float)
    image_path = Column(String(500))
    notes = Column(Text)
    recorded_at = Column(DateTime, default=datetime.utcnow)
    
    # 关系
    user = relationship("User", back_populates="workout_records")

class Recommendation(Base):
    __tablename__ = "recommendations"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    recommendation_type = Column(String(50), nullable=False)  # meal, workout, general
    title = Column(String(200), nullable=False)
    content = Column(Text, nullable=False)
    priority = Column(String(20), default="medium")  # low, medium, high
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # 关系
    user = relationship("User", back_populates="recommendations")

# Pydantic 模型
class UserCreate(BaseModel):
    username: str
    email: EmailStr
    password: str
    full_name: Optional[str] = None
    age: Optional[int] = None
    height: Optional[float] = None
    weight: Optional[float] = None
    gender: Optional[str] = None
    activity_level: Optional[str] = "moderate"
    goal: Optional[str] = "maintain"

class UserLogin(BaseModel):
    username: str
    password: str

class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    full_name: Optional[str]
    age: Optional[int]
    height: Optional[float]
    weight: Optional[float]
    gender: Optional[str]
    activity_level: Optional[str]
    goal: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True

class MealRecordCreate(BaseModel):
    meal_type: str
    food_name: str
    calories: float
    protein: Optional[float] = 0
    carbs: Optional[float] = 0
    fat: Optional[float] = 0
    portion_size: Optional[str] = None
    notes: Optional[str] = None

class MealRecordResponse(BaseModel):
    id: int
    meal_type: str
    food_name: str
    calories: float
    protein: float
    carbs: float
    fat: float
    portion_size: Optional[str]
    image_path: Optional[str]
    notes: Optional[str]
    recorded_at: datetime
    
    class Config:
        from_attributes = True

class WorkoutRecordCreate(BaseModel):
    workout_type: str
    duration_minutes: int
    calories_burned: float
    intensity: Optional[str] = "moderate"
    reps: Optional[int] = None
    sets: Optional[int] = None
    weight_used: Optional[float] = None
    notes: Optional[str] = None

class WorkoutRecordResponse(BaseModel):
    id: int
    workout_type: str
    duration_minutes: int
    calories_burned: float
    intensity: Optional[str]
    reps: Optional[int]
    sets: Optional[int]
    weight_used: Optional[float]
    image_path: Optional[str]
    notes: Optional[str]
    recorded_at: datetime
    
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

# 数据库依赖
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 认证依赖
def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security), db: Session = Depends(get_db)):
    token = credentials.credentials
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )
    except jwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user = db.query(User).filter(User.username == username).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user

# 工具函数
def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def save_image(file: UploadFile, user_id: int, record_type: str) -> str:
    """保存上传的图片并返回路径"""
    try:
        # 创建用户目录
        upload_dir = f"uploads/{user_id}/{record_type}"
        os.makedirs(upload_dir, exist_ok=True)
        
        # 生成文件名
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{record_type}_{timestamp}_{file.filename}"
        file_path = os.path.join(upload_dir, filename)
        
        # 保存文件
        with open(file_path, "wb") as buffer:
            content = file.file.read()
            buffer.write(content)
        
        # 压缩图片
        with Image.open(file_path) as img:
            img.thumbnail((800, 600), Image.Resampling.LANCZOS)
            img.save(file_path, "JPEG", quality=85)
        
        return file_path
    except Exception as e:
        logger.error(f"Error saving image: {e}")
        raise HTTPException(status_code=500, detail="Failed to save image")

# API 端点
@app.get("/")
async def root():
    return {"message": "iSeeFit Backend API", "version": "1.0.0"}

@app.post("/auth/register", response_model=UserResponse)
async def register(user: UserCreate, db: Session = Depends(get_db)):
    """用户注册"""
    # 检查用户名是否已存在
    if db.query(User).filter(User.username == user.username).first():
        raise HTTPException(status_code=400, detail="Username already registered")
    
    # 检查邮箱是否已存在
    if db.query(User).filter(User.email == user.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # 创建新用户
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
    
    logger.info(f"New user registered: {user.username}")
    return db_user

@app.post("/auth/login", response_model=Token)
async def login(user: UserLogin, db: Session = Depends(get_db)):
    """用户登录"""
    # 验证用户
    db_user = db.query(User).filter(User.username == user.username).first()
    if not db_user or not verify_password(user.password, db_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # 创建访问令牌
    access_token = create_access_token(data={"sub": db_user.username})
    
    logger.info(f"User logged in: {user.username}")
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/auth/me", response_model=UserResponse)
async def read_users_me(current_user: User = Depends(get_current_user)):
    """获取当前用户信息"""
    return current_user

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
