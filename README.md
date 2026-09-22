# MiniBot

**v2.61.0** — PowerShell 5.1. Point to an OpenAI-compatible server, it can use the PC: files, tools, and make changes with user permission.

<p align="center">
  <img src="https://raw.githubusercontent.com/illsk1lls/MiniBot/refs/heads/main/.readme/MiniBot.png" alt="MiniBot">
</p>

A single file. MiniBot.ps1

---

## What you can do with it

| You want to… | Use |
|---|---|
| Talk to a local model (llama.cpp, vLLM, Unsloth) or a cloud one (xAI and other `/v1` servers) | `-BaseUrl` |
| Switch models or add another server without restarting | Title bar **PoweredBy** menu |
| Have it edit code | `EditFile`, `ApplyPatch`, `WriteFile`. A `.bak` is written next to the file. PowerShell, JSON, and XML are parsed after the save |
| Find text in a project | `SearchFiles` (skips `.git` and `node_modules`, gives a line number) |
| Check that a change actually runs | `RunProjectCheck` — uses a test command already on the machine (`*.Tests.ps1`, `npm test`, `cargo test`, `go test`, `dotnet test`, `pytest`). It does not install anything |
| Look at a picture, PDF, or the screen | vision tools |
| Play a video or audio clip in the chat | `![title](C:\full\path\to\file.mp4)` |
| Draw a chart | SVG between `@@@RenderOpen` and `@@@RenderClose` |
| Inspect an EXE or DLL | forensics tools (`PeInfo`, `HexView`, `HexEdit`, strings, imports) |
| Fix or inventory the PC | system, diag, repair, registry, shares, Group Policy |
| Reach another PC on the domain | `RemoteCommand` (WinRM). Off-domain it stays unavailable |
| Pick up yesterday’s chat | `/sessions` then `/resume` |
| Save a readable copy of the chat | `/save` — the picker suggests `minibot-<date>.md` |

Auto-approve is **off**. Anything that changes the machine asks Yes / No / All.

<p align="center">
  <img src="https://raw.githubusercontent.com/illsk1lls/MiniBot/refs/heads/main/.readme/MiniBot-Markdown.png" alt="Chat with markdown"><br>
  Chat
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/illsk1lls/MiniBot/refs/heads/main/.readme/MiniBot-CodeBlock.png" alt="A code block"><br>
  Code blocks show line numbers, the language, and a Copy button. Copy does not include the line numbers. A long block scrolls inside the card.
</p>

---

## What you need

| | |
|---|---|
| Windows 10 or 11 | The window is WPF |
| Windows PowerShell 5.1 | `System32\WindowsPowerShell\v1.0`. PowerShell 7 is not required |
| A chat server | Anything that speaks OpenAI `/v1/chat/completions` |
| Admin, sometimes | Repair, setup, shares, and local users re-launch elevated |
| Domain + WinRM | Only for `RemoteCommand` (ports 5985 / 5986 on the other PC) |

Optional: `System.Speech` for voice. `curl.exe` (already on Windows 10+) for HTTPS tools that skip certificate checks. Poppler, ImageMagick, or Ghostscript if you want better PDF pages.

---

## Start it

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\MiniBot.ps1 -HideConsole:$false
```

Home lab on port 8080, no API key:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\MiniBot.ps1 `
  -BaseUrl "http://127.0.0.1:8080/v1" `
  -ApiKey none `
  -ModelAlias "HomeLab" `
  -HideConsole:$false
```

xAI:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\MiniBot.ps1 `
  -BaseUrl "https://api.x.ai/v1" `
  -ApiKey "xai-…" `
  -Model "grok-4.5"
```

If `-BaseUrl` is empty, or nothing answers, a Connect box opens. Put the URL there and pick API key, NPM basic auth, or none. Hold **Caps Lock** while launching to throw away a saved login and start clean.

Rename the file to `.cmd` if you want a double-click. The top of the script is a CMD header; the comment above `@START` says which lines that header uses.

First time in the window: type, Enter. The title bar shows the folder, how full the context window is, and the model. Chips under that are tool groups. A multi-step job draws a task list under the chips.

---

## The window

Drag the borderless frame. Minimize, maximize, close are on the title bar.

- **PoweredBy** picks the model and the server. **+** adds another server for this session.
- **Send** becomes **Stop** while it is working. Stop is the same as Esc.
- Approval strips are **Yes**, **No**, and **All** (All means yes for the rest of this kind of action).
- A task list under the chips is the current plan. Purple is the step it is on. Yellow means you hit Stop and it is paused on that step.

| Key | What it does |
|---|---|
| Enter | Send |
| Ctrl+Enter or Shift+Enter | New line |
| End a line with `\` | Keep typing on the next line |
| Esc, while idle | Clear the draft |
| Esc, while busy | Stop the reply and the tools |
| Up / Down | Earlier things you typed |
| Hold Right-Ctrl | Talk, if speech is on |

### Show a file in the chat

```text
![clip](C:\Users\You\Videos\clip.mp4)
```

Images: png, jpg, gif, webp, bmp, tif. Video: mp4, m4v, mov, wmv. Audio: mp3, wav, flac, m4a, and the usual others. Use a full path. MiniBot plays it in the chat. It opens an outside player only if you ask, or if the format will not play inline.

### Draw a chart

```text
@@@RenderOpen
<svg width="680" height="240" viewBox="0 0 680 240" xmlns="http://www.w3.org/2000/svg">
  <rect width="680" height="240" fill="#1A1A1E"/>
</svg>
@@@RenderClose
```

`width` and `height` have to be numbers, and the SVG needs `viewBox` and `xmlns`. Do not wrap that block in a markdown fence.

Shapes, paths, text, `tspan`, dashed lines, and `rgb` / `rgba` draw. Gradients, filters, markers, and `<use>` do not. If some of those are in the file, the card title says how many were skipped. The card can save SVG or HTML.

Dark colors that match the window: background `#121216` / `#1A1A1E`, text `#E5E7EB`, accent `#7AA2F7`.

<p align="center">
  <img src="https://raw.githubusercontent.com/illsk1lls/MiniBot/refs/heads/main/.readme/MiniBot-Login.png" alt="Login"><br>
  Login
</p>

---

## Commands you type

| Command | What it does |
|---|---|
| `/help` | The short list inside the app |
| `/doctor` | Checks that this script still parses and the coding checks are present. Writes nothing |
| `/status` | Session and context |
| `/context` | Where the context budget went |
| `/clear` | Wipe the chat. Notes you pinned stay. The chat you cleared is still in `/sessions` |
| `/compact` | Shrink history so the server has room |
| `/note …` | Pin a note the model keeps seeing |
| `/find …` | Pin a finding |
| `/forget` | Drop notes, findings, and the task list |
| `/auto on` or `off` | Auto-approve. Off is the default |
| `/autocompact` | Turn automatic history shrink on or off |
| `/cd <path>` | Working folder |
| `/wd` | Print the working folder |
| `/tools` | Which groups are on |
| `/tools <group>` | Turn a group on. Commas are fine: `/tools files,web` |
| `/tools full` | Turn every group on |
| `/tools core` | Back to the small set |
| `/sandbox` | Where the PowerShell lab writes |
| `/sandbox clear` | Delete this session’s lab files |
| `/sessions` | Chats saved for this folder |
| `/resume` | Continue the newest one |
| `/resume 2` or `/resume abcd` | A number from the list, or the start of an id |
| `/save` | Picker. Suggested name is `minibot-20260922-153045.md` |
| `/save C:\path\file.md` | That path, no picker. `.md` is a transcript. Anything else is JSON |
| `/load` | Open a file you saved |
| `/model` | Model id |
| `/retry` | Send your last message again |
| `/speech on` | Voice. Also `off`, `test`, `listen`, `say hello` |
| `exit` | Quit |

Chats also save themselves under `%LOCALAPPDATA%\MiniBot\sessions`, one folder per working directory. That folder is not inside your project. `/save` is the copy you choose.

If the folder has `minibot.md`, `AGENTS.md`, or `CLAUDE.md`, the closest one is shown to the model as the project’s own rules. MiniBot does not create those files.

---

## Launch options

Booleans are `-Name:$true` and `-Name:$false`.

| Parameter | Default | |
|---|---|---|
| `-BaseUrl` | the script default | Server URL. Put the port in the URL. `…/v1` for vLLM and Unsloth. Many llama.cpp builds are fine without `/v1`. `""` skips the probe and opens Connect |
| `-Model` | empty | Model id. Empty picks from `/models`. Slash ids are fine (`unsloth/…`) |
| `-ModelAlias` | empty | Name shown in PoweredBy. Empty shows the server’s id |
| `-ApiKey` | `none` | Bearer token. `none` sends no key |
| `-AgentName` | `MiniBot` | Name in the title bar |
| `-Version` | `2.61.0` | Shown in the title |
| `-MaxTokens` | `0` | Reply length. `0` means about one eighth of the server context |
| `-ContextWindowTokens` | `0` | Only if the server will not say its context size |
| `-Temperature` | `0.15` | |
| `-MaxTurns` | `50` | Tool rounds per message. The UI can set this to unlimited |
| `-MaxReplyContinues` | `5` | How many times to keep going when a reply is cut off |
| `-MaxToolResultChars` | `10000` | How much of a tool result the model sees |
| `-MaxHistoryMessages` | `48` | Soft cap before compacting |
| `-CommandTimeoutSec` | `360` | How long a command may run |
| `-ContextSoftPct` | `0.72` | Start compacting here |
| `-ContextHardPct` | `0.88` | Compact harder here |
| `-AutoCompactEnabled` | `$true` | |
| `-ModelCompactEnabled` | `$true` | Ask the model to write the summary. Off uses a plain extract |
| `-AutoApproveEnabled` | `$false` | Leave this off unless you mean it |
| `-SpeechEnabled` | `$false` | |
| `-SpeechAutoReply` | `$true` | Read the answer aloud when speech is on |
| `-StoreCredentials` | `$false` | Save the login in Windows Credential Manager |
| `-ToolProfile` | `core` | `core` starts small. `full` turns every group on |
| `-TaskApiBase` | empty | Optional URL for cancelling a backend task |
| `-DebugLog` | `$false` | `MiniBot-debug.log` on the Desktop, or in TEMP |
| `-HideConsole` | `$true` | Hide the PowerShell window. Use `$false` when you need to see errors |

| Environment | |
|---|---|
| `$env:store=1` | Save credentials, if you did not pass `-StoreCredentials` |
| `$env:clear=1` | Forget saved credentials at launch |
| `$env:debug=1` | Write the debug log |
| `$env:speech=1` | Start with speech on |

### More than one server

The primary server is `-BaseUrl`. Its auth is the API key, an NPM basic-auth login, or none.

Extra servers can be typed into the script, or added with PoweredBy → **+**.

```powershell
# Near the top of MiniBot.ps1:
# $script:MBExtraApiBases = @('http://192.168.1.20:8000/v1')
# $script:MBExtraApiAuth  = @{ 'http://192.168.1.20:8000/v1' = 'apikey' }
# $script:MBExtraApiKeys  = @{ 'http://192.168.1.20:8000/v1' = 'token-abc123' }
```

`apikey` sends that server’s bearer token. `npm` reuses the primary basic-auth login. `none` sends no Authorization header.

---

## Tools

The model only sees groups that are on. **core** is always on. Everything else waits until the task needs it, or until you run `/tools <group>`.

| Group | What is in it |
|---|---|
| core | Read, write, edit, patch, search, diff, shell, folder, env, task list |
| vision | Pictures, PDFs, the screen |
| sound | Speak, volume |
| forensics | Hex, PE headers, imports, resources, sections, strings |
| system | Processes, services, software, updates, brightness |
| network | Adapters, port checks, shares, web hosts, RDP, remote command |
| diag | Crash dumps, event log, disk, startup |
| repair | sfc, DISM, chkdsk |
| setup | Windows options, Group Policy, restore, uninstall, reboot, new-PC setup |
| identity | Local users, join or leave a domain |
| shares | Map a drive, create a share, add a printer |
| installers | Silent installs from the small catalog below |
| sandbox | A PowerShell scratch folder for experiments |
| files | Download, zip, CAB, ISO, bulk rename, duplicate files |
| packages | PowerShell Gallery |
| registry | Read and set values |
| clipboard | Read and write, with approval |
| web | Search, open a page, HTTP, GitHub |
| docs | Microsoft Learn and SS64 |

A few that people trip on:

- **Search the web** returns title, url, and snippet. If DuckDuckGo blocks the PC, ask for Bing or Brave, then open the useful links.
- **Open a page** pulls readable text. Pages that are only a JavaScript shell come back as needing a render. Certificate checks are off by default and go through `curl -k`.
- **Registry paths** look like `HKLM:\SOFTWARE\…`. Types are `String`, `DWord`, `QWord`, or the `REG_SZ` / `REG_DWORD` names. Setting a value always asks.
- **Port check** with no host walks the local subnet. Pass a computer name or a list if you mean specific machines.
- **Find shares** is the same idea: one host, or the subnet. It is not a loop of `net view`.
- **Remote command** is one host and one command, and it asks first.
- **Rename many files** previews unless you turn the dry run off.
- **Duplicate files** groups by size, then hashes.

### Archives

| Tool | |
|---|---|
| DownloadFile | HTTP download, with progress |
| ExpandArchive / CompressArchive | Zip only. CAB has its own tools. 7z and rar are refused |
| MakeCab / ExpandCab | Cabinet files |
| MakeIso | A data ISO |
| MountIso / UnmountIso | Mount and eject |

### Installers

`7zip`, `chrome`, `adobe_reader`, `adwcleaner`, `vlc`.

`ListInstallers` and `InstallPackage` ask before they install. `NewMachineSetup` is one approval for a batch of Windows settings plus that catalog. The list is `$script:MBInstallerCatalog` near the top of the script.

---

## When it asks, and when it shrinks the chat

Changes to the PC wait for Yes / No / All. A read-only command may run on its own. Several statements, a redirect, a download, or a repair tool asks.

Esc or Stop cancels the reply and kills child processes MiniBot started.

The context budget comes from the server, minus room for the reply. Around 72% it starts trimming. Around 88% it trims harder. `/compact` does it now. `/clear` wipes the chat and keeps pinned notes.

While tools are running, the start of the conversation stays put so a local server can reuse its prompt cache. It refreshes when your turn ends.

---

## If something is wrong

| What you see | What to do |
|---|---|
| No connection | Wait for the Connect box. Check the URL and that the server is up. Launch with `-HideConsole:$false` |
| Keeps asking you to log in | Caps Lock at launch, or `$env:clear=1`, then log in again |
| No models in the list | Auth mode has to match the server. API key, none, and NPM are different. Give `/models` a moment after Connect |
| 401 from a cloud server | Auth has to be API, with a real bearer key |
| 500 or 502 | Wait, then `/retry` |
| Context full | `/compact` or `/clear`. A bigger `n_ctx` on the server helps more than another compact |
| It says a tool does not exist | `/tools list`, then `/tools <group>`, or start with `-ToolProfile full` |
| Group Policy is greyed out | Home and Core editions do not have a local policy editor |
| Vision tools are greyed out | This model did not advertise vision |
| Remote command is greyed out | This PC is not on a domain, or you are logged in with a local account |
| Remote port closed | Turn on WinRM on the other PC. Do not keep probing it from the shell |
| HTTPS tools fail | `curl.exe` should be in System32. The tools call `curl -k` when certificate checks are off |
| Web search comes back empty | The lab IP is probably blocked. Try Bing or Brave, or open a URL you already know. Microsoft docs have their own search tool |
| The task list is stuck | Stop pauses it (yellow). A new plan should clear the old one first. If every step is done and the list is still there, clear it |
| Registry type rejected | Use `DWord`, `String`, `REG_DWORD`, or `REG_SZ` |
| You need the console | `-HideConsole:$false` |
| You need a log | `-DebugLog:$true` or `$env:debug=1` |

---

## License

MIT.

Made for IRM | IEX Deployment
