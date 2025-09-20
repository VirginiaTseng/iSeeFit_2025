#!/usr/bin/env python3
"""
简化的数据库初始化脚本
"""

import os
import sys
import getpass
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Float, Text, Boolean, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime
import bcrypt

# 数据库模型定义
Base = declarative_base()

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

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def init_database():
    """初始化数据库"""
    # 数据库配置
    db_host = os.getenv("DB_HOST", "localhost")
    db_port = os.getenv("DB_PORT", "3306")
    db_user = os.getenv("DB_USER", "root")
    db_password = os.getenv("DB_PASSWORD")
    db_name = os.getenv("DB_NAME", "iseefit")
    
    # 如果没有设置密码，提示用户输入
    if not db_password:
        db_password = getpass.getpass("请输入 MySQL root 密码: ")
    
    # 构建数据库 URL
    DATABASE_URL = f"mysql+pymysql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
    
    print(f"Connecting to database: mysql+pymysql://{db_user}:***@{db_host}:{db_port}/{db_name}")
    
    try:
        # 创建数据库引擎
        engine = create_engine(DATABASE_URL)
        
        # 创建所有表
        print("Creating database tables...")
        Base.metadata.create_all(bind=engine)
        print("✅ Database tables created successfully!")
        
        # 创建会话
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        db = SessionLocal()
        
        try:
            # 检查是否已有用户数据
            existing_user = db.query(User).first()
            if existing_user:
                print("ℹ️  Database already contains user data. Skipping sample data creation.")
                return True
            
            # 创建示例用户
            print("Creating sample users...")
            
            # 创建测试用户
            test_user = User(
                username="testuser",
                email="test@example.com",
                hashed_password=hash_password("password123"),
                full_name="Test User",
                age=25,
                height=170.0,
                weight=70.0,
                gender="male",
                activity_level="moderate",
                goal="maintain"
            )
            
            db.add(test_user)
            db.flush()  # 获取用户ID
            
            # 创建示例饮食记录
            print("Creating sample meal records...")
            sample_meals = [
                MealRecord(
                    user_id=test_user.id,
                    meal_type="breakfast",
                    food_name="燕麦粥",
                    calories=300,
                    protein=12,
                    carbs=45,
                    fat=8,
                    portion_size="1碗",
                    notes="加了蓝莓和坚果"
                ),
                MealRecord(
                    user_id=test_user.id,
                    meal_type="lunch",
                    food_name="鸡胸肉沙拉",
                    calories=450,
                    protein=35,
                    carbs=20,
                    fat=15,
                    portion_size="1份",
                    notes="蔬菜丰富"
                ),
                MealRecord(
                    user_id=test_user.id,
                    meal_type="dinner",
                    food_name="三文鱼配蔬菜",
                    calories=500,
                    protein=40,
                    carbs=25,
                    fat=20,
                    portion_size="1份",
                    notes="蒸煮方式"
                )
            ]
            
            for meal in sample_meals:
                db.add(meal)
            
            # 创建示例健身记录
            print("Creating sample workout records...")
            sample_workouts = [
                WorkoutRecord(
                    user_id=test_user.id,
                    workout_type="跑步",
                    duration_minutes=30,
                    calories_burned=300,
                    intensity="moderate",
                    notes="晨跑"
                ),
                WorkoutRecord(
                    user_id=test_user.id,
                    workout_type="力量训练",
                    duration_minutes=45,
                    calories_burned=250,
                    intensity="high",
                    reps=12,
                    sets=3,
                    weight_used=50.0,
                    notes="胸部和背部训练"
                ),
                WorkoutRecord(
                    user_id=test_user.id,
                    workout_type="瑜伽",
                    duration_minutes=60,
                    calories_burned=150,
                    intensity="low",
                    notes="放松瑜伽"
                )
            ]
            
            for workout in sample_workouts:
                db.add(workout)
            
            # 创建示例推荐
            print("Creating sample recommendations...")
            sample_recommendations = [
                Recommendation(
                    user_id=test_user.id,
                    recommendation_type="meal",
                    title="增加蛋白质摄入",
                    content="建议在早餐中添加鸡蛋或希腊酸奶，以增加蛋白质摄入量。",
                    priority="medium"
                ),
                Recommendation(
                    user_id=test_user.id,
                    recommendation_type="workout",
                    title="增加有氧运动",
                    content="建议每周增加2-3次有氧运动，如游泳或骑自行车。",
                    priority="high"
                ),
                Recommendation(
                    user_id=test_user.id,
                    recommendation_type="general",
                    title="保持充足水分",
                    content="建议每天饮用8-10杯水，运动时更要注意补充水分。",
                    priority="low"
                )
            ]
            
            for rec in sample_recommendations:
                db.add(rec)
            
            # 提交所有更改
            db.commit()
            print("✅ Sample data created successfully!")
            return True
            
        except Exception as e:
            print(f"❌ Error creating sample data: {e}")
            db.rollback()
            return False
        finally:
            db.close()
            
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        print()
        print("请检查：")
        print("1. MySQL 服务是否正在运行")
        print("2. 数据库用户名和密码是否正确")
        print("3. 是否有权限创建数据库")
        return False

def main():
    """主函数"""
    print("=== iSeeFit 数据库初始化 ===")
    print()
    
    # 设置环境变量（如果需要）
    if not os.getenv("DB_PASSWORD"):
        print("请设置数据库密码环境变量：")
        print("export DB_PASSWORD=your_mysql_password")
        print()
        print("或者直接运行此脚本，会提示输入密码")
        print()
    
    success = init_database()
    
    if success:
        print()
        print("🎉 数据库初始化完成！")
        print()
        print("现在你可以启动 API 服务器：")
        print("  python start_server.py")
        print()
        print("或者使用 uvicorn：")
        print("  uvicorn main:app --host 0.0.0.0 --port 8000 --reload")
        print()
        print("API 文档地址：")
        print("  http://localhost:8000/docs")
    else:
        print()
        print("❌ 数据库初始化失败，请检查配置后重试")
        sys.exit(1)

if __name__ == "__main__":
    main()
