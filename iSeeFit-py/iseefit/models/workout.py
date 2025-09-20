"""
Workout record model and related schemas
"""

from sqlalchemy import Column, Integer, String, DateTime, Float, Text, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from config.database import Base

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
    
    # Relationship
    user = relationship("User", back_populates="workout_records")
