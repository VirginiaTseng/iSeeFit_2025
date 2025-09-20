#!/usr/bin/env python3
"""
数据库初始化脚本
创建数据库表和初始数据
"""

import os
import sys
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from datetime import datetime

# 添加当前目录到 Python 路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from main import Base, User, MealRecord, WorkoutRecord, Recommendation, hash_password

def init_database():
    """初始化数据库"""
    # 数据库配置 - 从环境变量或用户输入获取
    db_host = os.getenv("DB_HOST", "localhost")
    db_port = os.getenv("DB_PORT", "3306")
    db_user = os.getenv("DB_USER", "root")
    db_password = os.getenv("DB_PASSWORD","nari2008")
    db_name = os.getenv("DB_NAME", "iseefit")
    
    # 如果没有设置密码，提示用户输入
    if not db_password:
        import getpass
        db_password = getpass.getpass("请输入 MySQL root 密码: ")
    
    # 构建数据库 URL
    DATABASE_URL = f"mysql+pymysql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
    
    print(f"Connecting to database: mysql+pymysql://{db_user}:***@{db_host}:{db_port}/{db_name}")
    
    # 创建数据库引擎
    engine = create_engine(DATABASE_URL)
    
    # 创建所有表
    print("Creating database tables...")
    Base.metadata.create_all(bind=engine)
    print("Database tables created successfully!")
    
    # 创建会话
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()
    
    try:
        # 检查是否已有用户数据
        existing_user = db.query(User).first()
        if existing_user:
            print("Database already contains user data. Skipping sample data creation.")
            return
        
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
        print("Sample data created successfully!")
        
    except Exception as e:
        print(f"Error creating sample data: {e}")
        db.rollback()
        raise
    finally:
        db.close()

def create_database():
    """创建数据库（如果不存在）"""
    import pymysql
    
    # 从环境变量获取数据库配置
    db_host = os.getenv("DB_HOST", "localhost")
    db_port = int(os.getenv("DB_PORT", "3306"))
    db_user = os.getenv("DB_USER", "root")
    db_password = os.getenv("DB_PASSWORD", "password")
    db_name = os.getenv("DB_NAME", "iseefit")
    
    try:
        # 连接到 MySQL 服务器
        connection = pymysql.connect(
            host=db_host,
            port=db_port,
            user=db_user,
            password=db_password,
            charset='utf8mb4'
        )
        
        with connection.cursor() as cursor:
            # 创建数据库
            cursor.execute(f"CREATE DATABASE IF NOT EXISTS {db_name} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
            print(f"Database '{db_name}' created or already exists")
        
        connection.close()
        
    except Exception as e:
        print(f"Error creating database: {e}")
        print("Please make sure MySQL is running and credentials are correct")
        raise

if __name__ == "__main__":
    print("Initializing iSeeFit database...")
    
    # 创建数据库
    create_database()
    
    # 初始化数据库表和数据
    init_database()
    
    print("Database initialization completed!")
    print("\nYou can now start the API server with:")
    print("python main.py")
    print("\nOr with uvicorn:")
    print("uvicorn main:app --host 0.0.0.0 --port 8000 --reload")
