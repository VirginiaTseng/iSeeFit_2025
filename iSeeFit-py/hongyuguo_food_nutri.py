"""
Calorie & Nutrition Estimator (OpenAI Vision + robust fallback)
- If OPENAI works: detect up to 3 foods + estimate grams automatically.
- If OPENAI fails or has no internet: fall back to Food-101 classifier (top-1) with the slider grams.
- Adds common foods: chicken, potatoes, peas, carrots (incl. roasted).
- Returns None (not "") when no report is produced (avoids Gradio IsADirectoryError).
- Surfaces a short DEBUG note when OpenAI failed so you know what to fix.
Tip: To enable debug text permanently, set env var DEBUG=1.
"""

import os, io, json, base64, re
from datetime import datetime
from typing import Any, Dict, List, Tuple, Optional

import gradio as gr
import pandas as pd
from PIL import Image

# ============== Config & Flags ==============
MODEL_NAME = "gpt-4o-mini"           # OpenAI vision model
OPENAI_API_KEY = (os.getenv("OPENAI_API_KEY")).strip()
print(OPENAI_API_KEY)
DEBUG = (os.getenv("DEBUG", "0").strip() == "1")

USE_OPENAI = bool(OPENAI_API_KEY)
print('USE_OPENAI: ',USE_OPENAI)
openai_client = None
openai_error_msg = None

if USE_OPENAI:
    try:
        from openai import OpenAI  # pip install openai>=1.40.0
        openai_client = OpenAI(api_key=OPENAI_API_KEY)
    except Exception as e:
        USE_OPENAI = False
        openai_client = None
        openai_error_msg = f"OpenAI SDK import failed: {e}"

# ============== Nutrition (per 100 g) ==============
NUTRITION_PER_100G: Dict[str, Dict[str, float]] = {
    # Fruits
    "apple": {"kcal": 52, "protein_g": 0.3, "carb_g": 14.0, "fat_g": 0.2},
    "banana": {"kcal": 96, "protein_g": 1.3, "carb_g": 27.0, "fat_g": 0.3},
    "orange": {"kcal": 47, "protein_g": 0.9, "carb_g": 12.0, "fat_g": 0.1},

    # Staples / dishes
    "white rice": {"kcal": 130, "protein_g": 2.4, "carb_g": 28.0, "fat_g": 0.3},
    "fried rice": {"kcal": 164, "protein_g": 3.2, "carb_g": 31.0, "fat_g": 2.8},
    "noodles": {"kcal": 138, "protein_g": 4.5, "carb_g": 21.0, "fat_g": 3.1},
    "spaghetti": {"kcal": 157, "protein_g": 5.8, "carb_g": 30.0, "fat_g": 1.0},
    "spaghetti bolognese": {"kcal": 132, "protein_g": 7.0, "carb_g": 14.0, "fat_g": 5.0},
    "pizza": {"kcal": 266, "protein_g": 11.0, "carb_g": 33.0, "fat_g": 10.0},
    "hamburger": {"kcal": 254, "protein_g": 13.0, "carb_g": 30.0, "fat_g": 9.0},
    "french fries": {"kcal": 312, "protein_g": 3.4, "carb_g": 41.0, "fat_g": 15.0},
    "fried chicken": {"kcal": 245, "protein_g": 20.0, "carb_g": 7.0, "fat_g": 14.0},
    "donut": {"kcal": 452, "protein_g": 5.0, "carb_g": 51.0, "fat_g": 25.0},
    "ice cream": {"kcal": 207, "protein_g": 3.5, "carb_g": 24.0, "fat_g": 11.0},
    "sandwich": {"kcal": 230, "protein_g": 9.0, "carb_g": 28.0, "fat_g": 9.0},
    "pancake": {"kcal": 227, "protein_g": 6.0, "carb_g": 28.0, "fat_g": 9.0},
    "waffle": {"kcal": 291, "protein_g": 7.8, "carb_g": 34.0, "fat_g": 14.0},

    # Asian favs
    "ramen": {"kcal": 436, "protein_g": 10.0, "carb_g": 62.0, "fat_g": 17.0},
    "sushi": {"kcal": 143, "protein_g": 4.0, "carb_g": 30.0, "fat_g": 1.5},
    "dumplings": {"kcal": 219, "protein_g": 8.0, "carb_g": 28.0, "fat_g": 8.0},
    "pho": {"kcal": 65, "protein_g": 5.0, "carb_g": 6.0, "fat_g": 2.0},

    # Proteins / salads / soups
    "steak": {"kcal": 271, "protein_g": 25.0, "carb_g": 0.0, "fat_g": 19.0},
    "salad": {"kcal": 20, "protein_g": 1.2, "carb_g": 3.0, "fat_g": 0.2},
    "chicken salad": {"kcal": 172, "protein_g": 14.0, "carb_g": 2.0, "fat_g": 12.0},
    "soup": {"kcal": 50, "protein_g": 2.0, "carb_g": 7.0, "fat_g": 1.0},

    # NEW: common plate items in your screenshots
    "chicken": {"kcal": 239, "protein_g": 27.0, "carb_g": 0.0, "fat_g": 14.0},           # cooked, average
    "roast chicken": {"kcal": 239, "protein_g": 27.0, "carb_g": 0.0, "fat_g": 14.0},
    "potatoes": {"kcal": 87, "protein_g": 2.0, "carb_g": 20.0, "fat_g": 0.1},            # boiled avg
    "roasted potatoes": {"kcal": 149, "protein_g": 2.5, "carb_g": 24.0, "fat_g": 5.0},
    "peas": {"kcal": 81, "protein_g": 5.4, "carb_g": 14.0, "fat_g": 0.4},
    "carrots": {"kcal": 41, "protein_g": 0.9, "carb_g": 10.0, "fat_g": 0.2},
}
FALLBACK_PER_100G = {"kcal": 200.0, "protein_g": 6.0, "carb_g": 25.0, "fat_g": 7.0}

ALIASES = {
    "burger": "hamburger",
    "cheeseburger": "hamburger",
    "fries": "french fries",
    "chips": "french fries",        # UK naming
    "roasted potatoes": "roasted potatoes",
    "roast potatoes": "roasted potatoes",
    "green peas": "peas",
    "roast chicken": "roast chicken",
    "chicken breast": "chicken",
}

# ============== Helpers ==============
def map_label_to_key(label: str) -> str:
    if not label:
        return ""
    lab = label.strip().lower()
    lab = lab.replace("_", " ").replace("-", " ")
    return ALIASES.get(lab, lab)

def resize_for_vision(img: Image.Image, max_side: int = 768) -> Image.Image:
    w, h = img.size
    if max(w, h) <= max_side:
        return img.convert("RGB")
    scale = max_side / float(max(w, h))
    new = (int(w * scale), int(h * scale))
    return img.convert("RGB").resize(new, Image.LANCZOS)

def img_to_data_url(img: Image.Image, fmt="JPEG", quality=90) -> str:
    buf = io.BytesIO()
    img.save(buf, format=fmt, quality=quality)
    b64 = base64.b64encode(buf.getvalue()).decode("utf-8")
    return f"data:image/{fmt.lower()};base64,{b64}"

def scale_nutrition(per100: Dict[str, float], grams: float) -> Dict[str, float]:
    factor = max(float(grams), 0.0) / 100.0
    return {
        "kcal": round(per100["kcal"] * factor, 1),
        "protein_g": round(per100["protein_g"] * factor, 2),
        "carb_g": round(per100["carb_g"] * factor, 2),
        "fat_g": round(per100["fat_g"] * factor, 2),
    }

# ============== OpenAI vision ==============
VISION_PROMPT = (
    "You are a nutrition assistant. Identify up to 3 distinct GENERIC foods in the photo "
    "and estimate each portion size in grams. Prefer generic names like hamburger, french fries, "
    "roast chicken, roasted potatoes, peas, carrots. Respond as STRICT JSON ONLY: "
    '{"items":[{"name":"string","grams":number,"confidence":0-1}],"notes":"short helpful note"}'
)

def openai_detect(img: Image.Image) -> Tuple[List[Dict[str, Any]], str, Optional[str]]:
    """Return (items, notes, error_msg). If call fails, error_msg is a short reason."""
    if not (USE_OPENAI and openai_client):
        return [], "", "OpenAI not configured."

    try:
        small = resize_for_vision(img)
        data_url = img_to_data_url(small)
        resp = openai_client.chat.completions.create(
            model=MODEL_NAME,
            temperature=0.2,
            response_format={"type": "json_object"},  # force JSON
            messages=[
                {"role": "system", "content": VISION_PROMPT},
                {"role": "user", "content": [
                    {"type": "text", "text": "Identify foods and estimate portions in grams."},
                    {"type": "image_url", "image_url": {"url": data_url}},
                ]},
            ],
        )
        raw = resp.choices[0].message.content or ""
        data = json.loads(raw) if raw.strip().startswith("{") else {}
        items = data.get("items", []) if isinstance(data, dict) else []
        notes = data.get("notes", "") if isinstance(data, dict) else ""
        if not isinstance(items, list):
            items = []
        return items, notes, None
    except Exception as e:
        return [], "", f"OpenAI call failed: {e}"

# ============== Food-101 fallback ==============
clf = None
def ensure_classifier():
    global clf
    if clf is None:
        from transformers import pipeline   # requires transformers, torch, torchvision
        clf = pipeline("image-classification", model="nateraw/food101", top_k=5)
    return clf

def classifier_top1(img: Image.Image) -> Tuple[str, float]:
    try:
        pipe = ensure_classifier()
        out = pipe(img.convert("RGB"))
        if isinstance(out, list) and out:
            return out[0]["label"], float(out[0]["score"])
        return "", 0.0
    except Exception:
        return "", 0.0

# ============== Core ==============
def analyze_image(
    image: Optional[Image.Image],
    use_ai_portions: bool,
    manual_override: str,
    portion_slider: float,
) -> Tuple[str, str, pd.DataFrame, pd.DataFrame, Optional[str], str]:
    """
    Returns: title_md, detections_md, per_item_df, totals_df, file_path_or_None, debug_text
    """
    try:
        if image is None and not manual_override.strip():
            return ("Please upload a food photo or type a manual name.",
                    "_No foods detected yet._", pd.DataFrame(), pd.DataFrame(), None,
                    "(hint) Upload a photo or type a food name.")

        debug_lines = []
        if openai_error_msg:
            debug_lines.append(openai_error_msg)

        # 1) Manual override
        items: List[Dict[str, Any]] = []
        notes = ""
        if manual_override.strip():
            items = [{"name": manual_override.strip(), "grams": float(portion_slider), "confidence": 1.0}]
            debug_lines.append("Using manual override.")
        else:
            # 2) Try OpenAI
            if USE_OPENAI and image is not None:
                items, notes, err = openai_detect(image)
                if err:
                    debug_lines.append(err)
            # 3) Fallback if needed
            if not items and image is not None:
                lbl, conf = classifier_top1(image)
                if lbl:
                    items = [{"name": lbl, "grams": float(portion_slider), "confidence": conf}]
                    debug_lines.append(f"Using classifier fallback: {lbl} (conf {conf:.2f})")
                else:
                    debug_lines.append("Classifier fallback unavailable or returned nothing. "
                                       "Install transformers/torch to enable it.")

        # Enforce slider grams if AI portions are off
        if items and not use_ai_portions:
            items = [dict(items[0], grams=float(portion_slider))]
            debug_lines.append("Forced manual grams (AI portions off).")

        # Build rows
        rows = []
        for it in items:
            name_raw = str(it.get("name", "")).strip()
            grams = float(it.get("grams", 0.0))
            conf = float(it.get("confidence", 0.0))
            key = map_label_to_key(name_raw)
            per100 = NUTRITION_PER_100G.get(key, FALLBACK_PER_100G)
            scaled = scale_nutrition(per100, grams)
            rows.append({
                "Food (detected)": key or name_raw or "unknown",
                "Portion (g)": grams,
                "Confidence": round(conf, 3),
                "Calories (kcal)": scaled["kcal"],
                "Protein (g)": scaled["protein_g"],
                "Carbs (g)": scaled["carb_g"],
                "Fat (g)": scaled["fat_g"],
                "Source": "built_in" if per100 is not FALLBACK_PER_100G else "fallback",
            })

        detections_md = (
            "\n".join([f"- {r['Food (detected)']} · {r['Portion (g)']} g · conf {r['Confidence']}" for r in rows])
            if rows else "_No foods detected confidently._"
        )

        per_item_df = pd.DataFrame(rows)
        if per_item_df.empty:
            debug_text = "\n".join(debug_lines) if (DEBUG or debug_lines) else ""
            return ("Could not detect food in the image.",
                    detections_md, pd.DataFrame(), pd.DataFrame(), None, debug_text)

        totals = {
            "Portion (g)": round(float(per_item_df["Portion (g)"].sum()), 1),
            "Calories (kcal)": round(float(per_item_df["Calories (kcal)"].sum()), 1),
            "Protein (g)": round(float(per_item_df["Protein (g)"].sum()), 2),
            "Carbs (g)": round(float(per_item_df["Carbs (g)"].sum()), 2),
            "Fat (g)": round(float(per_item_df["Fat (g)"].sum()), 2),
        }
        totals_df = pd.DataFrame([totals])

        title = f"Estimated nutrients for detected items (total ~{int(totals['Portion (g)'])} g)"
        if notes:
            title += f"\n\n*AI notes:* {notes}"

        # Save report
        report = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "mode": "openai_generative" if USE_OPENAI else "food101_classifier",
            "per_item": rows,
            "totals": totals,
        }
        path = f"calorie_report_{int(datetime.utcnow().timestamp())}.json"
        with open(path, "w", encoding="utf-8") as f:
            f.write(json.dumps(report, indent=2))

        debug_text = "\n".join(debug_lines) if (DEBUG or debug_lines) else ""
        return title, detections_md, per_item_df, totals_df, path, debug_text

    except Exception as e:
        msg = f"Something went wrong: {e}"
        return msg, "_No foods detected confidently._", pd.DataFrame(), pd.DataFrame(), None, str(e)

# ============== UI ==============
def build_ui():
    with gr.Blocks(theme=gr.themes.Soft(), fill_height=True) as demo:
        gr.Markdown(
            f"""
            # 🍽️ Calorie & Nutrition Estimator
            **Mode:** {"OpenAI Vision (gpt-4o-mini)" if USE_OPENAI else "Fallback: Food-101 classifier"}  
            Upload a photo; we’ll recognize food(s), estimate portions, and compute calories/macros.
            _Estimates only — recipes/brands vary. Not medical advice._
            """
        )

        with gr.Row():
            with gr.Column(scale=1):
                inp_image = gr.Image(label="Food photo", sources=["upload", "webcam"], type="pil", image_mode="RGB")
                use_ai_portions = gr.Checkbox(value=True, label="Use AI to estimate portion sizes")
                portion = gr.Slider(20, 1000, value=250, step=5, label="Manual portion (g) if AI portions off")
                manual_food = gr.Textbox(label="Manual override (optional)", placeholder="e.g., roast chicken")
                run_btn = gr.Button("Analyze", variant="primary")

            with gr.Column(scale=1):
                out_title = gr.Markdown()
                out_dets = gr.Markdown(label="Detections")
                out_items = gr.Dataframe(label="Per-item breakdown", wrap=True)
                out_totals = gr.Dataframe(label="Total (all items)")
                out_file = gr.File(label="Download JSON report")
                out_debug = gr.Markdown(label="Debug")

        def _run(image, ai_portions, manual_text, portion_g):
            return analyze_image(image, bool(ai_portions), manual_text or "", float(portion_g))

        run_btn.click(
            fn=_run,
            inputs=[inp_image, use_ai_portions, manual_food, portion],
            outputs=[out_title, out_dets, out_items, out_totals, out_file, out_debug]
        )
    return demo

if __name__ == "__main__":
    demo = build_ui()
    demo.launch()
