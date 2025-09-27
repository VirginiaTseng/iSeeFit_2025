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
from typing import List, Tuple

import sys
from pathlib import Path

# Add parent directory to Python path
parent_dir = Path(__file__).parent.parent
sys.path.append(str(parent_dir))

from services.food_analysis_service import analyze_food_image

# Setup logging
logger = logging.getLogger(__name__)

# Create router
router = APIRouter(prefix="/api/food", tags=["food"])
#router = APIRouter(prefix="/food", tags=["food"])



import io, torch, torch.nn as nn, torchvision.models as M, torchvision.transforms as T
from fastapi import FastAPI, UploadFile, File
from PIL import Image, ImageOps
import uvicorn






# ---------- 1) 启动时加载：模型 + 预处理 ----------
app = FastAPI()
device = torch.device("cuda" if torch.cuda.is_available()
                      else "mps" if torch.backends.mps.is_available() else "cpu")

list_food_items = ['apple_pie', 'baby_back_ribs', 'baklava', 'beef_carpaccio', 'beef_tartare', 'beet_salad', 'beignets', 'bibimbap', 'bread_pudding', 'breakfast_burrito', 'bruschetta', 'caesar_salad', 'cannoli', 'caprese_salad', 'carrot_cake', 'ceviche', 'cheesecake', 'cheese_plate', 'chicken_curry', 'chicken_quesadilla', 'chicken_wings', 'chocolate_cake', 'chocolate_mousse', 'churros', 'clam_chowder', 'club_sandwich', 'crab_cakes', 'creme_brulee', 'croque_madame', 'cup_cakes', 'deviled_eggs', 'donuts', 'dumplings', 'edamame', 'eggs_benedict', 'escargots', 'falafel', 'filet_mignon', 'fish_and_chips', 'foie_gras', 'french_fries', 'french_onion_soup', 'french_toast', 'fried_calamari', 'fried_rice', 'frozen_yogurt', 'garlic_bread', 'gnocchi', 'greek_salad', 'grilled_cheese_sandwich', 'grilled_salmon', 'guacamole', 'gyoza', 'hamburger', 'hot_and_sour_soup', 'hot_dog', 'huevos_rancheros', 'hummus', 'ice_cream', 'lasagna', 'lobster_bisque', 'lobster_roll_sandwich', 'macaroni_and_cheese', 'macarons', 'miso_soup', 'mussels', 'nachos', 'omelette', 'onion_rings', 'oysters', 'pad_thai', 'paella', 'pancakes', 'panna_cotta', 'peking_duck', 'pho', 'pizza', 'pork_chop', 'poutine', 'prime_rib', 'pulled_pork_sandwich', 'ramen', 'ravioli', 'red_velvet_cake', 'risotto', 'samosa', 'sashimi', 'scallops', 'seaweed_salad', 'shrimp_and_grits', 'spaghetti_bolognese', 'spaghetti_carbonara', 'spring_rolls', 'steak', 'strawberry_shortcake', 'sushi', 'tacos', 'takoyaki', 'tiramisu', 'tuna_tartare', 'waffles']
num_classes = len(list_food_items)

# 与训练一致的结构
model = M.vit_b_16(weights=None)
model.heads.head = nn.Linear(model.heads.head.in_features, num_classes)
model_path = parent_dir / "checkpoints" / "best_model.pt"
state = torch.load(model_path, map_location=device)  # 或 best_model_swa.pt
model.load_state_dict(state)
model.to(device).eval()
print("Food-100 Model loaded successfully")

mean,std=[0.485,0.456,0.406],[0.229,0.224,0.225]
val_tf = T.Compose([T.Resize(256), T.CenterCrop(224), T.ToTensor(), T.Normalize(mean,std)])


# predict food-100 by calling pt model
@router.post("/predict")
async def predict(file: UploadFile = File(...), topk: int = 5):
    # 读图 & EXIF 纠正
    img_bytes = await file.read()
    img = Image.open(io.BytesIO(img_bytes)).convert("RGB")
    img = ImageOps.exif_transpose(img)

    # 预处理（与验证一致）
    x = val_tf(img).unsqueeze(0).to(device)

    with torch.no_grad(), torch.autocast(device.type, torch.float16 if device.type!="cpu" else torch.float32):
        logits = model(x)
        probs = torch.softmax(logits, dim=1)[0]
        top_prob, top_idx = torch.topk(probs, k=min(topk, num_classes))

    result = [{"label": list_food_items[i], "prob": float(p)} for p,i in zip(top_prob.tolist(), top_idx.tolist())]
    return {"topk": result}


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



def auto_resize_to_rect(img: Image.Image, landscape=(512,384), portrait=(384,512)) -> Image.Image:
    """自动按横/竖图裁到 4:3 或 3:4，再缩放到目标尺寸"""
    w,h = img.size
    if w >= h:
        # 横图
        desired_ratio = landscape[0] / landscape[1]
        target_size = landscape
    else:
        desired_ratio = portrait[0] / portrait[1]
        target_size = portrait
    cur_ratio = w/h
    if cur_ratio > desired_ratio:
        new_w = int(h * desired_ratio)
        left = (w - new_w)//2; right = left + new_w
        img = img.crop((left, 0, right, h))
    else:
        new_h = int(w / desired_ratio)
        top = (h - new_h)//2; bottom = top + new_h
        img = img.crop((0, top, w, bottom))
    return img.resize(target_size, Image.Resampling.LANCZOS)

def to_tensor_norm(img: Image.Image):
    return T.Compose([T.ToTensor(), T.Normalize(mean, std)])(img)

def build_tta_tensors(img: Image.Image, use_auto_ratio: bool):
    """
    返回一个 list[tensor] 做 TTA。
    - 如果 use_auto_ratio=True：使用 512x384 / 384x512 的矩形输入 + 可选翻转
    - 否则：使用与验证一致的 224 CenterCrop + 多尺度
    """
    tensors = []
    if use_auto_ratio:
        base = auto_resize_to_rect(img)  # 512x384 或 384x512
        # 原图 + 水平翻转 两个视角
        tensors.append(to_tensor_norm(base))
        tensors.append(to_tensor_norm(base.transpose(Image.FLIP_LEFT_RIGHT)))
    else:
        # 与验证一致：224×224；再加一个 288 短边的 CenterCrop 作为 TTA
        for s in (256, 288):
            tf = T.Compose([T.Resize(s), T.CenterCrop(224), T.ToTensor(), T.Normalize(mean,std)])
            tensors.append(tf(img))
    return tensors

# ====== Top-K 预测 ======
def predict_topk(img_path: str, topk: int = 5, tta: bool = True, auto_ratio: bool = False
                 ) -> List[Tuple[str, float]]:
    """
    返回 Top-K [(label, prob)]。
    参数:
      - topk: 返回前 K 个类别
      - tta: 是否启用测试时增强
      - auto_ratio: 是否按长宽比裁成 512x384/384x512（若 False 则与验证一致 224×224）
    """
    img = Image.open(img_path).convert("RGB")
    img = ImageOps.exif_transpose(img)  # 矫正EXIF方向

    with torch.no_grad(), torch.autocast(device.type, torch.float16 if device.type!="cpu" else torch.float32):
        if tta:
            tensors = build_tta_tensors(img, use_auto_ratio=auto_ratio)
            logits_sum = None
            for t in tensors:
                x = t.unsqueeze(0).to(device)
                out = model(x)
                logits_sum = out if logits_sum is None else (logits_sum + out)
            logits = logits_sum / len(tensors)
        else:
            # 单视角输入
            x = (to_tensor_norm(auto_resize_to_rect(img)) if auto_ratio else val_tf_224(img)).unsqueeze(0).to(device)
            logits = model(x)

        probs = F.softmax(logits, dim=1)[0]
        top_prob, top_idx = torch.topk(probs, k=topk)
        top_prob = top_prob.tolist()
        top_idx = top_idx.tolist()
        result = [(list_food_items[i], float(p)) for i, p in zip(top_idx, top_prob)]
        return result

# ====== 用法示例 ======
# 1) 与验证一致的 224×224 + TTA（推荐先试这个，最稳）
# print(predict_topk("testimage4.png", topk=5, tta=True, auto_ratio=False))