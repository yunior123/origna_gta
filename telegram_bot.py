#!/usr/bin/env python3
"""
Telegram → Multi-AI Bridge
Supports: Claude Code CLI (Pro), Kimi 2.5 (NVIDIA NIM)

Commands:
  /start  - Initialize bot
  /claude - Switch to Claude Code (default) — can execute code, read/write files
  /kimi   - Switch to Kimi 2.5 — fast reasoning, code review, architecture
  /model  - Show current model
  /clear  - Reset conversation
  /help   - Show all commands

Run: python3 telegram_bot.py
"""

import os
import subprocess
import asyncio
import logging
import json
from pathlib import Path

import requests
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes

# Logging
logging.basicConfig(format="%(asctime)s - %(levelname)s - %(message)s", level=logging.INFO)
logger = logging.getLogger(__name__)

# Load .env from functions/
ENV_PATH = Path(__file__).parent / "functions" / ".env"
if ENV_PATH.exists():
    for line in ENV_PATH.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key and value:
                os.environ.setdefault(key, value)

# Config
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
PROJECT_DIR = Path(__file__).parent.resolve()
CLAUDE_CLI = "/Users/yuniorrodriguezosorio/.local/bin/claude"

# NVIDIA NIM Config
NIM_API_URL = "https://integrate.api.nvidia.com/v1/chat/completions"
NIM_API_KEY = os.getenv("NVIDIA_NIM_API_KEY")
KIMI_MODEL = "moonshotai/kimi-k2.5"

# System prompt for Kimi (project context)
KIMI_SYSTEM_PROMPT = """You are Kimi 2.5, a senior staff engineer working on OrignaGta — a Canada-only e-commerce marketplace built with Flutter + Firebase + Stripe Connect.

Key facts:
- MVVM architecture, Flutter frontend, Python Firebase Functions backend
- Stripe Connect Express for payments (direct charges, 2.5% platform fee)
- Firestore database, Algolia search, R2 Cloudflare for images
- Target: 100M+ users/year, single developer project
- Schema source of truth: docs/database_schema.json
- All money in integer CENTS

You help with: code review, architecture decisions, debugging, security audit, performance.
Be concise, direct, actionable. No filler. Think like a senior engineer at Stripe/Amazon."""

# Your Telegram user ID (first user auto-authorized)
ALLOWED_USER_ID = None

if not TELEGRAM_BOT_TOKEN:
    raise ValueError("TELEGRAM_BOT_TOKEN not set in functions/.env")

# Per-user state
conversations: dict[int, list] = {}
user_models: dict[int, str] = {}  # "claude" or "kimi"

# ============================================================
# AI BACKENDS
# ============================================================

def call_claude(prompt: str, timeout: int = 300) -> str:
    """Call claude CLI with --print flag (uses Pro subscription)."""
    try:
        result = subprocess.run(
            [
                CLAUDE_CLI,
                "--print",
                "--dangerously-skip-permissions",
                prompt
            ],
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=PROJECT_DIR
        )
        output = result.stdout.strip()
        if result.stderr and not output:
            output = result.stderr.strip()
        return output[:4000] if output else "(no response)"
    except subprocess.TimeoutExpired:
        return "⏱ Request timed out (5 min limit)"
    except Exception as e:
        return f"❌ Claude error: {e}"


def call_kimi(messages: list, timeout: int = 120) -> str:
    """Call Kimi 2.5 via NVIDIA NIM API (OpenAI-compatible)."""
    if not NIM_API_KEY:
        return "❌ NVIDIA_NIM_API_KEY not set in functions/.env"

    payload = {
        "model": KIMI_MODEL,
        "messages": messages,
        "temperature": 0.3,
        "max_tokens": 4096,
        "stream": False,
    }

    headers = {
        "Authorization": f"Bearer {NIM_API_KEY}",
        "Content-Type": "application/json",
    }

    try:
        res = requests.post(
            NIM_API_URL,
            headers=headers,
            json=payload,
            timeout=timeout,
        )
        res.raise_for_status()
        data = res.json()
        content = data["choices"][0]["message"]["content"]
        return content.strip() if content else "(no response)"
    except requests.exceptions.Timeout:
        return "⏱ Kimi request timed out (2 min limit)"
    except requests.exceptions.HTTPError as e:
        error_body = ""
        try:
            error_body = e.response.text[:500]
        except:
            pass
        return f"❌ Kimi API error {e.response.status_code}: {error_body}"
    except Exception as e:
        return f"❌ Kimi error: {e}"


def call_kimi_streaming(messages: list, timeout: int = 180) -> str:
    """Call Kimi 2.5 with streaming. Handles reasoning_content + content split."""
    if not NIM_API_KEY:
        return "❌ NVIDIA_NIM_API_KEY not set in functions/.env"

    payload = {
        "model": KIMI_MODEL,
        "messages": messages,
        "temperature": 0.3,
        "max_tokens": 16384,
        "stream": True,
    }

    headers = {
        "Authorization": f"Bearer {NIM_API_KEY}",
        "Accept": "text/event-stream",
        "Content-Type": "application/json",
    }

    try:
        res = requests.post(
            NIM_API_URL,
            headers=headers,
            json=payload,
            timeout=(30, timeout),
            stream=True,
        )
        res.raise_for_status()

        content_chunks = []
        reasoning_chunks = []
        for line in res.iter_lines(decode_unicode=True):
            if not line or not line.startswith("data: "):
                continue
            data_str = line[len("data: "):]
            if data_str.strip() == "[DONE]":
                break
            try:
                chunk = json.loads(data_str)
                delta = chunk["choices"][0].get("delta", {})
                # Kimi 2.5 sends reasoning in "reasoning_content" and final answer in "content"
                content = delta.get("content", "") or ""
                reasoning = delta.get("reasoning_content", "") or ""
                if content:
                    content_chunks.append(content)
                if reasoning:
                    reasoning_chunks.append(reasoning)
            except (json.JSONDecodeError, KeyError, IndexError):
                continue

        # Prefer content (the actual response). Fall back to reasoning if content is empty.
        final = "".join(content_chunks).strip()
        if not final and reasoning_chunks:
            # Model only produced reasoning (hit token limit before content)
            final = "🧠 *Kimi thinking (no final answer — token limit):*\n\n" + "".join(reasoning_chunks).strip()
        return final if final else "(no response)"
    except requests.exceptions.Timeout:
        return "⏱ Kimi request timed out"
    except requests.exceptions.HTTPError as e:
        error_body = ""
        try:
            error_body = e.response.text[:500]
        except:
            pass
        return f"❌ Kimi API error {e.response.status_code}: {error_body}"
    except Exception as e:
        return f"❌ Kimi error: {e}"


# ============================================================
# TELEGRAM HANDLERS
# ============================================================

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handle /start command."""
    global ALLOWED_USER_ID
    user = update.effective_user

    if ALLOWED_USER_ID is None:
        ALLOWED_USER_ID = user.id
        logger.info(f"Authorized user: {user.id} ({user.first_name})")

    conversations[user.id] = []
    user_models[user.id] = "claude"

    await update.message.reply_text(
        f"🤖 Multi-AI Bot Connected\n"
        f"User: {user.id}\n"
        f"Project: {PROJECT_DIR.name}\n\n"
        f"Models available:\n"
        f"  🟣 /claude — Claude Code (runs commands, edits files)\n"
        f"  🔵 /kimi — Kimi 2.5 (reasoning, review, architecture)\n\n"
        f"Current: 🟣 Claude\n\n"
        f"/model — show current\n"
        f"/clear — reset conversation\n"
        f"/help — all commands"
    )


async def switch_claude(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Switch to Claude model."""
    user_id = update.effective_user.id
    user_models[user_id] = "claude"
    conversations[user_id] = []
    await update.message.reply_text("🟣 Switched to **Claude Code**\nCan execute commands, read/write files, run tests.")


async def switch_kimi(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Switch to Kimi model."""
    user_id = update.effective_user.id
    user_models[user_id] = "kimi"
    conversations[user_id] = []
    status = "✅ API key found" if NIM_API_KEY else "❌ NVIDIA_NIM_API_KEY missing!"
    await update.message.reply_text(f"🔵 Switched to **Kimi 2.5** (NVIDIA NIM)\n{status}\nFast reasoning, code review, architecture.")


async def show_model(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Show current model."""
    user_id = update.effective_user.id
    model = user_models.get(user_id, "claude")
    icons = {"claude": "🟣 Claude Code (CLI)", "kimi": "🔵 Kimi 2.5 (NIM)"}
    await update.message.reply_text(f"Current model: {icons.get(model, model)}")


async def help_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Show help."""
    await update.message.reply_text(
        "🤖 **Commands:**\n\n"
        "/claude — Switch to Claude Code (default)\n"
        "/kimi — Switch to Kimi 2.5\n"
        "/model — Show current model\n"
        "/clear — Reset conversation\n"
        "/help — This message\n\n"
        "**Claude** can run commands, edit files, deploy.\n"
        "**Kimi** is fast for code review, architecture, debugging.\n\n"
        "Just send a message — it goes to the active model.",
        parse_mode="Markdown"
    )


async def clear(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handle /clear command."""
    user_id = update.effective_user.id
    conversations[user_id] = []
    await update.message.reply_text("🧹 Conversation cleared.")


async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Route message to the active AI model."""
    global ALLOWED_USER_ID

    logger.info(f"MSG: {update.message.text[:100] if update.message.text else 'NO TEXT'}")
    logger.info(f"FROM: {update.effective_user.id} ({update.effective_user.first_name})")

    user_id = update.effective_user.id

    # Security: only allow first user
    if ALLOWED_USER_ID is not None and user_id != ALLOWED_USER_ID:
        await update.message.reply_text("Unauthorized.")
        return
    if ALLOWED_USER_ID is None:
        ALLOWED_USER_ID = user_id

    user_message = update.message.text
    model = user_models.get(user_id, "claude")

    # Build context
    if user_id not in conversations:
        conversations[user_id] = []
    conversations[user_id].append({"role": "user", "content": user_message})

    # Keep last 10 messages
    if len(conversations[user_id]) > 10:
        conversations[user_id] = conversations[user_id][-10:]

    await update.message.chat.send_action("typing")

    loop = asyncio.get_event_loop()

    if model == "kimi":
        # Build Kimi messages with system prompt
        kimi_messages = [{"role": "system", "content": KIMI_SYSTEM_PROMPT}]
        kimi_messages.extend(conversations[user_id])
        response = await loop.run_in_executor(None, call_kimi_streaming, kimi_messages)
    else:
        # Claude: build text prompt from conversation
        context_lines = []
        for msg in conversations[user_id][-6:]:
            role = "User" if msg["role"] == "user" else "Claude"
            context_lines.append(f"{role}: {msg['content']}")
        context_str = "\n".join(context_lines)
        full_prompt = f"Previous context:\n{context_str}\n\nCurrent request: {user_message}\n\nExecute the request. Be concise in your response."
        response = await loop.run_in_executor(None, call_claude, full_prompt)

    # Save response
    conversations[user_id].append({"role": "assistant", "content": response[:500]})

    # Send
    await send_long_message(update, response)


async def send_long_message(update: Update, text: str) -> None:
    """Send message, splitting if too long."""
    if not text.strip():
        return

    if len(text) <= 4000:
        try:
            await update.message.reply_text(text, parse_mode="Markdown")
        except:
            await update.message.reply_text(text)
    else:
        chunks = [text[i:i+4000] for i in range(0, len(text), 4000)]
        for chunk in chunks:
            try:
                await update.message.reply_text(chunk, parse_mode="Markdown")
            except:
                await update.message.reply_text(chunk)
            await asyncio.sleep(0.3)


async def debug_all(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Debug: catch ALL updates."""
    logger.info(f"DEBUG UPDATE: {update}")


def main() -> None:
    """Start the bot."""
    if not Path(CLAUDE_CLI).exists():
        logger.warning(f"Claude CLI not found at {CLAUDE_CLI} — Claude mode will fail")

    if not NIM_API_KEY:
        logger.warning("NVIDIA_NIM_API_KEY not set — Kimi mode will fail")
    else:
        logger.info(f"Kimi 2.5 ready (model: {KIMI_MODEL})")

    app = Application.builder().token(TELEGRAM_BOT_TOKEN).build()

    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("claude", switch_claude))
    app.add_handler(CommandHandler("kimi", switch_kimi))
    app.add_handler(CommandHandler("model", show_model))
    app.add_handler(CommandHandler("help", help_cmd))
    app.add_handler(CommandHandler("clear", clear))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    app.add_handler(MessageHandler(filters.ALL, debug_all))

    logger.info("Bot starting (Multi-AI: Claude + Kimi 2.5)...")
    logger.info(f"Project: {PROJECT_DIR}")
    logger.info("Send /start in Telegram to begin")
    app.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
