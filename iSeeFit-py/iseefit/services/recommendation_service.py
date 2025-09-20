"""
Recommendation service for generating personalized recommendations
"""

import logging
from typing import List
from datetime import datetime, date, timedelta
from sqlalchemy.orm import Session
import sys
from pathlib import Path

# Add parent directory to Python path
parent_dir = Path(__file__).parent.parent
sys.path.append(str(parent_dir))

from models.user import User
from models.meal import MealRecord
from models.workout import WorkoutRecord
from models.recommendation import Recommendation

logger = logging.getLogger(__name__)

class RecommendationService:
    def __init__(self, db: Session):
        self.db = db
    
    def generate_recommendations(self, user: User) -> List[Recommendation]:
        """Generate personalized recommendations for user"""
        recommendations = []
        
        # Get user's recent data
        recent_meals = self._get_recent_meals(user.id, days=7)
        recent_workouts = self._get_recent_workouts(user.id, days=7)
        
        # Generate meal recommendations
        meal_recs = self._generate_meal_recommendations(user, recent_meals)
        recommendations.extend(meal_recs)
        
        # Generate workout recommendations
        workout_recs = self._generate_workout_recommendations(user, recent_workouts)
        recommendations.extend(workout_recs)
        
        # Generate general health recommendations
        general_recs = self._generate_general_recommendations(user, recent_meals, recent_workouts)
        recommendations.extend(general_recs)
        
        # Save recommendations to database
        for rec in recommendations:
            self.db.add(rec)
        
        self.db.commit()
        
        logger.info(f"Generated {len(recommendations)} recommendations for user {user.username}")
        return recommendations
    
    def _get_recent_meals(self, user_id: int, days: int = 7) -> List[MealRecord]:
        """Get user's recent meal records"""
        start_date = datetime.now() - timedelta(days=days)
        return self.db.query(MealRecord).filter(
            MealRecord.user_id == user_id,
            MealRecord.recorded_at >= start_date
        ).all()
    
    def _get_recent_workouts(self, user_id: int, days: int = 7) -> List[WorkoutRecord]:
        """Get user's recent workout records"""
        start_date = datetime.now() - timedelta(days=days)
        return self.db.query(WorkoutRecord).filter(
            WorkoutRecord.user_id == user_id,
            WorkoutRecord.recorded_at >= start_date
        ).all()
    
    def _generate_meal_recommendations(self, user: User, recent_meals: List[MealRecord]) -> List[Recommendation]:
        """Generate meal-related recommendations"""
        recommendations = []
        
        # Calculate daily average calories
        daily_calories = self._calculate_daily_calories(recent_meals)
        target_calories = self._calculate_target_calories(user)
        
        # Calorie intake recommendations
        if daily_calories < target_calories * 0.8:
            recommendations.append(Recommendation(
                user_id=user.id,
                recommendation_type="meal",
                title="Increase Calorie Intake",
                content=f"Your recent daily average calorie intake is {daily_calories:.0f} calories. Consider increasing to {target_calories:.0f} calories to meet your goals.",
                priority="high"
            ))
        elif daily_calories > target_calories * 1.2:
            recommendations.append(Recommendation(
                user_id=user.id,
                recommendation_type="meal",
                title="Control Calorie Intake",
                content=f"Your recent daily average calorie intake is {daily_calories:.0f} calories. Consider reducing to {target_calories:.0f} calories to meet your goals.",
                priority="high"
            ))
        
        # Protein intake recommendations
        daily_protein = self._calculate_daily_protein(recent_meals)
        target_protein = self._calculate_target_protein(user)
        
        if daily_protein < target_protein * 0.8:
            recommendations.append(Recommendation(
                user_id=user.id,
                recommendation_type="meal",
                title="Increase Protein Intake",
                content=f"Consider adding more protein-rich foods like eggs, Greek yogurt, or lean meats. Target daily protein: {target_protein:.0f}g.",
                priority="medium"
            ))
        
        return recommendations
    
    def _generate_workout_recommendations(self, user: User, recent_workouts: List[WorkoutRecord]) -> List[Recommendation]:
        """Generate workout-related recommendations"""
        recommendations = []
        
        # Calculate weekly exercise duration
        weekly_duration = sum(workout.duration_minutes for workout in recent_workouts)
        target_duration = 150  # WHO recommendation: 150 minutes per week
        
        if weekly_duration < target_duration * 0.5:
            recommendations.append(Recommendation(
                user_id=user.id,
                recommendation_type="workout",
                title="Increase Exercise Frequency",
                content=f"Your weekly exercise duration is {weekly_duration} minutes. Aim for at least {target_duration} minutes per week for optimal health.",
                priority="high"
            ))
        elif weekly_duration >= target_duration:
            recommendations.append(Recommendation(
                user_id=user.id,
                recommendation_type="workout",
                title="Maintain Exercise Routine",
                content="Great job! Your exercise routine is excellent. Consider adding variety or increasing intensity for continued progress.",
                priority="low"
            ))
        
        # Exercise variety recommendations
        workout_types = set(workout.workout_type for workout in recent_workouts)
        if len(workout_types) < 2:
            recommendations.append(Recommendation(
                user_id=user.id,
                recommendation_type="workout",
                title="Add Exercise Variety",
                content="Try incorporating different types of exercises like strength training, cardio, and flexibility work for comprehensive fitness.",
                priority="medium"
            ))
        
        return recommendations
    
    def _generate_general_recommendations(self, user: User, recent_meals: List[MealRecord], recent_workouts: List[WorkoutRecord]) -> List[Recommendation]:
        """Generate general health recommendations"""
        recommendations = []
        
        # Hydration recommendation
        recommendations.append(Recommendation(
            user_id=user.id,
            recommendation_type="general",
            title="Stay Hydrated",
            content="Remember to drink 8-10 glasses of water daily, especially during and after workouts.",
            priority="medium"
        ))
        
        # Sleep recommendation
        recommendations.append(Recommendation(
            user_id=user.id,
            recommendation_type="general",
            title="Get Quality Sleep",
            content="Aim for 7-9 hours of quality sleep each night to support recovery and overall health.",
            priority="medium"
        ))
        
        return recommendations
    
    def _calculate_daily_calories(self, meals: List[MealRecord]) -> float:
        """Calculate daily average calorie intake"""
        if not meals:
            return 0
        
        daily_calories = {}
        for meal in meals:
            meal_date = meal.recorded_at.date()
            if meal_date not in daily_calories:
                daily_calories[meal_date] = 0
            daily_calories[meal_date] += meal.calories
        
        return sum(daily_calories.values()) / len(daily_calories) if daily_calories else 0
    
    def _calculate_daily_protein(self, meals: List[MealRecord]) -> float:
        """Calculate daily average protein intake"""
        if not meals:
            return 0
        
        daily_protein = {}
        for meal in meals:
            meal_date = meal.recorded_at.date()
            if meal_date not in daily_protein:
                daily_protein[meal_date] = 0
            daily_protein[meal_date] += meal.protein
        
        return sum(daily_protein.values()) / len(daily_protein) if daily_protein else 0
    
    def _calculate_target_calories(self, user: User) -> float:
        """Calculate target daily calorie intake"""
        if not user.height or not user.weight or not user.age:
            return 2000  # Default value
        
        # Mifflin-St Jeor equation for BMR
        if user.gender == "male":
            bmr = 10 * user.weight + 6.25 * user.height - 5 * user.age + 5
        else:
            bmr = 10 * user.weight + 6.25 * user.height - 5 * user.age - 161
        
        # Activity level multipliers
        activity_multipliers = {
            "sedentary": 1.2,
            "light": 1.375,
            "moderate": 1.55,
            "active": 1.725,
            "very_active": 1.9
        }
        
        multiplier = activity_multipliers.get(user.activity_level, 1.55)
        tdee = bmr * multiplier
        
        # Adjust based on goal
        if user.goal == "lose_weight":
            return tdee * 0.8
        elif user.goal == "gain_weight":
            return tdee * 1.2
        else:
            return tdee
    
    def _calculate_target_protein(self, user: User) -> float:
        """Calculate target daily protein intake"""
        if not user.weight:
            return 60  # Default value
        
        # Protein needs based on goal
        if user.goal == "lose_weight":
            return user.weight * 2.2  # 2.2g/kg
        elif user.goal == "gain_weight":
            return user.weight * 2.0  # 2.0g/kg
        else:
            return user.weight * 1.6  # 1.6g/kg
