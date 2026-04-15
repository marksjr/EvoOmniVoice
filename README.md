# 🎙️ Evo OmniVoice - AI Text-to-Speech

High-quality **Text-to-Speech (TTS)** system powered by AI, supporting **11 languages**, **voice cloning**, and **emotional expressions**.

![Evo OmniVoice Interface](image.png)

---

## ✨ Key Features

- 🌍 **11 Languages Supported** - Portuguese, English, Spanish, French, German, Japanese, and more
- 🎭 **Expressive Tags** - Add laughter, sighs, whispers, and emotions to audio
- 👤 **Voice Cloning** - Clone any voice with just 3-10 seconds of audio
- 🎨 **Voice Design** - Create custom voices with descriptive prompts
- ⚡ **GPU Accelerated** - Uses NVIDIA CUDA for ultra-fast generation
- 🔌 **REST API** - Easy integration with other applications
- 📦 **100% Portable** - Everything stays within the project folder

---

## 💻 System Requirements

### Minimum Requirements
| Component | Requirement |
|---|---|
| **Operating System** | Windows 10/11 (64-bit) |
| **Processor** | Any x64 CPU (Intel/AMD) |
| **RAM** | 8 GB |
| **Storage** | 8 GB free space |
| **Internet** | Required for installation |
| **GPU** | Not required (CPU mode available) |

### Recommended Requirements
| Component | Recommendation |
|---|---|
| **Graphics Card** | NVIDIA GPU with CUDA support (GTX 1060 6GB or better) |
| **RAM** | 16 GB or more |
| **Storage** | 15 GB free space (SSD recommended) |

> **Note:** The system works without a GPU, but generation will be slower. With an NVIDIA GPU, generation is **5-10x faster**!

### GPU Compatibility
- **Supported:** NVIDIA GPUs with CUDA support (GTX 1060, RTX 2060, RTX 3070, RTX 4090, etc.)
- **Not Supported:** AMD GPUs, Intel integrated graphics (will use CPU mode)
- **VRAM Required:** Minimum 4 GB for GPU mode

---

## 🚀 Installation (Super Easy!)

### Step 1: Download the Project

```bash
git clone https://github.com/marksjr/EvoOmniVoice.git
```

Or download the ZIP directly from GitHub.

### Step 2: Install

1. Extract the folder anywhere (e.g., `C:\EvoOmniVoice`)
2. **Double-click** `install.bat`
3. Wait for automatic installation

The installer will automatically:
- ✅ Check available disk space
- ✅ Download and install portable Python
- ✅ Download and install FFmpeg
- ✅ Create virtual environment
- ✅ Install all dependencies
- ✅ Run post-installation tests

> ⏱️ **Estimated time:** 10-30 minutes (depends on your internet speed)

---

## 🎯 How to Use

### Start the System

**Double-click** `start.bat`

The system will:
1. Check if installed
2. Detect your hardware (GPU/CPU)
3. Start the server
4. Open the interface in your browser

> 🔄 **First time only:** The model will be downloaded automatically (~4-5 GB). Please wait!

### Web Interface

![Evo OmniVoice Interface](image.png)

#### Quick TTS Mode
1. Select the desired language
2. Type your text
3. Adjust speed and quality
4. Click **"Generate Audio"**

#### Voice Design Mode
1. Describe the voice you want to create
2. Use quick-select buttons for attributes
3. Click **"Generate Audio"**

**Valid attributes:**
- **Gender:** male, female
- **Age:** child, teenager, young adult, middle-aged, elderly
- **Pitch:** very low pitch, low pitch, moderate pitch, high pitch, very high pitch
- **Accent:** american, british, australian, canadian, chinese, indian, japanese, korean, portuguese, russian
- **Style:** whisper

#### Voice Cloning Mode
1. Upload reference audio (3-10 seconds)
2. (Optional) Type exact transcript of the audio
3. Type the text you want to synthesize
4. Click **"Generate Audio"**

---

## 🌍 Supported Languages

| Language | Code | Example |
|---|---|---|
| 🇧 Portuguese | `pt` | Olá, como vai você? |
| 🇺🇸 English | `en` | Hello, how are you? |
| 🇪🇸 Spanish | `es` | Hola, ¿cómo estás? |
| 🇫🇷 French | `fr` | Bonjour, comment allez-vous? |
| 🇩 German | `de` | Hallo, wie geht es Ihnen? |
| 🇯🇵 Japanese | `ja` | こんにちは、お元気ですか？ |
| 🇳🇴 Norwegian | `no` | Hei, hvordan har du det? |
| 🇸🇪 Swedish | `sv` | Hej, hur mår du? |
| 🇩 Danish | `da` | Hej, hvordan har du det? |
| 🇳🇱 Dutch | `nl` | Hallo, hoe gaat het? |
| 🇸🇦 Arabic | `ar` | مرحبا، كيف حالك؟ |

### How to Use Languages

In **Quick TTS mode**, simply:
1. **Select the language** from the dropdown menu
2. **Type your text** in the desired language

**Expressive tags** (`[laughter]`, `[sigh]`, etc.) work in **any language**!

---

## 🎭 Expressive Tags

Add emotions and sound effects to your text:

| Tag | Effect |
|---|---|
| `[laughter]` | Laughter |
| `[sigh]` | Sigh |
| `[whisper]` | Whisper |
| `[confirmation-en]` | Confirmation (en) |
| `[question-en]` | Question (en) |
| `[question-ah]` | Question (ah) |
| `[question-oh]` | Question (oh) |
| `[surprise-wa]` | Surprise (wa) |
| `[surprise-ah]` | Surprise (ah) |
| `[surprise-yo]` | Surprise (yo) |
| `[dissatisfaction-hnn]` | Dissatisfaction |

**Example:**
```
[laughter] Hello! What a beautiful day! [sigh] I am so happy today.
```

---

## 🔌 REST API

The system exposes a REST API for integration with other applications.

### System Status
```
GET http://localhost:8081/api/status
```

**Response:**
```json
{
  "status": "online",
  "model_loaded": true,
  "gpu_available": true,
  "gpu_name": "NVIDIA GeForce RTX 3070"
}
```

### Generate Audio
```
POST http://localhost:8081/api/generate
Content-Type: application/json
```

**Request body:**
```json
{
  "text": "Hello world, how are you?",
  "language": "en",
  "mode": "auto",
  "num_steps": 20,
  "speed": 1.0,
  "duration": 0
}
```

**Available modes:**
| Mode | Description |
|---|---|
| `auto` | Automatic synthesis (Quick TTS) |
| `instruct` / `design` | Voice design with prompt |
| `clone` | Voice cloning |

**Parameters for cloning:**
```json
{
  "text": "Text to synthesize",
  "language": "en",
  "mode": "clone",
  "ref_audio": "BASE64_AUDIO_STRING",
  "ref_text": "Transcript of reference audio"
}
```

**Response:**
```json
{
  "success": true,
  "audio": "BASE64_WAV_STRING",
  "metrics": {
    "char_count": 28,
    "generation_time": 2.34,
    "gpu_used": true
  }
}
```

---

## ⚙️ Settings

### Quality vs Speed
| Steps | Quality | Speed | Use Case |
|---|---|---|---|
| 16 | Fast | ⚡⚡ | Testing, prototypes |
| 20 | Balanced | ⚡⚡ | Daily use (default) |
| 32 | High | ⚡ | Production, maximum quality |

### Audio Speed
- **0.5x** - Very slow
- **1.0x** - Normal (default)
- **2.0x** - Very fast

### Fixed Duration
- **0** - Automatic (recommended)
- **1-30** - Fixed duration in seconds

---

## 📁 Project Structure

```
EvoOmniVoice/
├── install.bat          ← Install the system
├── start.bat            ← Start the system
├── server.py            ← FastAPI server
├── index.html           ← Web interface
├── doc.html             ← Documentation
├── image.png            ← Interface screenshot
├── README.md            ← This file
├── .gitignore           ← Files ignored by git
├── bin/                 ← Portable binaries (downloaded automatically)
└── venv/                ← Virtual environment (created automatically)
```

---

## ❓ Common Problems

### "Insufficient space"
Free up at least 8 GB of disk space and try again.

### "Download failed"
Check your internet connection. The installer needs to download:
- Python (~25 MB)
- FFmpeg (~70 MB)
- PyTorch (~200 MB - 2 GB)
- OmniVoice and libraries (~1 GB)

### "GPU not detected"
No problem! The system works on CPU, just slower.

### "Model takes long on first run"
Normal! The OmniVoice model will be downloaded (~4-5 GB). Subsequent runs will be fast.

### "Port 8081 already in use"
Close other programs using port 8081 or edit `server.py` to use a different port.

### "Error generating audio"
- Check if the server is running
- Try using less text (recommended maximum: 500 characters)
- Restart the system by closing and reopening `start.bat`

---

## 💡 Tips

1. **First use:** Wait for the model to fully download
2. **Quality:** Use 32 steps for better quality, 16 for faster speed
3. **Cloning:** Use clean audio without background noise
4. **Expressions:** Tags like `[laughter]` work best in English
5. **Portuguese:** The model natively supports Portuguese, just select "Portuguese"

---

## 📊 Estimated Performance

| Hardware | Generation Speed |
|---|---|
| NVIDIA RTX 4090 | ~50 chars/second |
| NVIDIA RTX 3070 | ~30 chars/second |
| NVIDIA RTX 2060 | ~20 chars/second |
| NVIDIA GTX 1060 | ~10 chars/second |
| CPU (Intel i5) | ~5 chars/second |

> *Approximate values for English text with 20 steps*

---

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest improvements
- Submit pull requests

---

## 📄 License

This project is distributed for educational and research purposes.

---

## 🔗 Links

- [GitHub Repository](https://github.com/marksjr/EvoOmniVoice)
- [Original OmniVoice Model](https://github.com/k2-fsa/OmniVoice)

---

**Built with ❤️ to be simple, portable, and powerful**
