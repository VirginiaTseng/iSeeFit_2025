"""
个性化推荐引擎
基于用户数据生成饮食和健身推荐
"""

import logging
from typing import List, Dict, Any
from datetime import datetime, date, timedelta
from sqlalchemy.orm import Session
import random

from main import User, MealRecord, WorkoutRecord, Recommendation

logger = logging.getLogger(__name__)

class RecommendationEngine:
    def __init__(self, db: Session):
        self.db = db
    
    def generate_recommendations(self, user: User) -> List[Recommendation]:
        """为用户生成个性化推荐"""
        recommendations = []
        
        # 获取用户最近的数据
        recent_meals = self._get_recent_meals(user.id, days=7)
        recent_workouts = self._get_recent_workouts(user.id, days=7)
        
        # 生成饮食推荐
        meal_recs = self._generate_meal_recommendations(user, recent_meals)
        recommendations.extend(meal_recs)
        
        # 生成健身推荐
        workout_recs = self._generate_workout_recommendations(user, recent_workouts)
        recommendations.extend(workout_recs)
        
        # 生成一般性健康建议
        general_recs = self._generate_general_recommendations(user, recent_meals, recent_workouts)
        recommendations.extend(general_recs)
        
        # 保存推荐到数据库
        for rec in recommendations:
            self.db.add(rec)
        
        self.db.commit()
        
        logger.info(f"Generated {len(recommendations)} recommendations for user {user.username}")
        return recommendations
    
    def _get_recent_meals(self, user_id: int, days: int = 7) -> List[MealRecord]:
        """获取用户最近的饮食记录"""
        start_date = datetime.now() - timedelta(days=days)
        return self.db.query(MealRecord).filter(
            MealRecord.user_id == user_id,
            MealRecord.recorded_at >= start_date
        ).all()
    
    def _get_recent_workouts(self, user_id: int, days: int = 7) -> List[WorkoutRecord]:
        """获取用户最近的健身记录"""
        start_date = datetime.now() - timedelta(days=days)
        return self.db.query(WorkoutRecord).filter(
            WorkoutRecord.user_id == user_id,
            WorkoutRecord.recorded_at >= start_date
        ).all()
    
    def _generate_meal_recommendations(self, user: User, recent_meals: List[MealRecord]) -> List[Recommendation]:
        """生成饮食推荐"""
        recommendations = []
        
        # 计算每日平均卡路里摄入
        daily_calories = self._calculate_daily_calories(recent_meals)
        target_calories = self._calculate_target_calories(user)
        
        # 卡路里摄入建议
        if daily_calories < target_calories * 0.8:
            recommendations.append(Recommendation(
                user_id=user.id,
                recommendation_type="meal",
                title="增加卡路里摄入",
                content=f"您最近的每日平均卡路里摄入为 {daily_calories:.0f} 卡，建议增加到 {target_calories:.0f} 卡以达到目标。",
                priority="high"
            ))
        elif daily_calories > target_calories * 1.2:
            recommendations.append(Recommendation(
                user_id=user.id,
                recommendation_type="meal",
                title="控制卡路里摄入",
                content=f"您最近的每日平均卡路里摄入为 {daily_calories:.0f} 卡，建议控制在 {target_calories:.0f} 卡以内。",
                priority="high"
            ))
        
        # 蛋白质摄入建议
        daily_protein = self._calculate_daily_protein(recent_meals)
        target_protein = self._calculate_target_protein(user)
        
        if daily_protein < target_protein * 0.8:
            recommendations.append(Recommendation(
                user_id=user.id,
                recommendation_type="meal",
                title="增加蛋白质摄入",
                content=f"建议增加富含蛋白质的食物，如鸡胸肉、鱼类、豆类等，目标每日 {target_protein:.0f}g 蛋白质。",
                priority="medium"
            ))
        
        # 餐次分布建议
        meal_distribution = self._analyze_meal_distribution(recent_meals)
        if meal_distribution.get("breakfast", 0) < 0.2:
            recommendations.append(Recommendation(
                user_id=user.id,
                recommendation_type="meal",
                title="重视早餐",
                content="建议每天吃营养丰富的早餐，有助于提高新陈代谢和保持血糖稳定。",
                priority="medium"
            ))
        
        return recommendations
    
    def _generate_workout_recommendations(self, user: User, recent_workouts: List[WorkoutRecord]) -> List[Recommendation]:
        """生成健身推荐"""
        recommendations = []
        
        # 计算每周运动时长
        weekly_duration = sum(workout.duration_minutes for workout in recent_workouts)
        target_duration = 150  # 世界卫生组织建议每周150分钟中等强度运动
        
        if weekly_duration < target_duration * 0.5:
            recommendations.append(Recommendation(
                user_id=user.id,
                recommendation_type="workout",
                title="增加运动量",
                content=f"建议每周进行至少 {target_duration} 分钟的中等强度运动，您目前为 {weekly_duration} 分钟。",
                priority="high"
            ))
        elif weekly_duration >= target_duration:
            recommendations.append(Recommendation(
                user_id=user.id,
                recommendation_type="workout",
                title="保持运动习惯",
                content="您的运动量很好！建议继续保持规律运动，可以尝试增加运动强度或尝试新的运动类型。",
                priority="low"
            ))
        
        # 运动类型多样性建议
        workout_types = set(workout.workout_type for workout in recent_workouts)
        if len(workout_types) < 2:
            recommendations.append(Recommendation(
                user_id=user.id,
                recommendation_type="workout",
                title="增加运动多样性",
                content="建议尝试不同类型的运动，如力量训练、有氧运动、柔韧性训练等，以获得全面的健康益处。",
                priority="medium"
            ))
        
        # 运动强度建议
        high_intensity_count = sum(1 for workout in recent_workouts if workout.intensity == "high")
        if high_intensity_count == 0 and weekly_duration > 100:
            recommendations.append(Recommendation(
                user_id=user.id,
                recommendation_type="workout",
                title="增加高强度运动",
                content="建议每周进行1-2次高强度间歇训练(HIIT)，有助于提高心肺功能和燃烧更多卡路里。",
                priority="medium"
            ))
        
        return recommendations
    
    def _generate_general_recommendations(self, user: User, recent_meals: List[MealRecord], recent_workouts: List[WorkoutRecord]) -> List[Recommendation]:
        """生成一般性健康建议"""
        recommendations = []
        
        # 水合作用建议
        recommendations.append(Recommendation(
            user_id=user.id,
            recommendation_type="general",
            title="保持充足水分",
            content="建议每天饮用8-10杯水，运动时更要注意补充水分。",
            priority="medium"
        ))
        
        # 睡眠建议
        recommendations.append(Recommendation(
            user_id=user.id,
            recommendation_type="general",
            title="保证充足睡眠",
            content="建议每晚7-9小时优质睡眠，有助于恢复和维持健康。",
            priority="medium"
        ))
        
        # 压力管理建议
        if len(recent_workouts) < 3:
            recommendations.append(Recommendation(
                user_id=user.id,
                recommendation_type="general",
                title="运动减压",
                content="规律运动是缓解压力的有效方法，建议每周至少3次运动。",
                priority="low"
            ))
        
        return recommendations
    
    def _calculate_daily_calories(self, meals: List[MealRecord]) -> float:
        """计算每日平均卡路里摄入"""
        if not meals:
            return 0
        
        # 按日期分组
        daily_calories = {}
        for meal in meals:
            meal_date = meal.recorded_at.date()
            if meal_date not in daily_calories:
                daily_calories[meal_date] = 0
            daily_calories[meal_date] += meal.calories
        
        return sum(daily_calories.values()) / len(daily_calories) if daily_calories else 0
    
    def _calculate_daily_protein(self, meals: List[MealRecord]) -> float:
        """计算每日平均蛋白质摄入"""
        if not meals:
            return 0
        
        # 按日期分组
        daily_protein = {}
        for meal in meals:
            meal_date = meal.recorded_at.date()
            if meal_date not in daily_protein:
                daily_protein[meal_date] = 0
            daily_protein[meal_date] += meal.protein
        
        return sum(daily_protein.values()) / len(daily_protein) if daily_protein else 0
    
    def _calculate_target_calories(self, user: User) -> float:
        """计算目标卡路里摄入"""
        if not user.height or not user.weight or not user.age:
            return 2000  # 默认值
        
        # 使用 Mifflin-St Jeor 公式计算基础代谢率
        if user.gender == "male":
            bmr = 10 * user.weight + 6.25 * user.height - 5 * user.age + 5
        else:
            bmr = 10 * user.weight + 6.25 * user.height - 5 * user.age - 161
        
        # 根据活动水平调整
        activity_multipliers = {
            "sedentary": 1.2,
            "light": 1.375,
            "moderate": 1.55,
            "active": 1.725,
            "very_active": 1.9
        }
        
        multiplier = activity_multipliers.get(user.activity_level, 1.55)
        tdee = bmr * multiplier
        
        # 根据目标调整
        if user.goal == "lose_weight":
            return tdee * 0.8
        elif user.goal == "gain_weight":
            return tdee * 1.2
        else:
            return tdee
    
    def _calculate_target_protein(self, user: User) -> float:
        """计算目标蛋白质摄入"""
        if not user.weight:
            return 60  # 默认值
        
        # 根据目标调整蛋白质需求
        if user.goal == "lose_weight":
            return user.weight * 2.2  # 2.2g/kg
        elif user.goal == "gain_weight":
            return user.weight * 2.0  # 2.0g/kg
        else:
            return user.weight * 1.6  # 1.6g/kg
    
    def _analyze_meal_distribution(self, meals: List[MealRecord]) -> Dict[str, float]:
        """分析餐次分布"""
        meal_calories = {"breakfast": 0, "lunch": 0, "dinner": 0, "snack": 0}
        
        for meal in meals:
            if meal.meal_type in meal_calories:
                meal_calories[meal.meal_type] += meal.calories
        
        total_calories = sum(meal_calories.values())
        if total_calories > 0:
            return {meal_type: calories / total_calories for meal_type, calories in meal_calories.items()}
        
        return meal_calories

def get_recommendations_for_user(user_id: int, db: Session) -> List[Recommendation]:
    """获取用户的推荐"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return []
    
    engine = RecommendationEngine(db)
    return engine.generate_recommendations(user)
