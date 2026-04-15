#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
OmniVoice TTS PRO - Compatible GPU Loading
"""

import os
import time
import base64
import io
import tempfile
import torch
import numpy as np
import soundfile as sf
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional

# Initialize FastAPI
app = FastAPI(title="Evo OmniVoice API")

# Enable CORS for local index.html
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Define the request class
class GenerateRequest(BaseModel):
    text: str
    language: str = "en"
    mode: str = "auto" 
    instruct: Optional[str] = "" 
    ref_audio: Optional[str] = None 
    ref_text: Optional[str] = "" 
    num_steps: int = 20 
    speed: float = 1.0
    duration: Optional[float] = None

# Global Model Variable
MODEL = None
DEVICE_AVAILABLE = torch.cuda.is_available()

def load_model():
    """Load OmniVoice model and manually move to GPU using .to()"""
    global MODEL, DEVICE_AVAILABLE
    if MODEL is None:
        try:
            from omnivoice import OmniVoice
            print(f"[HW] Checking GPU... Available: {DEVICE_AVAILABLE}")
            
            print("[INFO] Loading OmniVoice model weights...")
            # Load weights ONLY (without extra parameters as per inspection)
            MODEL = OmniVoice.from_pretrained("k2-fsa/OmniVoice")
            
            # Manually move to GPU if available
            if DEVICE_AVAILABLE:
                print("[HW] Moving model weights to RTX 3070 GPU...")
                MODEL.to("cuda") # Use .to() which is more standard
                print(f"[HW] GPU Memory Allocated: {torch.cuda.memory_allocated(0) / 1024**2:.2f} MB")
                
            print(f"[INFO] Model loaded successfully!")
        except Exception as e:
            print(f"[ERROR] Failed to load model: {e}")
            import traceback
            traceback.print_exc()
            raise RuntimeError(f"Initialization error: {str(e)}")
    return MODEL

@app.get("/api/status")
async def get_status():
    return {
        "status": "online",
        "model_loaded": MODEL is not None,
        "gpu_available": DEVICE_AVAILABLE,
        "gpu_name": torch.cuda.get_device_name(0) if DEVICE_AVAILABLE else "None"
    }

@app.post("/api/generate")
async def generate_audio(request: GenerateRequest):
    try:
        model = load_model()
        char_count = len(request.text)
        
        if not request.text.strip():
            raise HTTPException(status_code=400, detail="Text is required")

        print(f"[API] Generating: {char_count} chars | Mode: {request.mode}")
        
        ref_audio_path = None
        if request.mode == 'clone' and request.ref_audio:
            try:
                b64_data = request.ref_audio.split(",")[-1]
                audio_data = base64.b64decode(b64_data)
                with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as f:
                    f.write(audio_data)
                    ref_audio_path = f.name
            except Exception as e:
                print(f"[ERROR] Reference audio failed: {e}")

        start_time = time.time()
        
        try:
            # Map language to internal ID if needed
            lang_id = request.language if request.language else "en"
            
            # Use generate with inspected parameters
            from omnivoice.models.omnivoice import OmniVoiceGenerationConfig
            gen_config = OmniVoiceGenerationConfig(num_step=request.num_steps)
            kwargs = {
                "text": request.text,
                "language": lang_id,
                "speed": request.speed,
                "generation_config": gen_config
            }
            if request.duration is not None and request.duration > 0:
                kwargs["duration"] = request.duration
                
            if request.mode == "clone" and ref_audio_path:
                kwargs["ref_audio"] = ref_audio_path
                kwargs["ref_text"] = request.ref_text if request.ref_text else None
            elif (request.mode == "instruct" or request.mode == "design") and request.instruct:
                kwargs["instruct"] = request.instruct

            result = model.generate(**kwargs)
        except Exception as e:
            print(f"[ERROR] Model generation failed: {e}")
            raise e
        finally:
            if ref_audio_path and os.path.exists(ref_audio_path):
                os.unlink(ref_audio_path)

        generation_time = round(time.time() - start_time, 2)
        print(f"[API] Completed in {generation_time}s")

        if result and len(result) > 0:
            audio_array = result[0]
            buffer = io.BytesIO()
            sf.write(buffer, audio_array, 24000, format='WAV')
            buffer.seek(0)
            audio_b64 = base64.b64encode(buffer.read()).decode('utf-8')
            
            return {
                "success": True,
                "audio": audio_b64,
                "metrics": {
                    "char_count": char_count,
                    "generation_time": generation_time,
                    "gpu_used": DEVICE_AVAILABLE
                }
            }
        else:
            raise HTTPException(status_code=500, detail="Empty output")

    except Exception as e:
        print(f"[CRITICAL] {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8081)
