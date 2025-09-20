#!/usr/bin/env python3
"""
iSeeFit Database Creation Script
Creates database tables and sample data in English
"""

import os
import sys
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Float, Text, Boolean, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime
import bcrypt

# Database Models
Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(100))
    age = Column(Integer)
    height = Column(Float)  # cm
    weight = Column(Float)  # kg
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
    """Hash password using bcrypt"""
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def create_database():
    """Create database and tables"""
    # Database configuration
    db_host = os.getenv("DB_HOST", "localhost")
    db_port = os.getenv("DB_PORT", "3306")
    db_user = os.getenv("DB_USER", "root")
    db_password = os.getenv("DB_PASSWORD", "nari2008")
    db_name = os.getenv("DB_NAME", "iseefit")
    
    # Build database URL
    DATABASE_URL = f"mysql+pymysql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
    
    print("=== iSeeFit Database Creation ===")
    print(f"Host: {db_host}")
    print(f"Port: {db_port}")
    print(f"User: {db_user}")
    print(f"Database: {db_name}")
    print()
    
    try:
        # Create database engine
        print("Connecting to MySQL...")
        engine = create_engine(DATABASE_URL)
        
        # Test connection
        with engine.connect() as conn:
            print("✅ MySQL connection successful!")
        
        # Create all tables
        print("Creating database tables...")
        Base.metadata.create_all(bind=engine)
        print("✅ Database tables created successfully!")
        
        # Create session
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        db = SessionLocal()
        
        try:
            # Check if data already exists
            existing_user = db.query(User).first()
            if existing_user:
                print("ℹ️  Database already contains data. Skipping sample data creation.")
                return True
            
            # Create sample users
            print("Creating sample users...")
            
            # Test user
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
            
            # Demo user
            demo_user = User(
                username="demouser",
                email="demo@example.com",
                hashed_password=hash_password("demo123"),
                full_name="Demo User",
                age=28,
                height=165.0,
                weight=60.0,
                gender="female",
                activity_level="active",
                goal="lose_weight"
            )
            
            db.add(test_user)
            db.add(demo_user)
            db.flush()  # Get user IDs
            
            # Create sample meal records
            print("Creating sample meal records...")
            sample_meals = [
                # Test user meals
                MealRecord(
                    user_id=test_user.id,
                    meal_type="breakfast",
                    food_name="Oatmeal with Berries",
                    calories=320,
                    protein=15,
                    carbs=55,
                    fat=8,
                    portion_size="1 bowl",
                    notes="Added blueberries and almonds"
                ),
                MealRecord(
                    user_id=test_user.id,
                    meal_type="lunch",
                    food_name="Grilled Chicken Salad",
                    calories=450,
                    protein=35,
                    carbs=20,
                    fat=18,
                    portion_size="1 large bowl",
                    notes="Mixed greens with olive oil dressing"
                ),
                MealRecord(
                    user_id=test_user.id,
                    meal_type="dinner",
                    food_name="Salmon with Vegetables",
                    calories=520,
                    protein=42,
                    carbs=25,
                    fat=22,
                    portion_size="1 fillet",
                    notes="Steamed broccoli and sweet potato"
                ),
                MealRecord(
                    user_id=test_user.id,
                    meal_type="snack",
                    food_name="Greek Yogurt",
                    calories=150,
                    protein=12,
                    carbs=8,
                    fat=5,
                    portion_size="1 cup",
                    notes="Plain Greek yogurt with honey"
                ),
                # Demo user meals
                MealRecord(
                    user_id=demo_user.id,
                    meal_type="breakfast",
                    food_name="Avocado Toast",
                    calories=280,
                    protein=12,
                    carbs=30,
                    fat=12,
                    portion_size="2 slices",
                    notes="Whole grain bread with avocado"
                ),
                MealRecord(
                    user_id=demo_user.id,
                    meal_type="lunch",
                    food_name="Quinoa Bowl",
                    calories=380,
                    protein=18,
                    carbs=45,
                    fat=12,
                    portion_size="1 bowl",
                    notes="With chickpeas and vegetables"
                ),
                MealRecord(
                    user_id=demo_user.id,
                    meal_type="dinner",
                    food_name="Turkey Stir Fry",
                    calories=420,
                    protein=35,
                    carbs=30,
                    fat=15,
                    portion_size="1 plate",
                    notes="With mixed vegetables and brown rice"
                )
            ]
            
            for meal in sample_meals:
                db.add(meal)
            
            # Create sample workout records
            print("Creating sample workout records...")
            sample_workouts = [
                # Test user workouts
                WorkoutRecord(
                    user_id=test_user.id,
                    workout_type="Running",
                    duration_minutes=30,
                    calories_burned=300,
                    intensity="moderate",
                    notes="Morning jog in the park"
                ),
                WorkoutRecord(
                    user_id=test_user.id,
                    workout_type="Weight Training",
                    duration_minutes=45,
                    calories_burned=250,
                    intensity="high",
                    reps=12,
                    sets=3,
                    weight_used=50.0,
                    notes="Chest and back workout"
                ),
                WorkoutRecord(
                    user_id=test_user.id,
                    workout_type="Yoga",
                    duration_minutes=60,
                    calories_burned=150,
                    intensity="low",
                    notes="Evening relaxation session"
                ),
                WorkoutRecord(
                    user_id=test_user.id,
                    workout_type="Swimming",
                    duration_minutes=40,
                    calories_burned=400,
                    intensity="moderate",
                    notes="Freestyle laps"
                ),
                # Demo user workouts
                WorkoutRecord(
                    user_id=demo_user.id,
                    workout_type="HIIT",
                    duration_minutes=25,
                    calories_burned=350,
                    intensity="high",
                    notes="High intensity interval training"
                ),
                WorkoutRecord(
                    user_id=demo_user.id,
                    workout_type="Pilates",
                    duration_minutes=50,
                    calories_burned=200,
                    intensity="moderate",
                    notes="Core strengthening session"
                ),
                WorkoutRecord(
                    user_id=demo_user.id,
                    workout_type="Cycling",
                    duration_minutes=35,
                    calories_burned=280,
                    intensity="moderate",
                    notes="Indoor cycling class"
                )
            ]
            
            for workout in sample_workouts:
                db.add(workout)
            
            # Create sample recommendations
            print("Creating sample recommendations...")
            sample_recommendations = [
                # Test user recommendations
                Recommendation(
                    user_id=test_user.id,
                    recommendation_type="meal",
                    title="Increase Protein Intake",
                    content="Consider adding more protein-rich foods like eggs, Greek yogurt, or lean meats to your breakfast to support muscle maintenance.",
                    priority="medium"
                ),
                Recommendation(
                    user_id=test_user.id,
                    recommendation_type="workout",
                    title="Add Cardio Variety",
                    content="Try incorporating different types of cardio exercises like swimming or cycling to improve cardiovascular health and prevent boredom.",
                    priority="high"
                ),
                Recommendation(
                    user_id=test_user.id,
                    recommendation_type="general",
                    title="Stay Hydrated",
                    content="Remember to drink 8-10 glasses of water daily, especially during and after workouts to maintain proper hydration.",
                    priority="low"
                ),
                # Demo user recommendations
                Recommendation(
                    user_id=demo_user.id,
                    recommendation_type="meal",
                    title="Control Portion Sizes",
                    content="For weight loss goals, consider measuring your food portions to ensure you're in a calorie deficit while still getting adequate nutrition.",
                    priority="high"
                ),
                Recommendation(
                    user_id=demo_user.id,
                    recommendation_type="workout",
                    title="Increase Workout Frequency",
                    content="Aim for at least 4-5 workout sessions per week to maximize your weight loss results and improve overall fitness.",
                    priority="high"
                ),
                Recommendation(
                    user_id=demo_user.id,
                    recommendation_type="general",
                    title="Track Your Progress",
                    content="Keep a consistent record of your meals and workouts to better understand your patterns and make necessary adjustments.",
                    priority="medium"
                )
            ]
            
            for rec in sample_recommendations:
                db.add(rec)
            
            # Commit all changes
            db.commit()
            print("✅ Sample data created successfully!")
            
            # Display summary
            print()
            print("=== Database Summary ===")
            print(f"Users created: 2")
            print(f"Meal records: {len(sample_meals)}")
            print(f"Workout records: {len(sample_workouts)}")
            print(f"Recommendations: {len(sample_recommendations)}")
            print()
            print("Sample users:")
            print("  - testuser / password123")
            print("  - demouser / demo123")
            
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
        print("Please check:")
        print("1. MySQL service is running")
        print("2. Database credentials are correct")
        print("3. You have permission to create databases")
        return False

def main():
    """Main function"""
    success = create_database()
    
    if success:
        print()
        print("🎉 Database creation completed successfully!")
        print()
        print("You can now start the API server:")
        print("  python start_server.py")
        print()
        print("Or with uvicorn:")
        print("  uvicorn main:app --host 0.0.0.0 --port 8000 --reload")
        print()
        print("API Documentation:")
        print("  http://localhost:8000/docs")
    else:
        print()
        print("❌ Database creation failed. Please check the configuration and try again.")
        sys.exit(1)

if __name__ == "__main__":
    main()
