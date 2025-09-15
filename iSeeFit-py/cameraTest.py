import cv2
import requests

def test_stream_access():
    # Test direct HTTP access
    try:
        response = requests.get("http://10.0.0.213:8081/video", stream=True)
        print(f"HTTP Status Code: {response.status_code}")
    except Exception as e:
        print(f"HTTP Request Error: {e}")

    # Test OpenCV access
    stream = cv2.VideoCapture("http://10.0.0.213:8081/video")
    if stream.isOpened():
        print("OpenCV: Stream opened successfully")
        ret, frame = stream.read()
        if ret:
            print("OpenCV: Successfully read a frame")
        else:
            print("OpenCV: Could not read frame")
    else:
        print("OpenCV: Failed to open stream")
    
    stream.release()





if __name__ == "__main__":
    test_stream_access()

import time


# # Try different URL formats
# IP_URL_OPTIONS = [
#     "http://10.0.0.213:8081/video",
#     "http://10.0.0.213:8081/videofeed",
#     "http://10.0.0.213:8081/stream",
#     "rtsp://10.0.0.213:8081/video"  # If RTSP is supported
# ]



# def connect_to_stream(url, max_retries=3, delay=2):
#     for attempt in range(max_retries):
#         print(f"Attempt {attempt + 1} to connect to stream...")
#         cap = cv2.VideoCapture(url)
#         if cap.isOpened():
#             return cap
#         time.sleep(delay)
#     return None

# IP_URL="rstp://admin:admin@10.0.0.213:8554/live"

# # Replace the original VideoCapture code with:
# cap = connect_to_stream(IP_URL)
# if cap is None:
#     raise RuntimeError("Failed to connect to stream after multiple attempts")