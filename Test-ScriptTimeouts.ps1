# ===============================
# Script: Test-ScriptTimeouts.ps1
# Test timeout functionality for all scripts
# ===============================

Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           TEST TIMEOUT-URI SCRIPTURI                     ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$testResults = @()

function Test-ScriptSyntax {
    param([string]$ScriptPath)
    
    try {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $ScriptPath -Raw), [ref]$null)
        return $true
    } catch {
        Write-Host "  ❌ Eroare sintaxă: $_" -ForegroundColor Red
        return $false
    }
}

function Test-TimeoutPattern {
    param([string]$ScriptPath, [string]$ScriptName)
    
    $content = Get-Content $ScriptPath -Raw
    $hasReadHost = $content -match 'Read-Host'
    $hasTimeout = $content -match '\$timeout\s*=|timeout.*secunde|Timeout'
    $hasConsoleKey = $content -match '\[Console\]::KeyAvailable'
    $hasWhileTrue = $content -match 'while\s*\(\s*\$true\s*\)'
    
    $result = @{
        Script = $ScriptName
        Syntax = Test-ScriptSyntax $ScriptPath
        HasReadHost = $hasReadHost
        HasTimeout = $hasTimeout
        HasConsoleKey = $hasConsoleKey
        HasWhileTrue = $hasWhileTrue
        Status = "OK"
    }
    
    # Verificări specifice
    if ($hasReadHost -and -not $hasTimeout) {
        $result.Status = "WARN: Are Read-Host fără timeout"
    }
    
    if ($hasWhileTrue) {
        if ($content -match 'maxCycles|maxRuntime|Maximum.*ore') {
            $result.Status = "OK: While(true) cu protecție timeout"
        } else {
            $result.Status = "WARN: While(true) fără protecție timeout"
        }
    }
    
    if (-not $result.Syntax) {
        $result.Status = "ERROR: Eroare sintaxă"
    }
    
    return $result
}

# Test toate scripturile
$scripts = @(
    "SystemToolkit.ps1",
    "Monitor.ps1", 
    "UpdateWSL.ps1",
    "WindowsFullOptimization.ps1",
    "CleanSafeSurface.ps1",
    "PowerShell_Profile_Backup.ps1",
    "DriverUpdateAutomation.ps1",
    "SystemTemperatureMonitoring.ps1",
    "WeeklyMaintenance.ps1"
)

Write-Host "📋 TESTARE SCRIPTURI..." -ForegroundColor Yellow
Write-Host ""

foreach ($script in $scripts) {
    $scriptPath = Join-Path $PSScriptRoot $script
    
    if (Test-Path $scriptPath) {
        Write-Host "  Testing $script..." -NoNewline
        $result = Test-TimeoutPattern -ScriptPath $scriptPath -ScriptName $script
        $testResults += $result
        
        $color = switch ($result.Status) {
            { $_ -like "ERROR*" } { "Red" }
            { $_ -like "WARN*" } { "Yellow" }
            default { "Green" }
        }
        
        Write-Host " $($result.Status)" -ForegroundColor $color
    } else {
        Write-Host "  ⚠️ $script nu a fost găsit!" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    REZULTATE TEST                        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Sumar
$totalScripts = $testResults.Count
$passedScripts = ($testResults | Where-Object { $_.Status -like "OK*" }).Count
$warnScripts = ($testResults | Where-Object { $_.Status -like "WARN*" }).Count
$errorScripts = ($testResults | Where-Object { $_.Status -like "ERROR*" }).Count

Write-Host "📊 SUMAR:" -ForegroundColor Yellow
Write-Host "  Total scripturi: $totalScripts"
Write-Host "  ✅ OK: $passedScripts" -ForegroundColor Green
Write-Host "  ⚠️ WARNING: $warnScripts" -ForegroundColor Yellow
Write-Host "  ❌ ERROR: $errorScripts" -ForegroundColor Red
Write-Host ""

# Detalii
Write-Host "📝 DETALII:" -ForegroundColor Yellow
$testResults | Format-Table Script, Syntax, HasTimeout, HasWhileTrue, Status -AutoSize

Write-Host ""
Write-Host "✨ Test complet!" -ForegroundColor Green
Write-Host ""

# Return code
if ($errorScripts -gt 0) {
    exit 1
} elseif ($warnScripts -gt 0) {
    exit 0  # Warnings nu sunt fatale
} else {
    exit 0
}
