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
from pydantic import BaseModel, Field
from typing import Optional
from omnivoice.models.omnivoice import OmniVoiceGenerationConfig

# Audio sample rate constant
SAMPLE_RATE = 24000

# Initialize FastAPI
app = FastAPI(
    title="Evo OmniVoice API",
    description="REST API for OmniVoice Text-to-Speech with voice cloning and design capabilities",
    version="1.0.0"
)

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
    text: str = Field(..., description="Text to synthesize", min_length=1, max_length=5000)
    language: str = Field("en", description="Language code (en, pt, es, fr, de, ja, etc.)")
    mode: str = Field("auto", description="Synthesis mode: auto, design, clone")
    instruct: Optional[str] = Field("", description="Voice description prompt (for design mode)")
    ref_audio: Optional[str] = Field(None, description="Base64 encoded reference audio (for clone mode)")
    ref_text: Optional[str] = Field("", description="Transcript of reference audio (for clone mode)")
    num_steps: int = Field(20, description="Number of generation steps (quality)", ge=1, le=100)
    speed: float = Field(1.0, description="Audio speed multiplier", gt=0, le=5.0)
    duration: Optional[float] = Field(None, description="Target duration in seconds (0 or null for auto)", ge=0)

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
                gpu_name = torch.cuda.get_device_name(0)
                print(f"[HW] Moving model weights to {gpu_name} GPU...")
                MODEL.to("cuda") # Use .to() which is more standard
                print(f"[HW] GPU Memory Allocated: {torch.cuda.memory_allocated(0) / 1024**2:.2f} MB")

            print(f"[INFO] Model loaded successfully!")
        except Exception as e:
            print(f"[ERROR] Failed to load model: {e}")
            import traceback
            traceback.print_exc()
            raise RuntimeError(f"Initialization error: {str(e)}")
    return MODEL

@app.get("/api/status", summary="Get server status", description="Returns whether the model is loaded and GPU availability.")
async def get_status():
    """Check server status and GPU availability."""
    return {
        "status": "online",
        "model_loaded": MODEL is not None,
        "gpu_available": DEVICE_AVAILABLE,
        "gpu_name": torch.cuda.get_device_name(0) if DEVICE_AVAILABLE else "None"
    }

@app.post("/api/generate", summary="Generate audio", description="Generate speech from text using OmniVoice TTS")
async def generate_audio(request: GenerateRequest):
    """Generate audio from text using OmniVoice TTS."""
    try:
        model = load_model()
        char_count = len(request.text)

        if not request.text.strip():
            raise HTTPException(status_code=400, detail="Text is required")

        print(f"[API] Generating: {char_count} chars | Mode: {request.mode}")

        ref_audio_path = None
        if request.mode == 'clone' and request.ref_audio:
            try:
                # Handle both data URI format and raw base64
                b64_data = request.ref_audio.split(",", 1)[-1] if "," in request.ref_audio else request.ref_audio
                audio_data = base64.b64decode(b64_data)
                with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as f:
                    f.write(audio_data)
                    ref_audio_path = f.name
            except Exception as e:
                print(f"[ERROR] Reference audio failed: {e}")
                raise HTTPException(status_code=400, detail=f"Invalid reference audio: {str(e)}")

        start_time = time.time()

        try:
            # Map language to internal ID if needed
            lang_id = request.language if request.language else "en"

            # Use generate with inspected parameters
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
        except HTTPException:
            raise
        except Exception as e:
            print(f"[ERROR] Model generation failed: {e}")
            raise HTTPException(status_code=500, detail=f"Generation failed: {str(e)}")
        finally:
            if ref_audio_path and os.path.exists(ref_audio_path):
                os.unlink(ref_audio_path)

        generation_time = round(time.time() - start_time, 2)
        print(f"[API] Completed in {generation_time}s")

        if result is not None:
            # Handle different result formats (list, tensor, etc.)
            if isinstance(result, list) and len(result) > 0:
                audio_array = result[0]
            elif hasattr(result, 'numpy'):
                audio_array = result.numpy()
            else:
                raise HTTPException(status_code=500, detail="Unexpected result format from model")

            buffer = io.BytesIO()
            sf.write(buffer, audio_array, SAMPLE_RATE, format='WAV')
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

    except HTTPException:
        raise
    except Exception as e:
        print(f"[CRITICAL] {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8081)
