"""
推荐相关的 API 路由
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import logging

import sys
from pathlib import Path

# Add parent directory to Python path
parent_dir = Path(__file__).parent.parent
sys.path.append(str(parent_dir))

from config.database import get_db
from models.user import User
from models.recommendation import Recommendation
from models.schemas import RecommendationResponse
from utils.auth import get_current_user
from services.recommendation_service import RecommendationService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/recommendations", tags=["recommendations"])

class RecommendationResponse:
    def __init__(self, id: int, recommendation_type: str, title: str, content: str, 
                 priority: str, is_read: bool, created_at: datetime):
        self.id = id
        self.recommendation_type = recommendation_type
        self.title = title
        self.content = content
        self.priority = priority
        self.is_read = is_read
        self.created_at = created_at

@router.get("/")
async def get_recommendations(
    recommendation_type: Optional[str] = None,
    priority: Optional[str] = None,
    is_read: Optional[bool] = None,
    limit: int = 20,
    offset: int = 0,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取用户的推荐列表"""
    query = db.query(Recommendation).filter(Recommendation.user_id == current_user.id)
    
    if recommendation_type:
        query = query.filter(Recommendation.recommendation_type == recommendation_type)
    
    if priority:
        query = query.filter(Recommendation.priority == priority)
    
    if is_read is not None:
        query = query.filter(Recommendation.is_read == is_read)
    
    recommendations = query.order_by(Recommendation.created_at.desc()).offset(offset).limit(limit).all()
    
    return [
        RecommendationResponse(
            id=rec.id,
            recommendation_type=rec.recommendation_type,
            title=rec.title,
            content=rec.content,
            priority=rec.priority,
            is_read=rec.is_read,
            created_at=rec.created_at
        ) for rec in recommendations
    ]

@router.get("/unread")
async def get_unread_recommendations(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取未读推荐"""
    recommendations = db.query(Recommendation).filter(
        Recommendation.user_id == current_user.id,
        Recommendation.is_read == False
    ).order_by(Recommendation.created_at.desc()).all()
    
    return [
        RecommendationResponse(
            id=rec.id,
            recommendation_type=rec.recommendation_type,
            title=rec.title,
            content=rec.content,
            priority=rec.priority,
            is_read=rec.is_read,
            created_at=rec.created_at
        ) for rec in recommendations
    ]

@router.get("/stats")
async def get_recommendation_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取推荐统计信息"""
    total_recommendations = db.query(Recommendation).filter(
        Recommendation.user_id == current_user.id
    ).count()
    
    unread_recommendations = db.query(Recommendation).filter(
        Recommendation.user_id == current_user.id,
        Recommendation.is_read == False
    ).count()
    
    # 按类型统计
    type_stats = {}
    for rec_type in ["meal", "workout", "general"]:
        count = db.query(Recommendation).filter(
            Recommendation.user_id == current_user.id,
            Recommendation.recommendation_type == rec_type
        ).count()
        type_stats[rec_type] = count
    
    # 按优先级统计
    priority_stats = {}
    for priority in ["low", "medium", "high"]:
        count = db.query(Recommendation).filter(
            Recommendation.user_id == current_user.id,
            Recommendation.priority == priority
        ).count()
        priority_stats[priority] = count
    
    return {
        "total_recommendations": total_recommendations,
        "unread_recommendations": unread_recommendations,
        "read_recommendations": total_recommendations - unread_recommendations,
        "type_stats": type_stats,
        "priority_stats": priority_stats
    }

@router.post("/generate")
async def generate_new_recommendations(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """生成新的推荐"""
    try:
        recommendations = get_recommendations_for_user(current_user.id, db)
        
        logger.info(f"Generated {len(recommendations)} new recommendations for user {current_user.username}")
        return {
            "message": f"Generated {len(recommendations)} new recommendations",
            "count": len(recommendations)
        }
    except Exception as e:
        logger.error(f"Error generating recommendations: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate recommendations")

@router.put("/{recommendation_id}/read")
async def mark_recommendation_as_read(
    recommendation_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """标记推荐为已读"""
    recommendation = db.query(Recommendation).filter(
        Recommendation.id == recommendation_id,
        Recommendation.user_id == current_user.id
    ).first()
    
    if not recommendation:
        raise HTTPException(status_code=404, detail="Recommendation not found")
    
    recommendation.is_read = True
    db.commit()
    
    logger.info(f"Recommendation {recommendation_id} marked as read for user {current_user.username}")
    return {"message": "Recommendation marked as read"}

@router.put("/read-all")
async def mark_all_recommendations_as_read(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """标记所有推荐为已读"""
    updated_count = db.query(Recommendation).filter(
        Recommendation.user_id == current_user.id,
        Recommendation.is_read == False
    ).update({"is_read": True})
    
    db.commit()
    
    logger.info(f"Marked {updated_count} recommendations as read for user {current_user.username}")
    return {"message": f"Marked {updated_count} recommendations as read"}

@router.delete("/{recommendation_id}")
async def delete_recommendation(
    recommendation_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """删除推荐"""
    recommendation = db.query(Recommendation).filter(
        Recommendation.id == recommendation_id,
        Recommendation.user_id == current_user.id
    ).first()
    
    if not recommendation:
        raise HTTPException(status_code=404, detail="Recommendation not found")
    
    db.delete(recommendation)
    db.commit()
    
    logger.info(f"Recommendation {recommendation_id} deleted for user {current_user.username}")
    return {"message": "Recommendation deleted successfully"}

@router.get("/{recommendation_id}")
async def get_recommendation_detail(
    recommendation_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取推荐详情"""
    recommendation = db.query(Recommendation).filter(
        Recommendation.id == recommendation_id,
        Recommendation.user_id == current_user.id
    ).first()
    
    if not recommendation:
        raise HTTPException(status_code=404, detail="Recommendation not found")
    
    # 标记为已读
    if not recommendation.is_read:
        recommendation.is_read = True
        db.commit()
    
    return RecommendationResponse(
        id=recommendation.id,
        recommendation_type=recommendation.recommendation_type,
        title=recommendation.title,
        content=recommendation.content,
        priority=recommendation.priority,
        is_read=recommendation.is_read,
        created_at=recommendation.created_at
    )
