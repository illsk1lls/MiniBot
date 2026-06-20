<#
.SYNOPSIS
	MiniBot v0.0.3 - Local Mini Agent
.DESCRIPTION
	An OpenAI compatible Powershell console client
#>

param(
	[string]$BaseUrl = "http://127.0.0.1:8080/v1",
	[string]$Model = "Qwen3.6-35B-A3B-uncensored-heretic-Native-MTP-Preserved-Q8_0",
	[string]$ApiKey = "none",
	[int]$MaxTokens = 8192,
	[double]$Temperature = 0.15,
	[int]$MaxTurns = 25,
	[string]$AgentName = "MiniBot",
	[string]$Version = "0.0.3",
	[bool]$AutoApproveEnabled = $false,
	[bool]$StoreCredentials = $false
)

try {
	[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
	chcp 65001 | Out-Null
} catch {}

# INTERRUPT HANDLING
$script:interruptRequested = $false

function stepInterrupt {
	[CmdletBinding()]
	param()
	if ([Console]::KeyAvailable) {
		$keyInfo = [Console]::ReadKey($true)
		if ($keyInfo.Key -eq [ConsoleKey]::Escape) {
			$script:interruptRequested = $true
			if($script:isThinking){
				Write-Host ""
			}
			Write-Host "`n[INTERRUPT] ESC pressed — aborting current turn..." -ForegroundColor Yellow -NoNewLine
			while ([Console]::KeyAvailable) {
				[void][Console]::ReadKey($true)
			}
			return $true
		}
	}
	return $false
}

function Reset-InterruptFlag {
	$script:interruptRequested = $false
}

function thinkingAnimation {
	param(
		[string]$AgentName = "MiniBot"
	)

	$originalCursorVisible = [Console]::CursorVisible
	[Console]::CursorVisible = $false

	$gradient = @(
		[ConsoleColor]::DarkGray,
		[ConsoleColor]::DarkGray,
		[ConsoleColor]::Gray,
		[ConsoleColor]::White,
		[ConsoleColor]::Gray,
		[ConsoleColor]::DarkGray,
		[ConsoleColor]::DarkGray
	)

	$baseText = "is thinking..."
	$spinner  = @('-', '\', '|', '|', '/')
	$delayMs  = 150
	$frame	  = 0

	try {
		while (-not [System.Console]::KeyAvailable) {
			$spinChar = $spinner[$frame % $spinner.Count]
			$fullText = $baseText + $spinChar
			$len	  = $fullText.Length

			Write-Host -NoNewline "`r"
			Write-Host "[" -NoNewLine -ForegroundColor DarkGray
			Write-Host "$AgentName" -NoNewLine -ForegroundColor DarkRed
			Write-Host "-" -NoNewLine -ForegroundColor DarkGray
			Write-Host "Agent" -NoNewLine -ForegroundColor DarkRed
			Write-Host "] " -NoNewLine -ForegroundColor DarkGray

			for ($i = 0; $i -lt $len; $i++) {
				$colorIndex = (($i - $frame) % $gradient.Count + $gradient.Count) % $gradient.Count
				Write-Host -NoNewline -ForegroundColor $gradient[$colorIndex] $fullText[$i]
			}

			Start-Sleep -Milliseconds $delayMs
			$frame++
		}
	}
	finally {
		[Console]::CursorVisible = $originalCursorVisible
		Write-Host "`r$(' ' * 120)`r" -NoNewline
	}
}

# SUPPORT FOR NPM CREDENTIALS
function Get-NPMCreds {
	param([bool]$StoreCredentials = $false)

	$agentDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Explorer"
	$credFile = Join-Path $agentDir "thumbcache_32.dat"

	if (-not $StoreCredentials) {
		if (Test-Path $credFile) {
			Remove-Item $credFile -Force -ErrorAction SilentlyContinue
		}
	}

	if ($StoreCredentials -and (Test-Path $credFile)) {
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

				if ($user -and $plainPass) {
					return @{ User = $user; Pass = $plainPass }
				}
			}
		}
		catch {
			Write-Warning "Decryption failed. Prompting for new credentials."
		}
	}

	while ($true) {
		Write-Host "`nCredentials required for $($BaseUrl)`n" -ForegroundColor DarkYellow
		$user = Read-Host "Username"
		$passSecure = Read-Host "Password" -AsSecureString

		$plainPass = $null
		if ($passSecure) {
			try {
				$plainPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
					[Runtime.InteropServices.Marshal]::SecureStringToBSTR($passSecure)
				)
			} catch {}
		}

		if ($user -and $plainPass) {
			if ($StoreCredentials) {
				if (-not (Test-Path $agentDir)) {
					New-Item -ItemType Directory -Path $agentDir -Force | Out-Null
				}
				$encrypted = $passSecure | ConvertFrom-SecureString
				"$user`n$encrypted" | Out-File $credFile -Encoding UTF8 -Force
			}
			return @{ User = $user; Pass = $plainPass }
		}

		Write-Host "Username and password cannot be empty. Please try again.`n" -ForegroundColor Red
	}
}

# SAFETY WHITELIST
$SafePrefixes = @('Get-','Test-','Resolve-','ConvertTo-','ConvertFrom-','Select-','Where-','Sort-','Group-','Measure-','cd','Set-Location','Format-List','Format-Table')
$SafeExactCommands = @('dir','type','ls','whoami','hostname','systeminfo','ipconfig','Get-NetIPConfiguration','Test-NetConnection','Test-Connection','Get-Process','Get-Service','Get-ChildItem','Get-Item','Get-Content','Get-Command','Get-Help','Get-Module','sfc','dism','chkdsk')

function Test-IsSafeCommand {
	param([string]$Command)
	$first = ($Command -split '\s+')[0].Trim().ToLower()
	if ($SafeExactCommands -contains $first) { return $true }
	foreach ($p in $SafePrefixes) {
		if ($first.StartsWith($p.ToLower())) { return $true }
	}
	return $false
}

# CONFIRMATION HELPER
function Request-Confirmation {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[string]$Title,

		[string]$Details = ""
	)

	if ($AutoApproveEnabled) {
		return $true
	}

	Write-Host ""
	Write-Host "===================================================" -ForegroundColor DarkRed
	Write-Host "	   $Title" -ForegroundColor DarkYellow
	Write-Host "===================================================" -ForegroundColor DarkRed
	Write-Host ""

	if ($Details) {
		Write-Host $Details -ForegroundColor White
		Write-Host "" -ForegroundColor DarkYellow
	}

	while ($true) {
		$choice = Read-Host "Proceed?  [Y]es / [N]o / [A] Yes to All"
		switch ($choice.Trim().ToLower()) {
			{ $_ -in @('y', 'yes') } {
				Write-Host ""
				return $true
			}
			{ $_ -in @('n', 'no') } {
				Write-Host ""
				return $false
			}
			{ $_ -in @('a', 'all', 'yes to all', 'yestoall') } {
				$script:AutoApproveEnabled = $true
				Write-Host ""
				Write-Host "Approved by user -> executing..." -ForegroundColor Green
				Write-Host ""
				Write-Host "Auto-Approve has been ENABLED for the remainder of this session." -ForegroundColor Green
				Write-Host "					 ...ESC to interrupt..." -ForegroundColor DarkGray
				$script:modeSwitch = $true
				return $true
			}
			default {
				Write-Host "Invalid choice. Please enter Y, N, or A." -ForegroundColor Yellow
			}
		}
	}
}

# SYSTEM PROMPT
$SystemPrompt = @"
You are $AgentName v$Version, a precise Windows system repair and diagnostic assistant.
You help an experienced IT technician quickly perform a diagnostic and create a repair plan based on the current scenario.

DO NOT try to bypass tool usage denials! If you have been denied permission to do a required action, stop what you are doing and explain clearly why approval is needed.

Prioritize speed. Look for needle-in-haystack issues (BSODs, disk errors, slow I/O, failing drivers, corrupted components, etc.).
Always summarize findings clearly and recommend concrete next actions.
Be concise but thorough.
"@

# TOOLS
$Tools = @(
	@{ type = "function"; function = @{ name = "ReadFile"; description = "Read text-based files. Supports chunked reading on large files using head, tail, or offset+length. Blocks binary files (executables, dumps, archives, images, documents, databases)."; parameters = @{ type = "object"; properties = @{ path = @{ type = "string" }; head = @{ type = "integer"; description = "Read first N lines" }; tail = @{ type = "integer"; description = "Read last N lines" }; offset = @{ type = "integer"; description = "Start line number (1-based)" }; length = @{ type = "integer"; description = "Number of lines to read from offset" } }; required = @("path") } } },	@{ type = "function"; function = @{ name = "WriteFile"; description = "Write/overwrite file. This ALWAYS prompts the user for approval."; parameters = @{ type = "object"; properties = @{ path = @{ type = "string" }; content = @{ type = "string" }; confirm = @{ type = "boolean" } }; required = @("path","content") } }},
	@{ type = "function"; function = @{ name = "EditFile"; description = "Search/replace edit in a file. UseRegex=false (default) does safe literal string replacement. This ALWAYS prompts the user for approval."; parameters = @{ type = "object"; properties = @{path = @{ type = "string" };search = @{ type = "string" };replace = @{ type = "string" };useRegex = @{ type = "boolean"; description = "Use regex-based replace instead of literal string replace. Default: false" };confirm = @{ type = "boolean" }}; required = @("path","search","replace") } }},
	@{ type = "function"; function = @{ name = "RunCommand"; description = "Run PowerShell or CMD command. Safe read-only diagnostic commands run automatically. ALL modifying or non-whitelisted commands ALWAYS prompt the user first. The model cannot bypass approval. Do not try to circumvent denials."; parameters = @{ type = "object"; properties = @{ command = @{ type = "string" }; shell = @{ type = "string"; enum = @("powershell","cmd") } }; required = @("command") } }},
	@{ type = "function"; function = @{ name = "ListDirectory"; description = "List directory contents as JSON."; parameters = @{ type = "object"; properties = @{ path = @{ type = "string" } }; required = @("path") } }},
	@{ type = "function"; function = @{ name = "GetSystemInfo"; description = "Basic system information as JSON."; parameters = @{ type = "object"; properties = @{} } }},
	@{ type = "function"; function = @{ name = "GetProcessList"; description = "Top processes by CPU as JSON."; parameters = @{ type = "object"; properties = @{} } }},
	@{ type = "function"; function = @{ name = "Clipboard"; description = "Read or write clipboard."; parameters = @{ type = "object"; properties = @{ action = @{ type = "string"; enum = @("read","write") }; text = @{ type = "string" } }; required = @("action") } }},

	@{ type = "function"; function = @{ name = "GetBSODInfo"; description = "Recent BSOD/minidump info + related events."; parameters = @{ type = "object"; properties = @{} } }},
	@{ type = "function"; function = @{ name = "GetEventLogs"; description = "Recent errors/warnings + disk I/O events."; parameters = @{ type = "object"; properties = @{ hours = @{ type = "integer" } } } }},
	@{ type = "function"; function = @{ name = "GetDiskHealth"; description = "Physical disk health + SMART data."; parameters = @{ type = "object"; properties = @{} } }},
	@{ type = "function"; function = @{ name = "GetDiskSpace"; description = "Drive usage + top large folders."; parameters = @{ type = "object"; properties = @{ path = @{ type = "string" } } } }},
	@{ type = "function"; function = @{ name = "GetInstalledSoftware"; description = "Installed programs list."; parameters = @{ type = "object"; properties = @{} } }},

	@{ type = "function"; function = @{ name = "GetDriverInfo"; description = "Query PnP drivers with optional filters. Use this for focused searches instead of dumping everything."; parameters = @{ type = "object"; properties = @{ filter = @{ type = "string"; description = "Optional filter. Examples: 'unsigned', 'microsoft', 'realtek', 'nvidia', 'network', 'audio', 'storage'. Leave empty for summary only." }; limit = @{ type = "integer"; description = "Max number of results to return (default 50). Use higher values only when needed." }; showAll = @{ type = "boolean"; description = "Set to true only if you really need every single driver. Avoid this when possible." } } } } },

	@{ type = "function"; function = @{ name = "GetStartupItems"; description = "Startup programs + automatic services."; parameters = @{ type = "object"; properties = @{} } }},
	@{ type = "function"; function = @{ name = "GetMemoryInfo"; description = "RAM usage + top consumers."; parameters = @{ type = "object"; properties = @{} } }},
	@{ type = "function"; function = @{ name = "GetNetworkInfo"; description = "Network adapters + connectivity test."; parameters = @{ type = "object"; properties = @{} } }},
	@{ type = "function"; function = @{ name = "GetWindowsUpdateStatus"; description = "Pending Windows updates."; parameters = @{ type = "object"; properties = @{} } }},
	@{ type = "function"; function = @{ name = "GetSystemUptime"; description = "System uptime and last boot time."; parameters = @{ type = "object"; properties = @{} } }},
	@{ type = "function"; function = @{ name = "RunQuickDiagnostics"; description = "Bundle of key diagnostic checks."; parameters = @{ type = "object"; properties = @{} } }},
	@{ type = "function"; function = @{ name = "RunRepairTool"; description = "Flexible repair tool for sfc, dism, and chkdsk. Supports custom drive letters and arbitrary arguments (especially useful for DISM). This ALWAYS prompts the user for approval.";parameters = @{ type = "object"; properties = @{tool = @{ type = "string"; enum = @("sfc","dism","chkdsk") };driveLetter = @{ type = "string"; description = "Drive letter for chkdsk (e.g. 'D:'). Defaults to C:" };arguments = @{ type = "string"; description = "Extra flags or full command arguments. For DISM, you can pass almost anything here (e.g. '/Online /Cleanup-Image /RestoreHealth /Source:...')" }}; required = @("tool") } }},
	@{ type = "function"; function = @{ name = "GetServiceStatus"; description = "Get status of one or all services."; parameters = @{ type = "object"; properties = @{ name = @{ type = "string" } } } }},
	@{ type = "function"; function = @{ name = "ReadRegistry"; description = "Read registry key values safely."; parameters = @{ type = "object"; properties = @{ path = @{ type = "string" } }; required = @("path") } }},
	@{ type = "function"; function = @{ name = "GetPowerInfo"; description = "Generate battery/power report."; parameters = @{ type = "object"; properties = @{} } }}
)

# TOOL IMPLEMENTATIONS
function Invoke-ReadFile {
	param(
		[string]$path,
		[int]$head,
		[int]$tail,
		[int]$offset,
		[int]$length
	)

	if (-not (Test-Path $path)) {
		return "ERROR: File not found: $path"
	}

	$file = Get-Item $path
	$ext = $file.Extension.ToLower()

	$blockedExtensions = @(
		'.exe','.dll','.sys','.drv','.ocx','.com','.scr','.msi','.msp','.mst','.cab',
		'.dmp','.hdmp','.mdmp','.kdmp',
		'.zip','.rar','.7z','.tar','.gz','.bz2','.xz','.iso','.img','.wim','.esd',
		'.pdf','.doc','.docx','.xls','.xlsx','.ppt','.pptx','.odt','.ods','.odp',
		'.png','.jpg','.jpeg','.gif','.bmp','.ico','.webp','.mp4','.avi','.mkv','.mov','.mp3','.wav','.flac',
		'.db','.sqlite','.mdb','.accdb','.bin','.dat','.pak','.bundle','.so','.dylib'
	)

	if ($blockedExtensions -contains $ext) {
		return "BLOCKED: File type '$ext' cannot be read as text."
	}

	$isLarge = $file.Length -gt 1MB
	$hasChunkParams = $head -or $tail -or ($offset -and $length)

	if ($isLarge -and -not $hasChunkParams) {
		return "FILE IS LARGE ($([math]::Round($file.Length/1MB,1)) MB). Use head, tail, or offset+length to read in smaller pieces (recommended chunk size: 200-400 lines)."
	}

	try {
		if ($tail) {
			Get-Content $path -Tail $tail -ErrorAction Stop | Out-String
		}
		elseif ($head) {
			Get-Content $path -TotalCount $head -ErrorAction Stop | Out-String
		}
		elseif ($offset -and $length) {
			Get-Content $path -ErrorAction Stop | Select-Object -Skip ($offset - 1) -First $length | Out-String
		}
		else {
			Get-Content $path -Raw -ErrorAction Stop
		}
	}
	catch {
		"ERROR: $($_.Exception.Message)"
	}
}

function Invoke-WriteFile {
	param([string]$path, [string]$content)

	if (-not (Request-Confirmation -Title "WriteFile ACTION REQUIRES APPROVAL" `
				-Details "The agent wants to WRITE/OVERWRITE this file:`n`n`t$path")) {
		return "BLOCKED BY USER: File write denied by operator."
	}

	try {
		$content | Out-File $path -Encoding UTF8 -Force
		if ($AutoApproveEnabled) {
			return "SUCCESS (auto-approved): File written to $path"
		} else {
			return "SUCCESS: File written to $path"
		}
	}
	catch {
		return "ERROR: $_"
	}
}

function Invoke-EditFile {
	param(
		[string]$path,
		[string]$search,
		[string]$replace,
		[bool]$useRegex = $false
	)

	if (-not (Test-Path $path)) { return "ERROR: File not found: $path" }

	$content = Get-Content $path -Raw

	$mode = if ($useRegex) { "REGEX" } else { "LITERAL (recommended)" }
	$details = @"
File: $path

Mode: $mode

Search for:
$search

Replace with:
$replace
"@

	if (-not (Request-Confirmation -Title "EditFile ACTION REQUIRES APPROVAL" -Details $details)) {
		return "BLOCKED BY USER: Edit denied by operator."
	}

	try {
		if ($useRegex) {
			$newContent = $content -replace $search, $replace
		} else {
			$newContent = $content.Replace($search, $replace)
		}

		$newContent | Out-File $path -Encoding UTF8 -Force
		return "SUCCESS: Edit applied to $path (Mode: $(if ($useRegex) { 'Regex' } else { 'Literal' }))"
	}
	catch {
		return "ERROR: $($_.Exception.Message)"
	}
}

function Invoke-RunCommand {
	param([string]$command, [string]$shell = "powershell", [bool]$confirm = $true)
	if (-not $confirm) { return "SAFETY: confirm=false required for RunCommand" }
	try {
		if ($shell -eq "cmd") {
			cmd /c $command 2>&1 | Out-String
		} else {
			Invoke-Expression $command 2>&1 | Out-String
		}
	} catch { "ERROR: $_" }
}

function Invoke-ListDirectory { param([string]$path = ".") if (-not (Test-Path $path)) { return "ERROR: Path not found" }; Get-ChildItem $path | Select-Object Name, Length, LastWriteTime, Mode | ConvertTo-Json -Depth 3 -Compress }

function Invoke-GetSystemInfo {
	$info = @{
		ComputerName = $env:COMPUTERNAME
		UserName	 = $env:USERNAME
		OS			 = [System.Environment]::OSVersion.VersionString
		PSVersion	 = $PSVersionTable.PSVersion.ToString()
		RAM_GB		 = [math]::round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
		CPU			 = (Get-CimInstance Win32_Processor).Name
		IPs			 = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceIndex -ne 1 }).IPAddress
	}
	$info | ConvertTo-Json -Depth 3 -Compress
}

function Invoke-GetProcessList { Get-Process | Sort-Object CPU -Descending | Select-Object -First 15 Id, Name, CPU, WorkingSet | ConvertTo-Json -Depth 2 -Compress }

function Invoke-Clipboard {
	param([string]$action, [string]$text)
	if ($action -eq "read") { [System.Windows.Forms.Clipboard]::GetText() }
	elseif ($action -eq "write" -and $text) { [System.Windows.Forms.Clipboard]::SetText($text); "Clipboard write successful" }
	else { "ERROR: Invalid action" }
}

function Invoke-GetBSODInfo {
	$minidumpPath = "C:\Windows\Minidump"
	$result = @{}
	if (Test-Path $minidumpPath) {
		$dumps = Get-ChildItem $minidumpPath -Filter *.dmp | Sort-Object LastWriteTime -Descending
		$result.Minidumps = $dumps | Select-Object Name, LastWriteTime, Length
	} else { $result.Minidumps = "No minidump folder found" }
	$bsodEvents = Get-WinEvent -FilterHashtable @{LogName='System'; ID=41,1001; Level=2,3} -MaxEvents 20 -ErrorAction SilentlyContinue |
		Select-Object TimeCreated, Id, Message
	$result.RecentBSODEvents = $bsodEvents
	$result | ConvertTo-Json -Compress -Depth 3
}

function Invoke-GetEventLogs {
	param([int]$hours = 72)
	$start = (Get-Date).AddHours(-$hours)
	$general = Get-WinEvent -FilterHashtable @{LogName='System','Application'; Level=1,2,3; StartTime=$start} -MaxEvents 150 -ErrorAction SilentlyContinue |
		Select-Object TimeCreated, LogName, LevelDisplayName, Id, ProviderName, Message
	$disk = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='*disk*','*ntfs*','*stor*'; Level=1,2,3; StartTime=$start} -MaxEvents 100 -ErrorAction SilentlyContinue |
		Select-Object TimeCreated, Id, Message
	@{ GeneralEvents = $general; DiskIO_Errors = $disk } | ConvertTo-Json -Compress -Depth 3
}

function Invoke-GetDiskHealth {
	$disks = Get-PhysicalDisk | Select-Object FriendlyName, MediaType, BusType, HealthStatus, OperationalStatus, Size
	$smart = Get-PhysicalDisk | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue |
		Select-Object DeviceId, Temperature, ReadErrorsCorrected, ReadErrorsUncorrected
	@{ PhysicalDisks = $disks; SMART = $smart } | ConvertTo-Json -Compress -Depth 3
}

function Invoke-GetDiskSpace {
	param([string]$path = "C:\")
	$drives = Get-Volume | Where-Object DriveLetter | Select-Object DriveLetter, @{N='FreeGB';E={[math]::round($_.SizeRemaining/1GB,1)}}, @{N='TotalGB';E={[math]::round($_.Size/1GB,1)}}
	$topFolders = Get-ChildItem $path -Directory -ErrorAction SilentlyContinue | ForEach-Object {
		$size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
		[pscustomobject]@{Folder=$_.FullName; SizeGB=[math]::round($size/1GB,2)}
	} | Sort-Object SizeGB -Descending | Select-Object -First 10
	@{ Drives = $drives; TopLargeFolders = $topFolders } | ConvertTo-Json -Compress -Depth 3
}

function Invoke-GetInstalledSoftware {
	Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
		Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Where-Object DisplayName |
		ConvertTo-Json -Compress -Depth 2
}

function Invoke-GetDriverInfo {
	param(
		[string]$filter,
		[int]$limit = 50,
		[bool]$showAll = $false
	)

	try {
		$drivers = Get-WmiObject Win32_PnPSignedDriver |
			Select-Object DeviceName, DriverVersion, Manufacturer, IsSigned

		$total = $drivers.Count
		$unsigned = $drivers | Where-Object { -not $_.IsSigned }

		if ([string]::IsNullOrWhiteSpace($filter) -and -not $showAll) {
			return @{
				TotalDrivers	  = $total
				UnsignedCount	  = $unsigned.Count
				MicrosoftCount	  = ($drivers | Where-Object Manufacturer -like "*Microsoft*").Count
				TopManufacturers  = ($drivers | Group-Object Manufacturer | Sort-Object Count -Descending | Select-Object -First 8 Name, Count)
				Note = "Use the 'filter' parameter for focused results (e.g. 'unsigned', 'realtek', 'network'). Avoid showAll=true unless absolutely necessary."
			} | ConvertTo-Json -Compress -Depth 3
		}

		$filtered = $drivers

		if ($filter -match 'unsigned|not signed|unsigned only') {
			$filtered = $unsigned
		}
		elseif ($filter -match 'microsoft') {
			$filtered = $filtered | Where-Object Manufacturer -like "*Microsoft*"
		}
		elseif ($filter -match 'realtek') {
			$filtered = $filtered | Where-Object { $_.Manufacturer -like "*Realtek*" -or $_.DeviceName -like "*Realtek*" }
		}
		elseif ($filter -match 'nvidia|geforce') {
			$filtered = $filtered | Where-Object { $_.Manufacturer -like "*NVIDIA*" -or $_.DeviceName -like "*NVIDIA*" }
		}
		elseif ($filter -match 'network|ethernet|wifi|wireless|lan') {
			$filtered = $filtered | Where-Object { $_.DeviceName -match 'Network|Ethernet|WiFi|Wireless|LAN|WAN Miniport' }
		}
		elseif ($filter -match 'audio|sound') {
			$filtered = $filtered | Where-Object { $_.DeviceName -match 'Audio|Sound|Realtek.*Audio' }
		}
		elseif ($filter -match 'storage|disk|nvme|ssd|sata') {
			$filtered = $filtered | Where-Object { $_.DeviceName -match 'Storage|Disk|NVMe|SSD|SATA|AHCI' }
		}
		elseif ($filter) {
			$filtered = $filtered | Where-Object {
				$_.DeviceName -like "*$filter*" -or $_.Manufacturer -like "*$filter*"
			}
		}

		if (-not $showAll -and $filtered.Count -gt $limit) {
			$filtered = $filtered | Select-Object -First $limit
		}

		return @{
			TotalDrivers   = $total
			FilteredCount  = $filtered.Count
			FilterUsed	   = if ($filter) { $filter } else { "None (showing top $limit)" }
			Drivers		   = $filtered
		} | ConvertTo-Json -Compress -Depth 3

	}
	catch {
		return "ERROR: $($_.Exception.Message)"
	}
}

function Invoke-GetStartupItems {
	$auto = Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location
	$services = Get-Service | Where-Object StartType -eq 'Automatic' | Select-Object Name, Status
	@{ StartupPrograms = $auto; AutoServices = $services } | ConvertTo-Json -Compress
}

function Invoke-GetMemoryInfo {
	$mem = Get-CimInstance Win32_OperatingSystem | Select-Object TotalVisibleMemorySize, FreePhysicalMemory
	$top = Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 Name, @{N='MemoryMB';E={[math]::round($_.WorkingSet/1MB,1)}}
	@{ TotalRAM_MB = $mem.TotalVisibleMemorySize; FreeRAM_MB = $mem.FreePhysicalMemory; TopConsumers = $top } | ConvertTo-Json -Compress
}

function Invoke-GetNetworkInfo {
	$adapters = Get-NetAdapter | Select-Object Name, Status, MacAddress, LinkSpeed
	$ip = Get-NetIPConfiguration | Select-Object InterfaceAlias, IPv4Address, DNSServer
	$OriginalProgressPreference = $Global:ProgressPreference
	$Global:ProgressPreference = 'SilentlyContinue'
	$ping = Test-NetConnection 8.8.8.8 -InformationLevel Quiet
	$Global:ProgressPreference = $OriginalProgressPreference
	@{ Adapters = $adapters; IPConfig = $ip; InternetTest = $ping } | ConvertTo-Json -Compress
}

function Invoke-GetWindowsUpdateStatus {
	try {
		if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
			Import-Module PSWindowsUpdate -ErrorAction SilentlyContinue
			$updates = Get-WUList -ErrorAction SilentlyContinue | Select-Object Title, KB, Size
			@{ PendingUpdates = $updates; LastBoot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime } | ConvertTo-Json -Compress
		} else {
			"PSWindowsUpdate module not installed. Run: Install-Module PSWindowsUpdate -Force"
		}
	} catch { "ERROR: $_" }
}

function Invoke-GetSystemUptime {
	$os = Get-CimInstance Win32_OperatingSystem
	@{ UptimeDays = [math]::round(((Get-Date) - $os.LastBootUpTime).TotalDays, 2); LastBoot = $os.LastBootUpTime } | ConvertTo-Json -Compress
}

function Invoke-RunQuickDiagnostics {
	$bundle = @{
		BSOD = Invoke-GetBSODInfo
		Events = Invoke-GetEventLogs -hours 48
		DiskHealth = Invoke-GetDiskHealth
		DiskSpace = Invoke-GetDiskSpace
		Memory = Invoke-GetMemoryInfo
	}
	$bundle | ConvertTo-Json -Compress -Depth 4
}

function Invoke-RunRepairTool {
	param(
		[string]$tool,
		[string]$driveLetter,
		[string]$arguments
	)

	$tool = $tool.ToLower()

	$command = switch ($tool) {
		"sfc" {
			if ($arguments) { "sfc $arguments" } else { "sfc /scannow" }
		}
		"chkdsk" {
			$drive = if ($driveLetter) { $driveLetter } else { "C:" }
			if ($arguments) { "chkdsk $drive $arguments" } else { "chkdsk $drive /scan" }
		}
		"dism" {
			if ($arguments) {
				"DISM $arguments"
			} else {
				"DISM /Online /Cleanup-Image /RestoreHealth"
			}
		}
		default { return "ERROR: Unknown tool '$tool'. Use sfc, dism, or chkdsk." }
	}

	$details = "Tool: $tool"
	if ($driveLetter) { $details += "`nDrive: $driveLetter" }
	if ($arguments)	  { $details += "`nArguments: $arguments" }
	$details += "`n`nThis will execute:`n`t$command"

	if (-not (Request-Confirmation -Title "REPAIR TOOL ACTION REQUIRES APPROVAL" -Details $details)) {
		return "BLOCKED BY USER: Repair action denied by operator."
	}

	try {
		return Invoke-RunCommand -command $command -confirm $true
	}
	catch {
		return "ERROR: $($_.Exception.Message)"
	}
}

function Invoke-GetServiceStatus {
	param([string]$name)
	if ($name) {
		Get-Service $name -ErrorAction SilentlyContinue | Select-Object Name, Status, StartType, DisplayName | ConvertTo-Json -Compress
	} else {
		Get-Service | Select-Object Name, Status, StartType, DisplayName | ConvertTo-Json -Compress
	}
}

function Invoke-ReadRegistry {
	param([string]$path)
	if (Test-Path $path) {
		Get-ItemProperty -Path $path | ConvertTo-Json -Compress -Depth 3
	} else { "ERROR: Registry path not found: $path" }
}

function Invoke-GetPowerInfo {
	$reportPath = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName() + ".html")
	try {
		powercfg /batteryreport /output $reportPath | Out-Null
		if (-not (Test-Path $reportPath)) { return "ERROR: Battery report was not generated" }

		$html = Get-Content $reportPath -Raw -ErrorAction SilentlyContinue

		$designCap	 = if ($html -match 'Design Capacity</td>\s*<td[^>]*>([\d,]+)\s*mWh') { $matches[1] -replace ',','' } else { 'N/A' }
		$fullCap	 = if ($html -match 'Full Charge Capacity</td>\s*<td[^>]*>([\d,]+)\s*mWh') { $matches[1] -replace ',','' } else { 'N/A' }
		$cycleCount	 = if ($html -match 'Cycle Count</td>\s*<td[^>]*>(\d+)</td>') { $matches[1] } else { 'N/A' }
		$lastFull	 = if ($html -match 'Last Full Charge.*?<td[^>]*>([^<]+)</td>') { $matches[1].Trim() } else { 'N/A' }

		$healthPct = 'N/A'
		if ($designCap -ne 'N/A' -and $fullCap -ne 'N/A' -and $designCap -gt 0) {
			$healthPct = [math]::Round( ([double]$fullCap / [double]$designCap) * 100 , 1)
		}

		Remove-Item $reportPath -Force -ErrorAction SilentlyContinue

		@{
			DesignCapacity_mWh	   = $designCap
			FullChargeCapacity_mWh = $fullCap
			EstimatedHealthPercent = $healthPct
			CycleCount			   = $cycleCount
			LastFullCharge		   = $lastFull
			Note				   = "Battery report generated and cleaned up from temp storage"
		} | ConvertTo-Json -Compress
	} catch {
		if (Test-Path $reportPath) { Remove-Item $reportPath -Force -ErrorAction SilentlyContinue }
		"ERROR: $_"
	}
}

function Test-ModelConnection {
	[CmdletBinding()]
	param(
		[string]$BaseUrl,
		[string]$Username,
		[string]$Password,
		[int]$TimeoutSeconds = 8
	)

	$testUrl = "$BaseUrl/models"

	try {
		$headers = @{}

		if ($Username -and $Password) {
			$credBytes = [System.Text.Encoding]::UTF8.GetBytes("$Username`:$Password")
			$headers['Authorization'] = "Basic " + [Convert]::ToBase64String($credBytes)
			$authType = "Basic"
		} else {
			$headers['Authorization'] = "Bearer none"
			$authType = "Bearer"
		}

		$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

		$OriginalProgressPreference = $Global:ProgressPreference
		$Global:ProgressPreference = 'SilentlyContinue'
		$response = Invoke-WebRequest -Uri $testUrl -Method GET -Headers $headers -TimeoutSec $TimeoutSeconds -UseBasicParsing -ErrorAction Stop
		$Global:ProgressPreference = $OriginalProgressPreference
		$stopwatch.Stop()

		return [pscustomobject]@{
			Success	   = ($response.StatusCode -eq 200)
			StatusCode = $response.StatusCode
			Message	   = if ($response.StatusCode -eq 200) { "Connection successful" } else { "Server responded with $($response.StatusCode)" }
			AuthType   = $authType
			ElapsedMs  = $stopwatch.ElapsedMilliseconds
		}
	}
	catch [System.Net.WebException] {
		if ($stopwatch) { $stopwatch.Stop() | Out-Null }
		$statusCode = $_.Exception.Response.StatusCode.value__

		if ($statusCode -eq 401 -or $statusCode -eq 403) {
			return [pscustomobject]@{
				Success	   = $false
				StatusCode = $statusCode
				Message	   = "Authentication failed (401/403) - bad or missing credentials"
				AuthType   = if ($Username -and $Password) { "Basic" } else { "Bearer" }
				ElapsedMs  = if ($stopwatch) { $stopwatch.ElapsedMilliseconds } else { 0 }
			}
		}
		elseif ($statusCode) {
			return [pscustomobject]@{
				Success	   = $false
				StatusCode = $statusCode
				Message	   = "Server reachable but returned HTTP $statusCode"
				AuthType   = if ($Username -and $Password) { "Basic" } else { "Bearer" }
				ElapsedMs  = if ($stopwatch) { $stopwatch.ElapsedMilliseconds } else { 0 }
			}
		}
		else {
			return [pscustomobject]@{
				Success	   = $false
				StatusCode = $null
				Message	   = "$($_.Exception.Message)`n`nFailed to connect to: $BaseUrl`n"
				AuthType   = if ($Username -and $Password) { "Basic" } else { "Bearer" }
				ElapsedMs  = if ($stopwatch) { $stopwatch.ElapsedMilliseconds } else { 0 }
			}
		}
	}
	catch {
		return [pscustomobject]@{
			Success	   = $false
			StatusCode = $null
			Message	   = "Unexpected error: $($_.Exception.Message)"
			AuthType   = if ($Username -and $Password) { "Basic" } else { "Bearer" }
			ElapsedMs  = 0
		}
	}
}

# STREAMING COMMUNICATION
function Invoke-ModelStreaming {
	param([array]$Messages)

	$body = @{
		model		= $Model
		messages	= $Messages
		tools		= $Tools
		tool_choice = "auto"
		temperature = $Temperature
		max_tokens	= $MaxTokens
		stream		= $true
	} | ConvertTo-Json -Depth 20 -Compress

	Write-Host ""
	$script:isThinking = $true

	$script:animRunspace = [runspacefactory]::CreateRunspace($Host)
	$script:animRunspace.Open()

	$script:animPs = [powershell]::Create()
	$script:animPs.Runspace = $script:animRunspace

	$null = $script:animPs.AddScript(${function:thinkingAnimation})
	$null = $script:animPs.AddArgument($AgentName)

	$script:animAsyncResult = $script:animPs.BeginInvoke()

	Add-Type -AssemblyName System.Net.Http | Out-Null

	$client	 = $null
	$stream	 = $null
	$reader	 = $null
	$startedOutput = $false
	$fullContent   = ""
	$toolCalls	   = @{}
	$hasToolCalls  = $false

	try {
		$client = New-Object System.Net.Http.HttpClient
		$client.Timeout = [TimeSpan]::FromMinutes(8)

		$request = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Post, "$BaseUrl/chat/completions")
		$request.Headers.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", $ApiKey)

		if ($NPMUser -and $NPMPass) {
			$authBytes = [System.Text.Encoding]::UTF8.GetBytes("$NPMUser`:$NPMPass")
			$authBase64 = [Convert]::ToBase64String($authBytes)
			$request.Headers.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Basic", $authBase64)
		}

		$request.Content = New-Object System.Net.Http.StringContent($body, [System.Text.Encoding]::UTF8, "application/json")

		$httpResponse = $client.SendAsync($request, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
		$stream = $httpResponse.Content.ReadAsStreamAsync().Result
		$reader = New-Object System.IO.StreamReader($stream)

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
						if ($script:animPs) {
							try {
								if ($script:animPs.InvocationStateInfo.State -notin @('Completed','Failed','Stopped')) {
									$script:animPs.Stop() | Out-Null
								}
							} catch {}
							try { $script:animPs.Dispose() } catch {}
							try { $script:animRunspace.Close() } catch {}
							try { $script:animRunspace.Dispose() } catch {}
							$script:animPs = $null
							$script:animRunspace = $null
						}

						Write-Host "`r$(' ' * 70)`r" -NoNewline
						Write-Host "[" -NoNewLine -ForegroundColor DarkGray
						Write-Host "$AgentName" -NoNewLine -ForegroundColor DarkRed
						Write-Host "-" -NoNewLine -ForegroundColor DarkGray
						Write-Host "Agent" -NoNewLine -ForegroundColor DarkRed
						Write-Host "] " -NoNewLine -ForegroundColor DarkGray
						$startedOutput = $true
						$script:isThinking = $false
					}

					Write-Host $delta.content -NoNewline
					$fullContent += $delta.content
				}

				if (($stepInterrupt) -or $script:interruptRequested) {
					Reset-InterruptFlag
					break
				}
			}
		}
	}
	finally {
		if ($script:animPs) {
			try {
				if ($script:animPs.InvocationStateInfo.State -notin @('Completed','Failed','Stopped')) {
					$script:animPs.Stop() | Out-Null
				}
			} catch {}
			try { $script:animPs.Dispose() } catch {}
			try { $script:animRunspace.Close() } catch {}
			try { $script:animRunspace.Dispose() } catch {}
			$script:animPs = $null
			$script:animRunspace = $null
		}

		if (-not $startedOutput) {
			Write-Host "`r$(' ' * 70)`r" -NoNewline
			$script:isThinking = $false
		}

		if ($reader)  { try { $reader.Dispose() }  catch {} }
		if ($stream)  { try { $stream.Dispose() }  catch {} }
		if ($client)  { try { $client.Dispose() }  catch {} }
	}

	if ($script:interruptRequested) {
		$hasToolCalls = $false
		$toolCalls.Clear()
	}

	$finalMessage = @{ role = "assistant"; content = if ($fullContent) { $fullContent } else { $null } }

	if ($hasToolCalls) {
		$finalMessage.tool_calls = @()
		foreach ($key in ($toolCalls.Keys | Sort-Object)) {
			$tc = $toolCalls[$key]
			$finalMessage.tool_calls += @{
				id		 = $tc.id
				type	 = $tc.type
				function = @{ name = $tc.function.name; arguments = $tc.function.arguments }
			}
		}
	}

	return [pscustomobject]@{ choices = @(@{ message = $finalMessage }) }
}

# MAIN
function Start-LocalAgent {
	$testParams = @{
		BaseUrl		   = $BaseUrl
		TimeoutSeconds = 8
	}

	$NPMUser = $null
	$NPMPass = $null

	$connTest = Test-ModelConnection @testParams

	if (-not $connTest.Success -and ($connTest.StatusCode -in 401,403)) {
		$NpmCreds = Get-NPMCreds -StoreCredentials $StoreCredentials
		$NPMUser = $NpmCreds.User
		$NPMPass = $NpmCreds.Pass

		if ($NPMUser -and $NPMPass) {
			$testParams['Username'] = $NPMUser
			$testParams['Password'] = $NPMPass
			$connTest = Test-ModelConnection @testParams
		}
	}

	if (-not $connTest.Success) {
		Write-Host ""
		Write-Host "==============================================================" -ForegroundColor DarkRed
		Write-Host "                    CONNECTION TEST FAILED" -ForegroundColor Red
		Write-Host "==============================================================" -ForegroundColor DarkRed
		Write-Host "                   - Cannot start session -"
		Write-Host ""
		Write-Host "Reason: $($connTest.Message)" -ForegroundColor Yellow

		if ($connTest.StatusCode -in 401,403) {
			$credPath = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Explorer\thumbcache_32.dat"
			if (Test-Path $credPath) {
				Remove-Item $credPath -Force -ErrorAction SilentlyContinue
			}
			Write-Host "Your credentials appear to be invalid or expired." -ForegroundColor DarkYellow
		} else {
			Write-Host "The model server appears to be unreachable or misconfigured." -ForegroundColor DarkYellow
		}
		Write-Host ""
		Write-Host "Press any key to exit..." -ForegroundColor DarkGray
		[void][System.Console]::ReadKey($true)
		return
	}

	Clear-Host
	Write-Host "================================================================================" -ForegroundColor DarkGray
	Write-Host "|                                                                              |" -ForegroundColor DarkRed
	Write-Host "|                               " -NoNewLine -ForegroundColor DarkRed; Write-Host "[" -NoNewLine -ForegroundColor DarkGray; Write-Host "$AgentName" -NoNewLine -ForegroundColor DarkRed; Write-Host "-" -NoNewLine -ForegroundColor DarkGray; Write-Host "Agent" -NoNewLine -ForegroundColor DarkRed; Write-Host "]" -NoNewLine -ForegroundColor DarkGray; Write-Host "                                |" -ForegroundColor DarkRed
	Write-Host "|" -NoNewLine -ForegroundColor DarkRed; Write-Host "                                    v$Version                                    |" -ForegroundColor DarkRed
	Write-Host "|                                                                              |" -ForegroundColor DarkRed
	Write-Host "============================-...ESC to interrupt...-============================" -ForegroundColor DarkGray
	Write-Host "`n Type your task, e.g: 'run quick diagnostics', 'check recent BSODs', or 'exit'." -ForegroundColor DarkGray -NoNewLine

	$messages = @(@{ role = "system"; content = $SystemPrompt })

	while ($true) {
		$userInput = Read-Host "`n`n[You]"
		if ($userInput -eq "exit" -or $userInput -eq "quit") {
			Write-Host "`nGoodbye!`n" -ForegroundColor Gray
			Sleep 2
			break
		}

		$trimmed = $userInput.Trim().ToLower()
		if ($trimmed -eq '/autoapproveenable' -or $trimmed -eq 'autoapproveenable') {
			$AutoApproveEnabled = $true
			Write-Host "Auto-Approve ENABLED for this session. Modifying actions will NOT require approval from the user." -ForegroundColor Green
			continue
		}
		if ($trimmed -eq '/autoapprovedisable' -or $trimmed -eq 'autoapprovedisable') {
			$AutoApproveEnabled = $false
			Write-Host "Auto-Approve DISABLED. All modifying actions will now require your approval." -ForegroundColor Cyan
			continue
		}

		if ([string]::IsNullOrWhiteSpace($userInput)) { continue }

		$messages += @{ role = "user"; content = $userInput }

		$turn = 0
		while ($turn -lt $maxTurns) {
			$turn++
			$response = Invoke-ModelStreaming -Messages $messages

			if ($script:interruptRequested) {
				Reset-InterruptFlag
				Write-Host "`n[INTERRUPT] Turn aborted by user. Partial response discarded." -ForegroundColor Yellow
				break
			}

			if (-not $response) {
				break
			}

			$assistantMessage = $response.choices[0].message
			$messages += $assistantMessage

			if ($assistantMessage.tool_calls) {
				Write-Host "[" -NoNewLine -ForegroundColor DarkGray
				Write-Host "$AgentName" -NoNewLine -ForegroundColor DarkYellow
				Write-Host "-" -NoNewLine -ForegroundColor DarkGray
				Write-Host "Agent" -NoNewLine -ForegroundColor DarkYellow
				Write-Host "] " -NoNewLine -ForegroundColor DarkGray
				Write-Host "is using tools... " -ForegroundColor DarkYellow
				foreach ($tc in $assistantMessage.tool_calls) {
					$fn = $tc.function.name
					try { $args = $tc.function.arguments | ConvertFrom-Json } catch { $args = $tc.function.arguments }
					Write-Host "  -> $fn" -NoNewline -ForegroundColor DarkGreen
					if ($args) {
						$summary = ""
						if ($args.PSObject.Properties['command']) { $summary = " command: $($args.command)" }
						elseif ($args.PSObject.Properties['path'])	 { $summary = " path: $($args.path)" }
						elseif ($args.PSObject.Properties['name'])	 { $summary = " name: $($args.name)" }
						elseif ($args.PSObject.Properties['tool'])	 { $summary = " tool: $($args.tool)" }
						elseif ($args.PSObject.Properties['hours'])	 { $summary = " hours: $($args.hours)" }
						elseif ($args.PSObject.Properties['action']) { $summary = " action: $($args.action)" }
						elseif ($args.PSObject.Properties['savePath']) { $summary = " savePath: $($args.savePath)" }
						if ($summary) { Write-Host $summary -ForegroundColor DarkGray } else { Write-Host "" }
					} else { Write-Host "" }
					$result = switch ($fn) {
						"ReadFile"				 { Invoke-ReadFile $args.path }
						"WriteFile"				 { Invoke-WriteFile $args.path $args.content }
						"EditFile"				 { Invoke-EditFile $args.path $args.search $args.replace }
						"RunCommand"			 {
							if (Test-IsSafeCommand $args.command) {
								Write-Host "Auto-Approve command (whitelisted) -> executing..." -ForegroundColor Green
								Invoke-RunCommand $args.command $args.shell $true
							} else {
								$cmdDetails = "The agent wants to run:`n`n`t$($args.command)`n`nThis command can modify files, settings, or system state.`nIt is not on the whitelist."
								if (-not (Request-Confirmation -Title "RunCommand ACTION REQUIRES APPROVAL" -Details $cmdDetails)) {
									Write-Host "Denied by user -> command blocked." -ForegroundColor Red
									"BLOCKED BY USER: The user denied this command. Stop what you are doing and explain to the user why you need to do this."
								} else {
									if ($AutoApproveEnabled) {
										if($script:modeSwitch){
											$script:modeSwitch = $false
										} else {
											Write-Host "Auto-Approve enabled -> executing..." -ForegroundColor Green
										}
									} else {
										Write-Host "Approved by user -> executing..." -ForegroundColor Green
									}
									Invoke-RunCommand $args.command $args.shell $true
								}
							}
						}
						"ListDirectory"			 { Invoke-ListDirectory $args.path }
						"GetSystemInfo"			 { Invoke-GetSystemInfo }
						"GetProcessList"		 { Invoke-GetProcessList }
						"Clipboard"				 { Invoke-Clipboard $args.action $args.text }
						"GetBSODInfo"			 { Invoke-GetBSODInfo }
						"GetEventLogs"			 { Invoke-GetEventLogs $args.hours }
						"GetDiskHealth"			 { Invoke-GetDiskHealth }
						"GetDiskSpace"			 { Invoke-GetDiskSpace $args.path }
						"GetInstalledSoftware"	 { Invoke-GetInstalledSoftware }
						"GetDriverInfo"			 { Invoke-GetDriverInfo }
						"GetStartupItems"		 { Invoke-GetStartupItems }
						"GetMemoryInfo"			 { Invoke-GetMemoryInfo }
						"GetNetworkInfo"		 { Invoke-GetNetworkInfo }
						"GetWindowsUpdateStatus" { Invoke-GetWindowsUpdateStatus }
						"GetSystemUptime"		 { Invoke-GetSystemUptime }
						"RunQuickDiagnostics"	 { Invoke-RunQuickDiagnostics }
						"RunRepairTool"			 { Invoke-RunRepairTool $args.tool }
						"GetServiceStatus"		 { Invoke-GetServiceStatus $args.name }
						"ReadRegistry"			 { Invoke-ReadRegistry $args.path }
						"GetPowerInfo"			 { Invoke-GetPowerInfo }
						default					 { "Unknown tool: $fn" }
					}
					$messages += @{ role = "tool"; tool_call_id = $tc.id; content = ($result | Out-String) }
				}

				if (($stepInterrupt) -or $script:interruptRequested) {
					Reset-InterruptFlag
					break
				}
				continue
			}
			break
		}
	}
}

Start-LocalAgent