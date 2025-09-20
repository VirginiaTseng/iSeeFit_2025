"""
Image processing utilities
"""

import os
import logging
from datetime import datetime
from fastapi import UploadFile, HTTPException
from PIL import Image
from config.settings import settings

logger = logging.getLogger(__name__)

def save_image(file: UploadFile, user_id: int, record_type: str) -> str:
    """Save uploaded image and return path"""
    try:
        # Create user directory
        upload_dir = f"{settings.UPLOAD_DIR}/{user_id}/{record_type}"
        os.makedirs(upload_dir, exist_ok=True)
        
        # Generate filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{record_type}_{timestamp}_{file.filename}"
        file_path = os.path.join(upload_dir, filename)
        
        # Save file
        with open(file_path, "wb") as buffer:
            content = file.file.read()
            buffer.write(content)
        
        # Compress image
        with Image.open(file_path) as img:
            img.thumbnail((800, 600), Image.Resampling.LANCZOS)
            img.save(file_path, "JPEG", quality=85)
        
        logger.info(f"Image saved: {file_path}")
        return file_path
    except Exception as e:
        logger.error(f"Error saving image: {e}")
        raise HTTPException(status_code=500, detail="Failed to save image")

def delete_image(image_path: str) -> bool:
    """Delete image file"""
    try:
        if image_path and os.path.exists(image_path):
            os.remove(image_path)
            logger.info(f"Image deleted: {image_path}")
            return True
        return False
    except Exception as e:
        logger.warning(f"Failed to delete image: {e}")
        return False
