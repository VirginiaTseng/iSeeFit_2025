"""
饮食记录相关的 API 路由
"""

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, date
import logging

import sys
from pathlib import Path

# Add parent directory to Python path
parent_dir = Path(__file__).parent.parent
sys.path.append(str(parent_dir))

from config.database import get_db
from models.user import User
from models.meal import MealRecord
from models.schemas import MealRecordCreate, MealRecordResponse
from utils.auth import get_current_user
from utils.image import save_image

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/meals", tags=["meals"])

@router.post("/", response_model=MealRecordResponse)
async def create_meal_record(
    meal_type: str = Form(...),
    food_name: str = Form(...),
    calories: float = Form(...),
    protein: float = Form(0),
    carbs: float = Form(0),
    fat: float = Form(0),
    portion_size: Optional[str] = Form(None),
    notes: Optional[str] = Form(None),
    image: Optional[UploadFile] = File(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """创建饮食记录"""
    try:
        # 保存图片
        image_path = None
        if image:
            image_path = save_image(image, current_user.id, "meal")
        
        # 创建记录
        db_meal = MealRecord(
            user_id=current_user.id,
            meal_type=meal_type,
            food_name=food_name,
            calories=calories,
            protein=protein,
            carbs=carbs,
            fat=fat,
            portion_size=portion_size,
            image_path=image_path,
            notes=notes
        )
        
        db.add(db_meal)
        db.commit()
        db.refresh(db_meal)
        
        logger.info(f"Meal record created for user {current_user.username}: {food_name}")
        return db_meal
        
    except Exception as e:
        logger.error(f"Error creating meal record: {e}")
        raise HTTPException(status_code=500, detail="Failed to create meal record")

@router.get("/", response_model=List[MealRecordResponse])
async def get_meal_records(
    date_filter: Optional[date] = None,
    meal_type: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取用户的饮食记录"""
    query = db.query(MealRecord).filter(MealRecord.user_id == current_user.id)
    
    if date_filter:
        query = query.filter(MealRecord.recorded_at >= date_filter)
        query = query.filter(MealRecord.recorded_at < date_filter.replace(day=date_filter.day + 1))
    
    if meal_type:
        query = query.filter(MealRecord.meal_type == meal_type)
    
    records = query.order_by(MealRecord.recorded_at.desc()).offset(offset).limit(limit).all()
    return records

@router.get("/today", response_model=List[MealRecordResponse])
async def get_today_meal_records(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取今天的饮食记录"""
    today = date.today()
    records = db.query(MealRecord).filter(
        MealRecord.user_id == current_user.id,
        MealRecord.recorded_at >= today,
        MealRecord.recorded_at < today.replace(day=today.day + 1)
    ).order_by(MealRecord.recorded_at.desc()).all()
    
    return records

@router.get("/stats/daily")
async def get_daily_meal_stats(
    target_date: Optional[date] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取每日饮食统计"""
    if not target_date:
        target_date = date.today()
    
    records = db.query(MealRecord).filter(
        MealRecord.user_id == current_user.id,
        MealRecord.recorded_at >= target_date,
        MealRecord.recorded_at < target_date.replace(day=target_date.day + 1)
    ).all()
    
    total_calories = sum(record.calories for record in records)
    total_protein = sum(record.protein for record in records)
    total_carbs = sum(record.carbs for record in records)
    total_fat = sum(record.fat for record in records)
    
    # 按餐次分组
    meal_stats = {}
    for record in records:
        if record.meal_type not in meal_stats:
            meal_stats[record.meal_type] = {
                "calories": 0,
                "protein": 0,
                "carbs": 0,
                "fat": 0,
                "count": 0
            }
        
        meal_stats[record.meal_type]["calories"] += record.calories
        meal_stats[record.meal_type]["protein"] += record.protein
        meal_stats[record.meal_type]["carbs"] += record.carbs
        meal_stats[record.meal_type]["fat"] += record.fat
        meal_stats[record.meal_type]["count"] += 1
    
    return {
        "date": target_date,
        "total_calories": total_calories,
        "total_protein": total_protein,
        "total_carbs": total_carbs,
        "total_fat": total_fat,
        "meal_count": len(records),
        "meal_stats": meal_stats
    }

@router.get("/stats/weekly")
async def get_weekly_meal_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取每周饮食统计"""
    from datetime import timedelta
    
    end_date = date.today()
    start_date = end_date - timedelta(days=6)
    
    records = db.query(MealRecord).filter(
        MealRecord.user_id == current_user.id,
        MealRecord.recorded_at >= start_date,
        MealRecord.recorded_at <= end_date
    ).all()
    
    # 按日期分组
    daily_stats = {}
    for record in records:
        record_date = record.recorded_at.date()
        if record_date not in daily_stats:
            daily_stats[record_date] = {
                "calories": 0,
                "protein": 0,
                "carbs": 0,
                "fat": 0,
                "meal_count": 0
            }
        
        daily_stats[record_date]["calories"] += record.calories
        daily_stats[record_date]["protein"] += record.protein
        daily_stats[record_date]["carbs"] += record.carbs
        daily_stats[record_date]["fat"] += record.fat
        daily_stats[record_date]["meal_count"] += 1
    
    # 计算平均值
    total_days = len(daily_stats)
    avg_calories = sum(stats["calories"] for stats in daily_stats.values()) / total_days if total_days > 0 else 0
    avg_protein = sum(stats["protein"] for stats in daily_stats.values()) / total_days if total_days > 0 else 0
    avg_carbs = sum(stats["carbs"] for stats in daily_stats.values()) / total_days if total_days > 0 else 0
    avg_fat = sum(stats["fat"] for stats in daily_stats.values()) / total_days if total_days > 0 else 0
    
    return {
        "start_date": start_date,
        "end_date": end_date,
        "daily_stats": daily_stats,
        "averages": {
            "calories": avg_calories,
            "protein": avg_protein,
            "carbs": avg_carbs,
            "fat": avg_fat
        }
    }

@router.delete("/{meal_id}")
async def delete_meal_record(
    meal_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """删除饮食记录"""
    meal = db.query(MealRecord).filter(
        MealRecord.id == meal_id,
        MealRecord.user_id == current_user.id
    ).first()
    
    if not meal:
        raise HTTPException(status_code=404, detail="Meal record not found")
    
    # 删除图片文件
    if meal.image_path and os.path.exists(meal.image_path):
        try:
            os.remove(meal.image_path)
        except Exception as e:
            logger.warning(f"Failed to delete image file: {e}")
    
    db.delete(meal)
    db.commit()
    
    logger.info(f"Meal record deleted: {meal_id}")
    return {"message": "Meal record deleted successfully"}

@router.put("/{meal_id}", response_model=MealRecordResponse)
async def update_meal_record(
    meal_id: int,
    meal_type: str = Form(...),
    food_name: str = Form(...),
    calories: float = Form(...),
    protein: float = Form(0),
    carbs: float = Form(0),
    fat: float = Form(0),
    portion_size: Optional[str] = Form(None),
    notes: Optional[str] = Form(None),
    image: Optional[UploadFile] = File(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """更新饮食记录"""
    meal = db.query(MealRecord).filter(
        MealRecord.id == meal_id,
        MealRecord.user_id == current_user.id
    ).first()
    
    if not meal:
        raise HTTPException(status_code=404, detail="Meal record not found")
    
    # 更新字段
    meal.meal_type = meal_type
    meal.food_name = food_name
    meal.calories = calories
    meal.protein = protein
    meal.carbs = carbs
    meal.fat = fat
    meal.portion_size = portion_size
    meal.notes = notes
    
    # 处理新图片
    if image:
        # 删除旧图片
        if meal.image_path and os.path.exists(meal.image_path):
            try:
                os.remove(meal.image_path)
            except Exception as e:
                logger.warning(f"Failed to delete old image: {e}")
        
        # 保存新图片
        meal.image_path = save_image(image, current_user.id, "meal")
    
    db.commit()
    db.refresh(meal)
    
    logger.info(f"Meal record updated: {meal_id}")
    return meal
