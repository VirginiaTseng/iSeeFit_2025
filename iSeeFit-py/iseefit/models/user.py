"""
User model and related schemas
"""

from sqlalchemy import Column, Integer, String, DateTime, Float, Boolean
from sqlalchemy.orm import relationship
from datetime import datetime
from config.database import Base

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
    
    # Relationships
    meal_records = relationship("MealRecord", back_populates="user")
    workout_records = relationship("WorkoutRecord", back_populates="user")
    weight_records = relationship("WeightRecord", back_populates="user")
    recommendations = relationship("Recommendation", back_populates="user")
