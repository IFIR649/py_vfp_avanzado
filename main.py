from datetime import datetime, timezone
import json
from typing import Any

from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse, RedirectResponse
from pydantic import BaseModel, Field

app = FastAPI(title="VFP Local Bridge")

STATE: dict[str, Any] = {
    "started_at_utc": datetime.now(timezone.utc).isoformat(),
    "context": {},
    "messages": [],
}


class ContextPayload(BaseModel):
    source_app: str
    user_id: str | None = None
    filters: dict[str, Any] = Field(default_factory=dict)
    dataset_info: dict[str, Any] = Field(default_factory=dict)


class ChatPayload(BaseModel):
    message: str


UI_HTML = """<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <title>Chat Analitico Local</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    :root {
      --bg-top: #082f49;
      --bg-bottom: #020617;
      --panel: rgba(15, 23, 42, 0.78);
      --panel-strong: rgba(15, 23, 42, 0.92);
      --border: rgba(148, 163, 184, 0.18);
      --text: #e2e8f0;
      --muted: #94a3b8;
      --ok: #22c55e;
      --warn: #f59e0b;
      --error: #ef4444;
      --accent: #38bdf8;
      --accent-strong: #0ea5e9;
      --shadow: 0 20px 60px rgba(2, 6, 23, 0.35);
    }

    * {
      box-sizing: border-box;
    }

    body {
      margin: 0;
      min-height: 100vh;
      color: var(--text);
      font-family: "Segoe UI Variable Text", "Segoe UI", sans-serif;
      background:
        radial-gradient(circle at top left, rgba(56, 189, 248, 0.18), transparent 30%),
        radial-gradient(circle at top right, rgba(34, 197, 94, 0.14), transparent 26%),
        linear-gradient(160deg, var(--bg-top), var(--bg-bottom) 55%);
    }

    .shell {
      max-width: 1200px;
      margin: 0 auto;
      padding: 24px;
    }

    .hero {
      display: flex;
      justify-content: space-between;
      align-items: flex-end;
      gap: 24px;
      margin-bottom: 20px;
    }

    .eyebrow {
      margin: 0 0 10px;
      text-transform: uppercase;
      letter-spacing: 0.2em;
      font-size: 12px;
      color: #7dd3fc;
    }

    .title {
      margin: 0;
      font-size: clamp(32px, 5vw, 54px);
      line-height: 0.95;
      letter-spacing: -0.05em;
    }

    .subtitle {
      max-width: 700px;
      margin: 12px 0 0;
      color: var(--muted);
      font-size: 15px;
      line-height: 1.6;
    }

    .status-chip {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 12px 16px;
      border-radius: 999px;
      font-size: 14px;
      background: rgba(15, 23, 42, 0.72);
      border: 1px solid var(--border);
      box-shadow: var(--shadow);
      white-space: nowrap;
    }

    .status-chip::before {
      content: "";
      width: 10px;
      height: 10px;
      border-radius: 50%;
      background: var(--warn);
      box-shadow: 0 0 12px rgba(245, 158, 11, 0.5);
    }

    .status-chip[data-mode="ok"]::before {
      background: var(--ok);
      box-shadow: 0 0 14px rgba(34, 197, 94, 0.55);
    }

    .status-chip[data-mode="error"]::before {
      background: var(--error);
      box-shadow: 0 0 14px rgba(239, 68, 68, 0.55);
    }

    .grid {
      display: grid;
      grid-template-columns: minmax(280px, 360px) minmax(0, 1fr);
      gap: 18px;
    }

    .panel {
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: 22px;
      overflow: hidden;
      box-shadow: var(--shadow);
      backdrop-filter: blur(18px);
    }

    .panel-head {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      padding: 18px 20px;
      border-bottom: 1px solid var(--border);
      background: rgba(15, 23, 42, 0.5);
    }

    .panel-head h2,
    .panel-head h3 {
      margin: 0;
      font-size: 16px;
      letter-spacing: 0.02em;
    }

    .panel-body {
      padding: 20px;
    }

    .meta {
      display: grid;
      gap: 16px;
    }

    .muted {
      color: var(--muted);
      font-size: 13px;
      line-height: 1.6;
    }

    .json-block,
    .messages pre {
      margin: 0;
      font-family: Consolas, "Courier New", monospace;
      font-size: 13px;
      white-space: pre-wrap;
      word-break: break-word;
    }

    .json-block {
      min-height: 240px;
      padding: 16px;
      border-radius: 16px;
      background: rgba(2, 6, 23, 0.5);
      border: 1px solid rgba(56, 189, 248, 0.15);
    }

    .button-row {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
    }

    button {
      border: 0;
      border-radius: 999px;
      padding: 12px 18px;
      color: white;
      cursor: pointer;
      font-size: 14px;
      font-weight: 600;
      background: linear-gradient(135deg, var(--accent), var(--accent-strong));
      transition: transform 120ms ease, opacity 120ms ease;
    }

    button:hover {
      transform: translateY(-1px);
    }

    button:disabled {
      opacity: 0.6;
      cursor: not-allowed;
      transform: none;
    }

    button.secondary {
      color: var(--text);
      background: rgba(30, 41, 59, 0.9);
      border: 1px solid var(--border);
    }

    .panel-chat {
      display: flex;
      flex-direction: column;
      min-height: 640px;
    }

    .messages {
      flex: 1;
      padding: 20px;
      display: flex;
      flex-direction: column;
      gap: 14px;
      overflow: auto;
      background:
        linear-gradient(180deg, rgba(8, 47, 73, 0.08), transparent 30%),
        rgba(15, 23, 42, 0.3);
    }

    .message {
      max-width: min(760px, 92%);
      padding: 14px 16px;
      border-radius: 18px;
      border: 1px solid var(--border);
      background: rgba(30, 41, 59, 0.9);
    }

    .message.user {
      align-self: flex-end;
      border-color: rgba(56, 189, 248, 0.28);
      background: linear-gradient(135deg, rgba(8, 145, 178, 0.85), rgba(14, 165, 233, 0.9));
    }

    .message.assistant {
      align-self: flex-start;
      background: rgba(15, 23, 42, 0.96);
    }

    .message-role {
      margin-bottom: 8px;
      font-size: 12px;
      font-weight: 700;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      color: rgba(226, 232, 240, 0.8);
    }

    .empty {
      padding: 24px;
      border-radius: 18px;
      border: 1px dashed rgba(148, 163, 184, 0.3);
      color: var(--muted);
      background: rgba(2, 6, 23, 0.25);
    }

    .composer {
      border-top: 1px solid var(--border);
      background: var(--panel-strong);
      padding: 18px;
    }

    textarea {
      width: 100%;
      min-height: 120px;
      resize: vertical;
      border: 1px solid rgba(56, 189, 248, 0.18);
      border-radius: 18px;
      padding: 16px;
      color: var(--text);
      background: rgba(2, 6, 23, 0.55);
      font: inherit;
      outline: none;
    }

    textarea:focus {
      border-color: rgba(56, 189, 248, 0.55);
      box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.15);
    }

    .actions {
      margin-top: 12px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
    }

    .error-text {
      min-height: 20px;
      color: #fca5a5;
      font-size: 13px;
    }

    @media (max-width: 920px) {
      .shell {
        padding: 18px;
      }

      .hero {
        flex-direction: column;
        align-items: flex-start;
      }

      .grid {
        grid-template-columns: 1fr;
      }

      .panel-chat {
        min-height: 540px;
      }

      .message {
        max-width: 100%;
      }

      .actions {
        flex-direction: column;
        align-items: stretch;
      }

      button {
        width: 100%;
      }
    }
  </style>
</head>
<body>
  <div class="shell">
    <header class="hero">
      <div>
        <p class="eyebrow">localhost bridge</p>
        <h1 class="title">Chat Analitico</h1>
        <p class="subtitle">
          Primera version para VFP x86 con backend Python fuera del proceso y UI moderna
          cargada en WebView2.
        </p>
      </div>
      <div id="status-chip" class="status-chip" data-mode="busy">Conectando...</div>
    </header>

    <section class="grid">
      <aside class="panel">
        <div class="panel-head">
          <h2>Contexto actual</h2>
          <span class="muted">/api/context</span>
        </div>
        <div class="panel-body meta">
          <p class="muted">
            Aqui debe aterrizar el JSON que VFP envie con filtros, usuario, dataset y metadatos.
          </p>
          <pre id="context-view" class="json-block">Cargando contexto...</pre>
          <div class="button-row">
            <button id="refresh-btn" class="secondary" type="button">Refrescar</button>
            <button id="reset-btn" class="secondary" type="button">Limpiar chat</button>
          </div>
        </div>
      </aside>

      <section class="panel panel-chat">
        <div class="panel-head">
          <h3>Sesion local</h3>
          <span class="muted">/api/chat</span>
        </div>

        <div id="messages" class="messages"></div>

        <form id="chat-form" class="composer">
          <textarea
            id="message"
            placeholder="Pregunta algo sobre el dataset actual"
          ></textarea>
          <div class="actions">
            <div id="error-text" class="error-text"></div>
            <button id="send-btn" type="submit">Enviar</button>
          </div>
        </form>
      </section>
    </section>
  </div>

  <script>
    const contextView = document.getElementById('context-view');
    const messagesEl = document.getElementById('messages');
    const statusChip = document.getElementById('status-chip');
    const chatForm = document.getElementById('chat-form');
    const messageBox = document.getElementById('message');
    const sendButton = document.getElementById('send-btn');
    const refreshButton = document.getElementById('refresh-btn');
    const resetButton = document.getElementById('reset-btn');
    const errorText = document.getElementById('error-text');

    function setStatus(text, mode) {
      statusChip.textContent = text;
      statusChip.dataset.mode = mode;
    }

    function renderContext(data) {
      if (!data || Object.keys(data).length === 0) {
        contextView.textContent = 'Sin contexto enviado todavia.';
        return;
      }

      contextView.textContent = JSON.stringify(data, null, 2);
    }

    function renderMessages(messages) {
      messagesEl.innerHTML = '';

      if (!messages || messages.length === 0) {
        const empty = document.createElement('div');
        empty.className = 'empty';
        empty.textContent = 'Todavia no hay mensajes. Envia una pregunta o publica contexto desde VFP.';
        messagesEl.appendChild(empty);
        return;
      }

      for (const message of messages) {
        const card = document.createElement('article');
        card.className = `message ${message.role}`;

        const role = document.createElement('div');
        role.className = 'message-role';
        role.textContent = message.role === 'assistant' ? 'Asistente local' : 'Usuario';

        const content = document.createElement('pre');
        content.textContent = message.content;

        card.append(role, content);
        messagesEl.appendChild(card);
      }

      messagesEl.scrollTop = messagesEl.scrollHeight;
    }

    async function requestJson(url, options) {
      const response = await fetch(url, options);
      if (!response.ok) {
        let detail = `HTTP ${response.status}`;
        try {
          const data = await response.json();
          detail = data.detail || detail;
        } catch (error) {
          // Keep default detail.
        }
        throw new Error(detail);
      }

      return response.json();
    }

    async function refreshAll() {
      errorText.textContent = '';
      setStatus('Sincronizando...', 'busy');

      try {
        const [contextData, chatData] = await Promise.all([
          requestJson('/api/context'),
          requestJson('/api/chat')
        ]);

        renderContext(contextData);
        renderMessages(chatData.messages || []);
        setStatus('Conectado a localhost', 'ok');
      } catch (error) {
        renderContext({});
        renderMessages([]);
        errorText.textContent = error.message;
        setStatus('Backend no disponible', 'error');
      }
    }

    async function sendMessage(event) {
      event.preventDefault();
      const message = messageBox.value.trim();

      if (!message) {
        errorText.textContent = 'Escribe un mensaje antes de enviar.';
        return;
      }

      sendButton.disabled = true;
      errorText.textContent = '';

      try {
        await requestJson('/api/chat', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ message })
        });

        messageBox.value = '';
        await refreshAll();
      } catch (error) {
        errorText.textContent = error.message;
        setStatus('Error al enviar', 'error');
      } finally {
        sendButton.disabled = false;
        messageBox.focus();
      }
    }

    async function resetChat() {
      resetButton.disabled = true;
      errorText.textContent = '';

      try {
        await requestJson('/api/chat/reset', { method: 'POST' });
        await refreshAll();
      } catch (error) {
        errorText.textContent = error.message;
        setStatus('Error al limpiar', 'error');
      } finally {
        resetButton.disabled = false;
      }
    }

    messageBox.addEventListener('keydown', (event) => {
      if (event.key === 'Enter' && !event.shiftKey) {
        event.preventDefault();
        chatForm.requestSubmit();
      }
    });

    refreshButton.addEventListener('click', refreshAll);
    resetButton.addEventListener('click', resetChat);
    chatForm.addEventListener('submit', sendMessage);

    refreshAll();
    window.setInterval(refreshAll, 5000);
  </script>
</body>
</html>
"""


def build_reply(message: str) -> str:
    context = STATE["context"] or {}
    filters = context.get("filters") or {}
    dataset_info = context.get("dataset_info") or {}

    lines = [
        "Recibi tu pregunta y el contexto local.",
        "",
        f"Pregunta: {message}",
    ]

    if context.get("source_app"):
        lines.extend(["", f"Origen: {context['source_app']}"])

    if filters:
        lines.extend(["", "Filtros actuales:", json.dumps(filters, indent=2, ensure_ascii=False)])

    if dataset_info:
        lines.extend(["", "Dataset actual:", json.dumps(dataset_info, indent=2, ensure_ascii=False)])

    if not filters and not dataset_info:
        lines.extend(["", "Todavia no hay contexto enviado desde VFP."])

    return "\n".join(lines)


@app.get("/", include_in_schema=False)
def root():
    return RedirectResponse(url="/ui", status_code=307)


@app.get("/health")
def health():
    return {
        "ok": True,
        "service": "vfp-local-bridge",
        "started_at_utc": STATE["started_at_utc"],
        "message_count": len(STATE["messages"]),
        "has_context": bool(STATE["context"]),
    }


@app.get("/ui", response_class=HTMLResponse)
def ui():
    return HTMLResponse(UI_HTML)


@app.get("/api/context")
def get_context():
    return STATE["context"]


@app.post("/api/context")
def set_context(payload: ContextPayload):
    STATE["context"] = payload.model_dump()
    return {
        "ok": True,
        "context_keys": sorted(STATE["context"].keys()),
    }


@app.get("/api/chat")
def get_chat():
    return {"messages": STATE["messages"]}


@app.post("/api/chat")
def post_chat(payload: ChatPayload):
    message = payload.message.strip()
    if not message:
        raise HTTPException(status_code=400, detail="Message cannot be empty.")

    STATE["messages"].append({"role": "user", "content": message})
    STATE["messages"].append({"role": "assistant", "content": build_reply(message)})

    return {
        "ok": True,
        "message_count": len(STATE["messages"]),
    }


@app.post("/api/chat/reset")
def reset_chat():
    STATE["messages"].clear()
    return {"ok": True}
