"""
Pydantic schemas for request/response models
"""

from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional, List

# User schemas
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

# Meal record schemas
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

# Workout record schemas
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

# Recommendation schemas
class RecommendationResponse(BaseModel):
    id: int
    recommendation_type: str
    title: str
    content: str
    priority: str
    is_read: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

# Token schema
class Token(BaseModel):
    access_token: str
    token_type: str

# Statistics schemas
class DailyMealStats(BaseModel):
    date: str
    total_calories: float
    total_protein: float
    total_carbs: float
    total_fat: float
    meal_count: int
    meal_stats: dict

class DailyWorkoutStats(BaseModel):
    date: str
    total_duration_minutes: int
    total_calories_burned: float
    workout_count: int
    workout_stats: dict

class WeeklyStats(BaseModel):
    start_date: str
    end_date: str
    daily_stats: dict
    averages: dict
