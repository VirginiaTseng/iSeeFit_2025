import cv2
from ultralytics import YOLO
from ultralytics import solutions
import pyttsx3
import threading
import numpy as np

speaking = False
# IP_URL = "http://192.168.62.67:6677/videofeed?username=&password="
IP_URL = "http://10.0.0.213:8081/videofeed?username=admin&password=admin"

# Load the YOLO model
model = YOLO("yolo11n.pt")
cap = cv2.VideoCapture(IP_URL)

assert cap.isOpened(), "Error reading video file"
w, h, fps = (int(cap.get(x)) for x in (cv2.CAP_PROP_FRAME_WIDTH, cv2.CAP_PROP_FRAME_HEIGHT, cv2.CAP_PROP_FPS))

# Known width of the object (e.g., a car width in meters)
KNOWN_WIDTH = 100  # Example width in meters
FOCAL_LENGTH = 800  # Example focal length in pixels

# Video writer
video_writer = cv2.VideoWriter("distance_calculation.avi", cv2.VideoWriter_fourcc(*"MJPG"), 30, (640, 480))

# Init distance-calculation obj
distance1 = solutions.DistanceCalculation(model="yolo11n.pt", show=True)

def texttospeech(strs):
    def run_speech():
        engine = pyttsx3.init()
        engine.say(strs)
        engine.runAndWait()

    # Run text-to-speech in a separate thread to avoid blocking the main loop
    threading.Thread(target=run_speech).start()

def_speak_gap = 5
speak_gap = def_speak_gap

# To prevent multiple speech calls, use this flag to manage speech requests
speech_task = None

frame_counter = 0  # Used to skip frames

while cap.isOpened():
    success, im0 = cap.read()

    if not success:
        break

    frame_counter += 1
    if frame_counter % 5 != 0:  # Process every 5th frame to reduce workload
        continue

    results = model(im0)
    im0 = distance1(im0)
    for r in results:
        for box in r.boxes:
            cls = box.cls
            conf = box.conf

            if conf >= 0.5:
                # Calculate the width of the bounding box in pixels
                box_width = box.xyxy[0][1] - box.xyxy[0][0]
                # Calculate the distance
                distance = (KNOWN_WIDTH * FOCAL_LENGTH) / box_width

                if distance < 5:
                    # Schedule speech for objects too close
                    cls_name = model.names[int(cls)]
                    speech_task = threading.Thread(target=texttospeech, args=(f"{cls_name} is too close",))
                    speech_task.start()
    if im0 is None or not isinstance(im0, np.ndarray):
        continue  # Skip invalid frames

    video_writer.write(im0)



cap.release()
video_writer.release()
cv2.destroyAllWindows()
