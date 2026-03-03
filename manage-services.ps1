[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$BackendPidFile = Join-Path $env:TEMP "yapster-backend.pid"
$FrontendPidFile = Join-Path $env:TEMP "yapster-frontend.pid"

function Get-PidFromFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    try {
        return [int](Get-Content $Path -ErrorAction Stop | Select-Object -First 1)
    } catch {
        return $null
    }
}

function Test-ProcessRunning {
    param([int]$Pid)
    if (-not $Pid) { return $false }
    try {
        Get-Process -Id $Pid -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Wait-ForServicesReady {
    Write-Host "⏳ Waiting for services to be ready..."
    for ($i = 1; $i -le 10; $i++) {
        $backendReady = $false
        $frontendReady = $false

        try {
            $backendResp = Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing -ErrorAction Stop
            if ($backendResp.StatusCode -eq 200) { $backendReady = $true }
        } catch {}

        try {
            $frontendResp = Invoke-WebRequest -Uri "http://localhost:5173/health" -UseBasicParsing -ErrorAction Stop
            if ($frontendResp.StatusCode -eq 200) { $frontendReady = $true }
        } catch {}

        if ($backendReady -and $frontendReady) {
            Write-Host "🎉 Both services are ready!"
            return
        }

        Start-Sleep -Seconds 1
    }

    Write-Host "⚠️  Services started but may not be fully ready yet"
}

function Start-Services {
    Write-Host "🚀 Starting services..."

    $backendPid = Get-PidFromFile $BackendPidFile
    if (Test-ProcessRunning $backendPid) {
        Write-Host "⚠️  Backend already running (PID: $backendPid)"
    } else {
        Write-Host "🚀 Starting backend service..."
        $backendProc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "cd /d backend && npm run dev --silent" -PassThru
        $backendProc.Id | Set-Content -Path $BackendPidFile
        Write-Host "✅ Backend started (PID: $($backendProc.Id))"
    }

    $frontendPid = Get-PidFromFile $FrontendPidFile
    if (Test-ProcessRunning $frontendPid) {
        Write-Host "⚠️  Frontend already running (PID: $frontendPid)"
    } else {
        Write-Host "🚀 Starting frontend service..."
        $frontendProc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "cd /d frontend && npm run dev --silent" -PassThru
        $frontendProc.Id | Set-Content -Path $FrontendPidFile
        Write-Host "✅ Frontend started (PID: $($frontendProc.Id))"
    }

    Wait-ForServicesReady
}

function Stop-Services {
    Write-Host "🛑 Stopping services..."

    $backendPid = Get-PidFromFile $BackendPidFile
    if (Test-ProcessRunning $backendPid) {
        Stop-Process -Id $backendPid -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Backend stopped"
    }
    Remove-Item -Path $BackendPidFile -Force -ErrorAction SilentlyContinue

    $frontendPid = Get-PidFromFile $FrontendPidFile
    if (Test-ProcessRunning $frontendPid) {
        Stop-Process -Id $frontendPid -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Frontend stopped"
    }
    Remove-Item -Path $FrontendPidFile -Force -ErrorAction SilentlyContinue

    # Cleanup any orphaned service processes
    Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -match "node" -and $_.Path -and $_.Path -match "node"
    } | ForEach-Object {
        try {
            $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine
            if ($cmd -and ($cmd -match "vite" -or $cmd -match "ts-node-dev")) {
                Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            }
        } catch {}
    }

    Write-Host "✅ Services stopped"
}

function Show-Status {
    Write-Host "📊 Service status:"
    $backendPid = Get-PidFromFile $BackendPidFile
    $frontendPid = Get-PidFromFile $FrontendPidFile

    $backendRunning = Test-ProcessRunning $backendPid
    $frontendRunning = Test-ProcessRunning $frontendPid

    if ($backendRunning) {
        Write-Host "  ✅ Backend running (PID: $backendPid)"
    } else {
        Write-Host "  ❌ Backend not running"
    }

    if ($frontendRunning) {
        Write-Host "  ✅ Frontend running (PID: $frontendPid)"
    } else {
        Write-Host "  ❌ Frontend not running"
    }

    if ($backendRunning -and $frontendRunning) { exit 0 } else { exit 1 }
}

function Check-Running {
    $backendPid = Get-PidFromFile $BackendPidFile
    $frontendPid = Get-PidFromFile $FrontendPidFile
    if ((Test-ProcessRunning $backendPid) -and (Test-ProcessRunning $frontendPid)) { exit 0 }
    exit 1
}

if ($args.Count -lt 1) {
    Write-Host "Usage: .\manage-services.ps1 {start|stop|status|restart|check}"
    exit 1
}

switch ($args[0]) {
    "start"   { Start-Services; exit 0 }
    "stop"    { Stop-Services; exit 0 }
    "status"  { Show-Status }
    "restart" { Stop-Services; Start-Sleep -Seconds 2; Start-Services; exit 0 }
    "check"   { Check-Running }
    default {
        Write-Host "Usage: .\manage-services.ps1 {start|stop|status|restart|check}"
        exit 1
    }
}
