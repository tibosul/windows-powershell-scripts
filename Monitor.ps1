# ===============================
# Script: Monitor.ps1
# Monitorizare live a sistemului
# Versiune îmbunătățită cu logging și alertă
# ===============================

# Configurare logging
$logPath = "$env:TEMP\SystemMonitor_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$global:LogEnabled = $true
$alertThresholds = @{
    CPU = 85
    RAM = 90
    Disk = 15
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if ($global:LogEnabled) {
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
}

function Show-SystemHeader {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    MONITOR SISTEM LIVE                   ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host "🕒 Ultima actualizare: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" -ForegroundColor Gray
    Write-Host "📄 Log: $logPath" -ForegroundColor Gray
    Write-Host "💡 Apasă 'q' pentru ieșire, 'h' pentru ajutor" -ForegroundColor Yellow
    Write-Host ""
}

# Variabile pentru cache si performanta
$cpuCounter = '\Processor(_Total)\% Processor Time'
$updateCount = 0
$startTime = Get-Date

function Show-Help {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                       AJUTOR MONITOR                     ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🔑 Comenzi disponibile:" -ForegroundColor Yellow
    Write-Host "  [q] - Ieșire din monitor" -ForegroundColor White
    Write-Host "  [h] - Afișează acest ajutor" -ForegroundColor White
    Write-Host "  [s] - Salvează snapshot sistem" -ForegroundColor White
    Write-Host ""
    Write-Host "🎨 Indicatori de culoare:" -ForegroundColor Yellow
    Write-Host "  🟢 Verde - Valorile sunt normale" -ForegroundColor Green
    Write-Host "  🟡 Galben - Atenție, valori ridicate" -ForegroundColor Yellow
    Write-Host "  🔴 Roșu - Critic, interventie necesară" -ForegroundColor Red
    Write-Host ""
    Write-Host "📊 Praguri de alertă:" -ForegroundColor Yellow
    Write-Host "  • CPU: > $($alertThresholds.CPU)%" -ForegroundColor White
    Write-Host "  • RAM: > $($alertThresholds.RAM)%" -ForegroundColor White
    Write-Host "  • Disk: < $($alertThresholds.Disk) GB liber" -ForegroundColor White
    Write-Host ""
    Write-Host "Apasă orice tastă pentru a reveni la monitorizare..." -ForegroundColor Gray
    
    # Timeout pentru help screen
    $timeout = 30
    $startTime = Get-Date
    
    while (((Get-Date) - $startTime).TotalSeconds -lt $timeout) {
        if ([Console]::KeyAvailable) {
            $null = [Console]::ReadKey($true)
            break
        }
        Start-Sleep -Milliseconds 100
    }
}

function Save-SystemSnapshot {
    $snapshotPath = "$env:TEMP\SystemSnapshot_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    Write-Host "`n💾 Salvare snapshot sistem..." -ForegroundColor Cyan
    
    try {
        $snapshot = @()
        $snapshot += "=== SNAPSHOT SISTEM - $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') ==="
        $snapshot += ""
        
        # CPU
        $cpuUsage = try { [math]::Round((Get-Counter $cpuCounter -ErrorAction Stop).CounterSamples.CookedValue, 2) } catch { "N/A" }
        $snapshot += "CPU Usage: $cpuUsage%"
        
        # RAM
        $processes = Get-Process -ErrorAction SilentlyContinue
        if ($processes) {
            $totalRAM = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
            $usedRAM = ($processes | Measure-Object WorkingSet -Sum).Sum / 1GB
            $memUsagePercent = [math]::Round(($usedRAM / $totalRAM) * 100, 1)
            $snapshot += "RAM: $([math]::Round($usedRAM, 1))/$([math]::Round($totalRAM, 1)) GB ($memUsagePercent%)"
        }
        
        # Disk
        $disk = Get-PSDrive C -ErrorAction SilentlyContinue
        if ($disk) {
            $diskFree = [math]::Round($disk.Free / 1GB, 2)
            $diskTotal = [math]::Round(($disk.Used + $disk.Free) / 1GB, 2)
            $diskUsedPercent = [math]::Round(($disk.Used / ($disk.Used + $disk.Free)) * 100, 1)
            $snapshot += "Disk C:\: $([math]::Round(($diskTotal - $diskFree), 1))/$diskTotal GB ($diskUsedPercent% used, $diskFree GB free)"
        }
        
        # Top procese
        $snapshot += ""
        $snapshot += "TOP 5 PROCESE (CPU):"
        $topProcesses = $processes | Sort-Object CPU -Descending | Select-Object -First 5 ProcessName, CPU, @{Name="RAM(MB)";Expression={[math]::Round($_.WorkingSet/1MB,1)}}
        foreach ($proc in $topProcesses) {
            $snapshot += "$($proc.ProcessName) - CPU: $($proc.CPU), RAM: $($proc.'RAM(MB)') MB"
        }
        
        $snapshot += ""
        $snapshot += "TOP 5 PROCESE (RAM):"
        $topRAMProcesses = $processes | Sort-Object WorkingSet -Descending | Select-Object -First 5 ProcessName, @{Name="RAM(MB)";Expression={[math]::Round($_.WorkingSet/1MB,1)}}, CPU
        foreach ($proc in $topRAMProcesses) {
            $snapshot += "$($proc.ProcessName) - RAM: $($proc.'RAM(MB)') MB, CPU: $($proc.CPU)"
        }
        
        $snapshot | Out-File -FilePath $snapshotPath -Encoding UTF8
        Write-Host "✅ Snapshot salvat: $snapshotPath" -ForegroundColor Green
        Write-Log "Snapshot sistem salvat: $snapshotPath" "INFO"
        
    } catch {
        Write-Host "❌ Eroare la salvarea snapshot: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Eroare la salvarea snapshot: $($_.Exception.Message)" "ERROR"
    }
    
    Start-Sleep -Seconds 2
}

Write-Log "Pornire monitorizare sistem" "INFO"

# Variabilă pentru numărul maxim de cicluri (opțional)
$maxCycles = 1200  # 1200 cicluri × 3 secunde = 1 oră maximum
$cycleCount = 0

while($true) {
    $updateCount++
    $cycleCount++
    
    # Ieșire automată după maxCycles pentru a preveni rularea la nesfârșit
    if ($cycleCount -ge $maxCycles) {
        Write-Host "`n⏱️ Timeout maxim atins (1 oră). Monitorizare oprită automat." -ForegroundColor Yellow
        Write-Log "Monitorizare oprită automat după $maxCycles cicluri" "INFO"
        break
    }
    
    # Verifica input utilizator
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        switch ($key.KeyChar) {
            'q' { 
                Write-Host "`n👋 Monitorizare oprită." -ForegroundColor Green
                Write-Log "Monitorizare oprită de utilizator" "INFO"
                $endTime = Get-Date
                $duration = $endTime - $startTime
                Write-Host "⏱️ Durata totală: $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor Cyan
                Write-Host "📊 Actualizări efectuate: $updateCount" -ForegroundColor Cyan
                break 
            }
            'h' { 
                Show-Help
                continue
            }
            's' {
                Save-SystemSnapshot
                continue
            }
        }
    }

    Show-SystemHeader
    
    try {
        # CPU usage cu tratare erori
        $cpuUsage = try {
            [math]::Round((Get-Counter $cpuCounter -ErrorAction Stop).CounterSamples.CookedValue, 2)
        } catch {
            Write-Log "Eroare la citirea CPU: $($_.Exception.Message)" "ERROR"
            "N/A"
        }
        
        $cpuColor = if($cpuUsage -is [double]) {
            if($cpuUsage -gt $alertThresholds.CPU) { "Red" } 
            elseif($cpuUsage -gt 70) { "Yellow" } 
            else { "Green" }
        } else { "White" }
        
        Write-Host "🔥 CPU Usage: " -NoNewline
        Write-Host "$cpuUsage%" -ForegroundColor $cpuColor
        if($cpuUsage -is [double] -and $cpuUsage -gt $alertThresholds.CPU) {
            Write-Log "ALERTĂ: CPU usage critic: $cpuUsage%" "WARNING"
        }

        # Memory usage îmbunătățit
        $processes = Get-Process -ErrorAction SilentlyContinue
        if ($processes) {
            $totalRAM = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
            $usedRAM = ($processes | Measure-Object WorkingSet -Sum).Sum / 1GB
            $memUsagePercent = [math]::Round(($usedRAM / $totalRAM) * 100, 1)
            
            $memColor = if($memUsagePercent -gt $alertThresholds.RAM) { "Red" } 
                       elseif($memUsagePercent -gt 70) { "Yellow" } 
                       else { "Green" }
            
            Write-Host "💾 RAM: " -NoNewline
            Write-Host "[$([math]::Round($usedRAM, 1))/$([math]::Round($totalRAM, 1)) GB] " -NoNewline
            Write-Host "$memUsagePercent%" -ForegroundColor $memColor
            
            if($memUsagePercent -gt $alertThresholds.RAM) {
                Write-Log "ALERTĂ: RAM usage critic: $memUsagePercent%" "WARNING"
            }
        }

        # Disk space îmbunătățit
        $disk = Get-PSDrive C -ErrorAction SilentlyContinue
        if ($disk) {
            $diskFree = [math]::Round($disk.Free / 1GB, 2)
            $diskTotal = [math]::Round(($disk.Used + $disk.Free) / 1GB, 2)
            $diskUsedPercent = [math]::Round(($disk.Used / ($disk.Used + $disk.Free)) * 100, 1)
            
            $diskColor = if($diskFree -lt $alertThresholds.Disk) { "Red" } 
                        elseif($diskFree -lt 50) { "Yellow" } 
                        else { "Green" }
            
            Write-Host "💽 Disk C:\: " -NoNewline
            Write-Host "[$([math]::Round(($diskTotal - $diskFree), 1))/$diskTotal GB] " -NoNewline
            Write-Host "$diskUsedPercent% used, $diskFree GB free" -ForegroundColor $diskColor
            
            if($diskFree -lt $alertThresholds.Disk) {
                Write-Log "ALERTĂ: Spațiu disk critic: $diskFree GB liber" "WARNING"
            }
        }

        # Informații suplimentare
        $uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        Write-Host "⏰ Uptime: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m" -ForegroundColor Cyan
        
        # Temperatura (dacă este disponibilă)
        try {
            $temp = Get-CimInstance -Namespace root\wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
            if ($temp) {
                $tempCelsius = ($temp.CurrentTemperature / 10) - 273.15
                Write-Host "🌡️ Temp: $([math]::Round($tempCelsius, 1))°C" -ForegroundColor $(if($tempCelsius -gt 80) {"Red"} else {"White"})
            }
        } catch {
            # Temperatura nu este disponibilă pe toate sistemele
        }

        Write-Host ""
        Write-Host "🔝 TOP 5 PROCESE (CPU):" -ForegroundColor Yellow
        $topProcesses = $processes | Sort-Object CPU -Descending | Select-Object -First 5 ProcessName, CPU, @{Name="RAM(MB)";Expression={[math]::Round($_.WorkingSet/1MB,1)}}
        $topProcesses | Format-Table -AutoSize | Out-Host

        Write-Host ""
        Write-Host "🔝 TOP 5 PROCESE (RAM):" -ForegroundColor Yellow
        $topRAMProcesses = $processes | Sort-Object WorkingSet -Descending | Select-Object -First 5 ProcessName, @{Name="RAM(MB)";Expression={[math]::Round($_.WorkingSet/1MB,1)}}, CPU
        $topRAMProcesses | Format-Table -AutoSize | Out-Host

    } catch {
        Write-Host "⚠️ Eroare la citirea datelor sistem" -ForegroundColor Red
        Write-Log "Eroare generală: $($_.Exception.Message)" "ERROR"
    }

    Write-Host ""
    Write-Host "⏱️ Actualizare în 3 secunde... (Update #$updateCount)" -ForegroundColor Gray
    Start-Sleep -Seconds 3
}