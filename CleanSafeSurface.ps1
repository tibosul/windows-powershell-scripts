# ===============================
# Script: CleanSafeSurface.ps1
# Curățare 100% sigură Windows
# ===============================

# Rulează ca Administrator!

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

Show-Progress "Pornire curățare..." 0

# 1. Ștergere fișiere temporare ale utilizatorului
$currentStep++
Show-Progress "Curățare fișiere temp utilizator..." $currentStep
$beforeTemp = try { (Get-ChildItem $env:TEMP -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB } catch { 0 }
Remove-Item "$env:TEMP\*" -Force -Recurse -ErrorAction SilentlyContinue
$afterTemp = try { (Get-ChildItem $env:TEMP -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB } catch { 0 }
$freedTemp = [math]::Round($beforeTemp - $afterTemp, 2)
if ($freedTemp -gt 0) { Write-Host "  ✓ Eliberat: $freedTemp MB" -ForegroundColor Green }

# 2. Fișiere temporare de sistem
$currentStep++
Show-Progress "Curățare fișiere temp sistem..." $currentStep
$beforeSysTemp = try { (Get-ChildItem "C:\Windows\Temp" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB } catch { 0 }
Remove-Item "C:\Windows\Temp\*" -Force -Recurse -ErrorAction SilentlyContinue
$afterSysTemp = try { (Get-ChildItem "C:\Windows\Temp" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB } catch { 0 }
$freedSysTemp = [math]::Round($beforeSysTemp - $afterSysTemp, 2)
if ($freedSysTemp -gt 0) { Write-Host "  ✓ Eliberat: $freedSysTemp MB" -ForegroundColor Green }

# 3. Fișiere Prefetch (lansare rapidă aplicații)
$currentStep++
Show-Progress "Curățare Prefetch..." $currentStep
$beforePrefetch = try { (Get-ChildItem "C:\Windows\Prefetch" -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB } catch { 0 }
Remove-Item "C:\Windows\Prefetch\*" -Force -Recurse -ErrorAction SilentlyContinue
$afterPrefetch = try { (Get-ChildItem "C:\Windows\Prefetch" -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB } catch { 0 }
$freedPrefetch = [math]::Round($beforePrefetch - $afterPrefetch, 2)
if ($freedPrefetch -gt 0) { Write-Host "  ✓ Eliberat: $freedPrefetch MB" -ForegroundColor Green }

# 4. Fișiere log
$currentStep++
Show-Progress "Curățare loguri Windows..." $currentStep
$beforeLogs = try { (Get-ChildItem "C:\Windows\Logs" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB } catch { 0 }
Remove-Item "C:\Windows\Logs\*" -Force -Recurse -ErrorAction SilentlyContinue
$afterLogs = try { (Get-ChildItem "C:\Windows\Logs" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB } catch { 0 }
$freedLogs = [math]::Round($beforeLogs - $afterLogs, 2)
if ($freedLogs -gt 0) { Write-Host "  ✓ Eliberat: $freedLogs MB" -ForegroundColor Green }

# 5. Golește coșul de gunoi
$currentStep++
Show-Progress "Golire Recycle Bin..." $currentStep
try {
    # Calculează mărimea coșului înainte
    $recycleBinSize = 0
    $shell = New-Object -ComObject Shell.Application
    $recycleBin = $shell.Namespace(0xA)
    if ($recycleBin) {
        $recycleBinSize = ($recycleBin.Items() | ForEach-Object { $_.Size }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        $recycleBinSize = [math]::Round($recycleBinSize / 1MB, 2)
    }
    
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    if ($recycleBinSize -gt 0) { Write-Host "  ✓ Eliberat din Recycle Bin: $recycleBinSize MB" -ForegroundColor Green }
} catch {
    Write-Host "  ✓ Recycle Bin golit" -ForegroundColor Green
}

# 6. Delivery Optimization (actualizări Windows peer-to-peer)
$currentStep++
Show-Progress "Curățare Delivery Optimization cache..." $currentStep
$deliveryPath = "C:\ProgramData\Microsoft\Windows\DeliveryOptimization\Cache"
if (Test-Path $deliveryPath) {
    $beforeDelivery = try { (Get-ChildItem $deliveryPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB } catch { 0 }
    Remove-Item "$deliveryPath\*" -Force -Recurse -ErrorAction SilentlyContinue
    $afterDelivery = try { (Get-ChildItem $deliveryPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB } catch { 0 }
    $freedDelivery = [math]::Round($beforeDelivery - $afterDelivery, 2)
    if ($freedDelivery -gt 0) { Write-Host "  ✓ Eliberat: $freedDelivery MB" -ForegroundColor Green }
} else {
    Write-Host "  ✓ Folder Delivery Optimization nu există" -ForegroundColor Gray
}

# 7. Crash dumps & rapoarte de eroare
$currentStep++
Show-Progress "Ștergere crash dumps și rapoarte..." $currentStep
$werPath = "C:\ProgramData\Microsoft\Windows\WER"
$crashPath = "$env:LOCALAPPDATA\CrashDumps"
$totalFreedCrash = 0

if (Test-Path $werPath) {
    $beforeWER = try { (Get-ChildItem $werPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB } catch { 0 }
    Remove-Item "$werPath\*" -Force -Recurse -ErrorAction SilentlyContinue
    $afterWER = try { (Get-ChildItem $werPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB } catch { 0 }
    $totalFreedCrash += ($beforeWER - $afterWER)
}

if (Test-Path $crashPath) {
    $beforeCrash = try { (Get-ChildItem $crashPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB } catch { 0 }
    Remove-Item "$crashPath\*" -Force -Recurse -ErrorAction SilentlyContinue
    $afterCrash = try { (Get-ChildItem $crashPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB } catch { 0 }
    $totalFreedCrash += ($beforeCrash - $afterCrash)
}

$totalFreedCrash = [math]::Round($totalFreedCrash, 2)
if ($totalFreedCrash -gt 0) { Write-Host "  ✓ Eliberat din crash dumps: $totalFreedCrash MB" -ForegroundColor Green }

$endTime = Get-Date
$duration = $endTime - $startTime
$totalFreed = $freedTemp + $freedSysTemp + $freedPrefetch + $freedLogs + $totalFreedCrash
if ($recycleBinSize) { $totalFreed += $recycleBinSize }
if ($freedDelivery) { $totalFreed += $freedDelivery }

Write-Host "`n" 
Write-Host "═══════════════════════════════════════" -ForegroundColor Green
Write-Host " ✅ CURĂȚARE FINALIZATĂ CU SUCCES!" -ForegroundColor Green  
Write-Host "═══════════════════════════════════════" -ForegroundColor Green
Write-Host "⏱️  Durata: $($duration.Minutes) min și $($duration.Seconds) sec"
Write-Host "💾 Total spațiu eliberat: $([math]::Round($totalFreed, 2)) MB" -ForegroundColor Cyan
Write-Host "📅 Data: $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
Write-Host "`n💡 RECOMANDARE: Repornește PC-ul pentru aplicarea completă." -ForegroundColor Yellow
Write-Host "🔄 Rulează acest script săptămânal pentru performanțe optime." -ForegroundColor Cyan
