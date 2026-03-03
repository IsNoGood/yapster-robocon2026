# PowerShell script for running tests
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
# Activate Python venv
try {
    & atests\.venv\Scripts\Activate.ps1
} catch {
    Write-Error "Missing atests\.venv. Run setup script first."
    exit 1
}

# Setup cleanup function
function Cleanup {
    Write-Host "🛑 Cleaning up services..."
    
    if (Test-Path $env:TEMP\backend.pid) {
        $backendPid = Get-Content $env:TEMP\backend.pid
        Stop-Process -Id $backendPid -Force -ErrorAction SilentlyContinue
        Remove-Item $env:TEMP\backend.pid -Force
    }
    
    if (Test-Path $env:TEMP\frontend.pid) {
        $frontendPid = Get-Content $env:TEMP\frontend.pid
        Stop-Process -Id $frontendPid -Force -ErrorAction SilentlyContinue
        Remove-Item $env:TEMP\frontend.pid -Force
    }
    
    Get-Process | Where-Object { $_.Name -match "node" -and $_.CommandLine -match "vite|ts-node-dev" } | 
        ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
}

try {
    # Start backend service
    Write-Host "🚀 Starting backend service..."
    Push-Location backend
    $backendProcess = Start-Process cmd.exe -ArgumentList "/c", "npm run dev" -NoNewWindow -PassThru
    $backendProcess.Id | Out-File -FilePath $env:TEMP\backend.pid
    Pop-Location
    
    # Start frontend service
    Write-Host "🚀 Starting frontend service..."
    Push-Location frontend
    $frontendProcess = Start-Process cmd.exe -ArgumentList "/c", "npm run dev" -NoNewWindow -PassThru
    $frontendProcess.Id | Out-File -FilePath $env:TEMP\frontend.pid
    Pop-Location
    
    # Wait for both services to be ready
    Write-Host "⏳ Waiting for services to start..."
    $ready = $false
    $attempts = 0
    
    while (-not $ready -and $attempts -lt 30) {
        $attempts++
        $backendReady = $false
        $frontendReady = $false
        
        try {
            $backendResponse = Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing -ErrorAction SilentlyContinue
            if ($backendResponse.StatusCode -eq 200) {
                $backendReady = $true
            }
        } catch {}
        
        try {
            $frontendResponse = Invoke-WebRequest -Uri "http://localhost:5173/health" -UseBasicParsing -ErrorAction SilentlyContinue
            if ($frontendResponse.StatusCode -eq 200) {
                $frontendReady = $true
            }
        } catch {}
        
        if ($backendReady -and $frontendReady) {
            Write-Host "🎉 Both services are ready!"
            $ready = $true
            break
        }
        
        Write-Host "⏳ Attempt $attempts/30: Waiting... (Backend: $backendReady, Frontend: $frontendReady)"
        Start-Sleep -Seconds 1
    }
    
    # Run tests
    Write-Host "🧪 Running Robot Framework tests..."
    robot --outputdir atests/results atests/
    
} finally {
    # Always clean up, even if there's an error
    Cleanup
}
