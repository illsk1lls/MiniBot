<#
.SYNOPSIS
	MiniBot v0.0.1 - Local Mini Agent
.DESCRIPTION
	An OpenAI compatible Powershell console client
#>

try {
	[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
	chcp 65001 | Out-Null
} catch {}

Add-Type -AssemblyName System.Windows.Forms
$ForceCredRefresh = [System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Control
if ($ForceCredRefresh) {
	Write-Host "CTRL key held during launch - Forcing credential refresh" -ForegroundColor DarkRed
}

# ==================== CONFIG ====================

$BaseUrl	  = "http://192.168.1.231:8081/v1" # Point to an OpenAI compatible endpoint e.g. https://domain.com/v1, http://192.168.1.50:8080/v1
$Model		  = "Qwen3.6-35B-A3B-uncensored-heretic-Native-MTP-Preserved-Q8_0" # This needs to match the model name you want to connect with
$ApiKey		  = "none" # this usually doesnt matter but if you have it set enter it here

$MaxTokens	  = 4096
$Temperature  = 0.2
$maxTurns	  = 12

$AgentName	  = "MiniBot-Agent" # This is the agents display name
$DisplayModel = $Model # This displays the remote models name in the console header
$Version	  = "0.0.1"
$Protected	  = $false # Set $true to use NPMPlus access control credentials for outside access (Make sure to set 'Satify Any/Pass Auth to Upstream' in the access list for this to work properly.)

# ================================================

# SAFE COMMAND WHITELIST

$SafePrefixes = @('Get-','Test-','Resolve-','ConvertTo-','ConvertFrom-','Select-','Where-','Sort-','Group-','Measure-','Out-Null','cd','Set-Location')
$SafeExactCommands = @('dir','type','ls','whoami','hostname','systeminfo','ipconfig','Get-NetIPConfiguration','Test-NetConnection','Test-Connection','Get-Process','Get-Service','Get-ChildItem','Get-Item','Get-Content','Get-Command','Get-Help','Get-Module')

# PROMPT TUNING

$SystemPrompt = @"
You are $AgentName, a helpful, precise, and careful coding/technical assistant running on a Windows machine.

You have access to tools to read, write, and edit files on the local machine, and to run CMD and PowerShell commands.

Rules:
- Be extremely careful with destructive actions. Always confirm before writing files or running commands that modify the system.
- When editing code or configs, show a clear diff or summary of changes.
- If you need more context, use the Read tool first.
- Prefer simple, working solutions over clever ones.
- You are assisting an experienced IT technician. Use PowerShell and Windows-native approaches when appropriate.
"@

function Get-NpmPlusCreds {
	param([bool]$ForceRefresh = $false)

	$agentDir = Join-Path $env:AppData "minibot"
	$credFile = Join-Path $agentDir "boundaryedge"

	if ($ForceRefresh -and (Test-Path $credFile)) {
		Remove-Item $credFile -Force -ErrorAction SilentlyContinue
	}

	if (Test-Path $credFile) {
		try {
			$content = Get-Content $credFile -Raw -ErrorAction Stop
			$lines = $content -split "`r?`n" | Where-Object { $_.Trim() -ne "" }

			if ($lines.Count -ge 2) {
				$user = $lines[0].Trim()
				$encryptedStr = $lines[1].Trim()

				$securePass = $encryptedStr | ConvertTo-SecureString -ErrorAction Stop
				$plainPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
					[Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
				)

				return @{ User = $user; Pass = $plainPass }
			}
		}
		catch {
			Write-Warning "Decryption failed: $($_.Exception.Message). Forcing refresh."
		}
	}

	Write-Host "`nCredentials required.`n" -ForegroundColor DarkYellow
	$user = Read-Host "Username"
	$passSecure = Read-Host "Password" -AsSecureString

	if (-not $user -or -not $passSecure) {
		return @{ User = $null; Pass = $null }
	}

	if (-not (Test-Path $agentDir)) {
		New-Item -ItemType Directory -Path $agentDir -Force | Out-Null
	}

	$encrypted = $passSecure | ConvertFrom-SecureString
	"$user`n$encrypted" | Out-File $credFile -Encoding UTF8 -Force
	$plainPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
		[Runtime.InteropServices.Marshal]::SecureStringToBSTR($passSecure)
	)
	return @{ User = $user; Pass = $plainPass }
}

if($Protected){
	$NpmCreds = Get-NpmPlusCreds -ForceRefresh $ForceCredRefresh
	$NpmplusUser = $NpmCreds.User
	$NpmplusPass = $NpmCreds.Pass
}

function Test-IsSafeCommand {
	param([string]$Command)
	$first = ($Command -split '\s+')[0].Trim()
	if ($SafeExactCommands -contains $first) { return $true }
	foreach ($p in $SafePrefixes) {
		if ($first.StartsWith($p, [StringComparison]::OrdinalIgnoreCase)) { return $true }
	}
	return $false
}

# TOOL SETUP

$Tools = @(
	@{ type = "function"; function = @{
		name = "ReadFile"
		description = "Read the contents of a file on the local machine."
		parameters = @{ type = "object"; properties = @{ path = @{ type = "string" } }; required = @("path") }
	}},
	@{ type = "function"; function = @{
		name = "WriteFile"
		description = "Write or overwrite a file. Requires confirm=true."
		parameters = @{ type = "object"; properties = @{
			path = @{ type = "string" }; content = @{ type = "string" }; confirm = @{ type = "boolean" }
		}; required = @("path","content","confirm") }
	}},
	@{ type = "function"; function = @{
		name = "EditFile"
		description = "Search/replace edit. Requires confirm=true."
		parameters = @{ type = "object"; properties = @{
			path = @{ type = "string" }; search = @{ type = "string" }; replace = @{ type = "string" }; confirm = @{ type = "boolean" }
		}; required = @("path","search","replace","confirm") }
	}},
	@{ type = "function"; function = @{
		name = "RunCommand"
		description = "Run a PowerShell or CMD command. Requires confirm=true for changes."
		parameters = @{ type = "object"; properties = @{
			command = @{ type = "string" }; shell = @{ type = "string"; enum = @("powershell","cmd") }; confirm = @{ type = "boolean" }
		}; required = @("command","confirm") }
	}}
)

function Invoke-ReadFile   { param([string]$path) if (Test-Path $path) { Get-Content $path -Raw } else { "ERROR: File not found" } }
function Invoke-WriteFile  { param([string]$path,[string]$content,[bool]$confirm) if (-not $confirm) { return "SAFETY: confirm=false" }; try { $content | Out-File $path -Encoding UTF8 -Force; "SUCCESS" } catch { "ERROR: $_" } }
function Invoke-EditFile   { param([string]$path,[string]$search,[string]$replace,[bool]$confirm) if (-not $confirm) { return "SAFETY: confirm=false" }; if (-not (Test-Path $path)) { return "ERROR: Not found" }; try { (Get-Content $path -Raw) -replace [regex]::Escape($search), $replace | Out-File $path -Encoding UTF8 -Force; "SUCCESS" } catch { "ERROR: $_" } }
function Invoke-RunCommand {
	param([string]$command, [string]$shell="powershell", [bool]$confirm)
	try { if ($shell -eq "cmd") { cmd /c $command 2>&1 } else { Invoke-Expression $command 2>&1 | Out-String } } catch { "ERROR: $_" }
}

# COMMS

function Invoke-ModelStreaming {
	param([array]$Messages)

	$body = @{
		model = $Model
		messages = $Messages
		tools = $Tools
		tool_choice = "auto"
		temperature = $Temperature
		max_tokens = $MaxTokens
		stream = $true
	} | ConvertTo-Json -Depth 20 -Compress

	Write-Host ""
	Write-Host "[$AgentName is thinking...] " -NoNewline -ForegroundColor DarkRed

	Add-Type -AssemblyName System.Net.Http | Out-Null
	$client = New-Object System.Net.Http.HttpClient
	$client.Timeout = [TimeSpan]::FromMinutes(5)

	$request = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Post, "$BaseUrl/chat/completions")
	$request.Headers.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", $ApiKey)

	if ($NpmplusUser -and $NpmplusPass -and $Protected) {
		$authBytes = [System.Text.Encoding]::UTF8.GetBytes("$NpmplusUser`:$NpmplusPass")
		$authBase64 = [Convert]::ToBase64String($authBytes)
		$request.Headers.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Basic", $authBase64)
	}

	$request.Content = New-Object System.Net.Http.StringContent($body, [System.Text.Encoding]::UTF8, "application/json")

	$httpResponse = $client.SendAsync($request, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
	$stream = $httpResponse.Content.ReadAsStreamAsync().Result
	$reader = New-Object System.IO.StreamReader($stream)

	$fullContent = ""
	$toolCalls = @{}
	$hasToolCalls = $false
	$startedOutput = $false

	try {
		while (-not $reader.EndOfStream) {
			$line = $reader.ReadLine()
			if ([string]::IsNullOrWhiteSpace($line)) { continue }
			if ($line -eq "data: [DONE]") { break }

			if ($line.StartsWith("data: ")) {
				$json = $line.Substring(6).Trim()
				if ([string]::IsNullOrWhiteSpace($json)) { continue }

				try { $chunk = $json | ConvertFrom-Json } catch { continue }
				$delta = $chunk.choices[0].delta

				if ($delta.tool_calls) {
					$hasToolCalls = $true
					foreach ($tc in $delta.tool_calls) {
						$idx = $tc.index
						if (-not $toolCalls.ContainsKey($idx)) {
							$toolCalls[$idx] = @{ id = $tc.id; type = $tc.type; function = @{ name = ""; arguments = "" } }
						}
						if ($tc.function.name)		{ $toolCalls[$idx].function.name	  += $tc.function.name }
						if ($tc.function.arguments) { $toolCalls[$idx].function.arguments += $tc.function.arguments }
					}
				}

				if ($delta.content) {
					if (-not $startedOutput) {
						Write-Host "`r$(' ' * 60)`r" -NoNewline
						Write-Host "[$AgentName] " -ForegroundColor DarkRed -NoNewline
						$startedOutput = $true
					}
					Write-Host $delta.content -NoNewline
					$fullContent += $delta.content
				}
			}
		}
	}
	finally {
		if (-not $startedOutput) {
			Write-Host "`r$(' ' * 60)`r" -NoNewline
		}
		$reader.Dispose()
		$stream.Dispose()
		$client.Dispose()
	}

	Write-Host ""

	$finalMessage = @{ role = "assistant"; content = if ($fullContent) { $fullContent } else { $null } }

	if ($hasToolCalls) {
		$finalMessage.tool_calls = @()
		foreach ($key in ($toolCalls.Keys | Sort-Object)) {
			$tc = $toolCalls[$key]
			$finalMessage.tool_calls += @{
				id = $tc.id
				type = $tc.type
				function = @{ name = $tc.function.name; arguments = $tc.function.arguments }
			}
		}
	}

	return [pscustomobject]@{ choices = @(@{ message = $finalMessage }) }
}

# MAIN
function Start-LocalAgent {
	Clear-Host
	Write-Host "==============================================================" -ForegroundColor DarkGray
	Write-Host "|  $AgentName v$Version" -ForegroundColor DarkRed
	Write-Host "|  Endpoint  : $BaseUrl" -ForegroundColor DarkRed
	Write-Host "|  Powered by: $DisplayModel" -ForegroundColor DarkRed
	Write-Host "==============================================================" -ForegroundColor DarkGray
	Write-Host "  Type your task. Type 'exit' to quit." -ForegroundColor DarkGray

	$messages = @(@{ role = "system"; content = $SystemPrompt })

	while ($true) {
		$userInput = Read-Host "`n[You]"
		if ($userInput -eq "exit" -or $userInput -eq "quit") { Write-Host "`nGoodbye!" -ForegroundColor Gray; Sleep 2; Clear-Host; break }
		if ([string]::IsNullOrWhiteSpace($userInput)) { continue }

		$messages += @{ role = "user"; content = $userInput }

		$turn = 0
		while ($turn -lt $maxTurns) {
			$turn++

			$response = Invoke-ModelStreaming -Messages $messages
			if (-not $response) { break }

			$assistantMessage = $response.choices[0].message
			$messages += $assistantMessage

			if ($assistantMessage.tool_calls) {
				Write-Host "[$AgentName] Using tools..." -ForegroundColor DarkYellow

				foreach ($tc in $assistantMessage.tool_calls) {
					$fn = $tc.function.name
					$args = $tc.function.arguments | ConvertFrom-Json

					if ($fn -eq "RunCommand") {
						if (Test-IsSafeCommand $args.command) {
							Write-Host "  -> RunCommand (auto-approved)" -ForegroundColor DarkGreen
							$result = Invoke-RunCommand $args.command $args.shell $true
						} else {
							Write-Host ""
							Write-Host "[$AgentName] Wants to run:" -ForegroundColor Yellow
							Write-Host $args.command -ForegroundColor White
							$ans = Read-Host "Allow? [Y/N]"
							$result = if ($ans -match '^[Yy]') { Invoke-RunCommand $args.command $args.shell $true } else { "Denied by user. If there are no alternatives explain your reasoning." }
						}
					} else {
						Write-Host "  -> $fn" -ForegroundColor DarkCyan
						$result = switch ($fn) {
							"ReadFile"	{ Invoke-ReadFile $args.path }
							"WriteFile" { Invoke-WriteFile $args.path $args.content $args.confirm }
							"EditFile"	{ Invoke-EditFile $args.path $args.search $args.replace $args.confirm }
							default		{ "Unknown tool" }
						}
					}
					$messages += @{ role="tool"; tool_call_id=$tc.id; content=($result | Out-String) }
				}
				continue
			}

			break
		}
	}
}

Start-LocalAgent