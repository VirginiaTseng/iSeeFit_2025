#
#  weight.py
#  iSeeFit Backend
#
#  Created by Virginia Zheng on 2025-01-19.
#

from sqlalchemy import Column, Integer, Float, String, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from config.database import Base


class WeightRecord(Base):
    """体重记录模型"""
    __tablename__ = "weight_records"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    weight = Column(Float, nullable=False, comment="体重 (kg)")
    height = Column(Float, nullable=True, comment="身高 (cm) - 记录时的身高")
    bmi = Column(Float, nullable=True, comment="BMI 指数")
    notes = Column(Text, nullable=True, comment="备注")
    image_path = Column(String(500), nullable=True, comment="体重照片路径")
    recorded_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # 关联关系
    user = relationship("User", back_populates="weight_records")
    
    def __repr__(self):
        return f"<WeightRecord(id={self.id}, user_id={self.user_id}, weight={self.weight}kg, recorded_at={self.recorded_at})>"

