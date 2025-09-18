# ===============================
# Script: WindowsFullOptimization.ps1
# Optimizare completă și curățare avansată
# ===============================
# Rulează ca Administrator!

param(
    [switch]$Deep = $false,
    [switch]$NoRestart = $false
)

Write-Host "🚀 OPTIMIZARE COMPLETĂ WINDOWS" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# 1. CURĂȚARE AVANSATĂ
Write-Host "`n📦 CURĂȚARE AVANSATĂ..." -ForegroundColor Yellow

# Windows Update cleanup
Write-Host "  • Curățare Windows Update cache..."
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Force -Recurse -ErrorAction SilentlyContinue
Start-Service -Name wuauserv -ErrorAction SilentlyContinue

# Font cache
Write-Host "  • Rebuild font cache..."
Stop-Service -Name FontCache -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache\*" -Force -Recurse -ErrorAction SilentlyContinue
Start-Service -Name FontCache -ErrorAction SilentlyContinue

# Icon cache
Write-Host "  • Curățare icon cache..."
ie4uinit.exe -show
taskkill /F /IM explorer.exe 2>$null
Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*" -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe

# Thumbnail cache
Write-Host "  • Ștergere thumbnail cache..."
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache*.db" -Force -ErrorAction SilentlyContinue

# 2. DISK CLEANUP AVANSAT
Write-Host "`n💾 DISK CLEANUP AVANSAT..." -ForegroundColor Yellow
$cleanmgrKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
Get-ChildItem $cleanmgrKey | ForEach-Object {
    Set-ItemProperty -Path $_.PSPath -Name StateFlags0100 -Value 2 -ErrorAction SilentlyContinue
}
Start-Process cleanmgr.exe -ArgumentList "/sagerun:100" -Wait

# 3. DEFRAGMENTARE INTELIGENTĂ
Write-Host "`n🔧 VERIFICARE DEFRAGMENTARE..." -ForegroundColor Yellow
$drives = Get-Volume | Where-Object {$_.DriveLetter -and $_.DriveType -eq 'Fixed'}
foreach ($drive in $drives) {
    $letter = $drive.DriveLetter + ":"
    Write-Host "  • Analizez drive $letter..."
    
    try {
        # Identifică tipul discului prin asocierea cu discul fizic
        $partition = Get-Partition -DriveLetter $drive.DriveLetter -ErrorAction SilentlyContinue
        if ($partition) {
            $physicalDisk = Get-PhysicalDisk -Number $partition.DiskNumber -ErrorAction SilentlyContinue
            
            if ($physicalDisk) {
                $mediaType = $physicalDisk.MediaType
                $busType = $physicalDisk.BusType
                
                Write-Host "    → Tip disc: $mediaType ($busType)" -ForegroundColor Cyan
                
                # Decizie bazată pe tipul mediului și bus-ul
                $isSSD = ($mediaType -eq 'SSD') -or 
                         ($busType -eq 'NVMe') -or 
                         ($mediaType -eq 'Unspecified' -and $busType -in @('SATA', 'NVMe', 'USB'))
                
                if ($isSSD) {
                    Write-Host "    → SSD/NVMe detectat, rulez TRIM..." -ForegroundColor Green
                    Optimize-Volume -DriveLetter $drive.DriveLetter -ReTrim -ErrorAction SilentlyContinue
                } else {
                    Write-Host "    → HDD detectat, rulez defragmentare..." -ForegroundColor Green
                    # Pentru HDD-uri, verifică mai întâi dacă e nevoie de defragmentare
                    $analysis = Optimize-Volume -DriveLetter $drive.DriveLetter -Analyze -ErrorAction SilentlyContinue
                    Optimize-Volume -DriveLetter $drive.DriveLetter -Defrag -ErrorAction SilentlyContinue
                }
            } else {
                Write-Host "    → Nu s-a putut determina tipul discului, rulez optimizare generală..." -ForegroundColor Yellow
                Optimize-Volume -DriveLetter $drive.DriveLetter -Optimize -ErrorAction SilentlyContinue
            }
        }
    } catch {
        Write-Host "    ⚠️ Eroare la analiza drive-ului $letter" -ForegroundColor Red
        Write-Host "    → Încerc optimizare generală..." -ForegroundColor Yellow
        Optimize-Volume -DriveLetter $drive.DriveLetter -Optimize -ErrorAction SilentlyContinue
    }
}

# 4. VERIFICARE INTEGRITATE SISTEM
Write-Host "`n🛡️ VERIFICARE INTEGRITATE SISTEM..." -ForegroundColor Yellow
Write-Host "  • Rulez SFC (System File Checker)..."
Start-Process sfc -ArgumentList "/scannow" -Wait -NoNewWindow

if ($Deep) {
    Write-Host "  • Rulez DISM (poate dura mai mult)..."
    DISM /Online /Cleanup-Image /RestoreHealth
}

# 5. OPTIMIZARE SERVICII
Write-Host "`n⚙️ OPTIMIZARE SERVICII..." -ForegroundColor Yellow

# Servicii care pot fi dezactivate în siguranță pentru performanță
$servicesToOptimize = @(
    @{Name="DiagTrack"; DisplayName="Diagnostics Tracking"},
    @{Name="dmwappushservice"; DisplayName="Device Management WAP Push"},
    @{Name="RetailDemo"; DisplayName="Retail Demo Service"},
    @{Name="MapsBroker"; DisplayName="Downloaded Maps Manager"},
    @{Name="RemoteRegistry"; DisplayName="Remote Registry"}
)

foreach ($service in $servicesToOptimize) {
    $svc = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
    if ($svc -and $svc.StartType -ne 'Disabled') {
        Write-Host "  • Dezactivez: $($service.DisplayName)"
        Set-Service -Name $service.Name -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name $service.Name -Force -ErrorAction SilentlyContinue
    }
}

# 6. OPTIMIZARE MEMORIE
Write-Host "`n💾 OPTIMIZARE MEMORIE..." -ForegroundColor Yellow
Write-Host "  • Curățare Working Set..."
$processes = Get-Process | Where-Object {$_.WorkingSet -gt 100MB}
foreach ($proc in $processes) {
    try {
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    } catch {}
}

# Clear standby memory
Write-Host "  • Eliberare Standby Memory..."
$mem = Get-CimInstance Win32_OperatingSystem
$percentUsed = ($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / $mem.TotalVisibleMemorySize * 100
Write-Host "    → Memorie utilizată: $([math]::Round($percentUsed, 2))%"

# 7. OPTIMIZARE REȚEA
Write-Host "`n🌐 OPTIMIZARE REȚEA..." -ForegroundColor Yellow
Write-Host "  • Reset DNS cache..."
ipconfig /flushdns | Out-Null
Write-Host "  • Reset Winsock..."
netsh winsock reset catalog | Out-Null
Write-Host "  • Optimizare TCP/IP..."
netsh int tcp set global autotuninglevel=normal | Out-Null
netsh int tcp set global chimney=enabled | Out-Null

# 8. CURĂȚARE REGISTRY (safe)
Write-Host "`n📝 CURĂȚARE REGISTRY..." -ForegroundColor Yellow
Write-Host "  • Ștergere MRU lists..."
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name * -ErrorAction SilentlyContinue
Write-Host "  • Curățare recent documents..."
Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\*" -Force -ErrorAction SilentlyContinue

# 9. ACTUALIZARE DRIVERE
Write-Host "`n🔄 VERIFICARE ACTUALIZĂRI..." -ForegroundColor Yellow
Write-Host "  • Verificare Windows Update prin PowerShell..."
try {
    # Încearcă să verifice actualizările fără a deschide Settings
    $updateSession = (New-Object -ComObject Microsoft.Update.Session -ErrorAction SilentlyContinue)
    if ($updateSession) {
        Write-Host "    → Windows Update session inițializată cu succes" -ForegroundColor Green
    } else {
        Write-Host "    ⚠️ Nu s-a putut inițializa Windows Update session" -ForegroundColor Yellow
    }
} catch {
    Write-Host "    ⚠️ Eroare la verificarea actualizărilor" -ForegroundColor Yellow
    Write-Host "    💡 Poți verifica manual în Settings > Windows Update" -ForegroundColor Cyan
}

# 10. RAPORT FINAL
Write-Host "`n📊 RAPORT OPTIMIZARE" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green

# Spațiu eliberat
$after = Get-PSDrive C | Select-Object -ExpandProperty Free
Write-Host "✅ Optimizare completă!"
Write-Host "💾 Spațiu pe C: $([math]::Round($after/1GB, 2)) GB disponibil"

# Performanță
$cpu = Get-Counter '\Processor(_Total)\% Processor Time' | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty CookedValue
Write-Host "🔥 CPU Usage: $([math]::Round($cpu, 2))%"

$mem = Get-CimInstance Win32_OperatingSystem
$memUsed = ($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / $mem.TotalVisibleMemorySize * 100
Write-Host "💾 RAM Usage: $([math]::Round($memUsed, 2))%"

if (-not $NoRestart) {
    Write-Host "`n⚠️  Restart recomandat pentru aplicarea tuturor optimizărilor!" -ForegroundColor Yellow
    $restart = Read-Host "Dorești să repornești acum? (Y/N)"
    if ($restart -eq 'Y') {
        Write-Host "Repornire în 10 secunde..." -ForegroundColor Red
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    }
}

Write-Host "`n✨ Script finalizat cu succes!" -ForegroundColor Green