# src/scripts/recognize.py
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
import cv2
import mediapipe as mp
mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils
mp_drawing_styles = mp.solutions.drawing_styles
import numpy as np
import joblib
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import time
from collections import deque


class GestureRecognizer:
    def __init__(self, model_path=Path(__file__).resolve().parent.parent / "app" / "models" / "gesture_model.pkl"):
        # Load model
        model_data = joblib.load(model_path)
        self.model = model_data['model']
        self.scaler = model_data['scaler']
        
        classes_data = model_data['classes']
        if isinstance(classes_data, dict):
            self.gesture_names = classes_data
        else:
            self.gesture_names = {i: name for i, name in enumerate(classes_data)}
        
        print(f"Loaded model with {len(self.gesture_names)} gesture classes")
        
        # OPTIMIZED MediaPipe settings for better detection
        self.mp_hands = mp_hands
        self.hands = self.mp_hands.Hands(
            static_image_mode=False,
            max_num_hands=2,
            min_detection_confidence=0.5,      # Lowered from 0.7 for easier detection
            min_tracking_confidence=0.5,       # Lowered from 0.7 for better tracking
            model_complexity=1                 # 0=lite, 1=full (more accurate)
        )
        self.mp_drawing = mp_drawing
        self.mp_drawing_styles = mp_drawing_styles
        
        # Font setup
        self.font = self._load_unicode_font()
        
        # Collection settings
        self.collected_signs = []
        self.CONFIDENCE_THRESHOLD = 0.50  # Lowered threshold
        self.STABILITY_FRAMES = 3  # Reduced from 5 for faster collection
        self.COOLDOWN_FRAMES = 30  # Reduced from 45
        
        # Prediction stabilization
        self.prediction_buffer = deque(maxlen=self.STABILITY_FRAMES)
        self.cooldown_counter = 0
        self.last_collected_gesture = None
        
        # Performance metrics
        self.fps_history = deque(maxlen=30)
        self.detection_failures = 0
        self.detection_successes = 0
        
        print(f"[Config] Detection Confidence: 50% (optimized for sensitivity)")
        print(f"[Config] Tracking Confidence: 50% (optimized for stability)")
        print(f"[Config] Model Complexity: Full (better accuracy)")
        print(f"[Config] Gesture Confidence: {self.CONFIDENCE_THRESHOLD:.0%}")
        print(f"[Config] Stability Requirement: {self.STABILITY_FRAMES} frames")
        print(f"[Config] Cooldown: {self.COOLDOWN_FRAMES} frames\n")
    
    def _load_unicode_font(self):
        """Load Unicode-compatible font"""
        try:
            font_paths = [
                "C:\\Windows\\Fonts\\Arial.ttf",
                "C:\\Windows\\Fonts\\segoeui.ttf",
                "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
                "/System/Library/Fonts/Helvetica.ttc"
            ]
            for font_path in font_paths:
                if Path(font_path).exists():
                    return ImageFont.truetype(font_path, 26)
            return ImageFont.load_default()
        except Exception as e:
            print(f"⚠️  Font loading error: {e}")
            return ImageFont.load_default()
    
    def _draw_text(self, frame, text, position, color=(255, 255, 255), 
                   bg_color=None, font_size=26):
        """Draw text with optional background"""
        try:
            frame_pil = Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
            draw = ImageDraw.Draw(frame_pil)
            
            if bg_color:
                bbox = draw.textbbox(position, text, font=self.font)
                padding = 6
                draw.rectangle(
                    [(bbox[0]-padding, bbox[1]-padding), 
                     (bbox[2]+padding, bbox[3]+padding)],
                    fill=bg_color
                )
            
            draw.text(position, text, font=self.font, fill=color)
            return cv2.cvtColor(np.array(frame_pil), cv2.COLOR_RGB2BGR)
        except Exception:
            cv2.putText(frame, text, position, cv2.FONT_HERSHEY_SIMPLEX, 
                       0.7, color, 2, cv2.LINE_AA)
            return frame
    
    def _preprocess_frame(self, frame):
        """Enhance frame for better hand detection"""
        # Convert to RGB
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # Optional: Increase brightness and contrast slightly
        # Uncomment if detection is still poor
        # hsv = cv2.cvtColor(rgb_frame, cv2.COLOR_RGB2HSV)
        # h, s, v = cv2.split(hsv)
        # v = cv2.add(v, 20)  # Increase brightness
        # hsv = cv2.merge([h, s, v])
        # rgb_frame = cv2.cvtColor(hsv, cv2.COLOR_HSV2RGB)
        
        return rgb_frame
    
    def extract_features(self, results):
        """Extract hand landmark features"""
        features = []
        
        # First hand
        if results.multi_hand_landmarks and len(results.multi_hand_landmarks) > 0:
            hand_landmarks = results.multi_hand_landmarks[0]
            landmarks_array = np.array([[lm.x, lm.y, lm.z] 
                                       for lm in hand_landmarks.landmark])
            features.extend(landmarks_array.flatten())
        else:
            features.extend([0.0] * 63)
        
        # Second hand
        if results.multi_hand_landmarks and len(results.multi_hand_landmarks) > 1:
            hand_landmarks = results.multi_hand_landmarks[1]
            landmarks_array = np.array([[lm.x, lm.y, lm.z] 
                                       for lm in hand_landmarks.landmark])
            features.extend(landmarks_array.flatten())
        else:
            features.extend([0.0] * 63)
        
        return np.array(features).reshape(1, -1)
    
    def predict(self, results):
        """Predict gesture with confidence"""
        features = self.extract_features(results)
        features_scaled = self.scaler.transform(features)
        
        prediction_idx = self.model.predict(features_scaled)[0]
        probabilities = self.model.predict_proba(features_scaled)[0]
        confidence = probabilities.max()
        
        gesture_name = self.gesture_names.get(prediction_idx, 
                                              f"Unknown_{prediction_idx}")
        
        return gesture_name, confidence, probabilities
    
    def _check_stable_prediction(self, gesture, confidence):
        """Check if prediction is stable across frames"""
        if confidence > self.CONFIDENCE_THRESHOLD:
            self.prediction_buffer.append(gesture)
        else:
            self.prediction_buffer.clear()
            return None, False
        
        if len(self.prediction_buffer) == self.STABILITY_FRAMES:
            if len(set(self.prediction_buffer)) == 1:
                return gesture, True
        
        return gesture, False
    
    def run_realtime(self):
        """Main real-time recognition loop"""
        cap = cv2.VideoCapture(0)
        
        # 🔥 OPTIMIZED camera settings
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
        cap.set(cv2.CAP_PROP_FPS, 30)
        cap.set(cv2.CAP_PROP_AUTOFOCUS, 1)  # Enable autofocus
        cap.set(cv2.CAP_PROP_AUTO_EXPOSURE, 1)  # Enable auto exposure
        
        if not cap.isOpened():
            print("❌ Error: Cannot access webcam")
            return
        
        print("\n" + "="*70)
        print("SIGN LANGUAGE SENTENCE COLLECTOR - OPTIMIZED DETECTION")
        print("="*70)
        print("Camera initialized with enhanced settings")
        print("\n TIPS FOR BETTER DETECTION:")
        print("  * Position hands 30-60cm from camera")
        print("  * Use good lighting (front/overhead light)")
        print("  * Avoid cluttered/similar-colored backgrounds")
        print("  * Show full hand with wrist visible")
        print("  * Avoid rapid movements initially")
        print("\n Controls:")
        print("  [SPACE]  - Manual add | [R] - Reset | [D] - Delete")
        print("  [Q/ESC]  - Quit | [H] - Toggle detection help overlay")
        print("="*70 + "\n")
        
        frame_count = 0
        start_time = time.time()
        show_help_overlay = True
        
        while cap.isOpened():
            frame_start = time.time()
            ret, frame = cap.read()
            if not ret:
                print("❌ Failed to read frame")
                break
            
            # Flip and get dimensions
            frame = cv2.flip(frame, 1)
            h, w, _ = frame.shape
            
            # Preprocess for better detection
            rgb_frame = self._preprocess_frame(frame)
            results = self.hands.process(rgb_frame)
            
            # Update cooldown
            if self.cooldown_counter > 0:
                self.cooldown_counter -= 1
            
            # Track detection success rate
            if results.multi_hand_landmarks:
                self.detection_successes += 1
            else:
                self.detection_failures += 1
            
            # Default status
            status_text = "🔍 No hands detected"
            status_color = (100, 100, 100)
            confidence_bar_width = 0
            current_gesture = "None"
            current_confidence = 0.0
            num_hands = 0
            
            # Process hand detection
            if results.multi_hand_landmarks:
                num_hands = len(results.multi_hand_landmarks)
                
                # Draw enhanced landmarks
                for idx, hand_landmarks in enumerate(results.multi_hand_landmarks):
                    # Draw landmarks with better visibility
                    self.mp_drawing.draw_landmarks(
                        frame,
                        hand_landmarks,
                        self.mp_hands.HAND_CONNECTIONS,
                        landmark_drawing_spec=mp.solutions.drawing_utils.DrawingSpec(
                            color=(0, 255, 0), thickness=2, circle_radius=3),
                        connection_drawing_spec=mp.solutions.drawing_utils.DrawingSpec(
                            color=(255, 255, 255), thickness=2)
                    )
                    
                    # Draw hand bounding box for visual feedback
                    x_coords = [lm.x for lm in hand_landmarks.landmark]
                    y_coords = [lm.y for lm in hand_landmarks.landmark]
                    x_min, x_max = int(min(x_coords) * w), int(max(x_coords) * w)
                    y_min, y_max = int(min(y_coords) * h), int(max(y_coords) * h)
                    cv2.rectangle(frame, (x_min-10, y_min-10), 
                                (x_max+10, y_max+10), (0, 255, 0), 2)
                    cv2.putText(frame, f"Hand {idx+1}", (x_min-10, y_min-20),
                              cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
                
                # Predict gesture
                try:
                    gesture, confidence, probabilities = self.predict(results)
                    current_gesture = gesture
                    current_confidence = confidence
                    confidence_bar_width = int(400 * confidence)
                    
                    # Check for stable prediction
                    stable_gesture, is_stable = self._check_stable_prediction(
                        gesture, confidence)
                    
                    # Auto-collect logic
                    if is_stable and self.cooldown_counter == 0:
                        if gesture != self.last_collected_gesture:
                            self.collected_signs.append(gesture)
                            self.last_collected_gesture = gesture
                            self.cooldown_counter = self.COOLDOWN_FRAMES
                            self.prediction_buffer.clear()
                            status_text = f"✅ COLLECTED: {gesture}"
                            status_color = (0, 255, 0)
                        else:
                            status_text = f"⏭️  Skipped duplicate: {gesture}"
                            status_color = (255, 165, 0)
                            self.cooldown_counter = self.COOLDOWN_FRAMES // 2
                    elif is_stable:
                        status_text = f"⏳ Cooldown: {gesture} ({self.cooldown_counter})"
                        status_color = (0, 165, 255)
                    elif len(self.prediction_buffer) > 0:
                        stability = len(self.prediction_buffer)
                        status_text = f"🎯 Stabilizing: {gesture} ({stability}/{self.STABILITY_FRAMES})"
                        status_color = (255, 200, 0)
                    else:
                        if confidence < self.CONFIDENCE_THRESHOLD:
                            status_text = f"⚠️  Low confidence: {gesture} ({confidence:.1%})"
                            status_color = (0, 100, 255)
                        else:
                            status_text = f"👁️  Detecting: {gesture}"
                            status_color = (200, 200, 0)
                
                except Exception as e:
                    status_text = f"❌ Prediction error: {str(e)[:25]}"
                    status_color = (0, 0, 255)
            
            # Draw UI overlays
            overlay = frame.copy()
            
            # Top panel
            cv2.rectangle(overlay, (0, 0), (w, 200), (30, 30, 30), -1)
            frame = cv2.addWeighted(overlay, 0.75, frame, 0.25, 0)
            
            # Status
            frame = self._draw_text(frame, status_text, (15, 20), status_color)
            
            # Hand detection indicator
            detection_rate = self.detection_successes / (self.detection_successes + self.detection_failures + 1) * 100
            detection_color = (0, 255, 0) if num_hands > 0 else (0, 0, 255)
            frame = self._draw_text(frame, f"Hands: {num_hands} | Detection Rate: {detection_rate:.1f}%", 
                                   (15, 55), detection_color)
            
            # Confidence bar
            cv2.rectangle(frame, (15, 90), (415, 110), (50, 50, 50), -1)
            if confidence_bar_width > 0:
                bar_color = (0, 255, 0) if current_confidence > self.CONFIDENCE_THRESHOLD else (0, 165, 255)
                cv2.rectangle(frame, (15, 90), (15 + confidence_bar_width, 110), 
                            bar_color, -1)
            frame = self._draw_text(frame, f"Confidence: {current_confidence:.1%} | Threshold: {self.CONFIDENCE_THRESHOLD:.0%}", 
                                   (425, 85), (255, 255, 255))
            
            # Gesture info
            buffer_status = f"Stability: {len(self.prediction_buffer)}/{self.STABILITY_FRAMES}"
            frame = self._draw_text(frame, f"Gesture: {current_gesture}", 
                                   (15, 130), (255, 255, 255))
            frame = self._draw_text(frame, buffer_status, (15, 165), (200, 200, 200))
            
            # Help overlay (toggle with 'H')
            if show_help_overlay:
                help_y = 250
                help_bg = overlay.copy()
                cv2.rectangle(help_bg, (w-350, help_y), (w-10, help_y+180), (40, 40, 40), -1)
                frame = cv2.addWeighted(help_bg, 0.8, frame, 0.2, 0)
                
                frame = self._draw_text(frame, "💡 DETECTION TIPS:", (w-340, help_y+10), (0, 255, 255))
                tips = [
                    "• Show wrist clearly",
                    "• Good front lighting",
                    "• Plain background",
                    "• 30-60cm distance",
                    "• Steady hand position",
                    "Press H to hide"
                ]
                for i, tip in enumerate(tips):
                    frame = self._draw_text(frame, tip, (w-340, help_y+40+i*22), (200, 200, 200))
            
            # Bottom panel - Sentence
            sentence_y = h - 100
            cv2.rectangle(overlay, (0, sentence_y), (w, h), (30, 30, 30), -1)
            frame = cv2.addWeighted(overlay, 0.8, frame, 0.2, 0)
            
            sentence = " → ".join(self.collected_signs) if self.collected_signs else "[Empty - Start signing!]"
            frame = self._draw_text(frame, f"Sentence ({len(self.collected_signs)}): {sentence}", 
                                   (15, sentence_y + 15), (255, 255, 255))
            
            # Controls
            controls = "SPACE: Add | R: Reset | D: Delete | H: Help | Q/ESC: Quit"
            frame = self._draw_text(frame, controls, (15, sentence_y + 55), (150, 150, 150))
            
            # FPS
            fps = 1.0 / (time.time() - frame_start + 0.001)
            self.fps_history.append(fps)
            avg_fps = np.mean(self.fps_history)
            cv2.putText(frame, f"FPS: {avg_fps:.1f}", (w - 100, h - 15), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
            
            # Display
            cv2.imshow('Sign Language Sentence Collector', frame)
            
            # Keyboard controls
            key = cv2.waitKey(1) & 0xFF
            
            if key == ord('q') or key == 27:
                print("\n👋 Quitting...")
                break
            elif key == ord('r'):
                self.collected_signs = []
                self.last_collected_gesture = None
                self.cooldown_counter = 0
                self.prediction_buffer.clear()
                print("\n🔄 Sentence reset!")
            elif key == ord('d'):
                if self.collected_signs:
                    removed = self.collected_signs.pop()
                    self.last_collected_gesture = None
                    print(f"\n🗑️  Deleted: {removed}")
            elif key == ord(' '):
                if current_confidence > self.CONFIDENCE_THRESHOLD:
                    self.collected_signs.append(current_gesture)
                    self.last_collected_gesture = current_gesture
                    self.cooldown_counter = self.COOLDOWN_FRAMES
                    print(f"\n➕ Manually added: {current_gesture}")
            elif key == ord('h'):
                show_help_overlay = not show_help_overlay
            
            frame_count += 1
        
        # Cleanup
        total_time = time.time() - start_time
        cap.release()
        cv2.destroyAllWindows()
        
        # Summary
        print("\n" + "="*70)
        print("📊 SESSION SUMMARY")
        print("="*70)
        print(f"⏱️  Duration: {total_time:.1f}s")
        print(f"🎞️  Frames: {frame_count} | FPS: {frame_count/total_time:.1f}")
        print(f"👋 Detection Rate: {detection_rate:.1f}%")
        print(f"✍️  Signs: {len(self.collected_signs)}")
        
        if self.collected_signs:
            print("\n📝 Final Sentence:")
            print("  " + " → ".join(self.collected_signs))
        else:
            print("\n⚠️  No signs collected")
        print("="*70 + "\n")

    def process_frame(self, frame):
        """Processes a single picture from Flutter and returns the word."""
        # 1. Prepare the image using your existing method
        rgb_frame = self._preprocess_frame(frame)
        results = self.hands.process(rgb_frame)
        
        # 2. If it sees a hand...
        if results.multi_hand_landmarks:
            try:
                # 3. Use your existing predict method! (It handles both hands perfectly)
                gesture, confidence, probabilities = self.predict(results)
                return gesture, confidence
            except Exception as e:
                print(f"Error predicting frame: {e}")
                return None, 0.0
                
        # If no hand is seen, return nothing
        return None, 0.0


if __name__ == "__main__":
    recognizer = GestureRecognizer()
    recognizer.run_realtime()
