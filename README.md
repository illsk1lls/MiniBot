# MiniBot

**v2.40.0** — Local AI agent for Windows. Connect a PowerShell 5.1 host to any **OpenAI-compatible** model server and get a polished dark WPF workspace: chat, tools, approvals, live media, and **inline SVG visualizations/reports** — on your machine.

<p align="center">
  <img src="https://raw.githubusercontent.com/illsk1lls/MiniBot/refs/heads/main/.readme/MiniBot.png" alt="MiniBot">
</p>

MiniBot is a single-file agent harness: progressive tools, operator approvals for host changes, multi-endpoint model switching, connect recovery when the endpoint is down, LAN discovery and domain remoting, and a UI built for day-to-day work.

---

## Highlights

| Area | Capability |
|------|------------|
| **Models** | llama.cpp, vLLM, Unsloth Studio, xAI Grok, and other OpenAI-compatible `/v1` servers |
| **Endpoints** | Primary `-BaseUrl` plus optional extras; per-endpoint auth: **API key**, **NPM Basic**, or **none** |
| **Connect** | Fast hard-timeout probe; if the host is down (or `-BaseUrl` is empty), **Connect** collects URL + auth without hard-exiting |
| **UI** | Borderless dark WPF chrome, sticky status, tool-group chips, **PoweredBy** model/endpoint picker, approval strips |
| **Media** | Inline images, video, and audio via `![label](path)` — external players only as a last resort |
| **Visualize** | Inline **SVG** charts and visualizations, WPF **SvgView** (save SVG/HTML from the card) |
| **Speed** | Prefill / generation timing under replies (**pp/s** · **t/s**) when the server or stream window provides it |
| **Network** | **PortProbe**, **FindShares**, **FindWebHosts**, **FindRdp** — targeted host(s) or LAN search when hosts are omitted |
| **Remote** | **RemoteCommand** (WinRM) for domain admins on domain-joined hosts — orange / unavailable off-domain |
| **Safety** | Auto-approve off by default; mutating actions require Yes / No / All |
| **Tools** | Progressive groups (volume/brightness, GPO, shares, CAB/ISO, Gallery, HTTP with bad-cert support, …) |
| **Deploy** | One `.ps1` (or hybrid `.cmd`), optional elevation, single-instance lock |

---

<p align="center">
  <img src="https://raw.githubusercontent.com/illsk1lls/MiniBot/refs/heads/main/.readme/MiniBot-Markdown.png" alt="Markdown Support"><br>
  Markdown Support
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/illsk1lls/MiniBot/refs/heads/main/.readme/MiniBot-CodeBlock.png" alt="Codeblocks"><br>
  Codeblocks
</p>

---

## Requirements

| Requirement | Notes |
|-------------|--------|
| **Windows 10 / 11** | WPF desktop host |
| **Windows PowerShell 5.1** | `%SystemRoot%\System32\WindowsPowerShell\v1.0` |
| **OpenAI-compatible API** | Chat completions (set `-BaseUrl` to your server) |
| **Elevation** | Re-launches elevated when repair, setup, share, or identity tools need it |
| **Optional** | `System.Speech` for voice; **curl.exe** (System32) for HTTPS with bad/self-signed certs via tools; Poppler / ImageMagick / Ghostscript for richer PDF rendering |
| **RemoteCommand** | Domain-joined PC + signed-in **domain user**; WinRM enabled and reachable on the **remote** target (5985 / 5986) |

---

## Quick start

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\path\to\MiniBot.ps1"
```

Or rename to `.cmd` and double-click (hybrid launcher minimizes the console).

Point at your server and set a display label:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\MiniBot.ps1" `
  -BaseUrl "http://127.0.0.1:8080/v1" `
  -ModelAlias "HomeLab" `
  -HideConsole:$false
```

### Hybrid launcher

The file begins with a hybrid CMD header. Rename to `.cmd` for double-click launch. For pure hybrid CMD use, follow the comment at the top of the script regarding lines above `@START`.

### First session

1. MiniBot probes the primary base with a **short hard timeout**. If nothing answers (or `-BaseUrl` is empty), the **Connect** dialog opens (URL + auth mode).
2. Authenticate if required (optional save to Windows Credential Manager).
3. Type a task and press **Enter**.
4. Use the title bar for working directory, context budget, and **PoweredBy** (model / endpoint picker).
5. Tool-group chips show active groups; some tools paint **orange** when unavailable (no vision, Home/Core GPO, or off-domain RemoteCommand).

---

## Parameters

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `-BaseUrl` | *(script default)* | Primary API base (port lives in the URL). Prefer `…/v1` for vLLM / Unsloth; bare `:8080` is fine for many llama.cpp builds. Empty `""` opens Connect immediately (no probe wait). |
| `-Model` | *(empty)* | Preferred model id; empty → auto-pick from `/models` or PoweredBy. Slash ids OK (`unsloth/…`). |
| `-ModelAlias` | *(empty)* | Display label in PoweredBy; empty → live server model id |
| `-ApiKey` | `none` | HTTP **Bearer** only (not chat text). Use `none` to skip. Examples: Unsloth `sk-unsloth-…`, vLLM `--api-key`, xAI `xai-…` |
| `-AgentName` | `MiniBot` | Window brand / agent identity |
| `-Version` | `2.35.2` | Version string |
| `-MaxTokens` | `0` | Max completion tokens. **`0` = auto** (`n_ctx / 8` from server). Pass a value to lock. |
| `-ContextWindowTokens` | `0` | Fallback `n_ctx` for budget math. **`0` = use server `/props` + `/models` only** |
| `-Temperature` | `0.15` | Sampling temperature |
| `-MaxTurns` | `30` | Max tool-loop turns per user message |
| `-MaxReplyContinues` | `5` | Auto-continue when a reply is truncated |
| `-MaxToolResultChars` | `10000` | Cap on tool output returned to the model |
| `-MaxHistoryMessages` | `48` | Soft history length target |
| `-CommandTimeoutSec` | `360` | Default command / process timeout |
| `-ContextSoftPct` | `0.72` | Soft auto-compact threshold |
| `-ContextHardPct` | `0.88` | Hard auto-compact threshold |
| `-AutoCompactEnabled` | `$true` | Auto-trim history under budget pressure |
| `-ModelCompactEnabled` | `$true` | Model-written digest on compact (else extractive) |
| `-AutoApproveEnabled` | `$false` | Start with auto-approve **off** |
| `-SpeechEnabled` | `$false` | Voice mode at launch (Right-Ctrl hold-to-talk) |
| `-SpeechAutoReply` | `$true` | TTS final assistant text when speech is on |
| `-StoreCredentials` | `$false` | Persist login via Credential Manager |
| `-ToolProfile` | `core` | `core` = progressive groups; `full` = all groups unlocked |
| `-TaskApiBase` | `""` | Optional origin for backend task cancel |
| `-DebugLog` | `$false` | Write `MiniBot-debug.log` (Desktop preferred) |
| `-HideConsole` | `$true` | Hide PowerShell / Windows Terminal host |

Booleans: `-Name:$true` / `-Name:$false`.

### Environment

| Variable | Effect |
|----------|--------|
| `$env:store=1` | Store credentials (if `-StoreCredentials` not set on the command line) |
| `$env:clear=1` | Clear stored MiniBot credentials at launch |
| `$env:debug=1` | Enable file debug log |
| `$env:speech=1` | Enable speech at launch |

**Hold Caps Lock during launch** to clear stored credentials and force a fresh login.

---

<p align="center">
  <img src="https://raw.githubusercontent.com/illsk1lls/MiniBot/refs/heads/main/.readme/MiniBot-Login.png" alt="Basic Auth Support"><br>
  Basic Auth Support
</p>

---

## Multi-endpoint & authentication

**Primary host** is always `-BaseUrl`. Auth for primary:

| Mode | How |
|------|-----|
| **API key** | `-ApiKey '…'` → `Authorization: Bearer …` (also PoweredBy / Connect **API** mode) |
| **NPM Basic** | Session login through your reverse proxy (Connect / Login UI) |
| **None** | `-ApiKey 'none'` and no NPM login (open LAN servers) |

**Extra endpoints** (hardcode near the top of the script, or **PoweredBy → + Add endpoint** at runtime):

| Mode | Behavior |
|------|----------|
| `apikey` | Bearer from the per-base key map (Unsloth, vLLM `--api-key`, cloud hosts) |
| `npm` | Same NPM Basic session as primary |
| `none` | No Authorization header |

```powershell
# Example hardcode (edit MiniBot.ps1 near the top):
# $script:MBExtraApiBases = @('http://192.168.1.20:8000/v1')
# $script:MBExtraApiAuth  = @{ 'http://192.168.1.20:8000/v1' = 'apikey' }
# $script:MBExtraApiKeys  = @{ 'http://192.168.1.20:8000/v1' = 'token-abc123' }
```

Port is part of each base URL (not a separate parameter). Prefer `…/v1` for OpenAI-compat hosts.

**Cloud example (xAI):**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\MiniBot.ps1 `
  -BaseUrl "https://api.x.ai/v1" `
  -ApiKey "xai-…" `
  -Model "grok-4.5"
```

Boot probes use a short **HttpClient** timeout (not a long hang) so Connect / Login can appear quickly when the primary host is unreachable.

---

## User interface

- Borderless dark chrome with rounded corners: drag, minimize, maximize to work area, close  
- Title bar brand, path, context budget, **PoweredBy** model / endpoint menu (click toggles open/close; **+** adds an endpoint)  
- Chat log with banners, code, tables, **inline media**, and **SVG visualization** cards  
- Sticky header: path, budget, auto-approve / auto-compact, tool-group chips (orange = gated / unavailable)  
- Approval strips: **Yes** / **No** / **All**  
- **Send** ↔ **Stop** while the agent runs (Stop ≈ Esc interrupt)  
- **Connect / Login** shared window: recover from a dead endpoint, switch auth mode (None / API / Basic NPM)  
- Reply footers may show stream speed (**pp/s** · **t/s**) when timings are available  

### Keyboard

| Key | Action |
|-----|--------|
| **Enter** | Send |
| **Ctrl+Enter** / **Shift+Enter** | Newline |
| Trailing `\` | Continue multi-line |
| **Esc** (idle) | Clear draft |
| **Esc** (busy) | Interrupt stream and tools |
| **Up** / **Down** | Input history |
| **Right-Ctrl** (hold) | Push-to-talk when speech is on |

### Inline media

When media should be seen or heard, the agent embeds it in chat:

```text
![clip title](C:\Users\You\Videos\clip.mp4)
```

Supported: common images (`png` / `jpg` / `gif` / `webp` / `bmp` / `tif`), video (`mp4` / `m4v` / `mov` / `wmv`), audio (`mp3` / `wav` / `flac` / `m4a` / `aac` / `ogg` / `wma`). Prefer absolute paths. External apps only for incompatible formats or an explicit request.

---

<p align="center">
  <img src="https://raw.githubusercontent.com/illsk1lls/MiniBot/refs/heads/main/.readme/MiniBot-Video.png" alt="Inline Video Playback"><br>
  Inline Video Playback
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/illsk1lls/MiniBot/refs/heads/main/.readme/MiniBot-Audio.png" alt="Inline Audio Playback"><br>
  Inline Audio Playback
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/illsk1lls/MiniBot/refs/heads/main/.readme/MiniBot-Image.png" alt="Inline Image Display"><br>
  Inline Images
</p>

### Inline visualization (SVG)

Reports and charts use a pure WPF **SvgView** (no browser control). The model wraps SVG between markers on their own lines:

```text
@@@RenderOpen
<svg width="680" height="240" viewBox="0 0 680 240" xmlns="http://www.w3.org/2000/svg">
  <!-- numeric width/height required; viewBox + xmlns required -->
</svg>
@@@RenderClose
```

| Rule | Detail |
|------|--------|
| **Format** | SVG only (`rect` / `circle` / `line` / `path` / `text` / …) — not WPF XAML, not markdown fences around the body |
| **Size** | Always set numeric `width` and `height` (pixels). Avoid `width="100%"` / `height="auto"` |
| **Theme** | Dark palette: `#121216` / `#1A1A1E` bg, `#E5E7EB` text, `#7AA2F7` accent |
| **Save** | Card actions can export **SVG** or **HTML** for the rendered viz |
| **Reports** | Prefer one clear chart interleaved with short markdown over empty decoration |

---

<p align="center">
  <img src="https://raw.githubusercontent.com/illsk1lls/MiniBot/refs/heads/main/.readme/MiniBot-Visualize1.png" alt="Inline Visualization"><br>
  Inline Visualization
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/illsk1lls/MiniBot/refs/heads/main/.readme/MiniBot-Visualize2.png" alt="Inline Visualization"><br>
  Inline Visualization
</p>

---

## Slash commands

| Command | Description |
|---------|-------------|
| `/help` | Full help |
| `/status` | Session stats and context bar |
| `/context` | Detailed context breakdown |
| `/clear` | Clear chat history (sticky notes/findings kept) |
| `/compact` | Aggressive history trim |
| `/note <text>` | Pin a sticky note |
| `/find <text>` | Pin a finding |
| `/forget` | Clear notes and findings |
| `/auto [on\|off]` | Toggle auto-approve |
| `/autocompact` | Toggle automatic compaction |
| `/cd <path>` | Change working directory |
| `/wd` | Print working directory |
| `/tools` | List tools and groups |
| `/tools <group>` | Enable a group (comma-separated OK) |
| `/tools full` \| `core` \| `list` | Full surface / core-only / list |
| `/sandbox` | Show sandbox root |
| `/sandbox clear` \| `clear all` | Clear session or all machine sandboxes |
| `/save [path]` | Save session (JSON / Markdown; picker if omitted) |
| `/load [path]` | Load session |
| `/model` | Show active model id |
| `/retry` | Re-send last user message |
| `/speech [on\|off]` | Voice (`auto`, `test`, `listen`, `say …`) |
| `exit` / `quit` | End session |

---

## Tool groups

Only **active** groups are exposed to the model. **`core` is always on.** Default launch uses progressive groups (`-ToolProfile core`); use `-ToolProfile full` or `/tools full` for everything.

The agent calls **EnableToolGroup** as needed (`group=network,shares` or `groups=[diag,repair]`), or you can use `/tools <group>`.

| Group | Role |
|-------|------|
| **core** | Read/write/edit/patch, find/search, hex view/edit, shell (last resort), CWD, env, EnableToolGroup |
| **senses** | Vision (ReadImage, ReadPdf, ViewScreen), SpeakText — orange when the model has no vision |
| **system** | OS inventory, processes, memory, power, services, software, updates, uptime, **AudioVolume**, **DisplayBrightness** |
| **network** | Adapters, LAN scan, **PortProbe**, **FindShares** / **FindWebHosts** / **FindRdp**, maps/printers lists, **RemoteCommand** |
| **diag** | BSOD, events, disk, startup/tasks/drivers, StopProcess, quick diagnostics |
| **repair** | sfc / DISM / chkdsk |
| **setup** | Windows options, **GroupPolicy** (local Policies registry), restore, uninstall, reboot, NewMachineSetup |
| **identity** | Local users, join / leave domain |
| **shares** | Map/unmap, create/remove share, add/remove network printer |
| **installers** | Silent install catalog |
| **sandbox** | Multi-step PowerShell lab (isolated scratch tree) |
| **files** | Download, zip, **CAB**, **ISO** (make / mount / unmount) |
| **packages** | PowerShell Gallery (isolated child process; timeout / Esc) |
| **registry** | Read / set registry |
| **clipboard** | Clipboard read / write (approval) |
| **web** | MakeHttpRequest, BrowsePage, GitHub helpers |

### Notable tool behavior

| Area | Behavior |
|------|----------|
| **Volume / brightness** | **AudioVolume** / **DisplayBrightness** in the **system** group (not core, not RunCommand / COM shells) |
| **Group Policy** | **GroupPolicy** under **setup** — local Policies registry editor. Orange / unavailable on Windows Home/Core (no gpedit) |
| **PortProbe** | Native TCP open/closed. `computer=` / `hosts=` for targeted; omit hosts for LAN flood-alive then probe. Profiles: `winrm` / `ssh` / `rdp` / `web` / `smb` |
| **FindShares** | Required for locating network shares (not net-view loops). Targeted or auto LAN search, then SMB ports + timed share guess |
| **FindWebHosts** / **FindRdp** | LAN (or targeted) discovery for web ports / RDP 3389 via PortProbe |
| **RemoteCommand** | Run a command on another PC over **WinRM** (approval). Domain-admin tool: domain-joined host + domain user. Orange off-domain. Port check before auth; closed ports stop thrash |
| **Map drive** | Auto-picks free letters (skips empty CD/DVD); blank share passwords allowed when the account is blank |
| **HTTP** | **MakeHttpRequest**: default `verify_ssl=false` uses system **curl.exe -k** for bad/self-signed HTTPS. `verify_ssl=true` = strict `Invoke-WebRequest` |
| **Gallery** | Find/Install/Update run in a child PowerShell with timeout; Esc aborts the process tree |
| **Hex** | HexView / HexEdit for PE-friendly dumps, disasm, and patch workflows |

### Network discovery modes

| Mode | How |
|------|-----|
| **Targeted** | Pass `computer=IP` or `hosts=['IP',…]` — only those machines (self always skipped) |
| **Search** | Omit hosts — ICMP flood on the local prefix, then service ports / share guesses |

**RemoteCommand** is always single-host (`host=` + `command=`). It does not LAN-flood. Prefer **PortProbe** first when checking reachability.

### Files & archives

| Tool | Purpose |
|------|---------|
| **DownloadFile** | HTTP download with live progress in the chat UI |
| **ExpandArchive** / **CompressArchive** | Zip extract / create |
| **MakeCab** / **ExpandCab** | Cabinet build (`makecab`) with progress / extract |
| **MakeIso** | Build data ISOs (IMAPI2) |
| **MountIso** / **UnmountIso** | Mount and dismount ISO images |

---

## Installer catalog

Silent (and one interactive) packages for common desktop software:

| Id | Package |
|----|---------|
| `7zip` | 7-Zip |
| `chrome` | Google Chrome |
| `adobe_reader` | Adobe Acrobat Reader DC |
| `adwcleaner` | ADWCleaner (scan / clean UI) |
| `vlc` | VLC media player |

- **ListInstallers** / **InstallPackage** — always prompt before install.  
- **NewMachineSetup** — one approval for Windows settings plus the catalog (optional `skip_software`, `dry_run`).  
- URLs and silent flags live in `$script:MBInstallerCatalog` near the top of the script.

---

## Approvals & safety

- **Auto-approve is off by default.** Host mutations need operator confirmation.  
- Read-only shell may auto-run; multi-statement, redirects, downloads, writers, and repair tools prompt.  
- The agent is instructed not to delete or destroy data unless you explicitly request that target.  
- **Esc** / **Stop** cancels the stream and tears down tracked child process trees (sandbox, commands, downloads, Gallery).  
- Network tools prompt when using non-GET methods, credentials, or private/local URLs.  
- Keep auto-approve off for untrusted models or shared machines.

---

## Context & compaction

Budget is derived from the server context window (or `-ContextWindowTokens` when set) minus the completion reserve. Soft/hard percentages of usable prompt room drive auto-compact when enabled. Force with **`/compact`**. Sticky notes and findings survive **`/clear`**.

Default completion size is **auto** (`-MaxTokens 0` → about `n_ctx / 8`) so small and large models stay balanced without hardcoding a huge ceiling.

---

## Sessions & runtime

- **`/save`** / **`/load`** — JSON or Markdown (path or file picker).  
- **`/retry`** after transient API errors.  
- Single-instance lock per application id.  
- Optional elevation re-launch preserves bound parameters while honoring `-HideConsole`.  
- Working directory and sticky banners stay aligned when tools change CWD.  
- Model list refresh runs **after** the main WPF host is up so login/connect is not blocked by long `/models` scrapes.

---

## Example launches

```powershell
# Default script base (Connect dialog if nothing is listening)
powershell -NoProfile -ExecutionPolicy Bypass -File .\MiniBot.ps1 -HideConsole:$false

# Local llama.cpp-style base without /v1
powershell -NoProfile -ExecutionPolicy Bypass -File .\MiniBot.ps1 `
  -BaseUrl "http://127.0.0.1:8080" `
  -ModelAlias "Workstation" `
  -HideConsole:$false

# OpenAI-compat /v1 with Bearer key
powershell -NoProfile -ExecutionPolicy Bypass -File .\MiniBot.ps1 `
  -BaseUrl "http://192.168.1.50:8000/v1" `
  -ApiKey "token-abc123" `
  -ModelAlias "vLLM"

# Skip the probe — open Connect immediately
powershell -NoProfile -ExecutionPolicy Bypass -File .\MiniBot.ps1 -BaseUrl ""

# Full tool surface + speech + stored login
powershell -NoProfile -ExecutionPolicy Bypass -File .\MiniBot.ps1 `
  -StoreCredentials:$true `
  -ToolProfile full `
  -SpeechEnabled:$true

# Clear stored credentials, then start
$env:clear = '1'
powershell -NoProfile -ExecutionPolicy Bypass -File .\MiniBot.ps1
```

---

## Troubleshooting

| Symptom | What to try |
|---------|-------------|
| No connection / blank after hide console | Wait for Connect (probes are short); check `-BaseUrl`, firewall, server health; `-HideConsole:$false`; run `/status` |
| Auth loop | Hold Caps Lock at launch or `$env:clear=1`; re-login; `-StoreCredentials:$true` |
| Empty model list | Confirm auth mode (API vs None vs NPM); wait for `/models` after Connect |
| 401 on cloud host | Use Auth = **API** and a Bearer key — not None/NPM |
| 500 / 502 | Wait, then **`/retry`** |
| Context pressure | `/compact`, `/clear`; raise server `n_ctx`; avoid huge tool dumps |
| Tools missing | `/tools list`, `/tools <group>`, or `-ToolProfile full` |
| GroupPolicy orange | Windows Home/Core has no local GPO editor — expected |
| Vision tools orange | Active model has no `vision` ability |
| RemoteCommand orange | Host/user not on a domain (workgroup or local login) — domain-admin tool only |
| Remote port closed | Enable WinRM / firewall on the **remote** PC; do not thrash with shell probes |
| Bad HTTPS in tools | Install **System32\curl.exe** (Win10+); `verify_ssl=false` uses `curl -k` |
| Console needed | `-HideConsole:$false` |
| Diagnostics | `-DebugLog:$true` or `$env:debug=1` → Desktop / TEMP `MiniBot-debug.log` |

---

## Design principles

1. **Local first** — your model, your network, your approvals.  
2. **Progressive surface** — lean cold start; unlock capability by task.  
3. **Operator in the loop** — privileged host actions stay visible and confirmable.  
4. **UI that works** — sticky chrome, interruptible tools, inline media & SVG viz, connect recovery, clear status.  
5. **Native Windows** — WPF + built-in remoting/file tools; no third-party browser host for charts.

---

## Scope

MiniBot is a **self-contained Windows PowerShell agent** for OpenAI-compatible local (or private) inference endpoints. You control model choice, network reach, and every privileged action the host is allowed to take.

---

<p align="center">
  <sub>MiniBot · v2.40.0 · Windows PowerShell 5.1 · WPF</sub>
</p>
