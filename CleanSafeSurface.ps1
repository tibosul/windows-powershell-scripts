# ===============================
# Script: CleanSafeSurface.ps1
# Curățare sigură Windows Surface / Desktop
# ===============================

# Necesită rulare ca Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "⚠️ Rulează PowerShell ca Administrator!" -ForegroundColor Red
    exit
}

Write-Host "💻 CURĂȚARE SIGURĂ WINDOWS" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan
$startTime = Get-Date
$totalSteps = 7
$currentStep = 0

function Show-Progress {
    param([string]$Message, [int]$Step)
    $percent = [math]::Round(($Step / $totalSteps) * 100)
    Write-Host "[$Step/$totalSteps - $percent%] $Message" -ForegroundColor Yellow
}

# Funcție utilitară pentru calcul MB eliberat
function Get-FreedSpaceMB {
    param($Before, $After)
    return [math]::Round(($Before - $After), 2)
}

Show-Progress "Pornire curățare..." 0

# ===============================
# 1. TEMP Utilizator
# ===============================
$currentStep++
Show-Progress "Curățare fișiere temp utilizator..." $currentStep
$beforeTemp = (Get-ChildItem $env:TEMP -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB
Remove-Item "$env:TEMP\*" -Force -Recurse -ErrorAction SilentlyContinue
$afterTemp = (Get-ChildItem $env:TEMP -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB
$freedTemp = Get-FreedSpaceMB $beforeTemp $afterTemp
if ($freedTemp -gt 0) { Write-Host "  ✓ Eliberat: $freedTemp MB" -ForegroundColor Green }

# ===============================
# 2. TEMP Sistem
# ===============================
$currentStep++
Show-Progress "Curățare fișiere temp sistem..." $currentStep
$beforeSysTemp = (Get-ChildItem "C:\Windows\Temp" -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB
Remove-Item "C:\Windows\Temp\*" -Force -Recurse -ErrorAction SilentlyContinue
$afterSysTemp = (Get-ChildItem "C:\Windows\Temp" -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB
$freedSysTemp = Get-FreedSpaceMB $beforeSysTemp $afterSysTemp
if ($freedSysTemp -gt 0) { Write-Host "  ✓ Eliberat: $freedSysTemp MB" -ForegroundColor Green }

# ===============================
# 3. Prefetch (opțional)
# ===============================
$currentStep++
Show-Progress "Curățare Prefetch..." $currentStep
$beforePrefetch = (Get-ChildItem "C:\Windows\Prefetch" -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB
Remove-Item "C:\Windows\Prefetch\*" -Force -Recurse -ErrorAction SilentlyContinue
$afterPrefetch = (Get-ChildItem "C:\Windows\Prefetch" -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB
$freedPrefetch = Get-FreedSpaceMB $beforePrefetch $afterPrefetch
if ($freedPrefetch -gt 0) { Write-Host "  ✓ Eliberat: $freedPrefetch MB" -ForegroundColor Green }

# ===============================
# 4. Loguri Windows
# ===============================
$currentStep++
Show-Progress "Curățare loguri Windows..." $currentStep
$beforeLogs = (Get-ChildItem "C:\Windows\Logs" -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB
Remove-Item "C:\Windows\Logs\*" -Force -Recurse -ErrorAction SilentlyContinue
$afterLogs = (Get-ChildItem "C:\Windows\Logs" -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB
$freedLogs = Get-FreedSpaceMB $beforeLogs $afterLogs
if ($freedLogs -gt 0) { Write-Host "  ✓ Eliberat: $freedLogs MB" -ForegroundColor Green }

# ===============================
# 5. Recycle Bin
# ===============================
$currentStep++
Show-Progress "Golire Recycle Bin..." $currentStep
try {
    $shell = New-Object -ComObject Shell.Application
    $recycleBin = $shell.Namespace(0xA)
    $recycleBinSize = ($recycleBin.Items() | ForEach-Object { $_.Size }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    $recycleBinSizeMB = [math]::Round($recycleBinSize / 1MB, 2)
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ Eliberat din Recycle Bin: $recycleBinSizeMB MB" -ForegroundColor Green
} catch {
    Write-Host "  ✓ Recycle Bin golit" -ForegroundColor Green
}

# ===============================
# 6. Delivery Optimization
# ===============================
$currentStep++
Show-Progress "Curățare Delivery Optimization..." $currentStep
Stop-Service DoSvc -Force -ErrorAction SilentlyContinue
$deliveryPath = "C:\ProgramData\Microsoft\Windows\DeliveryOptimization\Cache"
if (Test-Path $deliveryPath) {
    $beforeDelivery = (Get-ChildItem $deliveryPath -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB
    Remove-Item "$deliveryPath\*" -Force -Recurse -ErrorAction SilentlyContinue
    $afterDelivery = (Get-ChildItem $deliveryPath -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB
    $freedDelivery = Get-FreedSpaceMB $beforeDelivery $afterDelivery
    if ($freedDelivery -gt 0) { Write-Host "  ✓ Eliberat: $freedDelivery MB" -ForegroundColor Green }
}
Start-Service DoSvc -ErrorAction SilentlyContinue

# ===============================
# 7. Crash Dumps & WER
# ===============================
$currentStep++
Show-Progress "Ștergere crash dumps & WER..." $currentStep
$werPath = "C:\ProgramData\Microsoft\Windows\WER"
$crashPath = "$env:LOCALAPPDATA\CrashDumps"
$totalFreedCrash = 0
foreach ($path in @($werPath, $crashPath)) {
    if (Test-Path $path) {
        $before = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB
        Remove-Item "$path\*" -Force -Recurse -ErrorAction SilentlyContinue
        $after = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB
        $totalFreedCrash += Get-FreedSpaceMB $before $after
    }
}
$totalFreedCrash = [math]::Round($totalFreedCrash, 2)
if ($totalFreedCrash -gt 0) { Write-Host "  ✓ Eliberat din crash dumps: $totalFreedCrash MB" -ForegroundColor Green }

# ===============================
# SUMAR FINAL
# ===============================
$endTime = Get-Date
$duration = $endTime - $startTime
$totalFreed = $freedTemp + $freedSysTemp + $freedPrefetch + $freedLogs + $freedDelivery + $totalFreedCrash + $recycleBinSizeMB

Write-Host "`n═══════════════════════════════════════" -ForegroundColor Green
Write-Host " ✅ CURĂȚARE FINALIZATĂ CU SUCCES!" -ForegroundColor Green  
Write-Host "═══════════════════════════════════════" -ForegroundColor Green
Write-Host "⏱️  Durata: $($duration.Minutes)m $($duration.Seconds)s"
Write-Host "💾 Total spațiu eliberat: $([math]::Round($totalFreed, 2)) MB" -ForegroundColor Cyan
Write-Host "📅 Data: $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
Write-Host "💡 Repornește PC-ul pentru aplicarea completă." -ForegroundColor Yellow
[console]::beep(800,400)
