"""
WhatsApp Automator - Flask API Server
Bridges the Flutter UI with the existing Python Selenium bot.
Run this before launching the Flutter app.
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import csv
import threading
import time
from datetime import datetime

app = Flask(__name__)
CORS(app)

# ─────────────────────────────────────────────
#  Global bot state (shared across threads)
# ─────────────────────────────────────────────
bot_state = {
    "status": "idle",        # idle | running | completed | error
    "progress": 0,
    "total": 0,
    "current_number": "",
    "message": "",
    "start_time": None,
    "with_media": False,
}

bot_thread = None
current_bot = None
lock = threading.Lock()
stop_event = threading.Event()   # set when user requests stop

DATA_DIR = "data"
LOGS_DIR = "logs"


def ensure_dirs():
    os.makedirs(DATA_DIR, exist_ok=True)
    os.makedirs(LOGS_DIR, exist_ok=True)


# ─────────────────────────────────────────────
#  Routes
# ─────────────────────────────────────────────

@app.route("/api/ping", methods=["GET"])
def ping():
    return jsonify({"status": "ok", "message": "WhatsApp Automator API is running"})


@app.route("/api/files", methods=["GET"])
def list_files():
    ensure_dirs()
    files = [
        f for f in os.listdir(DATA_DIR)
        if f.endswith(".csv") or f.endswith(".xlsx")
    ]
    return jsonify({"files": files})


@app.route("/api/upload", methods=["POST"])
def upload_file():
    if "file" not in request.files:
        return jsonify({"error": "No file provided"}), 400

    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "No file selected"}), 400

    if file and (file.filename.endswith(".csv") or file.filename.endswith(".xlsx")):
        ensure_dirs()
        filepath = os.path.join(DATA_DIR, file.filename)
        file.save(filepath)
        return jsonify({
            "message": f"File '{file.filename}' uploaded successfully",
            "filename": file.filename,
        })

    return jsonify({"error": "Invalid file type. Only CSV and XLSX are allowed"}), 400


@app.route("/api/status", methods=["GET"])
def get_status():
    with lock:
        return jsonify(dict(bot_state))


@app.route("/api/start", methods=["POST"])
def start_bot():
    global bot_thread, current_bot

    data = request.get_json(force=True) or {}
    filename = data.get("filename")
    with_media = bool(data.get("with_media", False))

    if not filename:
        return jsonify({"error": "No filename provided"}), 400

    filepath = os.path.join(DATA_DIR, filename)
    if not os.path.exists(filepath):
        return jsonify({"error": f"File '{filename}' not found in data/"}), 404

    with lock:
        if bot_state["status"] == "running":
            return jsonify({"error": "Bot is already running"}), 400

    # Count contacts (skip header row if present)
    total = 0
    try:
        with open(filepath, mode="r", encoding="utf-8") as f:
            reader = csv.reader(f)
            rows = [r for r in reader if any(r)]
            total = max(0, len(rows) - 1)
    except Exception:
        total = 0

    with lock:
        bot_state.update({
            "status": "running",
            "progress": 0,
            "total": total,
            "current_number": "",
            "message": "Starting bot…",
            "start_time": datetime.now().isoformat(),
            "with_media": with_media,
        })

    bot_thread = threading.Thread(
        target=_run_bot_thread,
        args=(filepath, with_media),
        daemon=True,
    )
    bot_thread.start()
    return jsonify({"message": "Bot started successfully"})


def _run_bot_thread(filepath, with_media):
    global current_bot

    stop_event.clear()
    try:
        import sys
        sys.path.insert(0, os.getcwd())
        from driver import Bot  # noqa: F401 – imported at runtime

        current_bot = Bot()
        current_bot.csv_numbers = filepath
        if with_media:
            current_bot._options = True

        with lock:
            bot_state["message"] = "Opening WhatsApp Web… please scan the QR code."

        # Monkey-patch send_message_to_contact to track progress
        original_send = current_bot.send_message_to_contact

        def _tracked_send(number, message):
            if stop_event.is_set():
                return True   # abort silently
            with lock:
                bot_state["current_number"] = number
                bot_state["message"] = f"Sending to {number}…"
            result = original_send(number, message)
            with lock:
                bot_state["progress"] += 1
            return result

        current_bot.send_message_to_contact = _tracked_send
        current_bot.login()

        # Only mark completed if stop was NOT requested
        if not stop_event.is_set():
            with lock:
                bot_state["status"] = "completed"
                bot_state["message"] = "✅ All messages sent successfully!"

    except Exception as exc:
        # Only update state if the exception wasn't caused by a user stop
        if not stop_event.is_set():
            with lock:
                bot_state["status"] = "error"
                bot_state["message"] = f"❌ Error: {exc}"
    finally:
        current_bot = None


@app.route("/api/stop", methods=["POST"])
def stop_bot():
    global current_bot
    # Signal the background thread first so it won't override our status
    stop_event.set()
    if current_bot:
        try:
            current_bot.quit_driver()
        except Exception:
            pass
        current_bot = None

    with lock:
        bot_state["status"] = "idle"
        bot_state["message"] = "Bot stopped by user."

    return jsonify({"message": "Bot stopped"})


@app.route("/api/reset", methods=["POST"])
def reset_status():
    with lock:
        bot_state.update({
            "status": "idle",
            "progress": 0,
            "total": 0,
            "current_number": "",
            "message": "",
            "start_time": None,
            "with_media": False,
        })
    return jsonify({"message": "Status reset"})


@app.route("/api/logs", methods=["GET"])
def get_logs():
    ensure_dirs()
    logs = []
    try:
        for fname in sorted(os.listdir(LOGS_DIR), reverse=True)[:20]:
            if not fname.endswith(".txt"):
                continue
            fpath = os.path.join(LOGS_DIR, fname)
            with open(fpath, "r", encoding="utf-8") as lf:
                numbers = [n.strip() for n in lf.readlines() if n.strip()]
            logs.append({
                "filename": fname,
                "type": "sent" if fname.endswith("_sent.txt") else "not_sent",
                "count": len(numbers),
                "numbers": numbers,
            })
    except Exception as exc:
        return jsonify({"error": str(exc), "logs": []}), 500

    return jsonify({"logs": logs})


# ─────────────────────────────────────────────
#  Entry point
# ─────────────────────────────────────────────
if __name__ == "__main__":
    ensure_dirs()
    print("=" * 55)
    print("  WhatsApp Automator – API Server")
    print("  Listening on  http://0.0.0.0:5000")
    print("  Flutter app connects to http://localhost:5000")
    print("=" * 55)
    app.run(host="0.0.0.0", port=5000, debug=False, threaded=True)
