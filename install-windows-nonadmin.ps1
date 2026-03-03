# PowerShell script to set up Yapster development environment for Windows (non-admin)
# Intended to run under a standard user account without elevation

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

$E_CHECK   = New-Emoji 0x2705
$E_CROSS   = New-Emoji 0x274C
$E_WARN    = New-Emoji 0x26A0
$E_ROCKET  = New-Emoji 0x1F680
$E_PKG     = New-Emoji 0x1F4E6
$E_BOOKS   = New-Emoji 0x1F4DA
$E_CLIP    = New-Emoji 0x1F4CB
$E_TADA    = New-Emoji 0x1F389
$E_ARROW   = New-Emoji 0x27A1

Write-Host ("{0} Setting up Yapster development environment for Windows (non-admin)" -f $E_ROCKET) -ForegroundColor Green
Write-Host "=======================================================================" -ForegroundColor Green

# Ensure TLS 1.2 for older PowerShell
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {
}

# Ensure we are NOT elevated
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if ($IsAdmin) {
    Write-Host ("{0} This script is for non-admin installs. Please run as a standard user." -f $E_WARN) -ForegroundColor Yellow
}

# Proxy support (environment variables are honored by tools)
$ProxyHttp = $env:HTTP_PROXY
$ProxyHttps = $env:HTTPS_PROXY
if ($ProxyHttp -or $ProxyHttps) {
    Write-Host ("{0} Proxy environment detected (HTTP_PROXY/HTTPS_PROXY)." -f $E_CHECK) -ForegroundColor Green
}

# Helpers
function Ensure-Dir([string]$Path) {
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop | Out-Null
    }
}

function Add-ToUserPath([string]$NewPath) {
    $current = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if ($current -notlike "*$NewPath*") {
        $updated = if ($current) { "$current;$NewPath" } else { $NewPath }
        [System.Environment]::SetEnvironmentVariable("Path", $updated, "User")
        $env:Path = "$updated;" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        Write-Host ("{0} Added to user PATH: {1}" -f $E_CHECK, $NewPath) -ForegroundColor Green
    }
}

function Disable-StorePythonAlias {
    $windowsApps = Join-Path $env:LOCALAPPDATA "Microsoft\\WindowsApps"
    if (-not (Test-Path $windowsApps)) { return }
    $aliases = @("python.exe", "python3.exe")
    foreach ($alias in $aliases) {
        $aliasPath = Join-Path $windowsApps $alias
        if (Test-Path $aliasPath) {
            try {
                Remove-Item -Path $aliasPath -Force -ErrorAction Stop
                Write-Host ("{0} Removed Windows Store alias: {1}" -f $E_CHECK, $aliasPath) -ForegroundColor Green
            } catch {
                Write-Host ("{0} Could not remove Windows Store alias: {1}" -f $E_WARN, $aliasPath) -ForegroundColor Yellow
            }
        }
    }
}

function Set-VSCodeGitPath([string]$GitExePath) {
    $settingsPath = Join-Path $env:APPDATA "Code\\User\\settings.json"
    $settingsDir = Split-Path $settingsPath -Parent
    Ensure-Dir $settingsDir

    $settingsObj = $null
    if (Test-Path $settingsPath) {
        try {
            $raw = Get-Content -Path $settingsPath -Raw
            if ($raw.Trim().Length -gt 0) {
                $settingsObj = $raw | ConvertFrom-Json -ErrorAction Stop
            }
        } catch {
            $backupPath = $settingsPath + ".bak"
            Copy-Item -Path $settingsPath -Destination $backupPath -Force
            Write-Host ("{0} VS Code settings invalid JSON; backed up to {1}" -f $E_WARN, $backupPath) -ForegroundColor Yellow
        }
    }

    if (-not $settingsObj) {
        $settingsObj = [ordered]@{}
    }
    $settingsObj."git.path" = $GitExePath
    $settingsJson = $settingsObj | ConvertTo-Json -Depth 20
    $settingsJson | Set-Content -Path $settingsPath -Encoding UTF8
    Write-Host ("{0} VS Code git.path set to {1}" -f $E_CHECK, $GitExePath) -ForegroundColor Green
}

function Invoke-WebRequestWithProxy {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$OutFile
    )
    $params = @{ Uri = $Uri; OutFile = $OutFile; UseBasicParsing = $true }
    if ($env:HTTPS_PROXY) { $params['Proxy'] = $env:HTTPS_PROXY }
    $maxAttempts = 3
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        try {
            $params['Headers'] = @{ 'User-Agent' = 'Mozilla/5.0' }
            Invoke-WebRequest @params
            return
        } catch {
            if ($attempt -ge $maxAttempts) { throw }
            Start-Sleep -Seconds 5
        }
    }
}

function Get-LatestPortableGitUrl {
    $apiUrl = "https://api.github.com/repos/git-for-windows/git/releases/latest"
    $headers = @{ 'User-Agent' = 'Mozilla/5.0' }
    $params = @{ Uri = $apiUrl; Headers = $headers; UseBasicParsing = $true }
    if ($env:HTTPS_PROXY) { $params['Proxy'] = $env:HTTPS_PROXY }
    try {
        $release = Invoke-RestMethod @params
        $asset = $release.assets | Where-Object { $_.name -match '^PortableGit-.*-64-bit\\.7z\\.exe$' } | Select-Object -First 1
        if ($asset) { return $asset.browser_download_url }
    } catch {
        return $null
    }
    return $null
}

# Base directories (resolve from user profile, not inherited env)
$LocalAppData = [System.Environment]::GetFolderPath("LocalApplicationData")
if (-not $LocalAppData) {
    $LocalAppData = Join-Path $env:USERPROFILE "AppData\\Local"
}
$BaseDir = Join-Path $LocalAppData "YapsterTools"
try {
    Ensure-Dir $BaseDir
} catch {
    $BaseDir = Join-Path $env:TEMP "YapsterTools"
    Ensure-Dir $BaseDir
}
$BinDir = Join-Path $BaseDir "bin"
Ensure-Dir $BinDir

$OfflineRoot = $null
$OfflinePackagePath = $env:YAPSTER_OFFLINE_PACKAGE_PATH
$OfflinePackageDir = $env:YAPSTER_OFFLINE_PACKAGE_DIR
if (-not $OfflineRoot) {
    $cwdChecksums = Join-Path (Get-Location) "checksums.txt"
    if (Test-Path $cwdChecksums) {
        $OfflineRoot = (Get-Location).Path
    }
}
if (-not $OfflinePackagePath -and -not $OfflinePackageDir) {
    $localZips = Get-ChildItem -Path $PSScriptRoot -Filter "yapster-windows-nonadmin-offline-*.zip" -ErrorAction SilentlyContinue |
        Sort-Object -Property LastWriteTime -Descending
    if ($localZips -and $localZips.Count -gt 0) {
        $OfflinePackagePath = $localZips[0].FullName
    }
}
if ($OfflinePackagePath -and (Test-Path $OfflinePackagePath)) {
    $offlineExtract = Join-Path $BaseDir "offline-package"
    if (Test-Path $offlineExtract) { Remove-Item $offlineExtract -Recurse -Force }
    Expand-Archive -Path $OfflinePackagePath -DestinationPath $offlineExtract -Force
    $OfflineRoot = $offlineExtract
}
if (-not $OfflineRoot -and $OfflinePackageDir -and (Test-Path $OfflinePackageDir)) {
    $OfflineRoot = $OfflinePackageDir
}
if ($OfflineRoot) {
    Write-Host ("{0} Using offline package at {1}" -f $E_CHECK, $OfflineRoot) -ForegroundColor Green
}

function Get-OfflineFile([string]$RelativePath) {
    if (-not $OfflineRoot) { return $null }
    $candidate = Join-Path $OfflineRoot $RelativePath
    if (-not (Test-Path $candidate)) {
        throw "Offline package missing: $RelativePath"
    }
    return $candidate
}

function Get-Asset {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$OutFile,
        [Parameter(Mandatory = $true)][string]$OfflineRelativePath
    )
    $offlineFile = Get-OfflineFile $OfflineRelativePath
    if ($offlineFile) {
        Copy-Item -Path $offlineFile -Destination $OutFile -Force
        return
    }
    Invoke-WebRequestWithProxy -Uri $Uri -OutFile $OutFile
}

$wheelhouse = $null
if ($OfflineRoot) {
    $wheelhouse = Join-Path $OfflineRoot "wheelhouse"
    if (-not (Test-Path $wheelhouse)) {
        throw "Offline package missing wheelhouse."
    }
}

# Install Node.js (portable ZIP)
Write-Host ("{0} Installing Node.js (portable)..." -f $E_PKG) -ForegroundColor Cyan
$nodeVersion = "v22.20.0"
$nodeFolder = Join-Path $BaseDir "node-$nodeVersion"
if (-not (Test-Path $nodeFolder)) {
    $nodeZip = Join-Path $BaseDir "node-$nodeVersion-win-x64.zip"
    $nodeUrl = "https://nodejs.org/dist/$nodeVersion/node-$nodeVersion-win-x64.zip"
    Get-Asset -Uri $nodeUrl -OutFile $nodeZip -OfflineRelativePath ("downloads/node-$nodeVersion-win-x64.zip")
    Expand-Archive -Path $nodeZip -DestinationPath $BaseDir -Force
    Remove-Item $nodeZip -Force
    Rename-Item -Path (Join-Path $BaseDir "node-$nodeVersion-win-x64") -NewName ("node-$nodeVersion")
}
Add-ToUserPath $nodeFolder
Write-Host ("{0} Node.js: {1}" -f $E_CHECK, (node --version)) -ForegroundColor Green
Write-Host ("{0} npm: {1}" -f $E_CHECK, (npm --version)) -ForegroundColor Green
if ($ProxyHttp) { npm config set proxy $ProxyHttp | Out-Null }
if ($ProxyHttps) { npm config set https-proxy $ProxyHttps | Out-Null }

# Install Git (PortableGit)
Write-Host ("{0} Installing Git (PortableGit)..." -f $E_PKG) -ForegroundColor Cyan
$gitFolder = Join-Path $BaseDir "PortableGit"
if (-not (Test-Path $gitFolder)) {
    $gitArchive = Join-Path $BaseDir "PortableGit.7z.exe"
    $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.52.0.windows.1/PortableGit-2.52.0-64-bit.7z.exe"
    if (-not $OfflineRoot) {
        $gitUrl = Get-LatestPortableGitUrl
        if (-not $gitUrl) {
            $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.52.0.windows.1/PortableGit-2.52.0-64-bit.7z.exe"
        }
        Write-Host ("{0} PortableGit source: {1}" -f $E_BOOKS, $gitUrl) -ForegroundColor Yellow
    }
    Get-Asset -Uri $gitUrl -OutFile $gitArchive -OfflineRelativePath "downloads/PortableGit-2.52.0-64-bit.7z.exe"
    & $gitArchive -o"$gitFolder" -y | Out-Null
    Remove-Item $gitArchive -Force
}
Add-ToUserPath (Join-Path $gitFolder "cmd")
Write-Host ("{0} Git: {1}" -f $E_CHECK, (git --version)) -ForegroundColor Green
if ($ProxyHttp) { git config --global http.proxy $ProxyHttp }
if ($ProxyHttps) { git config --global https.proxy $ProxyHttps }
Set-VSCodeGitPath (Join-Path $gitFolder "cmd\\git.exe")

# Install Python (NuGet package) + pip
Write-Host ("{0} Installing Python (NuGet package)..." -f $E_PKG) -ForegroundColor Cyan
$pyVersion = "3.12.9"
$pyFolder = Join-Path $BaseDir "python-$pyVersion"

function Install-PythonNuGet {
    if (Test-Path $pyFolder) {
        Remove-Item $pyFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
    $pyPackage = Join-Path $BaseDir "python-$pyVersion.nupkg"
    $pyUrl = "https://www.nuget.org/api/v2/package/python/$pyVersion"
    Get-Asset -Uri $pyUrl -OutFile $pyPackage -OfflineRelativePath ("downloads/python-$pyVersion.nupkg")
    Ensure-Dir $pyFolder
    $pyZip = Join-Path $BaseDir "python-$pyVersion.zip"
    Copy-Item -Path $pyPackage -Destination $pyZip -Force
    Expand-Archive -Path $pyZip -DestinationPath $pyFolder -Force
    Remove-Item $pyZip -Force -ErrorAction SilentlyContinue
    Remove-Item $pyPackage -Force -ErrorAction SilentlyContinue
}

if (-not (Test-Path $pyFolder)) {
    Install-PythonNuGet
}

# NuGet layout can vary; locate tools\python.exe even if it's nested.
$pyTools = Join-Path $pyFolder "tools"
$pyExe = Join-Path $pyTools "python.exe"
if (-not (Test-Path $pyExe)) {
    $foundPython = Get-ChildItem -Path $pyFolder -Recurse -Filter "python.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($foundPython) {
        $pyExe = $foundPython.FullName
        $pyTools = Split-Path $pyExe -Parent
    } else {
        Install-PythonNuGet
        $foundPython = Get-ChildItem -Path $pyFolder -Recurse -Filter "python.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($foundPython) {
            $pyExe = $foundPython.FullName
            $pyTools = Split-Path $pyExe -Parent
        }
    }
}
if (-not (Test-Path $pyExe)) {
    Write-Host ("{0} Python install failed; python.exe not found under {1}" -f $E_CROSS, $pyFolder) -ForegroundColor Red
    Get-ChildItem -Path $pyFolder -Recurse -ErrorAction SilentlyContinue | Select-Object -First 25 | Format-Table -AutoSize | Out-String | Write-Host
    exit 1
}
Add-ToUserPath $pyTools
Add-ToUserPath (Join-Path $pyTools "Scripts")
Write-Host ("{0} Python: {1}" -f $E_CHECK, (& $pyExe --version)) -ForegroundColor Green
$pipVersion = & $pyExe -m pip --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host ("{0} pip not available after install." -f $E_CROSS) -ForegroundColor Red
    exit 1
}
Write-Host ("{0} pip: {1}" -f $E_CHECK, $pipVersion) -ForegroundColor Green
Disable-StorePythonAlias

# Configure pip index for private Artifactory if provided
if ($env:PIP_INDEX_URL -or $env:PIP_EXTRA_INDEX_URL) {
    Write-Host ("{0} Using custom pip index (PIP_INDEX_URL/PIP_EXTRA_INDEX_URL)." -f $E_CHECK) -ForegroundColor Green
}
if ($wheelhouse) {
    $env:PIP_NO_INDEX = "1"
    $env:PIP_FIND_LINKS = $wheelhouse
    Write-Host ("{0} Using offline wheelhouse for pip installs." -f $E_CHECK) -ForegroundColor Green
}

# Install Robot Framework in project virtual environment
Write-Host ("{0} Setting up Robot Framework in project virtual environment..." -f $E_CLIP) -ForegroundColor Cyan
if (-not (Test-Path "atests")) {
    New-Item -ItemType Directory -Path "atests" | Out-Null
}

Set-Location "atests"
Write-Host ("{0} Creating clean Python venv at atests/.venv" -f $E_CLIP) -ForegroundColor Cyan
Remove-Item -Recurse -Force .venv -ErrorAction SilentlyContinue

# Create venv using virtualenv (embeddable Python lacks venv)
Write-Host ("{0} Installing virtualenv..." -f $E_PKG) -ForegroundColor Cyan
& $pyExe -m pip --version 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host ("{0} pip not available after Python install." -f $E_CROSS) -ForegroundColor Red
    exit 1
}
if ($wheelhouse) {
    & $pyExe -m pip install --upgrade pip virtualenv --no-index --find-links $wheelhouse | Out-Null
} else {
    & $pyExe -m pip install --upgrade pip virtualenv | Out-Null
}
try {
    & $pyExe -c "import virtualenv" | Out-Null
} catch {
    Write-Host ("{0} Failed to install virtualenv." -f $E_CROSS) -ForegroundColor Red
    exit 1
}
& $pyExe -m virtualenv .venv | Out-Null

$venvPython = Join-Path (Get-Location) ".venv\\Scripts\\python.exe"
if (-not (Test-Path $venvPython)) {
    Write-Host ("{0} Failed to create virtual environment." -f $E_CROSS) -ForegroundColor Red
    exit 1
}

Write-Host ("{0} Installing Robot Framework libraries in venv" -f $E_PKG) -ForegroundColor Cyan
if (-not (Test-Path "requirements.txt")) {
    @"
robotframework-browser-batteries==19.9.0
robotframework-requests>=0.9.0
"@ | Out-File -FilePath "requirements.txt" -Encoding UTF8
}
if ($wheelhouse) {
    & $venvPython -m pip install --quiet --no-index --find-links $wheelhouse -r requirements.txt
} else {
    & $venvPython -m pip install --quiet -r requirements.txt
}

Write-Host ("{0} Initializing BrowserLibrary (downloads Playwright browsers)" -f $E_CLIP) -ForegroundColor Cyan
$rfbrowserWrapperSource = if ($OfflineRoot) { Join-Path $OfflineRoot "rfbrowser\\wrapper" } else { $null }
$rfbrowserBrowsersSource = if ($OfflineRoot) { Join-Path $OfflineRoot "rfbrowser\\ms-playwright" } else { $null }
$rfbrowserWrapperTarget = Join-Path (Get-Location) ".venv\\Lib\\site-packages\\Browser\\wrapper"
$rfbrowserBrowsersTarget = Join-Path $env:LOCALAPPDATA "ms-playwright"
$rfbrowserLocalBrowsers = Join-Path $rfbrowserWrapperTarget "node_modules\\playwright-core\\.local-browsers"

if ($OfflineRoot -and (Test-Path $rfbrowserWrapperSource) -and (Test-Path $rfbrowserBrowsersSource)) {
    Ensure-Dir $rfbrowserWrapperTarget
    Ensure-Dir $rfbrowserBrowsersTarget
    Ensure-Dir $rfbrowserLocalBrowsers
    Copy-Item -Path $rfbrowserWrapperSource\* -Destination $rfbrowserWrapperTarget -Recurse -Force
    Copy-Item -Path $rfbrowserBrowsersSource\* -Destination $rfbrowserBrowsersTarget -Recurse -Force
    Copy-Item -Path $rfbrowserBrowsersSource\* -Destination $rfbrowserLocalBrowsers -Recurse -Force
    Write-Host ("{0} BrowserLibrary assets restored from offline package." -f $E_CHECK) -ForegroundColor Green
} else {
    try {
        & (Join-Path (Get-Location) ".venv\\Scripts\\rfbrowser.exe") init
        Write-Host ("{0} BrowserLibrary initialized successfully" -f $E_CHECK) -ForegroundColor Green
    } catch {
        Write-Host ("{0} Failed to initialize BrowserLibrary. You may need to run 'rfbrowser init' manually." -f $E_WARN) -ForegroundColor Yellow
    }
}

$venvCache = Join-Path $BaseDir "rf-venv"
if (Test-Path $venvCache) {
    Remove-Item $venvCache -Recurse -Force -ErrorAction SilentlyContinue
}
Copy-Item -Path (Join-Path (Get-Location) ".venv") -Destination $venvCache -Recurse -Force

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

Write-Host ""
Write-Host ("{0} Installation completed successfully!" -f $E_TADA) -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green
Write-Host ""
Write-Host ("{0} Installed tools:" -f $E_BOOKS) -ForegroundColor Yellow
Write-Host ("  Node.js: {0}" -f (node --version)) -ForegroundColor Green
Write-Host ("  npm: {0}" -f (npm --version)) -ForegroundColor Green
Write-Host ("  Python: {0}" -f (& $pyExe --version)) -ForegroundColor Green
$rfVersionText = $(try { atests\.venv\Scripts\python -m robot --version 2>$null } catch { 'Installed in venv' })
Write-Host ("  Robot Framework: {0}" -f $rfVersionText) -ForegroundColor Green
Write-Host ("  Git: {0}" -f (git --version)) -ForegroundColor Green
Write-Host ""
Write-Host ("{0} Next steps:" -f $E_CLIP) -ForegroundColor Yellow
Write-Host "  1. Close and reopen your terminal to refresh environment"
Write-Host "  2. Run tests: .\\run-tests.ps1"
Write-Host ""

# Only prompt when running interactively
if ($Host.UI.RawUI -and -not $env:CI -and -not $env:NONINTERACTIVE) {
    Write-Host ("{0} Press any key to exit..." -f $E_ARROW) -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
