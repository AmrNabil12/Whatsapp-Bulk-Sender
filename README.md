
# WhatsApp Automator

Automate sending WhatsApp Web messages in bulk from a CSV file using Selenium.

> ⚠️ **Important:** This project automates WhatsApp Web and can violate platform terms if misused. Use it responsibly and only with consent.

## Features

- Send text messages in bulk from a selected CSV file.
- Persistent browser session (QR login is reused via local browser profile data).
- Colorized terminal output and automatic success/failure logs.
- Simple CLI menu (`send`, `send with media`, `quit`).

## Current Project Structure

```text
.
├── main.py              # CLI menu and workflow entrypoint
├── driver.py            # Selenium bot implementation
├── requirements.txt     # Python dependencies
├── data/                # Input CSV files (private; ignored by git)
└── logs/                # Delivery logs (ignored except .gitkeep)
```

## Requirements

- Python 3.9+
- Google Chrome installed
- Stable internet connection

Install dependencies:

```bash
pip install -r requirements.txt
```

## Input File Format

Place one or more `.csv` files in the `data/` folder.

### Expected row format (current parser)

The current implementation expects each row as a **single quoted CSV value** in this shape:

```csv
"01012345678,Hello this is a test message"
"01098765432,Second message line 1
Second message line 2"
```

Notes:

- The bot prepends `+2` (Egypt country code) in code when searching contacts.
- Keep numbers **without** international prefix.
- Prefer avoiding English commas `,` in message text unless you update parser logic.

A safe sample file is included at `data/example_contacts.csv`.

## Run

```bash
python main.py
```

Menu options:

1. Send messages
2. Send messages with media (experimental workflow)
3. Quit

## Logs

Each run generates log files in `logs/`:

- `DD-MM-YYYY_HHMMSS_sent.txt`
- `DD-MM-YYYY_HHMMSS_notsent.txt`

## Known Limitations

- Country code is hardcoded as `+2` in `driver.py`.
- WhatsApp UI selector changes can break automation.
- Media option exists in menu but attachment behavior is not fully reliable in current code.

## Privacy & GitHub Readiness

This repository is configured to avoid committing private/large runtime files:

- Personal contact/message files in `data/`
- Generated logs in `logs/`
- Browser profile/cache artifacts created by Selenium/Chrome
- Virtual environments and IDE temp files

If you are uploading for the first time:

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/<your-username>/<repo-name>.git
git push -u origin main
```

## License

This project is licensed under the **MIT License**. See [LICENSE](LICENSE).
