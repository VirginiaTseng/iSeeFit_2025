"""
Food Analysis API Routes
Provides food image analysis and nutrition calculation functionality for iOS apps
"""

from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Depends
from fastapi.responses import JSONResponse
from typing import Optional
from PIL import Image
import io
import logging

import sys
from pathlib import Path

# Add parent directory to Python path
parent_dir = Path(__file__).parent.parent
sys.path.append(str(parent_dir))

from services.food_analysis_service import analyze_food_image

# Setup logging
logger = logging.getLogger(__name__)

# Create router
router = APIRouter(prefix="/api/food", tags=["Food Analysis"])

@router.post("/analyze")
async def analyze_food(
    image: UploadFile = File(..., description="Food image file"),
    use_ai_portions: bool = Form(True, description="Whether to use AI to estimate portion sizes"),
    manual_override: str = Form("", description="Manually specified food name (optional)"),
    portion_slider: float = Form(250.0, description="Manual portion size (grams)")
):
    """
    Analyze food image and return nutrition information
    
    Args:
        image: Uploaded food image
        use_ai_portions: Whether to use AI to estimate portion sizes
        manual_override: Manually specified food name
        portion_slider: Manual portion size (grams)
    
    Returns:
        JSON format nutrition analysis result
    """
    try:
        # Validate file type
        if not image.content_type or not image.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="Please upload a valid image file")
        
        logger.info(f"Received food analysis request: {image.filename}, size: {image.size} bytes")
        
        # Read image data
        image_data = await image.read()
        
        # Convert to PIL image object
        try:
            pil_image = Image.open(io.BytesIO(image_data))
            # Ensure image is in RGB format
            if pil_image.mode != 'RGB':
                pil_image = pil_image.convert('RGB')
        except Exception as e:
            logger.error(f"Image processing failed: {e}")
            raise HTTPException(status_code=400, detail=f"Unable to process image: {str(e)}")
        
        # Call analysis service
        result = analyze_food_image(
            image=pil_image,
            use_ai_portions=use_ai_portions,
            manual_override=manual_override,
            portion_slider=portion_slider
        )
        
        # Check for errors
        if "error" in result:
            logger.warning(f"Analysis failed: {result['error']}")
            raise HTTPException(status_code=500, detail=result["error"])
        
        logger.info("Food analysis completed, returning results")
        return JSONResponse(content=result)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Food analysis API error: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "food_analysis"}

@router.get("/config")
async def get_config():
    """Get service configuration information"""
    from services.food_analysis_service import USE_OPENAI, openai_error_msg
    
    config = {
        "openai_enabled": USE_OPENAI,
        "model_name": "gpt-4o-mini" if USE_OPENAI else None,
        "fallback_classifier": "food101" if not USE_OPENAI else "available",
    }
    
    if openai_error_msg:
        config["openai_error"] = openai_error_msg
    
    return config
