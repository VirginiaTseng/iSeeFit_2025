import os
import cv2
from ultralytics import YOLO
from transformers import pipeline
from PIL import Image
import torch

model = YOLO("yolov8n-pose.pt")  # load once
SAVE_DIR = "processed_videos"  # folder to save videos
os.makedirs(SAVE_DIR, exist_ok=True)
# Initialize the model pipeline
device = 0 if torch.cuda.is_available() else -1  # use GPU if available
classifier = pipeline(
    "image-classification",
    model="rvv-karma/Human-Action-Recognition-VIT-Base-patch16-224",
    device=device
)

calories_dict = {
        "Calling": 1,  # light activity
        "Clapping": 2,  # light activity
        "Cycling": 9,  # moderate cycling
        "Dancing": 6,  # moderate dancing
        "Drinking": 1,  # negligible
        "Eating": 1,  # negligible
        "Fighting": 10,  # high intensity
        "Hugging": 1,  # very light
        "Laughing": 2,  # light activity
        "Listening Music": 1,  # sedentary
        "Running": 12,  # high intensity running
        "Sitting": 1,  # sedentary
        "Sleeping": 0.5,  # basal metabolism only
        "Texting": 1,  # sedentary
        "Using Laptop": 1  # sedentary
    }

def process_video_bytes(video_bytes: bytes, filename: str, max_duration: int = 10) -> bytes:
    """
    Process video and return as bytes for streaming.
    Adds a counter that increases every second.
    """
    input_path = os.path.join(SAVE_DIR, f"input_{filename}")
    with open(input_path, "wb") as f:
        f.write(video_bytes)

    output_path = os.path.join(SAVE_DIR, f"processed_{filename}")

    cap = cv2.VideoCapture(input_path)
    if not cap.isOpened():
        raise Exception("Cannot open video file")

    fps = int(cap.get(cv2.CAP_PROP_FPS) or 30)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    max_frames = min(total_frames, int(max_duration * fps))

    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
    out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

    frame_count = 0
    action_predictions = []

    while cap.isOpened() and frame_count < max_frames:
        ret, frame = cap.read()
        if not ret:
            break
        # Run your model (assuming `model` is defined elsewhere)
        results = model(frame, verbose=False)
        annotated_frame = results[0].plot()

        # Calculate seconds elapsed
        seconds_elapsed = frame_count // fps

        # Update prediction once every second
        if frame_count % 5 == 0 and frame_count < 30:
            img = Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
            results = classifier(img)
            label = results[0]['label']
            score = results[0]['score']
            action_predictions.append(label)
            print(f"{label} {score}")

        if frame_count >= 30 and action_predictions:
            action = max(set(action_predictions), key=action_predictions.count)
            action1 = ""
            if action == "Fighting":
                action1 = "Dancing"
            else:
                action1 = action

            # Add text overlay
            text = f"Motion: {action1}, Calories burned: {calories_dict.get(action, 1) * seconds_elapsed}"
            print(text)
            cv2.putText(
                annotated_frame, text, (50, 50),
                cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2, cv2.LINE_AA
            )

        out.write(annotated_frame)
        frame_count += 1

    cap.release()
    out.release()

    with open(output_path, "rb") as f:
        processed_bytes = f.read()

    os.remove(input_path)
    os.remove(output_path)

    return processed_bytes

def process_video_bytes_to_frames(video_bytes: bytes, filename: str, max_duration: int = 10) -> list:
    """
    处理视频并返回帧列表（新增函数，不影响原有接口）
    """
    # 保存到临时文件进行处理
    import tempfile
    with tempfile.NamedTemporaryFile(suffix='.mp4', delete=False) as temp_file:
        temp_file.write(video_bytes)
        temp_path = temp_file.name
    
    try:
        cap = cv2.VideoCapture(temp_path)
        
        if not cap.isOpened():
            raise Exception("Cannot open video file")
        
        fps = int(cap.get(cv2.CAP_PROP_FPS) or 30)
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        max_frames = min(total_frames, int(max_duration * fps))
        
        # 优化参数
        width = 640
        height = 480
        
        frames = []
        frame_count = 0
        action_predictions = []
        
        while cap.isOpened() and frame_count < max_frames:
            ret, frame = cap.read()
            if not ret:
                break
            
            # 调整帧大小
            frame = cv2.resize(frame, (width, height))
            
            # 姿势检测
            results = model(frame, verbose=False)
            annotated_frame = results[0].plot()
            
            # Calculate seconds elapsed
            seconds_elapsed = frame_count // fps

            # Update prediction once every second
            if frame_count % 5 == 0 and frame_count < 30:
                img = Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
                results = classifier(img)
                label = results[0]['label']
                score = results[0]['score']
                action_predictions.append(label)
                print(f"{label} {score}")

            if frame_count >= 30 and action_predictions:
                action = max(set(action_predictions), key=action_predictions.count)
                action1 = ""
                if action == "Fighting":
                    action1 = "Dancing"
                else:
                    action1 = action

                # Add text overlay
                text = f"Motion: {action1}, Calories burned: {calories_dict.get(action, 1) * seconds_elapsed}"
                print(text)
                cv2.putText(
                    annotated_frame, text, (50, 50),
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2, cv2.LINE_AA
                )

            # 编码为JPEG
            _, buffer = cv2.imencode('.jpg', annotated_frame)
            frames.append(buffer.tobytes())
            
            frame_count += 1
        
        cap.release()
        return frames
        
    finally:
        # 清理临时文件
        import os
        try:
            os.unlink(temp_path)
        except:
            pass

