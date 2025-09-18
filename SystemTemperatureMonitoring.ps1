# ===============================
# Script: SystemTemperatureMonitoring.ps1
# Monitorizare temperatura sistem si hardware
# ===============================

function Get-CPUTemperature {
    Write-Host "`n[TEMP] MONITORIZARE TEMPERATURA CPU..." -ForegroundColor Yellow

    try {
        # Incearca WMI pentru temperatura CPU
        $thermalZones = Get-WmiObject -Namespace "root/WMI" -Class MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue

        if ($thermalZones) {
            Write-Host "`n[FIRE] TEMPERATURI ZONE TERMALE:" -ForegroundColor Cyan
            foreach ($zone in $thermalZones) {
                $tempCelsius = [math]::Round(($zone.CurrentTemperature / 10) - 273.15, 1)
                $status = if ($tempCelsius -lt 70) { "[OK] Normal" }
                         elseif ($tempCelsius -lt 85) { "[WARN] Atentie" }
                         else { "[CRIT] Pericol" }

                Write-Host "  • Zona $($zone.InstanceName): $tempCelsius°C - $status" -ForegroundColor White
            }
        }
        else {
            Write-Host "`n[WARN] Nu s-au gasit zone termale ACPI disponibile." -ForegroundColor Yellow
        }

        # Incearca sa obtina temperaturile prin WMI alternative
        $processors = Get-WmiObject -Class Win32_Processor
        if ($processors) {
            Write-Host "`n[CPU] INFORMATII PROCESOARE:" -ForegroundColor Cyan
            foreach ($proc in $processors) {
                $loadPercentage = $proc.LoadPercentage
                if ($loadPercentage -ne $null) {
                    $status = if ($loadPercentage -lt 50) { "[OK] Normal" }
                             elseif ($loadPercentage -lt 80) { "[WARN] Ridicat" }
                             else { "[CRIT] Critic" }

                    Write-Host "  • $($proc.Name)" -ForegroundColor White
                    Write-Host "    Utilizare: $loadPercentage% - $status" -ForegroundColor White
                }
            }
        }

        # Verifica performanta prin contoarele de performanta
        $cpuLoad = Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 3
        $avgLoad = ($cpuLoad.CounterSamples | Measure-Object -Property CookedValue -Average).Average
        $avgLoad = [math]::Round($avgLoad, 1)

        Write-Host "`n[STATS] UTILIZARE CPU MEDIE (3 secunde): $avgLoad%" -ForegroundColor Cyan
        $loadStatus = if ($avgLoad -lt 30) { "[OK] Redusa" }
                     elseif ($avgLoad -lt 70) { "[WARN] Moderata" }
                     else { "[CRIT] Ridicata" }
        Write-Host "  Status: $loadStatus" -ForegroundColor White

    }
    catch {
        Write-Host "[ERROR] Eroare la citirea temperaturii CPU: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[INFO] Temperatura hardware poate fi accesata doar pe anumite sisteme." -ForegroundColor Yellow
    }
}

function Get-SystemTemperatures {
    Write-Host "`n[TEMP] SCANARE COMPLETA TEMPERATURI..." -ForegroundColor Yellow

    try {
        # Temperaturi disponibile prin WMI
        Write-Host "`n[WMI] TEMPERATURI WMI:" -ForegroundColor Cyan

        # MSAcpi_ThermalZoneTemperature (ACPI Thermal Zones)
        $acpiThermal = Get-WmiObject -Namespace "root/WMI" -Class MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
        if ($acpiThermal) {
            foreach ($thermal in $acpiThermal) {
                $tempK = $thermal.CurrentTemperature / 10
                $tempC = [math]::Round($tempK - 273.15, 1)
                $criticalTemp = [math]::Round(($thermal.CriticalTripPoint / 10) - 273.15, 1)

                Write-Host "  • ACPI Zone: $tempC°C (Critic: $criticalTemp°C)" -ForegroundColor White
            }
        }
        else {
            Write-Host "  • ACPI Thermal Zones: Nu sunt disponibile" -ForegroundColor Yellow
        }

        # Win32_TemperatureProbe
        $tempProbes = Get-WmiObject -Class Win32_TemperatureProbe -ErrorAction SilentlyContinue
        if ($tempProbes) {
            Write-Host "`n[PROBE] SONDE TEMPERATURA:" -ForegroundColor Cyan
            foreach ($probe in $tempProbes) {
                if ($probe.CurrentReading) {
                    $tempC = [math]::Round($probe.CurrentReading / 10 - 273.15, 1)
                    Write-Host "  • $($probe.Description): $tempC°C" -ForegroundColor White
                }
            }
        }
        else {
            Write-Host "`n[PROBE] SONDE TEMPERATURA: Nu sunt disponibile" -ForegroundColor Yellow
        }

        # Verifica fan speeds daca sunt disponibile
        $fans = Get-WmiObject -Class Win32_Fan -ErrorAction SilentlyContinue
        if ($fans) {
            Write-Host "`n[FAN] VENTILATOARE:" -ForegroundColor Cyan
            foreach ($fan in $fans) {
                $speed = if ($fan.DesiredSpeed) { "$($fan.DesiredSpeed) RPM" } else { "N/A" }
                Write-Host "  • $($fan.Description): $speed" -ForegroundColor White
            }
        }
        else {
            Write-Host "`n[FAN] VENTILATOARE: Informatii nu sunt disponibile prin WMI" -ForegroundColor Yellow
        }

    }
    catch {
        Write-Host "[ERROR] Eroare la scanarea temperaturilor: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Monitor-SystemHealth {
    Write-Host "`n[SYS] MONITORIZARE SANATATE SISTEM..." -ForegroundColor Yellow

    try {
        # Memorie
        $memory = Get-WmiObject -Class Win32_OperatingSystem
        $totalRAM = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
        $freeRAM = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
        $usedRAM = $totalRAM - $freeRAM
        $memoryPercent = [math]::Round(($usedRAM / $totalRAM) * 100, 1)

        Write-Host "`n[RAM] MEMORIE RAM:" -ForegroundColor Cyan
        Write-Host "  • Total: $totalRAM GB" -ForegroundColor White
        Write-Host "  • Folosita: $usedRAM GB ($memoryPercent%)" -ForegroundColor White
        Write-Host "  • Libera: $freeRAM GB" -ForegroundColor White

        $memStatus = if ($memoryPercent -lt 70) { "[OK] Normal" }
                    elseif ($memoryPercent -lt 85) { "[WARN] Ridicat" }
                    else { "[CRIT] Critic" }
        Write-Host "  • Status: $memStatus" -ForegroundColor White

        # Disk Space si IO
        Write-Host "`n[DISK] SPATIU DISK:" -ForegroundColor Cyan
        $disks = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        foreach ($disk in $disks) {
            $totalSize = [math]::Round($disk.Size / 1GB, 2)
            $freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
            $usedSpace = $totalSize - $freeSpace
            $diskPercent = [math]::Round(($usedSpace / $totalSize) * 100, 1)

            $diskStatus = if ($diskPercent -lt 80) { "[OK] Normal" }
                         elseif ($diskPercent -lt 90) { "[WARN] Plin" }
                         else { "[CRIT] Critic" }

            Write-Host "  • Drive $($disk.DeviceID) $totalSize GB - Folosit: $diskPercent% - $diskStatus" -ForegroundColor White
        }

        # Procese care consuma resurse
        Write-Host "`n[PROC] TOP PROCESE (CPU):" -ForegroundColor Cyan
        $topProcesses = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
        foreach ($proc in $topProcesses) {
            if ($proc.CPU) {
                $cpuTime = [math]::Round($proc.CPU, 2)
                Write-Host "  • $($proc.ProcessName): $cpuTime sec CPU" -ForegroundColor White
            }
        }

        # Procese care consuma memorie
        Write-Host "`n[MEM] TOP PROCESE (MEMORIE):" -ForegroundColor Cyan
        $topMemoryProcesses = Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5
        foreach ($proc in $topMemoryProcesses) {
            $memoryMB = [math]::Round($proc.WorkingSet / 1MB, 1)
            Write-Host "  • $($proc.ProcessName): $memoryMB MB" -ForegroundColor White
        }

    }
    catch {
        Write-Host "[ERROR] Eroare la monitorizarea sistemului: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Start-ContinuousMonitoring {
    Write-Host "`n[LIVE] MONITORIZARE CONTINUA (Ctrl+C pentru oprire)..." -ForegroundColor Yellow
    Write-Host "[INFO] Actualizare la fiecare 5 secunde`n" -ForegroundColor Cyan

    try {
        $counter = 0
        while ($true) {
            Clear-Host
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host "       MONITORIZARE IN TIMP REAL         " -ForegroundColor Cyan
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host "Timp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Ciclu: $counter" -ForegroundColor Yellow

            # CPU Load
            $cpuLoad = Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1
            $currentCPU = [math]::Round($cpuLoad.CounterSamples[0].CookedValue, 1)
            $cpuStatus = if ($currentCPU -lt 30) { "[OK]" } elseif ($currentCPU -lt 70) { "[WARN]" } else { "[CRIT]" }
            Write-Host "`n[CPU] CPU: $currentCPU% $cpuStatus" -ForegroundColor White

            # Memory
            $memory = Get-WmiObject -Class Win32_OperatingSystem
            $memoryPercent = [math]::Round(((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100), 1)
            $memStatus = if ($memoryPercent -lt 70) { "[OK]" } elseif ($memoryPercent -lt 85) { "[WARN]" } else { "[CRIT]" }
            Write-Host "[RAM] RAM: $memoryPercent% $memStatus" -ForegroundColor White

            # Disk Activity
            try {
                $diskRead = Get-Counter "\PhysicalDisk(_Total)\Disk Reads/sec" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
                $diskWrite = Get-Counter "\PhysicalDisk(_Total)\Disk Writes/sec" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue

                if ($diskRead -and $diskWrite) {
                    $reads = [math]::Round($diskRead.CounterSamples[0].CookedValue, 1)
                    $writes = [math]::Round($diskWrite.CounterSamples[0].CookedValue, 1)
                    Write-Host "[DISK] Disk I/O: $reads reads/sec, $writes writes/sec" -ForegroundColor White
                }
            }
            catch {
                Write-Host "[DISK] Disk I/O: N/A" -ForegroundColor Yellow
            }

            # Network Activity
            try {
                $networkAdapter = Get-Counter "\Network Interface(*)\Bytes Total/sec" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue |
                                 Where-Object { $_.CounterSamples.InstanceName -notlike "*Loopback*" -and $_.CounterSamples.InstanceName -notlike "*isatap*" } |
                                 Select-Object -First 1

                if ($networkAdapter) {
                    $networkBytes = [math]::Round($networkAdapter.CounterSamples[0].CookedValue / 1KB, 1)
                    Write-Host "[NET] Retea: $networkBytes KB/s" -ForegroundColor White
                }
            }
            catch {
                Write-Host "[NET] Retea: N/A" -ForegroundColor Yellow
            }

            Write-Host "`n[INFO] Actualizare in 5 secunde... (Ctrl+C pentru stop)" -ForegroundColor Cyan
            $counter++
            Start-Sleep -Seconds 5
        }
    }
    catch [System.Management.Automation.PipelineStoppedException] {
        Write-Host "`n[STOP] Monitorizare oprita de utilizator." -ForegroundColor Yellow
    }
    catch {
        Write-Host "`n[ERROR] Eroare in monitorizare: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Export-TemperatureLog {
    Write-Host "`n[LOG] EXPORT LOG TEMPERATURI..." -ForegroundColor Yellow

    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $logPath = "$env:USERPROFILE\Desktop\TemperatureLog_$timestamp.txt"

        $logContent = @"
============================================
         RAPORT TEMPERATURI SISTEM
============================================

Data/Ora: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Computer: $env:COMPUTERNAME
Utilizator: $env:USERNAME

"@

        # Adauga informatii despre sistem
        $computerInfo = Get-ComputerInfo -Property WindowsProductName, TotalPhysicalMemory, CsProcessors
        $logContent += "`n[SYS] SISTEM:`n"
        $logContent += "• OS: $($computerInfo.WindowsProductName)`n"
        $logContent += "• RAM Total: $([math]::Round($computerInfo.TotalPhysicalMemory / 1GB, 2)) GB`n"
        $logContent += "• CPU: $($computerInfo.CsProcessors[0].Name)`n"

        # Adauga temperaturi daca sunt disponibile
        $thermalZones = Get-WmiObject -Namespace "root/WMI" -Class MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
        if ($thermalZones) {
            $logContent += "`n[TEMP] TEMPERATURI:`n"
            foreach ($zone in $thermalZones) {
                $tempCelsius = [math]::Round(($zone.CurrentTemperature / 10) - 273.15, 1)
                $logContent += "• Zona $($zone.InstanceName): $tempCelsius°C`n"
            }
        }
        else {
            $logContent += "`n[TEMP] TEMPERATURI: Nu sunt disponibile prin ACPI`n"
        }

        # Adauga informatii despre performanta
        $cpuLoad = Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1
        $currentCPU = [math]::Round($cpuLoad.CounterSamples[0].CookedValue, 1)

        $memory = Get-WmiObject -Class Win32_OperatingSystem
        $memoryPercent = [math]::Round(((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100), 1)

        $logContent += "`n[PERF] PERFORMANTA:`n"
        $logContent += "• CPU Load: $currentCPU%`n"
        $logContent += "• RAM Usage: $memoryPercent%`n"

        # Salveaza fisierul
        $logContent | Out-File -FilePath $logPath -Encoding UTF8

        Write-Host "[OK] Log salvat in: $logPath" -ForegroundColor Green

    }
    catch {
        Write-Host "[ERROR] Eroare la exportul log-ului: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Main-TemperatureMonitoring {
    Clear-Host
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "     MONITORIZARE TEMPERATURA SISTEM     " -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Verificare temperatura CPU" -ForegroundColor White
    Write-Host "  [2] Scanare completa temperaturi" -ForegroundColor White
    Write-Host "  [3] Monitorizare sanatate sistem" -ForegroundColor White
    Write-Host "  [4] Monitorizare continua (timp real)" -ForegroundColor White
    Write-Host "  [5] Export log temperaturi" -ForegroundColor White
    Write-Host "  [6] Raport complet (toate optiunile)" -ForegroundColor White
    Write-Host "  [0] Inapoi" -ForegroundColor Red
    Write-Host ""

    $choice = Read-Host "Alege optiunea"

    switch ($choice) {
        "1" { Get-CPUTemperature }
        "2" { Get-SystemTemperatures }
        "3" { Monitor-SystemHealth }
        "4" { Start-ContinuousMonitoring }
        "5" { Export-TemperatureLog }
        "6" {
            Get-CPUTemperature
            Get-SystemTemperatures
            Monitor-SystemHealth
            Export-TemperatureLog
        }
        "0" { return }
        default {
            Write-Host "[ERROR] Optiune invalida!" -ForegroundColor Red
            Start-Sleep 2
            Main-TemperatureMonitoring
        }
    }

    if ($choice -ne "0" -and $choice -ne "4") {
        Write-Host "`n[INFO] Operatiune completa! Apasa Enter pentru a continua..."
        Read-Host
        Main-TemperatureMonitoring
    }
}

# Ruleaza functia principala daca script-ul este executat direct
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Main-TemperatureMonitoring
}