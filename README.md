# MiniBot-R

**MiniBot v2.20.0** — Windows PowerShell 5.1 agent client for **OpenAI-compatible** local model servers (llama.cpp, etc.).

<p align="center"><img src="https://raw.githubusercontent.com/illsk1lls/MiniBot/refs/heads/main/.readme/MiniBot.png"></p>

Chat in a dark WPF UI. The agent can edit files, run commands, diagnose the PC, manage shares/maps, install a **personal** software catalog, and more — with **approval prompts** before mutating actions.

| `MiniBot.ps1` | Full/dev dual-agent tree (may include residential/business installer profiles) |

---

## What you need

| Requirement | Notes |
|-------------|--------|
| **Windows 10/11** | WPF desktop |
| **PowerShell 5.1** | Built-in `WindowsPowerShell\v1.0` |
| **Admin elevation** | Re-launches elevated (UAC) when needed for repair/setup/share tools |
| **Local model API** | OpenAI-style `…/chat/completions` (default `http://127.0.0.1:8080`) |
| **Optional** | `System.Speech` for `/speech`; **PSWindowsUpdate** for update status; Poppler/ImageMagick/Ghostscript for richer PDF vision |

---

## Quick start

```powershell
# Basic
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\path\to\MiniBot-R.ps1"

# Point at your server + display brand
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\path\to\MiniBot-R.ps1" `
  -BaseUrl "http://127.0.0.1:8080" `
  -Model "your-model-or-alias.gguf" `
  -ModelAlias "HomeLab" `
  -HideConsole:$false
```

### Hybrid CMD launcher

The script starts with a hybrid header. You can rename to `.cmd` and double-click (console minimized). For pure CMD hybrid use, remove the comment lines *above* the `@START` line as noted in the file header.

### First run

1. **Login** if the API requires auth (optional save to Credential Manager).
2. **Main window** — type a task, press **Enter**.
3. Title bar: brand, working directory, context budget, **PoweredBy** (`ModelAlias`).

---

## Parameters

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `-BaseUrl` | `http://127.0.0.1:8080` | API origin |
| `-Model` | *(script default GGUF name)* | Model id sent to the API |
| `-ModelAlias` | `YourServerName` | **Display only** — title bar `PoweredBy:` (not the API model id) |
| `-AgentName` | `MiniBot` | Window brand / agent name |
| `-Version` | `2.12.1` | Version string |
| `-ApiKey` | `none` | Bearer/API key if required |
| `-MaxTokens` | `32768` | Max completion tokens (also reserved out of context) |
| `-Temperature` | `0.15` | Sampling temperature |
| `-MaxToolResultChars` | `10000` | Cap on tool output returned to the model |
| `-MaxHistoryMessages` | `48` | Soft history length target |
| `-CommandTimeoutSec` | `360` | Default command/tool timeout |
| `-ContextWindowTokens` | `262144` | Assumed `n_ctx` for budget math |
| `-ContextSoftPct` | `0.72` | Soft auto-compact threshold |
| `-ContextHardPct` | `0.88` | Hard auto-compact threshold |
| `-AutoCompactEnabled` | `$true` | Auto-trim history when budget is high |
| `-ModelCompactEnabled` | `$true` | Model-written digest on compact (else extractive) |
| `-MaxTurns` | `30` | Max tool-loop turns per user message |
| `-MaxReplyContinues` | `8` | Auto-continue truncated replies |
| `-AutoApproveEnabled` | `$false` | Start with auto-approve **off** |
| `-SpeechEnabled` | `$false` | Voice mode at launch |
| `-SpeechAutoReply` | `$true` | TTS final assistant text when speech is on |
| `-StoreCredentials` | `$false` | Save login to Windows Credential Manager |
| `-ToolProfile` | `core` | `core` = progressive tools; `full` = all groups |
| `-TaskApiBase` | `""` | Optional extra origin for backend task stop |
| `-DebugLog` | `$false` | Write Desktop `MiniBot-debug.log` |
| `-HideConsole` | `$true` | Hide PowerShell / Windows Terminal host |

Booleans: use `-Name:$true` / `-Name:$false`.

---

## Environment flags

| Variable | Effect |
|----------|--------|
| `$env:store=1` | One-shot store credentials (if `-StoreCredentials` not on the command line) |
| `$env:clear=1` | Wipe stored MiniBot credentials at launch |
| `$env:debug=1` | Same as `-DebugLog:$true` |
| `$env:speech=1` | Can enable speech at launch |

**Caps Lock at launch:** hold **Caps Lock** while starting to clear stored credentials and force login.

---

## Authentication

- Status (`/status`) shows the completions URL.
- Login dialog when the server requires auth.
- **Save credentials** / `-StoreCredentials` / `$env:store=1` → Windows **Credential Manager** (DPAPI file fallback).
- Clear with `$env:clear=1`, Caps Lock at launch, or when a stored login is rejected.

---

## User interface

- Borderless dark WPF chrome (drag, min, maximize-to-work-area, close).
- Title-bar **robot** + taskbar icon (mood: ready / working / error bounce).
- Chat log with section banners and **approval** strips (**Yes** / **No** / **All**).
- Sticky header: path, budget, auto-approve / auto-compact, tool-group chips (used tools highlight).
- **Send** ↔ **Stop** while the agent runs (Stop ≈ Esc interrupt).

### Keys

| Key | Action |
|-----|--------|
| **Enter** | Send |
| **Ctrl+Enter** / **Shift+Enter** | Newline |
| Trailing `\` | Continue multi-line |
| **Esc** (idle) | Clear draft |
| **Esc** (busy) | Hard-stop stream + tools |
| **Up / Down** | Input history |
| **Right-Ctrl** (hold) | Push-to-talk when speech is on |

---

## Slash commands

| Command | Description |
|---------|-------------|
| `/help` | Full help |
| `/status` | Session stats + context bar |
| `/context` | Detailed context breakdown |
| `/clear` | Clear chat history (keeps sticky notes/findings) |
| `/compact` | Aggressive history trim |
| `/note <text>` | Pin sticky note |
| `/find <text>` | Pin finding |
| `/forget` | Clear notes + findings |
| `/auto [on\|off]` | Toggle auto-approve |
| `/autocompact` | Toggle automatic compaction |
| `/cd <path>` | Change working directory |
| `/wd` | Print working directory |
| `/tools` | List tools/groups |
| `/tools <group>` | Enable a group |
| `/tools full` \| `core` \| `list` | Full surface / core-only / list |
| `/sandbox` | Show sandbox root |
| `/sandbox clear` \| `clear all` | Clear session or all machine sandboxes |
| `/save [path]` | Save session (`.json` / `.md`; picker if no path) |
| `/load [path]` | Load session |
| `/model` | Show model id |
| `/retry` | Re-send last user message |
| `/speech [on\|off]` | Voice (`auto`, `test`, `listen`, `say …` also) |
| `exit` / `quit` | End session |

---

## Approvals & safety

- **Default: auto-approve off.** Mutating tools need Yes / No / All.
- Safe read-only `RunCommand` may auto-run; multi-statement, redirects, downloads, writers, repair shells prompt.
- Agent rules: no delete/destroy unless you explicitly asked for that thing.
- Esc / **Stop** aborts stream and backend tasks when possible.
- Leave auto-approve off with untrusted models or hosts.

---

## Context budget & compaction

Budget uses `ContextWindowTokens` minus `MaxTokens`, then soft/hard % of usable prompt room. Auto-compact runs when enabled and thresholds hit. Force with **`/compact`**. Sticky notes/findings survive `/clear`.

---

## Tool groups (progressive)

Only **active** groups are sent to the model. **`core` is always on.** Cold start = core unless `-ToolProfile full`.

| Group | Role |
|-------|------|
| **core** | Files, edit/patch, shell, CWD, env, enable groups |
| **senses** | Images, PDF, screen vision, SpeakText |
| **system** | OS / process / memory / services / software / uptime |
| **network** | Adapters, LAN scan, ProbeShares, local shares/maps/printers lists |
| **diag** | BSOD, events, disk, startup/tasks/drivers, StopProcess, quick bundle |
| **repair** | sfc / dism / chkdsk |
| **setup** | Volume, brightness, Windows options, restore, uninstall, reboot, NewMachineSetup |
| **identity** | Local users, join/leave domain |
| **shares** | Map/unmap, create/remove share, add/remove network printer |
| **installers** | Personal silent install catalog |
| **sandbox** | Multi-step PowerShell lab |
| **files** | Download, zip expand/compress |
| **packages** | PowerShell Gallery modules |
| **registry** | Read/set registry |
| **clipboard** | Clipboard read/write |
| **web** | HTTP, BrowsePage, GitHub helpers |

Enable via agent (`EnableToolGroup`) or `/tools <group>`.

---

## Personal installer catalog (R-specific)

**MiniBot-R** ships a **personal** catalog only. There is **no** GoToAssist / Avast business portal package set.

| Id | Package |
|----|---------|
| `7zip` | 7-Zip (silent) |
| `chrome` | Google Chrome (zip → MSI silent) |
| `adobe_reader` | Adobe Acrobat Reader DC (silent) |
| `adwcleaner` | ADWCleaner (interactive scan/clean) |
| `vlc` | VLC media player (silent) |

- **`ListInstallers`** / **`InstallPackage`** — always prompt before install.
- **`NewMachineSetup`** — one approval for Windows **settings** + the **full software catalog**
  - `skip_software=true` = settings only.  
  - `dry_run=true` = preview.

Edit URLs/flags in `$script:MBInstallerCatalog` near the top of `MiniBot-R.ps1`.

---

## Speech (optional)

```text
/speech on
```

- Hold **Right-Ctrl** to dictate; release to stop.
- Optional auto-TTS of final replies.
- Agent tool: **SpeakText** (senses; enabled with speech).

---

## Sessions

- **`/save`** / **`/load`** — JSON or Markdown (path or picker).
- **`/retry`** after API blips (500/502 often transient).
- Working directory shown in the chrome; change with `/cd`.

---

## Single instance & elevation

- One instance per app id (name lock).
- May re-launch as Administrator and pass bound parameters (console stays hidden when `-HideConsole` is true).

---

## Troubleshooting

| Symptom | Try |
|---------|-----|
| No API / blank | Check `-BaseUrl`, server, firewall; `/status` |
| Auth loop | Caps Lock at launch or `$env:clear=1`; re-login; `-StoreCredentials:$true` |
| 500/502 | Wait + **`/retry`** |
| Context full | `/compact`, `/clear`, raise server `n_ctx` + `-ContextWindowTokens` |
| Tools missing | `/tools list`, `/tools <group>`, or `-ToolProfile full` |
| Want console | `-HideConsole:$false` |
| Deep debug | `-DebugLog:$true` or `$env:debug=1` → Desktop `MiniBot-debug.log` |

---

## Example launches

```powershell
# Local server, visible console
powershell -NoProfile -ExecutionPolicy Bypass -File .\MiniBot-R.ps1 `
  -BaseUrl "http://127.0.0.1:8080" `
  -Model "MyModel.gguf" `
  -ModelAlias "Shop-PC" `
  -HideConsole:$false

# Store login, all tool groups, speech
powershell -NoProfile -ExecutionPolicy Bypass -File .\MiniBot-R.ps1 `
  -StoreCredentials:$true `
  -ToolProfile full `
  -SpeechEnabled:$true

# Wipe stored creds then run
$env:clear = '1'
powershell -NoProfile -ExecutionPolicy Bypass -File .\MiniBot-R.ps1
```

---

## Operator tips

1. Describe the goal in plain language; the agent enables groups and tools.
2. For LAN shares, prefer **ProbeShares** / **ScanNetwork** over long improvised `net view` loops.
3. Keep auto-approve **off** until you trust the model and machine.
4. Use **`/status`** and the budget chip before long jobs.
5. **Esc** early if a tool loop goes wrong, then `/retry` or rephrase.

---

## Scope

Self-contained PowerShell agent harness for **local** OpenAI-compatible endpoints. You own model choice, network access, and approval of privileged host actions.

---

*MiniBot-R · v2.20.0 · Windows PowerShell 5.1 · WPF host · personal installer catalog*
