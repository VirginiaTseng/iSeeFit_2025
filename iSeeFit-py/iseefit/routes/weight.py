#
#  weight.py
#  iSeeFit Backend - Weight Tracking API Routes
#
#  Created by Virginia Zheng on 2025-01-19.
#

from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from sqlalchemy.orm import Session
from sqlalchemy import desc, func, and_
from datetime import datetime, date, timedelta
from typing import Optional, List
import math
import os

from config.database import get_db
from models.user import User
from models.weight import WeightRecord
from models.schemas import (
    WeightRecordCreate, WeightRecordUpdate, WeightRecordResponse,
    BMICalculationRequest, BMICalculationResponse,
    WeightStatsResponse, WeightHistoryResponse, WeightTrendResponse
)
from utils.auth import get_current_user
from utils.image import save_image

router = APIRouter(prefix="/weight", tags=["weight"])

# BMI 计算工具函数
def calculate_bmi(weight: float, height: float) -> float:
    """计算 BMI 指数"""
    if height <= 0:
        return 0.0
    height_in_meters = height / 100.0
    return round(weight / (height_in_meters ** 2), 1)

def get_bmi_category(bmi: float) -> dict:
    """获取 BMI 分类信息"""
    if bmi < 18.5:
        return {
            "category": "underweight",
            "description": "偏瘦 (BMI < 18.5)",
            "color": "blue"
        }
    elif 18.5 <= bmi < 25:
        return {
            "category": "normal",
            "description": "正常 (BMI 18.5-24.9)",
            "color": "green"
        }
    elif 25 <= bmi < 30:
        return {
            "category": "overweight",
            "description": "超重 (BMI 25-29.9)",
            "color": "orange"
        }
    else:
        return {
            "category": "obese",
            "description": "肥胖 (BMI ≥ 30)",
            "color": "red"
        }

@router.post("/", response_model=WeightRecordResponse)
async def create_weight_record(
    weight_data: WeightRecordCreate,
    image: Optional[UploadFile] = File(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """创建体重记录"""
    try:
        # 获取用户当前身高（如果体重记录中没有提供）
        user_height = weight_data.height or current_user.height
        if not user_height:
            raise HTTPException(status_code=400, detail="用户身高信息缺失，请先完善个人资料")
        
        # 计算 BMI
        bmi = calculate_bmi(weight_data.weight, user_height)
        
        # 处理图片上传
        image_path = None
        if image:
            image_path = await save_image(image, "weight", current_user.id)
        
        # 创建体重记录
        weight_record = WeightRecord(
            user_id=current_user.id,
            weight=weight_data.weight,
            height=user_height,
            bmi=bmi,
            notes=weight_data.notes,
            image_path=image_path
        )
        
        db.add(weight_record)
        db.commit()
        db.refresh(weight_record)
        
        print(f"DEBUG: Created weight record for user {current_user.id}: {weight_data.weight}kg, BMI: {bmi}")
        return weight_record
        
    except Exception as e:
        db.rollback()
        print(f"ERROR: Failed to create weight record: {str(e)}")
        raise HTTPException(status_code=500, detail=f"创建体重记录失败: {str(e)}")

@router.get("/", response_model=WeightHistoryResponse)
async def get_weight_history(
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量"),
    start_date: Optional[date] = Query(None, description="开始日期"),
    end_date: Optional[date] = Query(None, description="结束日期"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取体重历史记录"""
    try:
        # 构建查询条件
        query = db.query(WeightRecord).filter(WeightRecord.user_id == current_user.id)
        
        if start_date:
            query = query.filter(WeightRecord.recorded_at >= start_date)
        if end_date:
            query = query.filter(WeightRecord.recorded_at <= end_date)
        
        # 获取总数
        total_count = query.count()
        
        # 分页查询
        offset = (page - 1) * page_size
        records = query.order_by(desc(WeightRecord.recorded_at)).offset(offset).limit(page_size).all()
        
        # 计算分页信息
        has_next = offset + page_size < total_count
        has_prev = page > 1
        
        print(f"DEBUG: Retrieved {len(records)} weight records for user {current_user.id}")
        
        return WeightHistoryResponse(
            records=records,
            total_count=total_count,
            page=page,
            page_size=page_size,
            has_next=has_next,
            has_prev=has_prev
        )
        
    except Exception as e:
        print(f"ERROR: Failed to get weight history: {str(e)}")
        raise HTTPException(status_code=500, detail=f"获取体重历史失败: {str(e)}")

@router.get("/stats", response_model=WeightStatsResponse)
async def get_weight_stats(
    days: int = Query(30, ge=1, le=365, description="统计天数"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取体重统计信息"""
    try:
        # 计算日期范围
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        
        # 查询指定时间范围内的体重记录
        records = db.query(WeightRecord).filter(
            and_(
                WeightRecord.user_id == current_user.id,
                WeightRecord.recorded_at >= start_date,
                WeightRecord.recorded_at <= end_date
            )
        ).order_by(WeightRecord.recorded_at.desc()).all()
        
        if not records:
            # 如果没有记录，返回默认值
            return WeightStatsResponse(
                current_weight=current_user.weight or 0.0,
                previous_weight=None,
                weight_change=0.0,
                weight_change_percentage=0.0,
                average_weight=0.0,
                min_weight=0.0,
                max_weight=0.0,
                record_count=0,
                bmi=0.0,
                bmi_category="unknown",
                period_days=days
            )
        
        # 计算统计数据
        current_weight = records[0].weight
        previous_weight = records[1].weight if len(records) > 1 else None
        
        weight_change = current_weight - previous_weight if previous_weight else 0.0
        weight_change_percentage = (weight_change / previous_weight * 100) if previous_weight else 0.0
        
        weights = [record.weight for record in records]
        average_weight = sum(weights) / len(weights)
        min_weight = min(weights)
        max_weight = max(weights)
        
        # 计算当前 BMI
        user_height = current_user.height or 170.0
        current_bmi = calculate_bmi(current_weight, user_height)
        bmi_info = get_bmi_category(current_bmi)
        
        print(f"DEBUG: Calculated weight stats for user {current_user.id}: {len(records)} records")
        
        return WeightStatsResponse(
            current_weight=current_weight,
            previous_weight=previous_weight,
            weight_change=round(weight_change, 1),
            weight_change_percentage=round(weight_change_percentage, 1),
            average_weight=round(average_weight, 1),
            min_weight=min_weight,
            max_weight=max_weight,
            record_count=len(records),
            bmi=current_bmi,
            bmi_category=bmi_info["category"],
            period_days=days
        )
        
    except Exception as e:
        print(f"ERROR: Failed to get weight stats: {str(e)}")
        raise HTTPException(status_code=500, detail=f"获取体重统计失败: {str(e)}")

@router.get("/trend", response_model=WeightTrendResponse)
async def get_weight_trend(
    days: int = Query(30, ge=7, le=365, description="趋势天数"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取体重趋势数据"""
    try:
        # 计算日期范围
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        
        # 查询体重记录
        records = db.query(WeightRecord).filter(
            and_(
                WeightRecord.user_id == current_user.id,
                WeightRecord.recorded_at >= start_date,
                WeightRecord.recorded_at <= end_date
            )
        ).order_by(WeightRecord.recorded_at.asc()).all()
        
        # 构建每日数据
        daily_data = []
        for record in records:
            daily_data.append({
                "date": record.recorded_at.date().isoformat(),
                "weight": record.weight,
                "bmi": record.bmi,
                "notes": record.notes
            })
        
        # 计算周平均值
        weekly_averages = []
        for i in range(0, len(records), 7):
            week_records = records[i:i+7]
            if week_records:
                avg_weight = sum(r.weight for r in week_records) / len(week_records)
                week_start = week_records[0].recorded_at.date()
                weekly_averages.append({
                    "week_start": week_start.isoformat(),
                    "average_weight": round(avg_weight, 1)
                })
        
        # 计算月平均值
        monthly_averages = []
        current_month = None
        month_records = []
        
        for record in records:
            record_month = record.recorded_at.date().replace(day=1)
            if current_month != record_month:
                if month_records:
                    avg_weight = sum(r.weight for r in month_records) / len(month_records)
                    monthly_averages.append({
                        "month": current_month.isoformat(),
                        "average_weight": round(avg_weight, 1)
                    })
                current_month = record_month
                month_records = [record]
            else:
                month_records.append(record)
        
        # 处理最后一个月的记录
        if month_records:
            avg_weight = sum(r.weight for r in month_records) / len(month_records)
            monthly_averages.append({
                "month": current_month.isoformat(),
                "average_weight": round(avg_weight, 1)
            })
        
        print(f"DEBUG: Generated weight trend data for user {current_user.id}: {len(daily_data)} daily records")
        
        return WeightTrendResponse(
            start_date=start_date.date(),
            end_date=end_date.date(),
            daily_data=daily_data,
            weekly_averages=weekly_averages,
            monthly_averages=monthly_averages
        )
        
    except Exception as e:
        print(f"ERROR: Failed to get weight trend: {str(e)}")
        raise HTTPException(status_code=500, detail=f"获取体重趋势失败: {str(e)}")

@router.post("/bmi", response_model=BMICalculationResponse)
async def calculate_bmi_endpoint(
    bmi_request: BMICalculationRequest,
    current_user: User = Depends(get_current_user)
):
    """计算 BMI 指数"""
    try:
        bmi = calculate_bmi(bmi_request.weight, bmi_request.height)
        bmi_info = get_bmi_category(bmi)
        
        print(f"DEBUG: Calculated BMI for user {current_user.id}: {bmi}")
        
        return BMICalculationResponse(
            bmi=bmi,
            category=bmi_info["category"],
            description=bmi_info["description"],
            color=bmi_info["color"]
        )
        
    except Exception as e:
        print(f"ERROR: Failed to calculate BMI: {str(e)}")
        raise HTTPException(status_code=500, detail=f"BMI 计算失败: {str(e)}")

@router.put("/{weight_id}", response_model=WeightRecordResponse)
async def update_weight_record(
    weight_id: int,
    weight_data: WeightRecordUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """更新体重记录"""
    try:
        # 查找体重记录
        weight_record = db.query(WeightRecord).filter(
            and_(
                WeightRecord.id == weight_id,
                WeightRecord.user_id == current_user.id
            )
        ).first()
        
        if not weight_record:
            raise HTTPException(status_code=404, detail="体重记录不存在")
        
        # 更新字段
        if weight_data.weight is not None:
            weight_record.weight = weight_data.weight
        if weight_data.height is not None:
            weight_record.height = weight_data.height
        if weight_data.notes is not None:
            weight_record.notes = weight_data.notes
        
        # 重新计算 BMI
        if weight_data.weight is not None or weight_data.height is not None:
            height = weight_record.height or current_user.height or 170.0
            weight_record.bmi = calculate_bmi(weight_record.weight, height)
        
        db.commit()
        db.refresh(weight_record)
        
        print(f"DEBUG: Updated weight record {weight_id} for user {current_user.id}")
        return weight_record
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        print(f"ERROR: Failed to update weight record: {str(e)}")
        raise HTTPException(status_code=500, detail=f"更新体重记录失败: {str(e)}")

@router.delete("/{weight_id}")
async def delete_weight_record(
    weight_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """删除体重记录"""
    try:
        # 查找体重记录
        weight_record = db.query(WeightRecord).filter(
            and_(
                WeightRecord.id == weight_id,
                WeightRecord.user_id == current_user.id
            )
        ).first()
        
        if not weight_record:
            raise HTTPException(status_code=404, detail="体重记录不存在")
        
        # 删除关联的图片文件
        if weight_record.image_path:
            try:
                os.remove(weight_record.image_path)
            except OSError:
                pass  # 文件不存在或无法删除，忽略错误
        
        # 删除记录
        db.delete(weight_record)
        db.commit()
        
        print(f"DEBUG: Deleted weight record {weight_id} for user {current_user.id}")
        return {"message": "体重记录删除成功"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        print(f"ERROR: Failed to delete weight record: {str(e)}")
        raise HTTPException(status_code=500, detail=f"删除体重记录失败: {str(e)}")

@router.get("/latest", response_model=WeightRecordResponse)
async def get_latest_weight(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取最新的体重记录"""
    try:
        latest_record = db.query(WeightRecord).filter(
            WeightRecord.user_id == current_user.id
        ).order_by(desc(WeightRecord.recorded_at)).first()
        
        if not latest_record:
            raise HTTPException(status_code=404, detail="暂无体重记录")
        
        print(f"DEBUG: Retrieved latest weight record for user {current_user.id}")
        return latest_record
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"ERROR: Failed to get latest weight: {str(e)}")
        raise HTTPException(status_code=500, detail=f"获取最新体重失败: {str(e)}")

