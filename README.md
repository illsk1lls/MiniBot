# MiniBot

**v2.51.0** - Local AI agent for Windows. Connect a PowerShell 5.1 host to any **OpenAI-compatible** model server and get a polished dark WPF workspace: chat, tools, approvals, live media, and **inline SVG visualizations** - on your machine.

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
| **UI** | Borderless dark WPF chrome, sticky status, tool-group chips, **PoweredBy** model/endpoint picker, **TaskBoard sticky** under chips |
| **Media** | Inline images, video, and audio via `![label](path)` - external players only as a last resort |
| **Visualize** | Inline **SVG** charts and visualization - pure WPF **SvgView** (save SVG/HTML from the card) |
| **Speed** | Prefill / generation timing under replies (**pp/s** · **t/s**) when the server or stream window provides it |
| **Network** | **PortProbe**, **FindShares**, **FindWebHosts**, **FindRdp** - targeted host(s) or LAN search when hosts are omitted |
| **Remote** | **RemoteCommand** (WinRM) for domain admins on domain-joined hosts - orange / unavailable off-domain |
| **Safety** | Auto-approve off by default; mutating actions require Yes / No / All |
| **Tools** | Progressive groups (catalog-order chips; volume/brightness, GPO, shares, CAB/ISO, Gallery, SearchWeb/BrowsePage, …) |
| **TaskBoard** | Multi-step checklist: sticky flyout under chips + SESSION STATE (`set` / `update` / `status` / `clear`) |
| **Edit stack** | **EditFile** / **ApplyPatch** / **WriteFile** with unified **LCS** diffs, default **`.bak`**, create-file patches |
| **Forensics** | Progressive group: **HexView** / **HexEdit** / **HexSearch** / **StringsScan** |
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
5. Tool-group chips show active groups; multi-step work paints a **TaskBoard sticky** under the chips (scrollable rows, active task highlighted).

---

## Parameters

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `-BaseUrl` | *(script default)* | Primary API base (port lives in the URL). Prefer `…/v1` for vLLM / Unsloth; bare `:8080` is fine for many llama.cpp builds. Empty `""` opens Connect immediately. |
| `-Model` | *(empty)* | Preferred model id; empty → auto-pick from `/models` or PoweredBy. Slash ids OK (`unsloth/…`). |
| `-ModelAlias` | *(empty)* | Display label in PoweredBy; empty → live server model id |
| `-ApiKey` | `none` | HTTP **Bearer** only. Use `none` to skip. |
| `-AgentName` | `MiniBot` | Window brand / agent identity |
| `-Version` | `2.51.0` | Version string |
| `-MaxTokens` | `0` | Max completion tokens. **`0` = auto** (`n_ctx / 8` from server). |
| `-ContextWindowTokens` | `0` | Fallback `n_ctx`. **`0` = use server `/props` + `/models` only** |
| `-Temperature` | `0.15` | Sampling temperature |
| `-MaxTurns` | `30` | Max tool-loop turns per user message (UI: **Unlimited** disables the cap) |
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
| **API key** | `-ApiKey '…'` → `Authorization: Bearer …` |
| **NPM Basic** | Session login through your reverse proxy (Connect / Login UI) |
| **None** | `-ApiKey 'none'` and no NPM login (open LAN servers) |

**Extra endpoints** (hardcode near the top of the script, or **PoweredBy → + Add endpoint**):

| Mode | Behavior |
|------|----------|
| `apikey` | Bearer from the per-base key map |
| `npm` | Same NPM Basic session as primary |
| `none` | No Authorization header |

```powershell
# Example hardcode (edit MiniBot.ps1 near the top):
# $script:MBExtraApiBases = @('http://192.168.1.20:8000/v1')
# $script:MBExtraApiAuth  = @{ 'http://192.168.1.20:8000/v1' = 'apikey' }
# $script:MBExtraApiKeys  = @{ 'http://192.168.1.20:8000/v1' = 'token-abc123' }
```

**Cloud example (xAI):**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\MiniBot.ps1 `
  -BaseUrl "https://api.x.ai/v1" `
  -ApiKey "xai-…" `
  -Model "grok-4.5"
```

---

## User interface

- Borderless dark chrome: drag, minimize, maximize to work area, close  
- Title bar brand, path, context budget, **PoweredBy** model / endpoint menu (**+** adds an endpoint)  
- Chat log with banners, code, tables, **inline media**, and **SVG visualization** cards  
- Sticky header: path, budget, auto-approve / auto-compact, tool-group chips  
- **TaskBoard sticky** under chips: goal, scrollable rows (max ~5 visible), purple **in_progress**, yellow when paused on Stop/Esc  
- Approval strips: **Yes** / **No** / **All**  
- **Send** ↔ **Stop** while the agent runs (Stop ≈ Esc interrupt)  
- **Connect / Login** shared window for endpoint recovery  

### Keyboard

| Key | Action |
|-----|--------|
| **Enter** | Send |
| **Ctrl+Enter** / **Shift+Enter** | Newline |
| Trailing `\` | Continue multi-line |
| **Esc** (idle) | Clear draft |
| **Esc** (busy) | Interrupt stream and tools (TaskBoard collapses to paused active row) |
| **Up** / **Down** | Input history |
| **Right-Ctrl** (hold) | Push-to-talk when speech is on |

### Inline media

```text
![clip title](C:\Users\You\Videos\clip.mp4)
```

Supported: common images, video (`mp4` / `m4v` / `mov` / `wmv`), audio (`mp3` / `wav` / `flac` / `m4a` / …). Prefer absolute paths.

### Inline visualization (SVG)

```text
@@@RenderOpen
<svg width="680" height="240" viewBox="0 0 680 240" xmlns="http://www.w3.org/2000/svg">
  <!-- numeric width/height required; viewBox + xmlns required -->
</svg>
@@@RenderClose
```

| Rule | Detail |
|------|--------|
| **Format** | SVG only - not WPF XAML, not markdown fences around the body |
| **Size** | Numeric `width` and `height` (pixels) |
| **Theme** | Dark palette: `#121216` / `#1A1A1E` bg, `#E5E7EB` text, `#7AA2F7` accent |
| **Save** | Card actions export **SVG** or **HTML** |

---

## Slash commands

| Command | Description |
|---------|-------------|
| `/help` | Full help |
| `/status` | Session stats and context bar |
| `/context` | Detailed context breakdown |
| `/clear` | Clear chat history (sticky notes / pins kept) |
| `/compact` | Aggressive history trim |
| `/note <text>` | Pin a sticky note |
| `/find <text>` | Pin a finding |
| `/forget` | Clear notes, findings, digest, path pins, TaskBoard |
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

| Group | Role |
|-------|------|
| **core** | Read/write/edit/patch, find/search, DiffText, shell, CWD, env, **TaskBoard**, EnableToolGroup |
| **vision** | **ReadImage**, **ReadPdf**, **ViewScreen** |
| **sound** | **SpeakText**, **AudioVolume** |
| **forensics** | **HexView**, **HexEdit**, **HexSearch**, **StringsScan** |
| **system** | Inventory, processes, memory, power, services, software, updates, **DisplayBrightness** |
| **network** | Adapters, LAN scan, **PortProbe**, **FindShares** / **FindWebHosts** / **FindRdp**, **RemoteCommand** |
| **diag** | BSOD, events, disk, startup/tasks/drivers, StopProcess |
| **repair** | sfc / DISM / chkdsk |
| **setup** | Windows options, **GroupPolicy**, restore, uninstall, reboot, NewMachineSetup |
| **identity** | Local users, join / leave domain |
| **shares** | Map/unmap, create/remove share, network printer |
| **installers** | Silent install catalog |
| **sandbox** | Multi-step PowerShell lab |
| **files** | Download, zip, **CAB**, **ISO**, **BulkRename**, **FindDuplicates** |
| **packages** | PowerShell Gallery |
| **registry** | **ReadRegistry** / **SetRegistry** |
| **clipboard** | Clipboard read / write (approval) |
| **web** | **SearchWeb**, **BrowsePage**, **MakeHttpRequest**, GitHub helpers |
| **docs** | **SearchMicrosoftLearn** / **ReadMicrosoftLearn**, SS64 helpers |

### Notable tool behavior

| Area | Behavior |
|------|----------|
| **TaskBoard** | Sticky flyout under chips (not chat). `action=set\|update\|status\|clear`. Auto-advance next pending on done. Stop/Esc pauses sticky to the active row (yellow); full board kept for resume. Multi-step asks nudge the model to set a board. |
| **SearchWeb** | Results `{title,url,snippet}[]`. Engines: DuckDuckGo (unwraps `uddg=` redirects) + **Bing** + **Brave** when blocked. `engine=auto\|duckduckgo\|bing\|brave`. Prefer `engine=bing` on bot-blocked hosts. Then **BrowsePage** best URLs. |
| **BrowsePage** | Readable extract + links; `needs_render=true` for JS shells. Default `verify_ssl=false` uses curl `-k`. |
| **ReadRegistry** / **SetRegistry** | Paths: `HKLM:\SOFTWARE\…`, `HKLM\SOFTWARE\…`, `HKEY_LOCAL_MACHINE\…`. Set types: `String\|DWord\|QWord\|…` and `REG_DWORD` / `REG_SZ` / `int` / `0xHEX`. Set always prompts. |
| **Volume / speak** | **AudioVolume** / **SpeakText** (sound group) |
| **Brightness** | **DisplayBrightness** (system group) |
| **Group Policy** | **GroupPolicy** (setup) - local Policies registry. Orange on Home/Core. |
| **PortProbe** | TCP open/closed. Targeted `computer=` / `hosts=` or LAN flood when omitted. |
| **FindShares** | Locate network shares (targeted or LAN). Not net-view loops. |
| **RemoteCommand** | WinRM remoting (approval). Domain-joined + domain user. |
| **HTTP** | **MakeHttpRequest**: default `verify_ssl=false` → curl `-k`. |
| **Hex / PE** | Forensics group: disasm, IAT, entropy, carve, hash, HexSearch `??`, StringsScan. |
| **BulkRename** | `find`/`replace` or `template`; **dry_run=true** default. |
| **FindDuplicates** | Size buckets then SHA256. |
| **Loop hygiene** | Same tool+args blocked after retest; NEED_INPUT / TOOLS_DONE; path pins + errors in SESSION STATE |

### Network discovery modes

| Mode | How |
|------|-----|
| **Targeted** | `computer=IP` or `hosts=['IP',…]` - only those machines (self skipped) |
| **Search** | Omit hosts - ICMP flood on the local prefix, then service ports / share guesses |

**RemoteCommand** is always single-host (`host=` + `command=`). Prefer **PortProbe** first for reachability.

### Files & archives

| Tool | Purpose |
|------|---------|
| **DownloadFile** | HTTP download with live progress |
| **ExpandArchive** / **CompressArchive** | Zip extract / create |
| **MakeCab** / **ExpandCab** | Cabinet build / extract |
| **MakeIso** | Build data ISOs (IMAPI2) |
| **MountIso** / **UnmountIso** | Mount and dismount ISO images |

---

## Installer catalog

| Id | Package |
|----|---------|
| `7zip` | 7-Zip |
| `chrome` | Google Chrome |
| `adobe_reader` | Adobe Acrobat Reader DC |
| `adwcleaner` | ADWCleaner |
| `vlc` | VLC media player |

- **ListInstallers** / **InstallPackage** - always prompt before install.  
- **NewMachineSetup** - one approval for Windows settings plus the catalog.  
- Catalog lives in `$script:MBInstallerCatalog` near the top of the script.

---

## Approvals & safety

- **Auto-approve is off by default.** Host mutations need confirmation.  
- Read-only shell may auto-run; multi-statement, redirects, downloads, writers, and repair tools prompt.  
- **Esc** / **Stop** cancels the stream and tears down tracked child process trees.  
- Network tools prompt when using non-GET methods, credentials, or private/local URLs.  

---

## Context & compaction

Budget is derived from the server context window (or `-ContextWindowTokens`) minus the completion reserve. Soft/hard percentages drive auto-compact when enabled. Force with **`/compact`**. Sticky notes and findings survive **`/clear`**.

Default completion size is **auto** (`-MaxTokens 0` → about `n_ctx / 8`).

During a multi-step tool loop, MiniBot keeps an **append-only** message prefix (frozen system/SESSION STATE) so local servers can reuse prompt cache between tool results. State is refreshed at the end of each user turn.

---

## Sessions & runtime

- **`/save`** / **`/load`** - JSON or Markdown (path or file picker).  
- **`/retry`** after transient API errors.  
- Single-instance lock per application id.  
- Optional elevation re-launch preserves bound parameters.  
- Model list refresh runs **after** the main WPF host is up.

---

## Example launches

```powershell
# Default script base (Connect dialog if nothing is listening)
powershell -NoProfile -ExecutionPolicy Bypass -File .\MiniBot.ps1 -HideConsole:$false

# Local llama.cpp-style base without /v1
powershell -NoProfile -ExecutionPolicy Bypass -File .\MiniBot.ps1 `
  -BaseUrl "http://127.0.0.1:8080" `
  -ModelAlias "Local" `
  -HideConsole:$false

# OpenAI-compat /v1 + API key
powershell -NoProfile -ExecutionPolicy Bypass -File .\MiniBot.ps1 `
  -BaseUrl "http://192.168.1.20:8000/v1" `
  -ApiKey "token-abc123" `
  -Model "my-model"
```

---

## Troubleshooting

| Symptom | What to try |
|---------|-------------|
| No connection / blank after hide console | Wait for **Connect** (probes are short); check `-BaseUrl`, firewall, server health; `-HideConsole:$false`; run `/status` |
| Auth loop | Hold **Caps Lock** at launch or `$env:clear=1`; re-login; `-StoreCredentials:$true` |
| Empty model list | Confirm auth mode (API vs None vs NPM); wait for `/models` after Connect; use PoweredBy → refresh if needed |
| 401 on cloud host | Use Auth = **API** and a Bearer key - not None/NPM |
| 500 / 502 | Wait, then **`/retry`** |
| Context pressure | `/compact`, `/clear`; raise server `n_ctx`; avoid huge tool dumps |
| Tools missing | `/tools list`, `/tools <group>`, or `-ToolProfile full` |
| GroupPolicy orange | Windows Home/Core has no local GPO editor - expected |
| Vision tools orange | Active model has no `vision` ability |
| RemoteCommand orange | Host/user not on a domain (workgroup or local login) - domain-admin tool only |
| Remote port closed | Enable WinRM / firewall on the **remote** PC; do not thrash with shell probes |
| Bad HTTPS in tools | Install **System32\curl.exe** (Win10+); `verify_ssl=false` uses `curl -k` |
| SearchWeb empty / few hits | DDG often bot-blocks lab IPs - try `engine=bing` or `engine=brave`; then **BrowsePage** known URLs; MS docs → **SearchMicrosoftLearn** |
| TaskBoard sticky stuck / wrong task | Stop/Esc pauses (yellow); new plan → **clear** then **set**; if the board is fully done it should auto-clear - use TaskBoard `action=clear` if it lingers |
| “Task board incomplete - continuing…” | Open items still pending - mark remaining `done` or `clear`; a clear “ALL PASSED” style final answer should auto-close the board |
| SetRegistry type error | Use `DWord` / `String` / `REG_DWORD` / `REG_SZ` / `int` (not arbitrary strings); path like `HKLM:\SOFTWARE\…` |
| Console needed | `-HideConsole:$false` |
| Diagnostics | `-DebugLog:$true` or `$env:debug=1` → Desktop / TEMP `MiniBot-debug.log` |

---

## License / deploy notes

Single-file distribution: copy `MiniBot.ps1` (or rename to `.cmd`). Edit the param defaults and optional `$script:MBExtraApiBases` / keys near the top for your lab. Optional XAML icon assets beside the script are used when present.

Made for IRM | IEX Deployment

MIT
