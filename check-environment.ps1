#!/usr/bin/env pwsh
[CmdletBinding()]
param()

# Make output stable and emoji-friendly on Windows PowerShell 5.1
try { Set-PSDebug -Off } catch {}
try { if ($IsWindows) { & chcp.com 65001 > $null } } catch {}
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Emoji helpers built from codepoints to keep file ASCII-only
function New-Emoji([int]$CodePoint) {
    if ($CodePoint -le 0xFFFF) { return [string]([char]$CodePoint) }
    $cp = $CodePoint - 0x10000
    $high = 0xD800 + (($cp -shr 10) -band 0x3FF)
    $low  = 0xDC00 + ($cp -band 0x3FF)
    return "{0}{1}" -f ([char]$high), ([char]$low)
}

$E_CHECK     = New-Emoji 0x2705   # ✅
$E_CROSS     = New-Emoji 0x274C   # ❌
$E_WARN      = New-Emoji 0x26A0   # ⚠
$E_ROCKET    = New-Emoji 0x1F680  # 🚀
$E_CLIPBOARD = New-Emoji 0x1F4CB  # 📋
$E_ROBOT     = New-Emoji 0x1F916  # 🤖
$E_BOOKS     = New-Emoji 0x1F4DA  # 📚
$E_TADA      = New-Emoji 0x1F389  # 🎉

$script:ChecksPassed = 0
$script:ChecksFailed = 0

function Write-Status {
    param(
        [Parameter(Mandatory)][bool]$Success,
        [Parameter(Mandatory)][string]$Message
    )

    if ($Success) {
        $script:ChecksPassed++
        Write-Host "$E_CHECK $Message" -ForegroundColor Green
    }
    else {
        $script:ChecksFailed++
        Write-Host "$E_CROSS $Message" -ForegroundColor Red
    }
}

function Get-VersionFromString {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }

    $match = [regex]::Match($Text, '\d+(\.\d+){1,3}')
    if ($match.Success) { return $match.Value }
    return $null
}

function Test-VersionRequirement {
    param(
        [Parameter(Mandatory)][string]$Required,
        [Parameter(Mandatory)][string]$Actual
    )

    try {
        $requiredVersion = [version]$Required
        $actualVersion = [version]$Actual
        return $actualVersion -ge $requiredVersion
    } catch { return $false }
}

function Check-ToolVersion {
    param(
        [Parameter(Mandatory)][string]$Tool,
        [Parameter(Mandatory)][string]$Command,
        [string[]]$Arguments = @(),
        [Parameter(Mandatory)][string]$RequiredVersion,
        [switch]$Optional
    )

    Write-Host -NoNewline "Checking $Tool... "

    $commandInfo = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $commandInfo) {
        if ($Optional) {
            Write-Host "$E_WARN  $Tool not installed (optional for basic training)" -ForegroundColor Yellow
            return
        }
        Write-Status -Success:$false -Message "$Tool is not installed"
        return
    }

    try {
        $rawOutput = & $commandInfo.Path @Arguments 2>&1
        if ($rawOutput -is [System.Array]) { $rawOutput = $rawOutput | Select-Object -First 1 }
        $rawOutput = $rawOutput | Out-String
    } catch { $rawOutput = $null }

    $actualVersion = Get-VersionFromString $rawOutput
    if (-not $actualVersion) {
        Write-Status -Success:$false -Message "$Tool version could not be determined"
        return
    }

    if (Test-VersionRequirement -Required $RequiredVersion -Actual $actualVersion) {
        Write-Status -Success:$true -Message ("{0} {1} (>= {2} required)" -f $Tool, $actualVersion, $RequiredVersion)
    } else {
        Write-Status -Success:$false -Message ("{0} {1} (>= {2} required)" -f $Tool, $actualVersion, $RequiredVersion)
    }
}

Write-Host ("{0} Yapster Training Environment Checker" -f $E_ROCKET) -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host

$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$versionsFile = Join-Path $scriptDir 'required-versions.txt'

if (-not (Test-Path $versionsFile)) {
    Write-Host ("{0} Required versions file not found: {1}" -f $E_CROSS, $versionsFile) -ForegroundColor Red
    exit 1
}

Write-Host "Loading required versions from: $versionsFile" -ForegroundColor Yellow
Write-Host

$requiredVersions = @{}
Get-Content $versionsFile | ForEach-Object {
    $line = $_.Trim()
    if (-not $line -or $line.StartsWith('#')) { return }
    $parts = $line.Split('=', 2)
    if ($parts.Count -ne 2) { return }
    $tool = $parts[0].Trim()
    $version = $parts[1].Trim()
    if ($tool) { $requiredVersions[$tool] = $version }
}

$expectedTools = 'node','npm','python','git','robot','browser'
foreach ($tool in $expectedTools) {
    if (-not $requiredVersions.ContainsKey($tool)) {
        Write-Host ("{0} Required version for {1} not found in {2}" -f $E_CROSS, $tool, $versionsFile) -ForegroundColor Red
        exit 1
    }
}

Write-Host ("{0} Checking Core Tools" -f $E_CLIPBOARD) -ForegroundColor Cyan
Write-Host "===================="

Check-ToolVersion -Tool 'node' -Command 'node' -Arguments @('--version') -RequiredVersion $requiredVersions['node']
Check-ToolVersion -Tool 'npm'  -Command 'npm'  -Arguments @('--version') -RequiredVersion $requiredVersions['npm']

$pythonCommand = if (Get-Command 'python3' -ErrorAction SilentlyContinue) { 'python3' } elseif (Get-Command 'python' -ErrorAction SilentlyContinue) { 'python' } else { $null }
if ($pythonCommand) {
    Check-ToolVersion -Tool $pythonCommand -Command $pythonCommand -Arguments @('--version') -RequiredVersion $requiredVersions['python']
} else {
    Write-Host -NoNewline "Checking python... "
    Write-Status -Success:$false -Message 'python is not installed'
}

Check-ToolVersion -Tool 'git' -Command 'git' -Arguments @('--version') -RequiredVersion $requiredVersions['git']

Write-Host
Write-Host ("{0} Checking Robot Framework Environment" -f $E_ROBOT) -ForegroundColor Cyan
Write-Host "===================================="

$venvPath = Join-Path $scriptDir 'atests/.venv'
if (-not (Test-Path $venvPath)) {
    Write-Host -NoNewline "Checking Robot Framework virtual environment... "
    Write-Status -Success:$false -Message "Virtual environment not found at atests/.venv"
    $venvPython = $null
} else {
    Write-Host -NoNewline "Checking Robot Framework virtual environment... "
    Write-Status -Success:$true -Message "Virtual environment found at atests/.venv"
    $venvPython = Join-Path $venvPath 'bin/python'
    if (-not (Test-Path $venvPython)) { $venvPython = Join-Path $venvPath 'Scripts/python.exe' }
}

if ($venvPython -and (Test-Path $venvPython)) {
    Write-Host -NoNewline "Checking Robot Framework installation... "
    try {
        $rfVersion = & $venvPython -c 'import robot; import sys; print(robot.__version__)' 2>$null
        $rfVersion = ($rfVersion | Select-Object -First 1).Trim()
    } catch { $rfVersion = $null }

    if ($rfVersion) {
        $reqRobot = $requiredVersions['robot']
        if (Test-VersionRequirement -Required $reqRobot -Actual $rfVersion) {
            Write-Status -Success:$true -Message ("Robot Framework {0} (>= {1} required)" -f $rfVersion, $reqRobot)
        } else {
            Write-Status -Success:$false -Message ("Robot Framework {0} (>= {1} required)" -f $rfVersion, $reqRobot)
        }
    } else {
        Write-Status -Success:$false -Message 'Robot Framework version could not be determined'
    }

    Write-Host -NoNewline "Checking Browser library... "
    try {
        $browserVersion = & $venvPython -c 'import Browser; import sys; print(Browser.__version__)' 2>$null
        $browserVersion = ($browserVersion | Select-Object -First 1).Trim()
    } catch { $browserVersion = $null }

    if ($browserVersion) {
        $reqBrowser = $requiredVersions['browser']
        if (Test-VersionRequirement -Required $reqBrowser -Actual $browserVersion) {
            Write-Status -Success:$true -Message ("Browser library {0} (>= {1} required)" -f $browserVersion, $reqBrowser)
        } else {
            Write-Status -Success:$false -Message ("Browser library {0} (>= {1} required)" -f $browserVersion, $reqBrowser)
        }
    } else {
        Write-Status -Success:$false -Message 'Browser library version could not be determined'
    }

    Write-Host -NoNewline "Testing Browser library functionality... "
    $pythonScript = @'
from Browser import Browser
import sys
try:
    browser = Browser()
    print('Browser library test passed')
    sys.exit(0)
except Exception as err:
    print(f'Browser library test failed: {err}')
    sys.exit(1)
'@
    $testResult = & $venvPython -c $pythonScript 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Status -Success:$true -Message 'Browser library functionality test passed'
    } else {
        Write-Status -Success:$false -Message 'Browser library functionality test failed'
        if ($testResult) { Write-Host $testResult.Trim() -ForegroundColor Yellow }
    }
} else {
    Write-Host -NoNewline "Checking Robot Framework installation... "
    Write-Status -Success:$false -Message 'Robot Framework not found in virtual environment'
    Write-Host -NoNewline "Checking Browser library... "
    Write-Status -Success:$false -Message 'Browser library not found'
    Write-Host -NoNewline "Testing Browser library functionality... "
    Write-Status -Success:$false -Message 'Browser library functionality test skipped (missing virtual environment)'
}

Write-Host
Write-Host ("{0} Summary" -f $E_BOOKS) -ForegroundColor Cyan
Write-Host "=========="
Write-Host "Passed: $script:ChecksPassed" -ForegroundColor Green
Write-Host "Failed: $script:ChecksFailed" -ForegroundColor Red
Write-Host

if ($script:ChecksFailed -eq 0) {
    Write-Host ("{0} Environment check completed successfully!" -f $E_TADA) -ForegroundColor Green
    Write-Host 'Your system is ready for Yapster training.' -ForegroundColor Green
    exit 0
} else {
    Write-Host ("{0}  Environment check found issues." -f $E_WARN) -ForegroundColor Red
    Write-Host 'Please fix the failed checks before starting training.' -ForegroundColor Yellow
    Write-Host 'Run the setup script for your platform if needed:' -ForegroundColor Yellow
    Write-Host '  ./setup-linux.sh (macOS/Linux)' -ForegroundColor Yellow
    Write-Host '  ./setup-windows.ps1 (Windows)' -ForegroundColor Yellow
    exit 1
}
