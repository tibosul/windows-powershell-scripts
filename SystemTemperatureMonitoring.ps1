# ===============================
# Script: SystemTemperatureMonitoring.ps1
# Monitorizare temperatura sistem si hardware
# Versiune îmbunătățită cu logging și alertă
# ===============================

# Configurare logging
$logPath = "$env:TEMP\TemperatureMonitor_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$global:LogEnabled = $true

# Praguri configurabile pentru temperaturi
$temperatureThresholds = @{
    CPU_Normal = 70
    CPU_Warning = 85
    CPU_Critical = 95
    System_Normal = 60
    System_Warning = 75
    System_Critical = 90
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if ($global:LogEnabled) {
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    
    # Afișează în consolă cu culori
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry -ForegroundColor White }
    }
}

function Get-CPUTemperature {
    Write-Log "Începere monitorizare temperatură CPU" "INFO"
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                🌡️ MONITORIZARE TEMPERATURĂ CPU           ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    try {
        # Încearcă CIM pentru temperatura CPU (modernizare)
        Write-Log "Scanare zone termale ACPI" "INFO"
        $thermalZones = Get-CimInstance -Namespace "root/WMI" -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue

        if ($thermalZones) {
            Write-Host "🔥 TEMPERATURI ZONE TERMALE:" -ForegroundColor Yellow
            foreach ($zone in $thermalZones) {
                $tempCelsius = [math]::Round(($zone.CurrentTemperature / 10) - 273.15, 1)
                
                # Determină statusul bazat pe pragurile configurabile
                $status = if ($tempCelsius -lt $temperatureThresholds.CPU_Normal) { 
                    "🟢 Normal" 
                } elseif ($tempCelsius -lt $temperatureThresholds.CPU_Warning) { 
                    "🟡 Atenție" 
                } else { 
                    "🔴 Critic" 
                }
                
                $color = if ($tempCelsius -lt $temperatureThresholds.CPU_Normal) { "Green" }
                        elseif ($tempCelsius -lt $temperatureThresholds.CPU_Warning) { "Yellow" }
                        else { "Red" }

                Write-Host "  • Zona $($zone.InstanceName): " -NoNewline
                Write-Host "$tempCelsius°C - $status" -ForegroundColor $color
                
                Write-Log "Temperatură zonă $($zone.InstanceName): $tempCelsius°C - Status: $status" "INFO"
                
                # Alertă pentru temperaturi critice
                if ($tempCelsius -gt $temperatureThresholds.CPU_Critical) {
                    Write-Log "ALERTĂ CRITICĂ: Temperatură CPU prea mare: $tempCelsius°C" "ERROR"
                } elseif ($tempCelsius -gt $temperatureThresholds.CPU_Warning) {
                    Write-Log "ALERTĂ: Temperatură CPU ridicată: $tempCelsius°C" "WARNING"
                }
            }
        }
        else {
            Write-Log "Zone termale ACPI nu sunt disponibile" "WARNING"
            Write-Host "⚠️ Nu s-au găsit zone termale ACPI disponibile." -ForegroundColor Yellow
        }

        # Încearcă să obțină informațiile procesorului prin CIM
        Write-Log "Colectare informații procesor" "INFO"
        $processors = Get-CimInstance -ClassName Win32_Processor
        if ($processors) {
            Write-Host ""
            Write-Host "💻 INFORMATII PROCESOARE:" -ForegroundColor Yellow
            foreach ($proc in $processors) {
                $loadPercentage = $proc.LoadPercentage
                if ($null -ne $loadPercentage) {
                    $status = if ($loadPercentage -lt 50) { "🟢 Normal" }
                             elseif ($loadPercentage -lt 80) { "🟡 Ridicat" }
                             else { "🔴 Critic" }
                    
                    $color = if ($loadPercentage -lt 50) { "Green" }
                            elseif ($loadPercentage -lt 80) { "Yellow" }
                            else { "Red" }

                    Write-Host "  • $($proc.Name)" -ForegroundColor White
                    Write-Host "    Utilizare: " -NoNewline
                    Write-Host "$loadPercentage% - $status" -ForegroundColor $color
                    
                    Write-Log "Procesor $($proc.Name): Utilizare $loadPercentage%" "INFO"
                }
            }
        }

        # Verifică performanța prin contoarele de performanță
        Write-Log "Măsurare performanță CPU medie" "INFO"
        $cpuLoad = Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 3
        $avgLoad = ($cpuLoad.CounterSamples | Measure-Object -Property CookedValue -Average).Average
        $avgLoad = [math]::Round($avgLoad, 1)

        Write-Host ""
        Write-Host "📊 UTILIZARE CPU MEDIE (3 secunde): " -NoNewline -ForegroundColor Cyan
        $loadStatus = if ($avgLoad -lt 30) { "🟢 Redusă" }
                     elseif ($avgLoad -lt 70) { "🟡 Moderată" }
                     else { "🔴 Ridicată" }
        
        $loadColor = if ($avgLoad -lt 30) { "Green" }
                    elseif ($avgLoad -lt 70) { "Yellow" }
                    else { "Red" }
        
        Write-Host "$avgLoad% - $loadStatus" -ForegroundColor $loadColor
        
        Write-Log "Utilizare CPU medie: $avgLoad% - Status: $loadStatus" "INFO"

    }
    catch {
        Write-Log "Eroare la citirea temperaturii CPU: $($_.Exception.Message)" "ERROR"
        Write-Host "❌ Eroare la citirea temperaturii CPU: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "💡 Temperatura hardware poate fi accesată doar pe anumite sisteme." -ForegroundColor Yellow
    }
}

function Get-SystemTemperatures {
    Write-Log "Începere scanare completă temperaturi sistem" "INFO"
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║            🌡️ SCANARE COMPLETĂ TEMPERATURI               ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    try {
        # Temperaturi disponibile prin CIM (modernizare)
        Write-Log "Scanare temperaturi prin CIM" "INFO"
        Write-Host "🔍 TEMPERATURI DISPONIBILE:" -ForegroundColor Yellow

        # MSAcpi_ThermalZoneTemperature (ACPI Thermal Zones)
        $acpiThermal = Get-CimInstance -Namespace "root/WMI" -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
        if ($acpiThermal) {
            Write-Host ""
            Write-Host "🔥 ACPI THERMAL ZONES:" -ForegroundColor Cyan
            foreach ($thermal in $acpiThermal) {
                $tempK = $thermal.CurrentTemperature / 10
                $tempC = [math]::Round($tempK - 273.15, 1)
                $criticalTemp = [math]::Round(($thermal.CriticalTripPoint / 10) - 273.15, 1)

                $status = if ($tempC -lt $temperatureThresholds.System_Normal) { "🟢 Normal" }
                        elseif ($tempC -lt $temperatureThresholds.System_Warning) { "🟡 Atenție" }
                        else { "🔴 Critic" }

                $color = if ($tempC -lt $temperatureThresholds.System_Normal) { "Green" }
                        elseif ($tempC -lt $temperatureThresholds.System_Warning) { "Yellow" }
                        else { "Red" }

                Write-Host "  • ACPI Zone: " -NoNewline
                Write-Host "$tempC°C (Critic: $criticalTemp°C) - $status" -ForegroundColor $color
                
                Write-Log "ACPI Zone temperatură: $tempC°C, Prag critic: $criticalTemp°C" "INFO"
            }
        }
        else {
            Write-Log "ACPI Thermal Zones nu sunt disponibile" "WARNING"
            Write-Host "  ⚠️ ACPI Thermal Zones: Nu sunt disponibile" -ForegroundColor Yellow
        }

        # Win32_TemperatureProbe
        $tempProbes = Get-CimInstance -ClassName Win32_TemperatureProbe -ErrorAction SilentlyContinue
        if ($tempProbes) {
            Write-Host ""
            Write-Host "🌡️ SONDE TEMPERATURĂ:" -ForegroundColor Cyan
            foreach ($probe in $tempProbes) {
                if ($probe.CurrentReading) {
                    $tempC = [math]::Round($probe.CurrentReading / 10 - 273.15, 1)
                    Write-Host "  • $($probe.Description): $tempC°C" -ForegroundColor White
                    Write-Log "Sondă temperatură $($probe.Description): $tempC°C" "INFO"
                }
            }
        }
        else {
            Write-Log "Sonde temperatură nu sunt disponibile" "WARNING"
            Write-Host ""
            Write-Host "  ⚠️ SONDE TEMPERATURĂ: Nu sunt disponibile" -ForegroundColor Yellow
        }

        # Verifică viteza ventilatorelor dacă sunt disponibile
        $fans = Get-CimInstance -ClassName Win32_Fan -ErrorAction SilentlyContinue
        if ($fans) {
            Write-Host ""
            Write-Host "🌀 VENTILATOARE:" -ForegroundColor Cyan
            foreach ($fan in $fans) {
                $speed = if ($fan.DesiredSpeed) { "$($fan.DesiredSpeed) RPM" } else { "N/A" }
                Write-Host "  • $($fan.Description): $speed" -ForegroundColor White
                Write-Log "Ventilator $($fan.Description): $speed" "INFO"
            }
        }
        else {
            Write-Log "Informații ventilatoare nu sunt disponibile prin CIM" "WARNING"
            Write-Host ""
            Write-Host "  ⚠️ VENTILATOARE: Informații nu sunt disponibile prin CIM" -ForegroundColor Yellow
        }

        # Informații suplimentare despre sistem
        Write-Host ""
        Write-Host "💻 INFORMAȚII SISTEM:" -ForegroundColor Yellow
        try {
            $computerInfo = Get-ComputerInfo -Property CsProcessors, TotalPhysicalMemory, WindowsProductName -ErrorAction SilentlyContinue
            if ($computerInfo) {
                Write-Host "  • Sistem: $($computerInfo.WindowsProductName)" -ForegroundColor White
                Write-Host "  • RAM Total: $([math]::Round($computerInfo.TotalPhysicalMemory / 1GB, 2)) GB" -ForegroundColor White
                if ($computerInfo.CsProcessors) {
                    Write-Host "  • CPU: $($computerInfo.CsProcessors[0].Name)" -ForegroundColor White
                }
                Write-Log "Informații sistem colectate cu succes" "INFO"
            }
        } catch {
            Write-Log "Eroare la colectarea informațiilor sistem: $($_.Exception.Message)" "ERROR"
        }

        Write-Log "Scanare completă temperaturi finalizată" "SUCCESS"

    }
    catch {
        Write-Log "Eroare la scanarea temperaturilor: $($_.Exception.Message)" "ERROR"
        Write-Host "❌ Eroare la scanarea temperaturilor: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-SystemHealth {
    Write-Log "Începere monitorizare sănătate sistem" "INFO"
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              💚 MONITORIZARE SĂNĂTATE SISTEM            ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    try {
        # Memorie cu CIM
        Write-Log "Colectare informații memorie" "INFO"
        $memory = Get-CimInstance -ClassName Win32_OperatingSystem
        $totalRAM = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
        $freeRAM = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
        $usedRAM = $totalRAM - $freeRAM
        $memoryPercent = [math]::Round(($usedRAM / $totalRAM) * 100, 1)

        Write-Host "💾 MEMORIE RAM:" -ForegroundColor Yellow
        Write-Host "  • Total: $totalRAM GB" -ForegroundColor White
        Write-Host "  • Folosită: $usedRAM GB (" -NoNewline
        Write-Host "$memoryPercent%" -NoNewline -ForegroundColor $(if($memoryPercent -lt 70) {"Green"} elseif($memoryPercent -lt 85) {"Yellow"} else {"Red"})
        Write-Host ")" -ForegroundColor White
        Write-Host "  • Liberă: $freeRAM GB" -ForegroundColor White

        $memStatus = if ($memoryPercent -lt 70) { "🟢 Normal" }
                    elseif ($memoryPercent -lt 85) { "🟡 Ridicat" }
                    else { "🔴 Critic" }
        
        $memColor = if ($memoryPercent -lt 70) { "Green" }
                   elseif ($memoryPercent -lt 85) { "Yellow" }
                   else { "Red" }
        
        Write-Host "  • Status: " -NoNewline
        Write-Host "$memStatus" -ForegroundColor $memColor

        Write-Log "Memorie: $usedRAM/$totalRAM GB ($memoryPercent%) - Status: $memStatus" "INFO"

        # Disk Space și IO cu CIM
        Write-Log "Colectare informații disk" "INFO"
        Write-Host ""
        Write-Host "💽 SPAȚIU DISK:" -ForegroundColor Yellow
        $disks = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        foreach ($disk in $disks) {
            $totalSize = [math]::Round($disk.Size / 1GB, 2)
            $freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
            $usedSpace = $totalSize - $freeSpace
            $diskPercent = [math]::Round(($usedSpace / $totalSize) * 100, 1)

            $diskStatus = if ($diskPercent -lt 80) { "🟢 Normal" }
                         elseif ($diskPercent -lt 90) { "🟡 Plin" }
                         else { "🔴 Critic" }

            $diskColor = if ($diskPercent -lt 80) { "Green" }
                        elseif ($diskPercent -lt 90) { "Yellow" }
                        else { "Red" }

            Write-Host "  • Drive $($disk.DeviceID) $totalSize GB - Folosit: " -NoNewline
            Write-Host "$diskPercent%" -NoNewline -ForegroundColor $diskColor
            Write-Host " - $diskStatus" -ForegroundColor White

            Write-Log "Disk $($disk.DeviceID): $usedSpace/$totalSize GB ($diskPercent%) - Status: $diskStatus" "INFO"
        }

        # Procese care consumă resurse
        Write-Log "Colectare informații procese CPU" "INFO"
        Write-Host ""
        Write-Host "🔝 TOP PROCESE (CPU):" -ForegroundColor Yellow
        $topProcesses = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
        foreach ($proc in $topProcesses) {
            if ($proc.CPU) {
                $cpuTime = [math]::Round($proc.CPU, 2)
                Write-Host "  • $($proc.ProcessName): $cpuTime sec CPU" -ForegroundColor White
                Write-Log "Proces CPU: $($proc.ProcessName) - $cpuTime sec" "INFO"
            }
        }

        # Procese care consumă memorie
        Write-Log "Colectare informații procese memorie" "INFO"
        Write-Host ""
        Write-Host "🔝 TOP PROCESE (MEMORIE):" -ForegroundColor Yellow
        $topMemoryProcesses = Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5
        foreach ($proc in $topMemoryProcesses) {
            $memoryMB = [math]::Round($proc.WorkingSet / 1MB, 1)
            Write-Host "  • $($proc.ProcessName): $memoryMB MB" -ForegroundColor White
            Write-Log "Proces RAM: $($proc.ProcessName) - $memoryMB MB" "INFO"
        }

        Write-Log "Monitorizare sănătate sistem finalizată" "SUCCESS"

    }
    catch {
        Write-Log "Eroare la monitorizarea sistemului: $($_.Exception.Message)" "ERROR"
        Write-Host "❌ Eroare la monitorizarea sistemului: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Start-ContinuousMonitoring {
    Write-Log "Începere monitorizare continuă" "INFO"
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║            🔴 MONITORIZARE CONTINUĂ (LIVE)               ║" -ForegroundColor Cyan
    Write-Host "║              ⏱️ Actualizare la fiecare 5 secunde         ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host "💡 Apasă Ctrl+C pentru oprire" -ForegroundColor Yellow
    Write-Host ""

    try {
        $counter = 0
        $startTime = Get-Date
        while ($true) {
            $counter++
            $currentTime = Get-Date
            $runtime = $currentTime - $startTime
            
            Clear-Host
            Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
            Write-Host "║            🔴 MONITORIZARE ÎN TIMP REAL               ║" -ForegroundColor Cyan
            Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
            Write-Host "🕒 Timp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
            Write-Host "🔄 Ciclu: $counter" -ForegroundColor Gray
            Write-Host "⏱️ Runtime: $($runtime.Hours)h $($runtime.Minutes)m $($runtime.Seconds)s" -ForegroundColor Gray
            Write-Host ""

            # CPU Load
            $cpuLoad = Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1
            $currentCPU = [math]::Round($cpuLoad.CounterSamples[0].CookedValue, 1)
            $cpuStatus = if ($currentCPU -lt 30) { "🟢 OK" } elseif ($currentCPU -lt 70) { "🟡 WARN" } else { "🔴 CRIT" }
            $cpuColor = if ($currentCPU -lt 30) { "Green" } elseif ($currentCPU -lt 70) { "Yellow" } else { "Red" }
            
            Write-Host "🔥 CPU: " -NoNewline
            Write-Host "$currentCPU% $cpuStatus" -ForegroundColor $cpuColor

            # Memory cu CIM
            $memory = Get-CimInstance -ClassName Win32_OperatingSystem
            $memoryPercent = [math]::Round(((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100), 1)
            $memStatus = if ($memoryPercent -lt 70) { "🟢 OK" } elseif ($memoryPercent -lt 85) { "🟡 WARN" } else { "🔴 CRIT" }
            $memColor = if ($memoryPercent -lt 70) { "Green" } elseif ($memoryPercent -lt 85) { "Yellow" } else { "Red" }
            
            Write-Host "💾 RAM: " -NoNewline
            Write-Host "$memoryPercent% $memStatus" -ForegroundColor $memColor

            # Temperatură (dacă este disponibilă)
            try {
                $thermalZones = Get-CimInstance -Namespace "root/WMI" -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
                if ($thermalZones) {
                    $maxTemp = 0
                    foreach ($zone in $thermalZones) {
                        $tempCelsius = [math]::Round(($zone.CurrentTemperature / 10) - 273.15, 1)
                        if ($tempCelsius -gt $maxTemp) { $maxTemp = $tempCelsius }
                    }
                    $tempStatus = if ($maxTemp -lt $temperatureThresholds.CPU_Normal) { "🟢 OK" } 
                                 elseif ($maxTemp -lt $temperatureThresholds.CPU_Warning) { "🟡 WARN" } 
                                 else { "🔴 CRIT" }
                    $tempColor = if ($maxTemp -lt $temperatureThresholds.CPU_Normal) { "Green" }
                                elseif ($maxTemp -lt $temperatureThresholds.CPU_Warning) { "Yellow" }
                                else { "Red" }
                    
                    Write-Host "🌡️ TEMP: " -NoNewline
                    Write-Host "$maxTemp°C $tempStatus" -ForegroundColor $tempColor
                    
                    # Log alertă pentru temperaturi critice
                    if ($maxTemp -gt $temperatureThresholds.CPU_Critical) {
                        Write-Log "ALERTĂ CRITICĂ: Temperatură prea mare în monitorizare continuă: $maxTemp°C" "ERROR"
                    } elseif ($maxTemp -gt $temperatureThresholds.CPU_Warning) {
                        Write-Log "ALERTĂ: Temperatură ridicată în monitorizare continuă: $maxTemp°C" "WARNING"
                    }
                }
            }
            catch {
                # Temperatura nu este disponibilă
            }

            # Disk Activity
            try {
                $diskRead = Get-Counter "\PhysicalDisk(_Total)\Disk Reads/sec" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
                $diskWrite = Get-Counter "\PhysicalDisk(_Total)\Disk Writes/sec" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue

                if ($diskRead -and $diskWrite) {
                    $reads = [math]::Round($diskRead.CounterSamples[0].CookedValue, 1)
                    $writes = [math]::Round($diskWrite.CounterSamples[0].CookedValue, 1)
                    Write-Host "💽 DISK I/O: $reads reads/sec, $writes writes/sec" -ForegroundColor White
                }
            }
            catch {
                Write-Host "💽 DISK I/O: N/A" -ForegroundColor Yellow
            }

            # Network Activity
            try {
                $networkAdapter = Get-Counter "\Network Interface(*)\Bytes Total/sec" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue |
                                 Where-Object { $_.CounterSamples.InstanceName -notlike "*Loopback*" -and $_.CounterSamples.InstanceName -notlike "*isatap*" } |
                                 Select-Object -First 1

                if ($networkAdapter) {
                    $networkBytes = [math]::Round($networkAdapter.CounterSamples[0].CookedValue / 1KB, 1)
                    Write-Host "🌐 NET: $networkBytes KB/s" -ForegroundColor White
                }
            }
            catch {
                Write-Host "🌐 NET: N/A" -ForegroundColor Yellow
            }

            Write-Host ""
            Write-Host "⏱️ Actualizare în 5 secunde... (Ctrl+C pentru stop)" -ForegroundColor Cyan
            Write-Host "📄 Log: $logPath" -ForegroundColor Gray
            
            Start-Sleep -Seconds 5
        }
    }
    catch [System.Management.Automation.PipelineStoppedException] {
        Write-Log "Monitorizare oprită de utilizator" "INFO"
        Write-Host ""
        Write-Host "🛑 Monitorizare oprită de utilizator." -ForegroundColor Yellow
        $endTime = Get-Date
        $totalDuration = $endTime - $startTime
        Write-Host "⏱️ Durata totală: $($totalDuration.Hours)h $($totalDuration.Minutes)m $($totalDuration.Seconds)s" -ForegroundColor Cyan
        Write-Host "📊 Cicluri complete: $counter" -ForegroundColor Cyan
    }
    catch {
        Write-Log "Eroare în monitorizare continuă: $($_.Exception.Message)" "ERROR"
        Write-Host ""
        Write-Host "❌ Eroare în monitorizare: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Export-TemperatureLog {
    Write-Log "Începere export log temperaturi" "INFO"
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                📄 EXPORT LOG TEMPERATURI                ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $exportPath = "$env:USERPROFILE\Desktop\TemperatureLog_$timestamp.txt"

        $logContent = @"
============================================
         RAPORT TEMPERATURI SISTEM
         Versiune îmbunătățită
============================================

Data/Ora: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Computer: $env:COMPUTERNAME
Utilizator: $env:USERNAME
Log Intern: $logPath

"@

        # Adaugă informații despre sistem cu CIM
        try {
            $computerInfo = Get-ComputerInfo -Property WindowsProductName, TotalPhysicalMemory, CsProcessors -ErrorAction SilentlyContinue
            if ($computerInfo) {
                $logContent += "`n[SYS] SISTEM:`n"
                $logContent += "• OS: $($computerInfo.WindowsProductName)`n"
                $logContent += "• RAM Total: $([math]::Round($computerInfo.TotalPhysicalMemory / 1GB, 2)) GB`n"
                if ($computerInfo.CsProcessors) {
                    $logContent += "• CPU: $($computerInfo.CsProcessors[0].Name)`n"
                }
                Write-Log "Informații sistem adăugate în export" "INFO"
            }
        } catch {
            Write-Log "Eroare la colectarea informațiilor sistem pentru export: $($_.Exception.Message)" "ERROR"
        }

        # Adaugă temperaturi dacă sunt disponibile cu CIM
        $thermalZones = Get-CimInstance -Namespace "root/WMI" -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
        if ($thermalZones) {
            $logContent += "`n[TEMP] TEMPERATURI:`n"
            foreach ($zone in $thermalZones) {
                $tempCelsius = [math]::Round(($zone.CurrentTemperature / 10) - 273.15, 1)
                $criticalTemp = [math]::Round(($zone.CriticalTripPoint / 10) - 273.15, 1)
                $logContent += "• Zona $($zone.InstanceName): $tempCelsius°C (Critic: $criticalTemp°C)`n"
            }
            Write-Log "Temperaturi ACPI adăugate în export" "INFO"
        }
        else {
            $logContent += "`n[TEMP] TEMPERATURI: Nu sunt disponibile prin ACPI`n"
            Write-Log "Temperaturi ACPI nu sunt disponibile pentru export" "WARNING"
        }

        # Adaugă informații despre performanță cu CIM
        try {
            $cpuLoad = Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1
            $currentCPU = [math]::Round($cpuLoad.CounterSamples[0].CookedValue, 1)

            $memory = Get-CimInstance -ClassName Win32_OperatingSystem
            $memoryPercent = [math]::Round(((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100), 1)

            $logContent += "`n[PERF] PERFORMANȚĂ:`n"
            $logContent += "• CPU Load: $currentCPU%`n"
            $logContent += "• RAM Usage: $memoryPercent%`n"
            
            Write-Log "Informații performanță adăugate în export" "INFO"
        } catch {
            Write-Log "Eroare la colectarea performanței pentru export: $($_.Exception.Message)" "ERROR"
        }

        # Adaugă praguri de temperatură
        $logContent += "`n[THRESH] PRAGURI TEMPERATURĂ:`n"
        $logContent += "• CPU Normal: < $($temperatureThresholds.CPU_Normal)°C`n"
        $logContent += "• CPU Warning: $($temperatureThresholds.CPU_Warning)°C`n"
        $logContent += "• CPU Critical: $($temperatureThresholds.CPU_Critical)°C`n"
        $logContent += "• System Normal: < $($temperatureThresholds.System_Normal)°C`n"
        $logContent += "• System Warning: $($temperatureThresholds.System_Warning)°C`n"
        $logContent += "• System Critical: $($temperatureThresholds.System_Critical)°C`n"

        # Salvează fișierul
        $logContent | Out-File -FilePath $exportPath -Encoding UTF8

        Write-Host "✅ Log salvat în: $exportPath" -ForegroundColor Green
        Write-Log "Export log temperaturi finalizat cu succes: $exportPath" "SUCCESS"

    }
    catch {
        Write-Log "Eroare la exportul log-ului: $($_.Exception.Message)" "ERROR"
        Write-Host "❌ Eroare la exportul log-ului: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-TemperatureMonitoringMenu {
    Write-Log "Pornire aplicație monitorizare temperatură" "INFO"
    
    do {
        Clear-Host
        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║            🌡️ MONITORIZARE TEMPERATURĂ SISTEM           ║" -ForegroundColor Cyan
        Write-Host "║                  ✨ Versiune îmbunătățită                ║" -ForegroundColor Magenta
        Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "📄 Log fișier: $logPath" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  [1] 🌡️ Verificare temperatură CPU" -ForegroundColor White
        Write-Host "  [2] 🔍 Scanare completă temperaturi" -ForegroundColor White
        Write-Host "  [3] 💚 Monitorizare sănătate sistem" -ForegroundColor White
        Write-Host "  [4] 🔴 Monitorizare continuă (timp real)" -ForegroundColor White
        Write-Host "  [5] 📄 Export log temperaturi" -ForegroundColor White
        Write-Host "  [6] 📊 Raport complet (toate opțiunile)" -ForegroundColor White
        Write-Host "  [7] ⚙️ Afișează log-ul intern" -ForegroundColor Yellow
        Write-Host "  [0] ❌ Înapoi" -ForegroundColor Red
        Write-Host ""

        $choice = Read-Host "Alege opțiunea"

        switch ($choice) {
            "1" { Get-CPUTemperature }
            "2" { Get-SystemTemperatures }
            "3" { Show-SystemHealth }
            "4" { Start-ContinuousMonitoring }
            "5" { Export-TemperatureLog }
            "6" {
                Get-CPUTemperature
                Get-SystemTemperatures
                Show-SystemHealth
                Export-TemperatureLog
            }
            "7" { 
                if (Test-Path $logPath) {
                    Write-Host "`n📄 CONȚINUT LOG INTERN:" -ForegroundColor Yellow
                    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
                    Get-Content $logPath | ForEach-Object { Write-Host $_ }
                    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
                } else {
                    Write-Host "❌ Log-ul intern nu a fost găsit!" -ForegroundColor Red
                }
            }
            "0" { break }
            default {
                Write-Log "Opțiune invalidă selectată: $choice" "ERROR"
                Write-Host "❌ Opțiune invalidă!" -ForegroundColor Red
                Start-Sleep 2
                continue
            }
        }

        if ($choice -ne "0" -and $choice -ne "4" -and $choice -ne "7") {
            Write-Host ""
            Write-Host "✅ Operațiune completă! Apasă Enter pentru a continua..." -ForegroundColor Green
            Read-Host
        }
    } while ($choice -ne "0")
    
    Write-Log "Aplicație monitorizare temperatură închisă" "INFO"
}

# Rulează funcția principală dacă script-ul este executat direct
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Show-TemperatureMonitoringMenu
}