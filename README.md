# MiniBot
OpenAI-compatible PowerShell agent client for local models (Windows PowerShell 5.1 + WPF UI).

<p align="center"><img src="https://raw.githubusercontent.com/illsk1lls/MiniBot/refs/heads/main/.readme/MiniBot.png"></p>

## Setup
1. Edit the defaults at the top of `MiniBot.ps1` (`BaseUrl`, `Model`, `ApiKey`, etc).
2. Run it.

```
powershell -NoProfile -ExecutionPolicy Bypass -File .\MiniBot.ps1
```

Or rename to `.cmd` and double-click (hybrid launcher at the top of the file).

```
irm https://YOUR_HOST/MiniBot.ps1 | iex
```

## Useful params
Set them in the `param` block or pass on the command line:

| Param | Default | Notes |
| --- | --- | --- |
| `BaseUrl` | your host | OpenAI-compatible base (chat/completions) |
| `Model` | model id | API model name |
| `ModelAlias` | same as model | Sticky "PoweredBy" label (empty = hide) |
| `ApiKey` | `none` | Or store with `-StoreCredentials` / login checkbox |
| `AgentName` | agent name | Branding in UI |
| `HideConsole` | `$true` | `$false` keeps the PS/Terminal window open |
| `AutoApproveEnabled` | `$false` | Skip Y/N prompts for mutating tools |
| `ToolProfile` | `core` | `full` enables all tool groups at start |
| `SpeechEnabled` | `$false` | Right-Ctrl push-to-talk + optional TTS |
| `DebugLog` | `$false` | Writes `MiniBot-debug.log` on Desktop |

Examples:

```
.\MiniBot.ps1 -HideConsole:$false
.\MiniBot.ps1 -BaseUrl "http://127.0.0.1:8081" -Model "my-model"
.\MiniBot.ps1 -ToolProfile full -AutoApproveEnabled:$true
```

## Commands
Type a task in the prompt, or use:

```
/help
/status
/tools              # list groups
/tools vision       # enable a group
/auto on|off        # auto-approve mutating actions
/cd <path>
/save  /load  /export
/speech on|off
exit
```

Esc interrupts a running turn.

## Tools
Starts on **core** (files, edits, shell, cwd). Other groups load on demand (`EnableToolGroup` or `/tools <group>`):

`vision` `system` `repair` `setup` `installers` `sandbox` `files` `packages` `registry` `clipboard` `web` `speech`

Mutating actions prompt for approval unless auto-approve is on. Safe read-only shell commands can auto-run; everything else asks.

Installer catalog is near the top of the script (`$script:MBInstallerCatalog`). Edit URLs/flags there.

## Auth
If the host needs credentials, MiniBot prompts. Use **Save credentials** or `-StoreCredentials` to write Windows Credential Manager. Caps Lock held at launch clears stored MiniBot creds.

If you use NPMPlus ACL: set Satisfy Any / Pass Auth to Upstream. For streaming, `proxy_buffering off; proxy_request_buffering off;` in custom proxy settings helps.

## Notes
- Needs Windows PowerShell 5.1+ and WPF (normal desktop Windows).
- Optional: `PSWindowsUpdate` for update status, `System.Speech` for voice.
- Runs elevated (UAC) when needed for machine setup / installs.
- Temp folders under `%TEMP%` are cleaned as it goes and again on launch if a previous run died dirty.

Have your favorite AI review the script before trying it and see what it thinks?

## License
Do whatever you want with it. ;)
