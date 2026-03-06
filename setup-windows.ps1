# PowerShell script to set up Yapster development environment for Windows
# Run this script as Administrator in PowerShell

# Normalize encoding and enable emoji output on Windows PowerShell 5.1
try { Set-PSDebug -Off } catch {}
try { if ($IsWindows) { & chcp.com 65001 > $null } } catch {}
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Build emojis from codepoints to keep this file ASCII-safe
function New-Emoji([int]$CodePoint) {
    if ($CodePoint -le 0xFFFF) { return [string]([char]$CodePoint) }
    $cp = $CodePoint - 0x10000
    $high = 0xD800 + (($cp -shr 10) -band 0x3FF)
    $low  = 0xDC00 + ($cp -band 0x3FF)
    return "{0}{1}" -f ([char]$high), ([char]$low)
}

$E_CHECK   = New-Emoji 0x2705   # âœ…
$E_CROSS   = New-Emoji 0x274C   # âŒ
$E_WARN    = New-Emoji 0x26A0   # âš 
$E_ROCKET  = New-Emoji 0x1F680  # ðŸš€
$E_PKG     = New-Emoji 0x1F4E6  # ðŸ“¦
$E_BOOKS   = New-Emoji 0x1F4DA  # ðŸ“š
$E_CLIP    = New-Emoji 0x1F4CB  # ðŸ“‹
$E_TADA    = New-Emoji 0x1F389  # ðŸŽ‰
$E_ARROW   = New-Emoji 0x27A1   # âž¡

Write-Host ("{0} Setting up Yapster development environment for Windows" -f $E_ROCKET) -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green

# Check if running as Administrator (required for this setup)
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $IsAdmin) {
    Write-Host ("{0} This script must be run as Administrator. Right-click PowerShell and choose 'Run as administrator'." -f $E_CROSS) -ForegroundColor Red
    exit 1
}

# Ensure Windows long paths are enabled
Write-Host ("{0} Checking Windows long path support..." -f $E_CLIP) -ForegroundColor Cyan
$longPathsKey = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
$longPathsValue = "LongPathsEnabled"
try {
    $longPathsEnabled = (Get-ItemProperty -Path $longPathsKey -Name $longPathsValue -ErrorAction Stop).$longPathsValue
} catch {
    $longPathsEnabled = 0
}

if ($longPathsEnabled -ne 1) {
    try {
        Set-ItemProperty -Path $longPathsKey -Name $longPathsValue -Value 1 -Type DWord -ErrorAction Stop
        Write-Host ("{0} Enabled Windows long paths support" -f $E_CHECK) -ForegroundColor Green
    } catch {
        Write-Host ("{0} Failed to enable long paths: {1}" -f $E_CROSS, $_.Exception.Message) -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host ("{0} Windows long paths already enabled" -f $E_CHECK) -ForegroundColor Green
}

# Fix execution policy warning by checking first
Write-Host ("{0} Setting PowerShell execution policy..." -f $E_CLIP) -ForegroundColor Cyan
$currentPolicy = Get-ExecutionPolicy
if ($currentPolicy -eq 'Restricted') {
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Write-Host ("{0} Execution policy updated to RemoteSigned" -f $E_CHECK) -ForegroundColor Green
} else {
    Write-Host ("{0} Execution policy already set to {1}" -f $E_CHECK, $currentPolicy) -ForegroundColor Green
}

# Define RefreshEnv function if not already defined
if (-not (Get-Command RefreshEnv -ErrorAction SilentlyContinue)) {
    function global:RefreshEnv {
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Write-Host ("{0} Environment variables refreshed" -f $E_CHECK) -ForegroundColor Green
    }
}

# Install Chocolatey (Windows package manager)
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    if ($IsAdmin) {
        Write-Host ("{0} Installing Chocolatey package manager..." -f $E_PKG) -ForegroundColor Cyan
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        RefreshEnv
        Write-Host ("{0} Chocolatey installed successfully" -f $E_CHECK) -ForegroundColor Green
    } else {
        Write-Host ("{0} Chocolatey not found and cannot install without Administrator. Skipping Chocolatey-related installs." -f $E_WARN) -ForegroundColor Yellow
    }
} else {
    Write-Host ("{0} Chocolatey already installed: {1}" -f $E_CHECK, (choco --version)) -ForegroundColor Green
}

function Get-PwshVersion {
    $pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if (-not $pwshCmd) { return $null }
    try {
        $versionText = & $pwshCmd.Source -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>$null
        if (-not $versionText) { return $null }
        return [version]$versionText.Trim()
    } catch {
        return $null
    }
}

# Ensure PowerShell 6+ is available
Write-Host ("{0} Checking for PowerShell 6/7 (pwsh)..." -f $E_CLIP) -ForegroundColor Cyan
$pwshVersion = Get-PwshVersion
if ($pwshVersion -and $pwshVersion.Major -ge 6) {
    Write-Host ("{0} PowerShell Core found: {1}" -f $E_CHECK, $pwshVersion) -ForegroundColor Green
} else {
    if ($IsAdmin -and (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host ("{0} Installing PowerShell 7 (Chocolatey package: powershell-core)..." -f $E_PKG) -ForegroundColor Cyan
        try {
            choco install powershell-core -y
            RefreshEnv
            $pwshVersion = Get-PwshVersion
            if ($pwshVersion -and $pwshVersion.Major -ge 6) {
                Write-Host ("{0} PowerShell Core installed: {1}" -f $E_CHECK, $pwshVersion) -ForegroundColor Green
            } else {
                Write-Host ("{0} PowerShell install finished but pwsh is not yet available in this session." -f $E_WARN) -ForegroundColor Yellow
            }
        } catch {
            Write-Host ("{0} Failed to install PowerShell Core: {1}" -f $E_WARN, $_.Exception.Message) -ForegroundColor Yellow
        }
    } else {
        Write-Host ("{0} PowerShell 6/7 not found and cannot auto-install without Administrator + Chocolatey." -f $E_WARN) -ForegroundColor Yellow
    }
}

# Install Node.js v22.20.0 specifically
Write-Host ("{0} Installing Node.js v22.20.0..." -f $E_PKG) -ForegroundColor Cyan
$nodeInstalled = $false
if (Get-Command node -ErrorAction SilentlyContinue) {
    $nodeVersion = (node --version).Trim()
    if ($nodeVersion -eq "v22.20.0") {
        Write-Host ("{0} Node.js v22.20.0 already installed" -f $E_CHECK) -ForegroundColor Green
        $nodeInstalled = $true
    } else {
        Write-Host ("{0} Node.js {1} installed, but v22.20.0 required. Installing..." -f $E_WARN, $nodeVersion) -ForegroundColor Yellow
    }
}

if (-not $nodeInstalled) {
    if ($IsAdmin -and (Get-Command choco -ErrorAction SilentlyContinue)) {
        choco install nodejs --version=22.20.0 -y
        RefreshEnv
    } else {
        Write-Host ("{0} Skipping Node.js installation (requires Administrator and Chocolatey)." -f $E_WARN) -ForegroundColor Yellow
    }
}

Write-Host ("{0} Node.js: {1}" -f $E_CHECK, (node --version)) -ForegroundColor Green
Write-Host ("{0} npm: {1}" -f $E_CHECK, (npm --version)) -ForegroundColor Green

# Install Python 3
Write-Host ("{0} Installing Python 3..." -f $E_PKG) -ForegroundColor Cyan
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    if ($IsAdmin -and (Get-Command choco -ErrorAction SilentlyContinue)) {
        choco install python -y
        RefreshEnv
    } else {
        Write-Host ("{0} Python not found and cannot install without Administrator. Skipping." -f $E_WARN) -ForegroundColor Yellow
    }
} else {
    Write-Host ("{0} Python already installed: {1}" -f $E_CHECK, (python --version)) -ForegroundColor Green
}

Write-Host ("{0} Python: {1}" -f $E_CHECK, (python --version)) -ForegroundColor Green
$pipVersion = (python -m pip --version | Select-Object -First 1).ToString().Trim()
Write-Host ("{0} pip: {1}" -f $E_CHECK, $pipVersion) -ForegroundColor Green

# Install Robot Framework in project virtual environment
Write-Host ("{0} Setting up Robot Framework in project virtual environment..." -f $E_CLIP) -ForegroundColor Cyan
if (-not (Test-Path "atests")) {
    New-Item -ItemType Directory -Path "atests" | Out-Null
}

Set-Location "atests"
Write-Host ("{0} Creating clean Python venv at atests/.venv" -f $E_CLIP) -ForegroundColor Cyan
# Remove any existing broken venv
Remove-Item -Recurse -Force .venv -ErrorAction SilentlyContinue

# Create venv without pip (to avoid copying broken system pip)
python -m venv .venv --without-pip
.\.venv\Scripts\Activate.ps1

Write-Host ("{0} Installing fresh pip with get-pip.py" -f $E_PKG) -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile "get-pip.py" -ErrorAction Stop
    python get-pip.py
    Remove-Item "get-pip.py"
    $pipVersionAfter = (python -m pip --version | Select-Object -First 1).ToString().Trim()
    Write-Host ("{0} Fresh pip installed: {1}" -f $E_CHECK, $pipVersionAfter) -ForegroundColor Green
} catch {
    Write-Host ("{0} Failed to install pip. Check your internet connection or permissions." -f $E_CROSS) -ForegroundColor Red
    exit 1
}

# Install Robot Framework Browser batteries package when available
Write-Host ("{0} Installing Robot Framework Browser batteries..." -f $E_PKG) -ForegroundColor Cyan
$batteriesInstalled = $false
try {
    pip install --quiet --upgrade robotframework-browser-batteries
    Write-Host ("{0} Robot Framework Browser batteries package installed" -f $E_CHECK) -ForegroundColor Green
    $batteriesInstalled = $true
} catch {
    Write-Host ("{0} Browser batteries install failed; falling back to requirements.txt" -f $E_WARN) -ForegroundColor Yellow
}

# Fix the requirements.txt location issue
Write-Host ("{0} Installing Robot Framework libraries in venv" -f $E_PKG) -ForegroundColor Cyan
# We're already in the atests directory at this point
if (-not (Test-Path "requirements.txt")) {
    Write-Host ("{0} requirements.txt not found in atests directory, creating basic file" -f $E_WARN) -ForegroundColor Yellow
    @"
robotframework-browser-batteries>=19.9.0
robotframework-requests>=0.9.0
"@ | Out-File -FilePath "requirements.txt" -Encoding UTF8
    Write-Host ("{0} Created requirements.txt in atests directory" -f $E_CHECK) -ForegroundColor Green
}
pip install --quiet -r requirements.txt

Write-Host ("{0} Initializing BrowserLibrary (downloads Playwright browsers)" -f $E_CLIP) -ForegroundColor Cyan
try {
    rfbrowser init
    Write-Host ("{0} BrowserLibrary initialized successfully" -f $E_CHECK) -ForegroundColor Green
} catch {
    Write-Host ("{0} Failed to initialize BrowserLibrary. You may need to run 'rfbrowser init' manually." -f $E_WARN) -ForegroundColor Yellow
}

# Ensure Playwright's Windows dependency tool (winldd) is installed
try {
    $wrapperPath = & atests\.venv\Scripts\python -c "import Browser, os, sys; sys.stdout.write(os.path.join(os.path.dirname(Browser.__file__), 'wrapper'))"
    $pwCoreLocal = Join-Path $wrapperPath 'node_modules\playwright-core\.local-browsers'
    $winlddExe = Get-ChildItem -Path $pwCoreLocal -Recurse -Filter 'PrintDeps.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($winlddExe) {
        Write-Host ("{0} Playwright winldd already present: {1}" -f $E_CHECK, $winlddExe.FullName) -ForegroundColor Green
    } else {
        Write-Host ("{0} Installing Playwright winldd tool..." -f $E_PKG) -ForegroundColor Cyan
        Push-Location $wrapperPath
        try {
            npx --yes --quiet playwright install winldd
            Write-Host ("{0} Playwright winldd installed" -f $E_CHECK) -ForegroundColor Green
        } catch {
            Write-Host ("{0} Failed to install Playwright winldd. Try 'npx playwright install winldd' manually." -f $E_WARN) -ForegroundColor Yellow
        } finally {
            Pop-Location
        }
    }
} catch {
    Write-Host ("{0} Could not verify/install winldd: {1}" -f $E_WARN, $_.Exception.Message) -ForegroundColor Yellow
}

Set-Location ".."
Write-Host ("{0} Robot Framework: {1}" -f $E_CHECK, (atests\.venv\Scripts\python -m robot --version 2>$null)) -ForegroundColor Green

# Install Node.js dependencies
Write-Host ("{0} Installing Node.js dependencies..." -f $E_PKG) -ForegroundColor Cyan
if (Test-Path "package.json") {
    Write-Host ("{0} Installing root dependencies..." -f $E_PKG) -ForegroundColor Cyan
    npm install --silent
    
    if ((Test-Path "frontend") -and (Test-Path "frontend\package.json")) {
        Write-Host ("{0} Installing frontend dependencies..." -f $E_PKG) -ForegroundColor Cyan
        Set-Location "frontend"
        npm install --silent
        Set-Location ".."
    }
    
    if ((Test-Path "backend") -and (Test-Path "backend\package.json")) {
        Write-Host ("{0} Installing backend dependencies..." -f $E_PKG) -ForegroundColor Cyan
        Set-Location "backend"
        npm install --silent
        Set-Location ".."
    }
    
    Write-Host ("{0} Node.js dependencies installed" -f $E_CHECK) -ForegroundColor Green
} else {
    Write-Host ("{0} No package.json found, skipping npm install" -f $E_WARN) -ForegroundColor Yellow
}

# Install Git
Write-Host ("{0} Installing Git..." -f $E_PKG) -ForegroundColor Cyan
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    if ($IsAdmin -and (Get-Command choco -ErrorAction SilentlyContinue)) {
        choco install git -y
        RefreshEnv
    } else {
        Write-Host ("{0} Git not found and cannot install without Administrator. Skipping." -f $E_WARN) -ForegroundColor Yellow
    }
} else {
    Write-Host ("{0} Git already installed: {1}" -f $E_CHECK, (git --version)) -ForegroundColor Green
}

# Enhanced GitHub CLI installation with path verification
Write-Host ("{0} Installing GitHub CLI..." -f $E_PKG) -ForegroundColor Cyan
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    if ($IsAdmin -and (Get-Command choco -ErrorAction SilentlyContinue)) {
        choco install gh -y
    } else {
        Write-Host ("{0} GitHub CLI not found and cannot install without Administrator. Skipping." -f $E_WARN) -ForegroundColor Yellow
    }
    # Force refresh path to ensure gh is available
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Host ("{0} GitHub CLI installed but not found in PATH. You may need to restart PowerShell." -f $E_WARN) -ForegroundColor Yellow
        # Try to locate the gh.exe and add to temporary path
        $possibleGhPaths = @(
            "C:\Program Files\GitHub CLI\",
            "C:\Program Files (x86)\GitHub CLI\"
        )
        foreach ($path in $possibleGhPaths) {
            if (Test-Path "$path\bin\gh.exe") {
                $env:Path += ";$path\bin"
                Write-Host ("{0} Added GitHub CLI to PATH for this session" -f $E_CHECK) -ForegroundColor Green
                break
            }
        }
    } else {
        $ghVersionOnce = (gh --version | Select-Object -First 1).ToString().Trim()
        Write-Host ("{0} GitHub CLI installed successfully: {1}" -f $E_CHECK, $ghVersionOnce) -ForegroundColor Green
    }
} else {
    $ghVersionOnce2 = (gh --version | Select-Object -First 1).ToString().Trim()
    Write-Host ("{0} GitHub CLI already installed: {1}" -f $E_CHECK, $ghVersionOnce2) -ForegroundColor Green
}

# Enhanced Azure CLI installation with path verification
Write-Host ("{0} Installing Azure CLI..." -f $E_PKG) -ForegroundColor Cyan
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    if ($IsAdmin -and (Get-Command choco -ErrorAction SilentlyContinue)) {
        choco install azure-cli -y
    } else {
        Write-Host ("{0} Azure CLI not found and cannot install without Administrator. Skipping." -f $E_WARN) -ForegroundColor Yellow
    }
    # Force refresh path to ensure az is available
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        Write-Host ("{0} Azure CLI installed but not found in PATH. You may need to restart PowerShell." -f $E_WARN) -ForegroundColor Yellow
        # Try to locate the az.cmd and add to temporary path
        $possibleAzPaths = @(
            "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\CLI2\wbin",
            "$env:ProgramFiles\Microsoft SDKs\Azure\CLI2\wbin"
        )
        foreach ($path in $possibleAzPaths) {
            if (Test-Path "$path\az.cmd") {
                $env:Path += ";$path"
                Write-Host ("{0} Added Azure CLI to PATH for this session" -f $E_CHECK) -ForegroundColor Green
                break
            }
        }
    } else {
        Write-Host ("{0} Azure CLI installed successfully: {1}" -f $E_CHECK, (az --version | Select-String 'azure-cli')) -ForegroundColor Green
    }
} else {
    Write-Host ("{0} Azure CLI already installed: {1}" -f $E_CHECK, (az --version | Select-String 'azure-cli')) -ForegroundColor Green
}

# Docker not needed for local development (using npm run dev)

# Install development utilities
if ($IsAdmin -and (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host ("{0} Installing development utilities..." -f $E_PKG) -ForegroundColor Cyan
    choco install curl wget -y
} else {
    Write-Host ("{0} Skipping dev utilities install (requires Administrator and Chocolatey)." -f $E_WARN) -ForegroundColor Yellow
}

# Refresh environment variables
RefreshEnv

Write-Host ""
Write-Host ("{0} Installation completed successfully!" -f $E_TADA) -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green
Write-Host ""
Write-Host ("{0} Installed tools:" -f $E_BOOKS) -ForegroundColor Yellow
Write-Host ("  Node.js: {0}" -f (node --version)) -ForegroundColor Green
Write-Host ("  npm: {0}" -f (npm --version)) -ForegroundColor Green
Write-Host ("  Python: {0}" -f (python --version)) -ForegroundColor Green
$rfVersionText = $(try { atests\.venv\Scripts\python -m robot --version 2>$null } catch { 'Installed in venv' })
Write-Host ("  Robot Framework: {0}" -f $rfVersionText) -ForegroundColor Green
Write-Host ("  Git: {0}" -f (git --version)) -ForegroundColor Green
$ghText = if (Get-Command gh -ErrorAction SilentlyContinue) { gh --version } else { 'Not installed yet' }
Write-Host ("  GitHub CLI: {0}" -f $ghText) -ForegroundColor Green
$azText = if (Get-Command az -ErrorAction SilentlyContinue) { az --version | Select-String 'azure-cli' } else { 'Not installed yet' }
Write-Host ("  Azure CLI: {0}" -f $azText) -ForegroundColor Green
Write-Host ("  Chocolatey: {0}" -f (choco --version)) -ForegroundColor Green
Write-Host ""
Write-Host ("{0} Next steps:" -f $E_CLIP) -ForegroundColor Yellow
Write-Host "  1. Close and reopen PowerShell to refresh environment"
Write-Host "  2. Clone the repository: git clone <your-repo-url>"
Write-Host "  3. Navigate to project: cd training-ai-aided-sw-development"
Write-Host "  4. Install dependencies: npm install"
Write-Host "  5. Run tests: .\run-tests.ps1"
Write-Host ""
Write-Host "Development workflow:" -ForegroundColor Cyan
Write-Host "  - Start backend: cd backend" -ForegroundColor White
Write-Host "  - Then run: npm run dev" -ForegroundColor White
Write-Host "  - Start frontend: cd frontend" -ForegroundColor White
Write-Host "  - Then run: npm run dev" -ForegroundColor White
Write-Host ""
Write-Host ("{0} For the best experience on Windows:" -f $E_CLIP) -ForegroundColor Cyan
Write-Host "  - Consider installing Windows Terminal for a better command-line experience"

Write-Host ""
# Only prompt when running interactively
if ($Host.UI.RawUI -and -not $env:CI -and -not $env:NONINTERACTIVE) {
    Write-Host ("{0} Press any key to exit..." -f $E_ARROW) -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
