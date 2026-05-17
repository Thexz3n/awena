import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import cv2
import numpy as np
import base64
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware

from scripts.recognize import GestureRecognizer

app = FastAPI()

# Allow Flutter Web (Chrome) to connect from any origin
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

print("Waking up the AI Model...")
recognizer = GestureRecognizer()
print("Model is awake and ready!")


@app.get("/health")
async def health():
    return {"status": "ok", "model": "loaded"}


@app.websocket("/ws/recognize")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    print("[WS] Flutter App Connected!")

    try:
        while True:
            data = await websocket.receive_text()

            img_bytes = base64.b64decode(data)
            np_arr = np.frombuffer(img_bytes, np.uint8)
            frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

            if frame is not None:
                gesture, confidence = recognizer.process_frame(frame)

                # Always send result so Flutter knows what's happening
                if gesture:
                    await websocket.send_json({
                        "gesture": gesture,
                        "confidence": float(confidence)
                    })
                    if confidence > 0.7:
                        print(f"[OK] {gesture} ({confidence:.0%})")

    except WebSocketDisconnect:
        print("[WS] Flutter App Disconnected.")
    except Exception as e:
        print(f"[ERR] {e}")