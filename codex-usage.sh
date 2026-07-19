#!/bin/bash
# Notchy Codex usage updater.
# Reads current Codex rate limits and reset credits through the local app-server,
# with recent session JSONL as an offline fallback, then updates Notchy's state.

set -euo pipefail

CODEX_DIR="$HOME/.codex"
STATE_DIR="$CODEX_DIR/notchy"
SESSIONS_DIR="$CODEX_DIR/sessions"
USAGE_FILE="$STATE_DIR/usage"

mkdir -p "$STATE_DIR"

CODEX_SESSIONS_DIR="$SESSIONS_DIR" CODEX_USAGE_FILE="$USAGE_FILE" python3 - <<'PYEOF'
import json
import os
import selectors
import shutil
import subprocess
import time
from pathlib import Path

sessions_dir = Path(os.environ["CODEX_SESSIONS_DIR"])
usage_path = Path(os.environ["CODEX_USAGE_FILE"])

def format_number(value):
    try:
        number = float(value)
    except (TypeError, ValueError):
        return None
    if number.is_integer():
        return str(int(number))
    return f"{number:.1f}".rstrip("0").rstrip(".")

def format_int(value):
    try:
        return str(int(float(value)))
    except (TypeError, ValueError):
        return None

def read_window(value):
    if not isinstance(value, dict):
        return None
    used = format_number(value.get("usedPercent", value.get("used_percent")))
    reset = format_int(value.get("resetsAt", value.get("resets_at")))
    minutes = format_int(value.get("windowDurationMins", value.get("window_minutes")))
    if None in (used, reset, minutes):
        return None
    return (used, reset, minutes)

def query_app_server(timeout_seconds=8):
    codex = shutil.which("codex")
    if codex is None:
        return None

    process = None
    try:
        process = subprocess.Popen(
            [codex, "app-server", "--stdio"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            bufsize=1,
        )
        requests = [
            {
                "method": "initialize",
                "id": 1,
                "params": {
                    "clientInfo": {"name": "notchy", "title": "Notchy", "version": "1"},
                    "capabilities": None,
                },
            },
            {"method": "account/rateLimits/read", "id": 2},
        ]
        for request in requests:
            process.stdin.write(json.dumps(request, separators=(",", ":")) + "\n")
        process.stdin.flush()

        selector = selectors.DefaultSelector()
        selector.register(process.stdout, selectors.EVENT_READ)
        deadline = time.monotonic() + timeout_seconds
        response = None
        while time.monotonic() < deadline:
            ready = selector.select(deadline - time.monotonic())
            if not ready:
                break
            line = process.stdout.readline()
            if not line:
                break
            try:
                message = json.loads(line)
            except json.JSONDecodeError:
                continue
            if message.get("id") == 2:
                response = message.get("result")
                break
        selector.close()
        return response if isinstance(response, dict) else None
    except (OSError, ValueError, subprocess.SubprocessError):
        return None
    finally:
        if process is not None and process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=1)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()

def app_server_usage():
    result = query_app_server()
    if result is None:
        return None

    limits = result.get("rateLimits") or {}
    by_id = result.get("rateLimitsByLimitId") or {}
    limits = by_id.get("codex") or limits
    windows = []
    for key in ("primary", "secondary"):
        window = read_window(limits.get(key))
        if window is not None:
            windows.append(window)
    if not windows:
        return None

    reset_credits = result.get("rateLimitResetCredits")
    credit_count = "-1"
    nearest_expiry = "0"
    if isinstance(reset_credits, dict):
        parsed_count = format_int(reset_credits.get("availableCount"))
        if parsed_count is not None:
            credit_count = parsed_count
        expiries = []
        for credit in reset_credits.get("credits") or []:
            if not isinstance(credit, dict) or credit.get("status") != "available":
                continue
            expiry = format_int(credit.get("expiresAt"))
            if expiry is not None and int(expiry) > 0:
                expiries.append(int(expiry))
        if expiries:
            nearest_expiry = str(min(expiries))
    return windows, credit_count, nearest_expiry

try:
    usage_age = time.time() - usage_path.stat().st_mtime
    if 0 <= usage_age < 30 and usage_path.read_text().startswith("v2\t"):
        raise SystemExit(0)
except OSError:
    pass

def recent_tail(path, max_bytes=2_000_000):
    try:
        with path.open("rb") as handle:
            handle.seek(0, os.SEEK_END)
            size = handle.tell()
            handle.seek(max(0, size - max_bytes))
            data = handle.read()
    except OSError:
        return []
    return data.decode("utf-8", errors="ignore").splitlines()

usage = app_server_usage()

if usage is None and sessions_dir.exists():
    files = []
    for path in sessions_dir.rglob("*.jsonl"):
        try:
            files.append((path.stat().st_mtime, path))
        except OSError:
            pass

    latest = None
    for _mtime, path in sorted(files, reverse=True)[:30]:
        for line in recent_tail(path):
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            if event.get("payload", {}).get("type") != "token_count":
                continue
            payload = event.get("payload") or {}
            rate_limits = event.get("rate_limits") or payload.get("rate_limits") or {}
            windows = []
            for key in ("primary", "secondary"):
                window = read_window(rate_limits.get(key))
                if window is not None:
                    windows.append(window)
            if not windows:
                continue

            timestamp = event.get("timestamp") or ""
            candidate = (timestamp, windows)
            if latest is None or candidate[0] > latest[0]:
                latest = candidate

    if latest is not None:
        usage = (latest[1], "-1", "0")

if usage is None:
    raise SystemExit(0)

windows, credit_count, nearest_expiry = usage
row = ["v2", str(len(windows))]
for window in windows:
    row.extend(window)
row.extend((credit_count, nearest_expiry))

usage_path.parent.mkdir(parents=True, exist_ok=True)
tmp_path = usage_path.with_suffix(".tmp")
tmp_path.write_text("\t".join(row) + "\n")
os.replace(tmp_path, usage_path)
PYEOF
