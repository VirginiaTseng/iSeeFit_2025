import os
import cv2
from ultralytics import YOLO

model = YOLO("yolov8n-pose.pt")  # load once
SAVE_DIR = "processed_videos"  # folder to save videos
os.makedirs(SAVE_DIR, exist_ok=True)
def process_video_bytes(video_bytes: bytes, filename: str, max_duration: int = 10) -> bytes:
    """
    Process video and return as bytes for streaming.
    """
    # Save input video temporarily
    input_path = os.path.join(SAVE_DIR, f"input_{filename}")
    with open(input_path, "wb") as f:
        f.write(video_bytes)

    # Output path
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
    while cap.isOpened() and frame_count < max_frames:
        ret, frame = cap.read()
        if not ret:
            break
        results = model(frame, verbose=False)
        annotated_frame = results[0].plot()
        out.write(annotated_frame)
        frame_count += 1

    cap.release()
    out.release()

    # Read processed video and return as bytes
    with open(output_path, "rb") as f:
        processed_bytes = f.read()

    return processed_bytes