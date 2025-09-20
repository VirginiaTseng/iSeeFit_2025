"""
健身记录相关的 API 路由
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
from models.workout import WorkoutRecord
from models.schemas import WorkoutRecordCreate, WorkoutRecordResponse
from utils.auth import get_current_user
from utils.image import save_image

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/workouts", tags=["workouts"])

@router.post("/", response_model=WorkoutRecordResponse)
async def create_workout_record(
    workout_type: str = Form(...),
    duration_minutes: int = Form(...),
    calories_burned: float = Form(...),
    intensity: str = Form("moderate"),
    reps: Optional[int] = Form(None),
    sets: Optional[int] = Form(None),
    weight_used: Optional[float] = Form(None),
    notes: Optional[str] = Form(None),
    image: Optional[UploadFile] = File(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """创建健身记录"""
    try:
        # 保存图片
        image_path = None
        if image:
            image_path = save_image(image, current_user.id, "workout")
        
        # 创建记录
        db_workout = WorkoutRecord(
            user_id=current_user.id,
            workout_type=workout_type,
            duration_minutes=duration_minutes,
            calories_burned=calories_burned,
            intensity=intensity,
            reps=reps,
            sets=sets,
            weight_used=weight_used,
            image_path=image_path,
            notes=notes
        )
        
        db.add(db_workout)
        db.commit()
        db.refresh(db_workout)
        
        logger.info(f"Workout record created for user {current_user.username}: {workout_type}")
        return db_workout
        
    except Exception as e:
        logger.error(f"Error creating workout record: {e}")
        raise HTTPException(status_code=500, detail="Failed to create workout record")

@router.get("/", response_model=List[WorkoutRecordResponse])
async def get_workout_records(
    date_filter: Optional[date] = None,
    workout_type: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取用户的健身记录"""
    query = db.query(WorkoutRecord).filter(WorkoutRecord.user_id == current_user.id)
    
    if date_filter:
        query = query.filter(WorkoutRecord.recorded_at >= date_filter)
        query = query.filter(WorkoutRecord.recorded_at < date_filter.replace(day=date_filter.day + 1))
    
    if workout_type:
        query = query.filter(WorkoutRecord.workout_type == workout_type)
    
    records = query.order_by(WorkoutRecord.recorded_at.desc()).offset(offset).limit(limit).all()
    return records

@router.get("/today", response_model=List[WorkoutRecordResponse])
async def get_today_workout_records(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取今天的健身记录"""
    today = date.today()
    records = db.query(WorkoutRecord).filter(
        WorkoutRecord.user_id == current_user.id,
        WorkoutRecord.recorded_at >= today,
        WorkoutRecord.recorded_at < today.replace(day=today.day + 1)
    ).order_by(WorkoutRecord.recorded_at.desc()).all()
    
    return records

@router.get("/stats/daily")
async def get_daily_workout_stats(
    target_date: Optional[date] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取每日健身统计"""
    if not target_date:
        target_date = date.today()
    
    records = db.query(WorkoutRecord).filter(
        WorkoutRecord.user_id == current_user.id,
        WorkoutRecord.recorded_at >= target_date,
        WorkoutRecord.recorded_at < target_date.replace(day=target_date.day + 1)
    ).all()
    
    total_duration = sum(record.duration_minutes for record in records)
    total_calories_burned = sum(record.calories_burned for record in records)
    workout_count = len(records)
    
    # 按运动类型分组
    workout_stats = {}
    for record in records:
        if record.workout_type not in workout_stats:
            workout_stats[record.workout_type] = {
                "duration": 0,
                "calories_burned": 0,
                "count": 0
            }
        
        workout_stats[record.workout_type]["duration"] += record.duration_minutes
        workout_stats[record.workout_type]["calories_burned"] += record.calories_burned
        workout_stats[record.workout_type]["count"] += 1
    
    return {
        "date": target_date,
        "total_duration_minutes": total_duration,
        "total_calories_burned": total_calories_burned,
        "workout_count": workout_count,
        "workout_stats": workout_stats
    }

@router.get("/stats/weekly")
async def get_weekly_workout_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取每周健身统计"""
    from datetime import timedelta
    
    end_date = date.today()
    start_date = end_date - timedelta(days=6)
    
    records = db.query(WorkoutRecord).filter(
        WorkoutRecord.user_id == current_user.id,
        WorkoutRecord.recorded_at >= start_date,
        WorkoutRecord.recorded_at <= end_date
    ).all()
    
    # 按日期分组
    daily_stats = {}
    for record in records:
        record_date = record.recorded_at.date()
        if record_date not in daily_stats:
            daily_stats[record_date] = {
                "duration": 0,
                "calories_burned": 0,
                "workout_count": 0
            }
        
        daily_stats[record_date]["duration"] += record.duration_minutes
        daily_stats[record_date]["calories_burned"] += record.calories_burned
        daily_stats[record_date]["workout_count"] += 1
    
    # 计算平均值
    total_days = len(daily_stats)
    avg_duration = sum(stats["duration"] for stats in daily_stats.values()) / total_days if total_days > 0 else 0
    avg_calories = sum(stats["calories_burned"] for stats in daily_stats.values()) / total_days if total_days > 0 else 0
    
    return {
        "start_date": start_date,
        "end_date": end_date,
        "daily_stats": daily_stats,
        "averages": {
            "duration_minutes": avg_duration,
            "calories_burned": avg_calories
        }
    }

@router.get("/stats/monthly")
async def get_monthly_workout_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取每月健身统计"""
    from datetime import timedelta
    
    end_date = date.today()
    start_date = end_date - timedelta(days=29)  # 最近30天
    
    records = db.query(WorkoutRecord).filter(
        WorkoutRecord.user_id == current_user.id,
        WorkoutRecord.recorded_at >= start_date,
        WorkoutRecord.recorded_at <= end_date
    ).all()
    
    # 按周分组
    weekly_stats = {}
    for record in records:
        # 计算是第几周
        week_start = record.recorded_at.date() - timedelta(days=record.recorded_at.weekday())
        if week_start not in weekly_stats:
            weekly_stats[week_start] = {
                "duration": 0,
                "calories_burned": 0,
                "workout_count": 0
            }
        
        weekly_stats[week_start]["duration"] += record.duration_minutes
        weekly_stats[week_start]["calories_burned"] += record.calories_burned
        weekly_stats[week_start]["workout_count"] += 1
    
    # 按运动类型统计
    workout_type_stats = {}
    for record in records:
        if record.workout_type not in workout_type_stats:
            workout_type_stats[record.workout_type] = {
                "duration": 0,
                "calories_burned": 0,
                "count": 0
            }
        
        workout_type_stats[record.workout_type]["duration"] += record.duration_minutes
        workout_type_stats[record.workout_type]["calories_burned"] += record.calories_burned
        workout_type_stats[record.workout_type]["count"] += 1
    
    return {
        "start_date": start_date,
        "end_date": end_date,
        "weekly_stats": weekly_stats,
        "workout_type_stats": workout_type_stats,
        "total_workouts": len(records)
    }

@router.delete("/{workout_id}")
async def delete_workout_record(
    workout_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """删除健身记录"""
    workout = db.query(WorkoutRecord).filter(
        WorkoutRecord.id == workout_id,
        WorkoutRecord.user_id == current_user.id
    ).first()
    
    if not workout:
        raise HTTPException(status_code=404, detail="Workout record not found")
    
    # 删除图片文件
    if workout.image_path and os.path.exists(workout.image_path):
        try:
            os.remove(workout.image_path)
        except Exception as e:
            logger.warning(f"Failed to delete image file: {e}")
    
    db.delete(workout)
    db.commit()
    
    logger.info(f"Workout record deleted: {workout_id}")
    return {"message": "Workout record deleted successfully"}

@router.put("/{workout_id}", response_model=WorkoutRecordResponse)
async def update_workout_record(
    workout_id: int,
    workout_type: str = Form(...),
    duration_minutes: int = Form(...),
    calories_burned: float = Form(...),
    intensity: str = Form("moderate"),
    reps: Optional[int] = Form(None),
    sets: Optional[int] = Form(None),
    weight_used: Optional[float] = Form(None),
    notes: Optional[str] = Form(None),
    image: Optional[UploadFile] = File(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """更新健身记录"""
    workout = db.query(WorkoutRecord).filter(
        WorkoutRecord.id == workout_id,
        WorkoutRecord.user_id == current_user.id
    ).first()
    
    if not workout:
        raise HTTPException(status_code=404, detail="Workout record not found")
    
    # 更新字段
    workout.workout_type = workout_type
    workout.duration_minutes = duration_minutes
    workout.calories_burned = calories_burned
    workout.intensity = intensity
    workout.reps = reps
    workout.sets = sets
    workout.weight_used = weight_used
    workout.notes = notes
    
    # 处理新图片
    if image:
        # 删除旧图片
        if workout.image_path and os.path.exists(workout.image_path):
            try:
                os.remove(workout.image_path)
            except Exception as e:
                logger.warning(f"Failed to delete old image: {e}")
        
        # 保存新图片
        workout.image_path = save_image(image, current_user.id, "workout")
    
    db.commit()
    db.refresh(workout)
    
    logger.info(f"Workout record updated: {workout_id}")
    return workout
