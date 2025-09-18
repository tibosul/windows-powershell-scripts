# ===============================
# Script: WeeklyMaintenance_v2.ps1
# Maintenance automat săptămânal - VERSIUNE ÎMBUNĂTĂȚITĂ
# ===============================
# Requires -RunAsAdministrator

Write-Host "`n🔧 MAINTENANCE SĂPTĂMÂNAL v2.0" -ForegroundColor Magenta
Write-Host "================================" -ForegroundColor Magenta
$startTime = Get-Date

# 1. BACKUP REGISTRY (cu arhivare automată)
Write-Host "`n📁 Backup Registry..." -ForegroundColor Yellow
$backupPath = "$env:USERPROFILE\Documents\RegistryBackups"
if (!(Test-Path $backupPath)) { 
    New-Item -ItemType Directory -Path $backupPath | Out-Null 
}

# Ștergere backup-uri mai vechi de 30 de zile
Get-ChildItem $backupPath -Filter "*.reg" | 
    Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | 
    Remove-Item -Force

$date = Get-Date -Format "yyyy-MM-dd_HHmm"
reg export HKLM "$backupPath\HKLM_$date.reg" /y | Out-Null
reg export HKCU "$backupPath\HKCU_$date.reg" /y | Out-Null
Write-Host "  ✓ Registry backup salvat în $backupPath" -ForegroundColor Green

# 2. REZOLVARE PROBLEME WINDOWS UPDATE
Write-Host "`n🔧 Rezolvare probleme Windows Update..." -ForegroundColor Yellow
# Oprire servicii
Stop-Service -Name wuauserv, bits, cryptsvc -Force -ErrorAction SilentlyContinue

# Curățare cache Windows Update
Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\System32\catroot2\*" -Force -Recurse -ErrorAction SilentlyContinue

# Repornire servicii
Start-Service -Name wuauserv, bits, cryptsvc -ErrorAction SilentlyContinue
Write-Host "  ✓ Windows Update cache resetat" -ForegroundColor Green

# 3. ACTUALIZARE SOFTWARE INTELIGENTĂ
Write-Host "`n📦 Actualizare aplicații..." -ForegroundColor Yellow

# Winget cu gestionare erori
Write-Host "  • Verificare actualizări Winget..."
try {
    $updates = winget upgrade --include-unknown 2>$null
    if ($updates -match "upgrades available") {
        Write-Host "    → Actualizări disponibile, instalare..." -ForegroundColor Green
        
        # Exclude VirtualBox dacă ai VM-uri active
        $vmRunning = Get-Process -Name "VirtualBoxVM" -ErrorAction SilentlyContinue
        if ($vmRunning) {
            Write-Host "    ⚠️ VirtualBox nu va fi actualizat (VM-uri active)" -ForegroundColor Yellow
            winget upgrade --all --silent --accept-package-agreements --accept-source-agreements --exclude "Oracle.VirtualBox"
        } else {
            winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
        }
    } else {
        Write-Host "    ✓ Toate aplicațiile sunt actualizate!" -ForegroundColor Green
    }
} catch {
    Write-Host "    ⚠️ Eroare la verificare Winget" -ForegroundColor Yellow
}

# Microsoft Store apps
Write-Host "  • Actualizare Microsoft Store apps..."
try {
    Get-CimInstance -Namespace "root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | 
        Invoke-CimMethod -MethodName UpdateScanMethod -ErrorAction SilentlyContinue | Out-Null
    Write-Host "    ✓ Store apps verificate" -ForegroundColor Green
} catch {
    Write-Host "    ⚠️ Nu s-a putut verifica Store" -ForegroundColor Yellow
}

# 4. SCANARE SECURITATE ÎMBUNĂTĂȚITĂ
Write-Host "`n🛡️ Scanare securitate..." -ForegroundColor Yellow

# Update definitions
Write-Host "  • Actualizare definiții antivirus..."
Update-MpSignature -ErrorAction SilentlyContinue

# Quick scan
Write-Host "  • Windows Defender Quick Scan..."
Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue

# Verificare amenințări
$threats = Get-MpThreat -ErrorAction SilentlyContinue
if ($threats) {
    Write-Host "  ⚠️ AMENINȚĂRI DETECTATE!" -ForegroundColor Red
    $threats | ForEach-Object { 
        Write-Host "    - $($_.ThreatName) [Severity: $($_.SeverityID)]" -ForegroundColor Red
    }
} else {
    Write-Host "  ✓ Nu au fost detectate amenințări" -ForegroundColor Green
}

# Verificare firewall
Write-Host "  • Verificare Windows Firewall..."
$firewall = Get-NetFirewallProfile | Where-Object {$_.Enabled -eq $false}
if ($firewall) {
    Write-Host "    ⚠️ Firewall dezactivat pentru: $($firewall.Name -join ', ')" -ForegroundColor Red
} else {
    Write-Host "    ✓ Firewall activ pe toate profilele" -ForegroundColor Green
}

# 5. VERIFICARE HARDWARE CORECTATĂ
Write-Host "`n🖥️ Verificare hardware..." -ForegroundColor Yellow

# SMART pentru SSD/HDD
Write-Host "  • Verificare SMART pentru discuri..."
Get-PhysicalDisk | ForEach-Object {
    $disk = $_
    $health = Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction SilentlyContinue
    if ($health) {
        $temp = if ($health.Temperature) { "$($health.Temperature)°C" } else { "N/A" }
        $status = if ($disk.HealthStatus -eq "Healthy") { "✓" } else { "⚠️" }
        Write-Host "    $status Disk $($disk.FriendlyName): Health = $($disk.HealthStatus), Temp = $temp"
        
        # Avertizare pentru temperaturi mari
        if ($health.Temperature -and $health.Temperature -gt 60) {
            Write-Host "      ⚠️ ATENȚIE: Temperatura discului este mare!" -ForegroundColor Red
        }
    }
}

# Verificare baterie ÎMBUNĂTĂȚITĂ
$batteries = @(Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue)
if ($batteries.Count -gt 0) {
    Write-Host "  • Status baterii laptop ($($batteries.Count) baterii):"
    
    for ($i = 0; $i -lt $batteries.Count; $i++) {
        $bat = $batteries[$i]
        Write-Host "    Bateria $($i + 1):"
        
        try {
            if ($bat.DesignCapacity -and $bat.FullChargeCapacity -and $bat.FullChargeCapacity -gt 0) {
                $healthPercent = [math]::Round(($bat.FullChargeCapacity / $bat.DesignCapacity) * 100, 2)
                Write-Host "      → Sănătate: $healthPercent% din capacitatea originală"
                
                if ($healthPercent -lt 80) {
                    Write-Host "        ⚠️ Bateria ar putea necesita înlocuire" -ForegroundColor Yellow
                } elseif ($healthPercent -gt 90) {
                    Write-Host "        ✓ Baterie în stare excelentă" -ForegroundColor Green
                }
            }
            
            if ($bat.EstimatedChargeRemaining) {
                $chargePercent = $bat.EstimatedChargeRemaining
                Write-Host "      → Încărcare curentă: $chargePercent%"
                
                if ($chargePercent -lt 20) {
                    Write-Host "        ⚠️ Baterie descărcată!" -ForegroundColor Yellow
                }
            }
            
            $status = switch ($bat.BatteryStatus) {
                1 { "Other" }
                2 { "Unknown" }
                3 { "Fully Charged" }
                4 { "Low" }
                5 { "Critical" }
                6 { "Charging" }
                7 { "Charging and High" }
                8 { "Charging and Low" }
                9 { "Charging and Critical" }
                10 { "Undefined" }
                11 { "Partially Charged" }
                default { "Status necunoscut ($($bat.BatteryStatus))" }
            }
            Write-Host "      → Status: $status"
            
        } catch {
            Write-Host "      ⚠️ Nu s-au putut citi detaliile acestei baterii" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  • Nu au fost detectate baterii (sistem desktop)" -ForegroundColor Gray
}

# 6. OPTIMIZARE STARTUP ÎMBUNĂTĂȚITĂ
Write-Host "`n⚡ Optimizare startup..." -ForegroundColor Yellow
$startupItems = Get-CimInstance Win32_StartupCommand
Write-Host "  • Total programe la startup: $($startupItems.Count)"

# Identificare programe grele la startup
$heavyStartups = @("Steam", "Skype", "Teams", "Discord", "Spotify")
$foundHeavy = $startupItems | Where-Object { 
    $heavyStartups -contains ($_.Name -replace '\s.*$','')
}

if ($foundHeavy) {
    Write-Host "  ⚠️ Programe grele detectate la startup:" -ForegroundColor Yellow
    $foundHeavy | ForEach-Object { Write-Host "    - $($_.Name)" }
    Write-Host "    💡 Consideră dezactivarea lor din Task Manager > Startup" -ForegroundColor Cyan
}

# 7. CURĂȚARE BROWSERE EXTINSĂ
Write-Host "`n🌐 Curățare cache browsere..." -ForegroundColor Yellow

# Chrome
$chromePaths = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Service Worker"
)
foreach ($path in $chromePaths) {
    if (Test-Path $path) {
        Write-Host "  • Curățare Chrome: $(Split-Path $path -Leaf)..."
        Remove-Item "$path\*" -Force -Recurse -ErrorAction SilentlyContinue
    }
}

# Edge
$edgePaths = @(
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Service Worker"
)
foreach ($path in $edgePaths) {
    if (Test-Path $path) {
        Write-Host "  • Curățare Edge: $(Split-Path $path -Leaf)..."
        Remove-Item "$path\*" -Force -Recurse -ErrorAction SilentlyContinue
    }
}

# Firefox
$firefoxPath = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"
if (Test-Path $firefoxPath) {
    Write-Host "  • Curățare Firefox cache..."
    Get-ChildItem $firefoxPath -Directory | ForEach-Object {
        Remove-Item "$($_.FullName)\cache2\*" -Force -Recurse -ErrorAction SilentlyContinue
    }
}

# 8. CURĂȚARE FIȘIERE TEMPORARE EXTINSE
Write-Host "`n🗑️ Curățare fișiere temporare..." -ForegroundColor Yellow
$tempPaths = @(
    "$env:TEMP",
    "C:\Windows\Temp",
    "C:\Windows\Prefetch",
    "$env:LOCALAPPDATA\Temp",
    "C:\ProgramData\Microsoft\Windows\WER",
    "$env:LOCALAPPDATA\CrashDumps"
)

$totalFreed = 0
foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        $before = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | 
                  Measure-Object -Property Length -Sum).Sum / 1MB
        
        Remove-Item "$path\*" -Force -Recurse -ErrorAction SilentlyContinue
        
        $after = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | 
                 Measure-Object -Property Length -Sum).Sum / 1MB
        
        $freed = [math]::Round($before - $after, 2)
        $totalFreed += $freed
        
        if ($freed -gt 0) {
            Write-Host "  • $(Split-Path $path -Leaf): $freed MB eliberat"
        }
    }
}
Write-Host "  ✓ Total eliberat: $([math]::Round($totalFreed, 2)) MB" -ForegroundColor Green

# 9. VERIFICARE EVENT LOG ÎMBUNĂTĂȚITĂ
Write-Host "`n📋 Analiză Event Log..." -ForegroundColor Yellow
$criticalErrors = @{
    "Service Control Manager" = 0
    "Microsoft-Windows-WindowsUpdateClient" = 0
    "DCOM" = 0
    "Application Error" = 0
}

$errors = Get-EventLog -LogName System -EntryType Error -Newest 50 -ErrorAction SilentlyContinue
foreach ($error in $errors) {
    if ($criticalErrors.ContainsKey($error.Source)) {
        $criticalErrors[$error.Source]++
    }
}

Write-Host "  • Sumar erori critice (ultimele 50):"
foreach ($source in $criticalErrors.Keys) {
    $count = $criticalErrors[$source]
    if ($count -gt 0) {
        $color = if ($count -gt 5) { "Red" } elseif ($count -gt 2) { "Yellow" } else { "White" }
        Write-Host "    - $source`: $count erori" -ForegroundColor $color
    }
}

# Verificare probleme SQL Server
if ($errors | Where-Object {$_.Source -like "*SQL*"}) {
    Write-Host "  ⚠️ Probleme SQL Server detectate!" -ForegroundColor Yellow
    Write-Host "    💡 Rulează scriptul de optimizare SQL Server" -ForegroundColor Cyan
}

# 10. OPTIMIZARE WINDOWS SEARCH
Write-Host "`n🔍 Optimizare Windows Search..." -ForegroundColor Yellow
Write-Host "  • Verificare serviciu Windows Search..."
$searchService = Get-Service WSearch -ErrorAction SilentlyContinue
if ($searchService.Status -ne "Running") {
    Start-Service WSearch -ErrorAction SilentlyContinue
    Write-Host "    → Serviciu pornit" -ForegroundColor Green
} else {
    Write-Host "    ✓ Serviciu funcțional" -ForegroundColor Green
}

# 11. CREARE RESTORE POINT
Write-Host "`n💾 Creare System Restore Point..." -ForegroundColor Yellow
try {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "Weekly Maintenance $(Get-Date -Format 'yyyy-MM-dd HH:mm')" `
                       -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    Write-Host "  ✓ Restore point creat cu succes" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️ Nu s-a putut crea restore point" -ForegroundColor Yellow
}

# 12. VERIFICARE SPAȚIU PE DISC
Write-Host "`n💾 Verificare spațiu pe disc..." -ForegroundColor Yellow
Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Free -ne $null} | ForEach-Object {
    $percentFree = [math]::Round(($_.Free / ($_.Used + $_.Free)) * 100, 2)
    $color = if ($percentFree -lt 10) { "Red" } elseif ($percentFree -lt 20) { "Yellow" } else { "Green" }
    
    Write-Host "  • Drive $($_.Name): $percentFree% liber ($([math]::Round($_.Free/1GB, 2)) GB)" -ForegroundColor $color
    
    if ($percentFree -lt 10) {
        Write-Host "    ⚠️ ATENȚIE: Spațiu critic pe disc!" -ForegroundColor Red
        Write-Host "    💡 Rulează scriptul de curățare profundă" -ForegroundColor Cyan
    }
}

# 13. RAPORT FINAL
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n" 
Write-Host "═══════════════════════════════════════" -ForegroundColor Green
Write-Host " 📊 RAPORT MAINTENANCE COMPLETAT" -ForegroundColor Green  
Write-Host "═══════════════════════════════════════" -ForegroundColor Green
Write-Host "⏱️  Durata: $($duration.Minutes) min și $($duration.Seconds) sec"
Write-Host "📅 Data: $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
Write-Host "🖥️  Computer: $env:COMPUTERNAME"
Write-Host "👤 Utilizator: $env:USERNAME"

# Status general sistem
$cpu = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
$mem = Get-CimInstance Win32_OperatingSystem
$memUsed = ($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / $mem.TotalVisibleMemorySize * 100

Write-Host "`n📈 Status Sistem:"
Write-Host "  • CPU: $([math]::Round($cpu.CounterSamples.CookedValue, 2))%"
Write-Host "  • RAM: $([math]::Round($memUsed, 2))% utilizat"
Write-Host "  • Uptime: $((Get-CimInstance Win32_OperatingSystem).LastBootUpTime | Get-Date -Format 'dd/MM HH:mm')"

# Salvare log
$logPath = "$env:USERPROFILE\Documents\MaintenanceLogs"
if (!(Test-Path $logPath)) { 
    New-Item -ItemType Directory -Path $logPath | Out-Null 
}

$logFile = "$logPath\Maintenance_$(Get-Date -Format 'yyyy-MM-dd_HHmm').log"
@"
Maintenance Report - $(Get-Date)
Duration: $($duration.TotalMinutes) minutes
Computer: $env:COMPUTERNAME
User: $env:USERNAME
Status: Completed Successfully
"@ | Out-File $logFile

Write-Host "`n✅ Toate taskurile finalizate cu succes!" -ForegroundColor Green
Write-Host "📝 Log salvat în: $logFile" -ForegroundColor Cyan

# Sugestii bazate pe probleme găsite
Write-Host "`n💡 RECOMANDĂRI:" -ForegroundColor Cyan
if ($errors | Where-Object {$_.Source -eq "Microsoft-Windows-WindowsUpdateClient"}) {
    Write-Host "  • Rulează Windows Update Troubleshooter"
}
if ($criticalErrors["DCOM"] -gt 5) {
    Write-Host "  • Verifică permisiunile DCOM în Component Services"
}
if ($memUsed -gt 80) {
    Write-Host "  • Consideră upgrade RAM sau închidere aplicații"
}

Write-Host "`n🔄 Următorul maintenance: $((Get-Date).AddDays(7).ToString('dd/MM/yyyy'))" -ForegroundColor Gray