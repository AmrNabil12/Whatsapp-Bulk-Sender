# 📱 WhatsApp Bulk Message Automator

A **WhatsApp bulk messaging automation tool** with a modern Flutter Windows desktop UI.  
Send personalized messages to hundreds of contacts automatically via WhatsApp Web.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Installation](#installation)
5. [Running the App](#running-the-app)
6. [CSV File Format](#csv-file-format)
7. [Features](#features)
8. [Project Structure](#project-structure)
9. [Development Notes](#development-notes)

---

## Overview

This project automates sending bulk WhatsApp messages using **Selenium + WhatsApp Web**.  
A **Flutter Windows desktop app** provides a clean GUI, while a **Python Flask API** bridges the UI with the Selenium bot.

On first run, Chrome will open WhatsApp Web and ask you to scan the QR code with your phone. After that, the session is saved automatically.

---

## Architecture

```
┌─────────────────────────────┐
│   Flutter Windows App       │  ← You interact here
│   (whatsapp_automator_ui/)  │
└────────────┬────────────────┘
             │ HTTP REST (port 5000)
             ▼
┌─────────────────────────────┐
│   Python Flask API Server   │  ← api_server.py
│   localhost:5000            │
└────────────┬────────────────┘
             │ subprocess
             ▼
┌─────────────────────────────┐
│   Selenium Bot              │  ← driver.py
│   (Chrome + WhatsApp Web)   │
└─────────────────────────────┘
```

**Flow:**
1. Flutter app auto-starts `api_server.py` on launch
2. User picks a CSV file and clicks **Start Sending**
3. Flask spawns a Selenium bot thread
4. Bot opens Chrome → WhatsApp Web → sends messages one by one
5. Flutter polls `/api/status` every 2 seconds and shows live progress

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Python | 3.8 + | [python.org](https://python.org) |
| Flutter | 3.3 + | [flutter.dev](https://flutter.dev) |
| Google Chrome | Latest | Must be installed |
| Windows | 10 / 11 | Developer Mode must be enabled |

> **Enable Developer Mode** (required for Flutter Windows):  
> Settings → Privacy & Security → For Developers → Developer Mode → **ON**

---

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/AmrNabil12/Whatsapp-Bulk-Sender.git
cd Whatsapp-Bulk-Sender
```

### 2. Install Python dependencies

```bash
pip install flask flask-cors colorama selenium webdriver-manager
```

### 3. Install Flutter dependencies

```bash
cd whatsapp_automator_ui
flutter pub get
cd ..
```

### 4. Create the contacts folder

```bash
mkdir data
mkdir logs
```

---

## Running the App

### ▶ Option A — One-click launcher (recommended)

Right-click **`run_app.bat`** → **Run as Administrator**

This will:
- Enable Developer Mode automatically
- Install Python dependencies
- Launch the Flutter Windows app (which auto-starts the API server)

---

### ▶ Option B — Manual (two terminals)

**Terminal 1 — Start the Python server:**
```bash
python api_server.py
```
Server runs at `http://localhost:5000`

**Terminal 2 — Start the Flutter app:**
```bash
cd whatsapp_automator_ui
flutter run -d windows
```

---

### ▶ Option C — Server only (for testing)

```bash
# Windows
start_server.bat

# or directly
python api_server.py
```

---

## CSV File Format

Place your contacts file in the `data/` folder.

> ⚠️ **Important:** Each data row must be **quoted** so the parser treats `phone,message` as a single field.

```
header_row
"01012345678,Hello Ahmed! How are you?"
"01098765432,Hi Sara, checking in!"
"01155667788,Good morning, hope you're well!"
```

**Rules:**
- First row is always skipped (header)
- Each row: `"phone_number,message"` — wrapped in double quotes
- Phone format: Egyptian numbers without country code (e.g., `01012345678`)
- The bot prepends `+2` automatically

You can also upload CSV files directly from within the app (Send screen → Upload button).

---

## Features

| Screen | What it does |
|--------|-------------|
| **Splash** | Auto-starts Python server, shows live startup log |
| **Dashboard** | Live bot status, progress bar, stats (sent / remaining / %) |
| **Send Messages** | Select CSV, toggle media attachment, Start / Stop bot |
| **Logs** | View sent & failed number lists, copy to clipboard |
| **Settings** | Configure server URL, test connection |

**Additional highlights:**
- 🌙 Dark / Light mode (follows Windows system theme)
- 🖥️ Sidebar navigation on wide screens
- ⏹️ Instant stop — bot quits Chrome and UI resets immediately
- 📎 Media sending — copy a file (Ctrl+C) then enable the toggle before sending
- 🔄 Auto-reconnect — splash screen retries if server takes time to start

---

## Project Structure

```
Whatsapp-Bulk-Sender/
│
├── api_server.py              # Flask REST API bridge (NEW)
├── driver.py                  # Selenium WhatsApp bot (original, unchanged)
├── main.py                    # Original CLI entry point (unchanged)
├── requirements.txt           # Python dependencies
├── run_app.bat                # One-click Windows launcher
├── start_server.bat           # Server-only launcher
├── README.md                  # This file
│
├── data/                      # 📁 Your CSV contact files go here (git-ignored)
├── logs/                      # 📁 Sent/failed logs from each run (git-ignored)
│
└── whatsapp_automator_ui/     # Flutter Windows app
    ├── lib/
    │   ├── main.dart          # App entry point
    │   ├── app.dart           # MaterialApp + theme
    │   ├── models/
    │   │   ├── bot_status.dart    # Bot state model
    │   │   └── log_entry.dart     # Log entry model
    │   ├── providers/
    │   │   └── bot_provider.dart  # State management (ChangeNotifier)
    │   ├── services/
    │   │   ├── api_service.dart   # HTTP client for Flask API
    │   │   └── python_service.dart # Manages Python subprocess
    │   └── screens/
    │       ├── splash_screen.dart  # Startup / server launch
    │       ├── home_screen.dart    # Dashboard + navigation shell
    │       ├── send_screen.dart    # File picker + send controls
    │       ├── logs_screen.dart    # Log viewer
    │       └── settings_screen.dart # Server URL config
    ├── pubspec.yaml
    └── android/               # Android platform (for future use)
```

---

## Development Notes

### API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/ping` | Health check |
| GET | `/api/files` | List CSV files in `data/` |
| POST | `/api/upload` | Upload a CSV file |
| GET | `/api/status` | Get current bot state |
| POST | `/api/start` | Start the bot `{filename, with_media}` |
| POST | `/api/stop` | Stop the bot |
| POST | `/api/reset` | Reset status to idle |
| GET | `/api/logs` | Get log files from `logs/` |

### Stop mechanism

When **Stop** is clicked:
1. `stop_event.set()` — signals the thread
2. `bot.quit_driver()` — closes Chrome
3. `bot_state["status"] = "idle"` — server reflects stopped state
4. Flutter immediately resets `_botStatus` locally — UI updates instantly

### WhatsApp session persistence

Chrome profile is stored in `Whatsapp-Automator-main/` folder (git-ignored).  
After scanning the QR code once, you stay logged in across restarts.

---

## ⚠️ Disclaimer

This tool is for personal/educational use only. Sending bulk messages through WhatsApp Web may violate [WhatsApp's Terms of Service](https://www.whatsapp.com/legal/terms-of-service). Use responsibly and at your own risk.
