# MiniBot

**v2.30.0** — Local AI agent for Windows. Connect a PowerShell 5.1 host to any **OpenAI-compatible** model server and get a polished dark WPF workspace: chat, tools, approvals, and live media — on your machine.

<p align="center">
  <img src="https://raw.githubusercontent.com/illsk1lls/MiniBot/refs/heads/main/.readme/MiniBot.png" alt="MiniBot">
</p>

MiniBot is a single-file agent harness: progressive tools, operator approvals for host changes, multi-endpoint model switching, and a UI built for day-to-day work — not a toy demo.

---

## Highlights

| Area | Capability |
|------|------------|
| **Models** | llama.cpp, vLLM, Unsloth Studio, and other OpenAI-compatible `/v1` servers |
| **Endpoints** | Primary `-BaseUrl` plus optional extra bases; per-endpoint auth: **API key**, **NPM Basic**, or **none** |
| **UI** | Borderless dark WPF chrome, sticky status, tool-group chips, model picker, approval strips |
| **Media** | Inline images, video, and audio in chat |
| **Safety** | Auto-approve off by default; mutating actions require Yes / No / All |
| **Tools** | Files, shell, diagnostics, shares, installers, sandbox lab, ISO/CAB, registry, web, and more |
| **Deploy** | One `.ps1` (or hybrid `.cmd`), optional elevation, single-instance lock |

---

## Requirements

| Requirement | Notes |
|-------------|--------|
| **Windows 10 / 11** | WPF desktop host |
| **Windows PowerShell 5.1** | `%SystemRoot%\System32\WindowsPowerShell\v1.0` |
| **OpenAI-compatible API** | Chat completions endpoint (default `http://127.0.0.1:8080`) |
| **Elevation** | Re-launches elevated when repair, setup, or share tools need it |
| **Optional** | `System.Speech` for basic voice; **PSWindowsUpdate** for update status; Poppler / ImageMagick / Ghostscript for richer PDF rendering |

---

## Quick start

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\path\to\MiniBot.ps1"
```

Point at your server and set a display name for the title bar:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\MiniBot.ps1" `
  -BaseUrl "http://127.0.0.1:8080" `
  -ModelAlias "HomeLab" `
  -HideConsole:$false
```

### Hybrid launcher

The file begins with a hybrid CMD header. Rename to `.cmd` for double-click launch (console minimized). For pure hybrid CMD use, follow the comment at the top of the script regarding lines above `@START`.

### First session

1. Authenticate if the server requires it (optional save to Windows Credential Manager).
2. Type a task and press **Enter**.
3. Use the title bar for working directory, context budget, and **PoweredBy** (model / endpoint picker).

---

## Parameters

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `-BaseUrl` | `http://127.0.0.1:8080` | Primary API base (port stays in the URL; prefer `…/v1` for vLLM / Unsloth) |
| `-Model` | *(empty)* | Preferred model id; empty → auto-pick from `/models` or PoweredBy |
| `-ModelAlias` | *(empty)* | Display label in PoweredBy; empty → live server model id |
| `-ApiKey` | `none` | HTTP **Bearer** only (not chat text). Use `none` to skip |
| `-AgentName` | `MiniBot` | Window brand / agent identity |
| `-Version` | `2.30.0` | Version string |
| `-MaxTokens` | `32768` | Max completion tokens (`0` = auto from server context when supported) |
| `-Temperature` | `0.15` | Sampling temperature |
| `-MaxTurns` | `30` | Max tool-loop turns per user message |
| `-MaxReplyContinues` | `8` | Auto-continue when a reply is truncated |
| `-MaxToolResultChars` | `10000` | Cap on tool output returned to the model |
| `-MaxHistoryMessages` | `48` | Soft history length target |
| `-CommandTimeoutSec` | `360` | Default command / process timeout |
| `-ContextWindowTokens` | `262144` | Fallback `n_ctx` for budget math (`0` = prefer server `/props` + `/models`) |
| `-ContextSoftPct` | `0.72` | Soft auto-compact threshold |
| `-ContextHardPct` | `0.88` | Hard auto-compact threshold |
| `-AutoCompactEnabled` | `$true` | Auto-trim history under budget pressure |
| `-ModelCompactEnabled` | `$true` | Model-written digest on compact (else extractive) |
| `-AutoApproveEnabled` | `$false` | Start with auto-approve **off** |
| `-SpeechEnabled` | `$false` | Voice mode at launch |
| `-SpeechAutoReply` | `$true` | TTS final assistant text when speech is on |
| `-StoreCredentials` | `$false` | Persist login via Credential Manager |
| `-ToolProfile` | `core` | `core` = progressive groups; `full` = all groups |
| `-TaskApiBase` | `""` | Optional origin for backend task cancel |
| `-DebugLog` | `$false` | Desktop `MiniBot-debug.log` |
| `-HideConsole` | `$true` | Hide PowerShell / Windows Terminal host |

Booleans: `-Name:$true` / `-Name:$false`.

### Environment

| Variable | Effect |
|----------|--------|
| `$env:store=1` | Store credentials (if `-StoreCredentials` not set) |
| `$env:clear=1` | Clear stored MiniBot credentials at launch |
| `$env:debug=1` | Enable file debug log |
| `$env:speech=1` | Enable speech at launch |

**Caps Lock at launch** clears stored credentials and forces a fresh login.

---

## Multi-endpoint & authentication

**Primary host** is always `-BaseUrl`. Auth for primary:

| Mode | How |
|------|-----|
| **API key** | `-ApiKey '…'` → `Authorization: Bearer …` |
| **NPM Basic** | Session login through your reverse proxy |
| **None** | `-ApiKey 'none'` and no NPM login |

**Extra endpoints** (optional hardcode at the top of the script, or **PoweredBy → + Add endpoint**):

| Mode | Behavior |
|------|----------|
| `apikey` | Bearer from the per-base key map (Unsloth, vLLM `--api-key`, …) |
| `npm` | Same NPM Basic session as primary |
| `none` | No Authorization header |

Port is part of each base URL (not a separate parameter), so HTTPS, `/v1`, and multi-host catalogs stay simple.

---

## User interface

- Borderless dark chrome: drag, minimize, maximize to work area, close  
- Title bar brand, path, context budget, **PoweredBy** model / endpoint menu (click toggles open/close)  
- Chat log with banners, code, tables, and **inline media** cards  
- Sticky header: path, budget, auto-approve / auto-compact, tool-group chips  
- Approval strips: **Yes** / **No** / **All**  
- **Send** ↔ **Stop** while the agent runs (Stop ≈ Esc interrupt)  

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

Supported inline types include common images, video (`mp4` / `m4v` / `mov` / `wmv`), and audio. External apps are reserved for incompatible formats or an explicit request.

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
| `/tools <group>` | Enable a group |
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

| Group | Role |
|-------|------|
| **core** | Read/write/edit/patch, find/search, hex, shell, CWD, env, enable groups |
| **senses** | Vision (image, PDF, screen), SpeakText |
| **system** | OS, processes, memory, services, software, uptime |
| **network** | Adapters, LAN scan, **ProbeShares**, local shares / maps / printers (lists) |
| **diag** | BSOD, events, disk, startup/tasks/drivers, StopProcess, quick diagnostics |
| **repair** | sfc / DISM / chkdsk |
| **setup** | Volume, brightness, Windows options, restore, uninstall, reboot, NewMachineSetup |
| **identity** | Local users, join / leave domain |
| **shares** | Map/unmap, create/remove share, add/remove network printer |
| **installers** | Silent install catalog |
| **sandbox** | Multi-step PowerShell lab (isolated scratch tree) |
| **files** | Download, zip, **CAB**, **ISO** (make / mount / unmount) |
| **packages** | PowerShell Gallery modules |
| **registry** | Read / set registry |
| **clipboard** | Clipboard read / write |
| **web** | HTTP client, BrowsePage, GitHub helpers |

The agent calls **EnableToolGroup** as needed, or you can use `/tools <group>`.

### Files & archives

| Tool | Purpose |
|------|---------|
| **DownloadFile** | HTTP download with live progress in the chat UI |
| **ExpandArchive** / **CompressArchive** | Zip extract / create |
| **MakeCab** / **ExpandCab** | Cabinet build (`makecab`) with progress / extract |
| **MakeIso** | Build bootable or data ISOs (IMAPI2; optional `boot_file` e.g. `efisys.bin`) |
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
- **Esc** / **Stop** cancels the stream and tears down tracked child process trees (sandbox, commands, downloads).  
- Keep auto-approve off for untrusted models or shared machines.

---

## Context & compaction

Budget is derived from context window size minus completion reserve, then soft/hard percentages of usable prompt room. Auto-compact runs when enabled and thresholds are crossed. Force with **`/compact`**. Sticky notes and findings survive **`/clear`**.

---

## Sessions & runtime

- **`/save`** / **`/load`** — JSON or Markdown (path or file picker).  
- **`/retry`** after transient API errors.  
- Single-instance lock per application id.  
- Optional elevation re-launch preserves bound parameters while honoring `-HideConsole`.

---

## Example launches

```powershell
# Local server, visible console
powershell -NoProfile -ExecutionPolicy Bypass -File .\MiniBot.ps1 `
  -BaseUrl "http://127.0.0.1:8080" `
  -ModelAlias "Workstation" `
  -HideConsole:$false

# OpenAI-compat /v1 with Bearer key
powershell -NoProfile -ExecutionPolicy Bypass -File .\MiniBot.ps1 `
  -BaseUrl "http://192.168.1.50:8000/v1" `
  -ApiKey "token-abc123" `
  -ModelAlias "vLLM"

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
| No connection | Verify `-BaseUrl`, server health, firewall; run `/status` |
| Auth loop | Hold Caps Lock at launch or `$env:clear=1`; re-login; `-StoreCredentials:$true` |
| 500 / 502 | Wait, then **`/retry`** |
| Context pressure | `/compact`, `/clear`, increase server context and `-ContextWindowTokens` |
| Tools missing | `/tools list`, `/tools <group>`, or `-ToolProfile full` |
| Console needed | `-HideConsole:$false` |
| Diagnostics | `-DebugLog:$true` or `$env:debug=1` → Desktop `MiniBot-debug.log` |

---

## Design principles

1. **Local first** — your model, your network, your approvals.  
2. **Progressive surface** — lean cold start; unlock capability by task.  
3. **Operator in the loop** — privileged host actions stay visible and confirmable.  
4. **UI that works** — sticky chrome, interruptible tools, inline media, clear status.

---

## Scope

MiniBot is a **self-contained Windows PowerShell agent** for OpenAI-compatible local (or private) inference endpoints. You control model choice, network reach, and every privileged action the host is allowed to take.

---

<p align="center">
  <sub>MiniBot · v2.30.0 · Windows PowerShell 5.1 · WPF</sub>
</p>
