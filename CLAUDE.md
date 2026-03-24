# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

A three-layer bridge that lets a 32-bit Visual FoxPro (VFP) application drive a modern web-based chat UI:

1. **Python FastAPI backend** (`backend/main.py`) — serves the UI and REST API on `http://127.0.0.1:8765`
2. **C# WinForms host** (`dotnet/host/`) — standalone WebView2 host (x86) for testing outside VFP
3. **C# COM bridge** (`dotnet/bridge/`) — embeds WebView2 inside a VFP form using COM + child window hosting
4. **VFP integration layer** (`vfp_local_bridge.prg`) — called from a VFP form (`FORMS/visual_py.scx`) to start the backend, initialize the COM bridge, and POST context/chat data

## Repository layout

- `backend/` — FastAPI app and Python dependencies
- `dotnet/host/` — standalone WinForms/WebView2 host
- `dotnet/bridge/` — COM-visible x86 bridge used by VFP
- `scripts/` — startup and COM registration scripts
- `FORMS/` — Visual FoxPro form assets
- `vfp_local_bridge.prg` — VFP bridge logic

## Running the project

### Start only the Python backend
```
scripts\start_backend.bat
# or directly:
cd backend
python -m uvicorn main:app --host 127.0.0.1 --port 8765
```

### Start backend + WebView2 host together (PowerShell)
```powershell
.\scripts\start_demo.ps1
```
`scripts/start_demo.ps1` checks `/health` first; if the backend is already running it skips launching it. It then runs `dotnet run --project dotnet/host/VfpWebViewHost.csproj`.

### Build the C# host
```
dotnet build dotnet/host/VfpWebViewHost.csproj
```

### Build/register the COM bridge for VFP
```powershell
dotnet build .\dotnet\bridge\VfpWebViewBridge.csproj
.\scripts\register_vfp_webview_bridge.ps1
```

### Install Python dependencies
```
pip install -r backend/requirements.txt
```
Runtime dependencies: `fastapi==0.135.2`, `uvicorn==0.42.0`.

## Architecture details

### Python backend (`backend/main.py`)
- All state is **in-memory** in the module-level `STATE` dict — no persistence across restarts.
- The entire chat UI is a single HTML string (`UI_HTML`) served at `GET /ui`. The root `/` redirects there.
- `GET /health` is the readiness probe used by both the C# host and `vfp_local_bridge.prg`.
- `POST /api/context` accepts a `ContextPayload` (source_app, user_id, filters, dataset_info) and stores it in `STATE["context"]`.
- `POST /api/chat` appends a user message and a generated assistant reply (via `build_reply()`) to `STATE["messages"]`.
- `build_reply()` echoes back the current context — replace this with real AI/LLM logic when integrating.
- The UI polls `/api/context` and `/api/chat` every 5 seconds via `setInterval`.

### C# WinForms host (`dotnet/host/MainForm.cs`)
- Targets **net8.0-windows, x86** — the 32-bit target is intentional for VFP process compatibility.
- On load, polls `GET /health` up to 10 times with 1-second delays before navigating WebView2 to `/ui`.
- WebView2 user data is stored in `%LOCALAPPDATA%\VfpWebViewHost\WebView2`.
- If the backend is unreachable, it renders an inline HTML error page inside WebView2 (via `NavigateToString`).
- Toolbar buttons: "Reintentar" (retry navigation) and "Abrir en navegador" (open in default browser).

### C# COM bridge (`dotnet/bridge/VfpWebViewBridgeHost.cs`)
- Exposes `VfpWebViewBridge.Host` via COM for consumption from VFP.
- Hosts WebView2 on a dedicated STA thread and attaches it as a child window inside the VFP form.
- Preloads `WebView2Loader.dll` from the bridge output so VFP does not depend on the current working directory.

### VFP integration layer (`vfp_local_bridge.prg`)
- Designed to be called from within a VFP form. Entry points:
  - `BridgeInitForm(toForm, tcBridgePath)` — adds properties to the VFP form and builds the diagnostic UI dynamically using `AddObject`.
  - `HandleStartBridge(toForm)` — starts `scripts\start_backend.bat`, waits for `/health`, and embeds the WebView2 UI via the COM bridge.
  - `HandleSendContext(toForm)` — POSTs the JSON in `edtContextJson` to `/api/context`.
  - `HandleSendChat(toForm)` — POSTs the text in `edtChatMessage` to `/api/chat`.
- HTTP is done with `MSXML2.ServerXMLHTTP.6.0` (COM, no VFP external libraries needed).
- `BridgeEventSink` is a VFP Custom class whose methods are bound to form button Click events via `BINDEVENT`.
- `JsonEscape()` is a minimal hand-rolled JSON string escaper — it only handles `\`, CR/LF, tab, and double-quote.

### Startup flow (from VFP)
1. VFP form calls `BridgeInitForm(thisform, FULLPATH("vfp_local_bridge.prg"))`.
2. User clicks "Iniciar bridge" → `HandleStartBridge` → launches the backend script, waits, and embeds WebView2 inside the VFP form.
3. Alternatively, a developer can run `scripts/start_demo.ps1` directly from a terminal.
