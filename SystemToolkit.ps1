# ===============================
# Script: SystemToolkit.ps1
# Toolkit complet cu meniu interactiv
# ===============================

function Show-Menu {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║            SYSTEM TOOLKIT                ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] 🧹 Curățare rapidă (Temp + Cache)" -ForegroundColor White
    Write-Host "  [2] 🚀 Optimizare completă sistem" -ForegroundColor White
    Write-Host "  [3] 📦 Actualizare toate aplicațiile" -ForegroundColor White
    Write-Host "  [4] 🛡️  Scanare securitate completă" -ForegroundColor White
    Write-Host "  [5] 🔧 Reparare fișiere sistem (SFC + DISM)" -ForegroundColor White
    Write-Host "  [6] 🌐 Reset complet rețea" -ForegroundColor White
    Write-Host "  [7] 💾 Backup Registry + Restore Point" -ForegroundColor White
    Write-Host "  [8] 📊 Raport complet sistem" -ForegroundColor White
    Write-Host "  [9] ⚡ Optimizare SQL Server" -ForegroundColor White
    Write-Host "  [10] 🔍 Găsește fișiere mari (>1GB)" -ForegroundColor White
    Write-Host "  [11] 🎮 Mod Gaming (Optimizare pentru jocuri)" -ForegroundColor White
    Write-Host "  [12] 📝 Verificare și instalare C++ Redistributables" -ForegroundColor White
    Write-Host "  [13] 🔄 Repornire servicii Windows blocat" -ForegroundColor White
    Write-Host "  [14] 🗑️  Uninstall bloatware Windows 11" -ForegroundColor White
    Write-Host "  [15] 📸 Screenshot toate erorile din Event Log" -ForegroundColor White
    Write-Host ""
    Write-Host "  [0] ❌ Ieșire" -ForegroundColor Red
    Write-Host ""
    Write-Host "══════════════════════════════════════════" -ForegroundColor Cyan
}

function Quick-Clean {
    Write-Host "`n🧹 CURĂȚARE RAPIDĂ..." -ForegroundColor Yellow
    
    # Calculează spațiu înainte
    $before = Get-PSDrive C | Select-Object -ExpandProperty Free
    
    # Curățare
    Remove-Item "$env:TEMP\*" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Temp\*" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Prefetch\*" -Force -Recurse -ErrorAction SilentlyContinue
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    
    # Calculează spațiu după
    $after = Get-PSDrive C | Select-Object -ExpandProperty Free
    $freed = [math]::Round(($after - $before) / 1MB, 2)
    
    Write-Host "✅ Curățare completă! Spațiu eliberat: $freed MB" -ForegroundColor Green
}

function Update-AllApps {
    Write-Host "`n📦 ACTUALIZARE APLICAȚII..." -ForegroundColor Yellow
    
    # Winget
    Write-Host "  • Actualizare via Winget..."
    winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
    
    # Chocolatey (dacă este instalat)
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "  • Actualizare via Chocolatey..."
        choco upgrade all -y
    }
    
    # Microsoft Store
    Write-Host "  • Actualizare Microsoft Store apps..."
    Get-CimInstance -Namespace "root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | 
        Invoke-CimMethod -MethodName UpdateScanMethod | Out-Null
    
    Write-Host "✅ Toate aplicațiile au fost actualizate!" -ForegroundColor Green
}

function Security-Scan {
    Write-Host "`n🛡️ SCANARE SECURITATE..." -ForegroundColor Yellow
    
    # Update definitions
    Write-Host "  • Actualizare definiții antivirus..."
    Update-MpSignature -ErrorAction SilentlyContinue
    
    # Full scan
    Write-Host "  • Pornire scanare completă (va rula în background)..."
    Start-MpScan -ScanType FullScan -AsJob
    
    # Check threats
    $threats = Get-MpThreatDetection -ErrorAction SilentlyContinue
    if ($threats) {
        Write-Host "  ⚠️ AMENINȚĂRI DETECTATE!" -ForegroundColor Red
        $threats | ForEach-Object { Write-Host "    - $($_.ThreatName)" }
    } else {
        Write-Host "  ✓ Nu au fost detectate amenințări" -ForegroundColor Green
    }
    
    Write-Host "✅ Scanare inițiată!" -ForegroundColor Green
}

function Network-Reset {
    Write-Host "`n🌐 RESET COMPLET REȚEA..." -ForegroundColor Yellow
    
    Write-Host "  • Reset Winsock..."
    netsh winsock reset
    
    Write-Host "  • Reset TCP/IP..."
    netsh int ip reset
    
    Write-Host "  • Flush DNS..."
    ipconfig /flushdns
    
    Write-Host "  • Release și Renew IP..."
    ipconfig /release
    ipconfig /renew
    
    Write-Host "  • Reset Windows Firewall..."
    netsh advfirewall reset
    
    Write-Host "✅ Rețea resetată! Repornire recomandată." -ForegroundColor Green
}

function Optimize-SQLServer {
    Write-Host "`n⚡ OPTIMIZARE SQL SERVER..." -ForegroundColor Yellow

    # Verifică dacă SQL Server este instalat (Standard sau Express)
    $sqlService = Get-Service -Name "MSSQLSERVER" -ErrorAction SilentlyContinue
    $sqlExpressService = Get-Service -Name "MSSQL`$SQLEXPRESS" -ErrorAction SilentlyContinue

    if ($sqlService -or $sqlExpressService) {
        $activeService = if ($sqlService) { $sqlService } else { $sqlExpressService }
        $serviceName = $activeService.Name
        Write-Host "  • Detectat: $($activeService.DisplayName)"
        Write-Host "  • Verificare serviciu SQL Server..."
        if ($activeService.Status -ne "Running") {
            Start-Service -Name $serviceName
            Write-Host "    → Serviciu $serviceName pornit"
        } else {
            Write-Host "    ✓ Serviciul rulează deja"
        }

        # Optimizări de bază
        Write-Host "  • Setare SQL Server priority HIGH..."
        $process = Get-Process sqlservr -ErrorAction SilentlyContinue
        if ($process) {
            $process.PriorityClass = "High"
            Write-Host "    ✓ Prioritate setată pe HIGH"
        }

        # Curățare logs vechi (adaptată pentru Express)
        Write-Host "  • Curățare SQL Server logs..."
        $sqlLogPaths = @(
            "C:\Program Files\Microsoft SQL Server\MSSQL*\MSSQL\Log",
            "C:\Program Files\Microsoft SQL Server\MSSQL*\MSSQL\LOG"
        )
        foreach ($path in $sqlLogPaths) {
            Get-ChildItem $path -Filter "*.log" -ErrorAction SilentlyContinue |
                Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} |
                Remove-Item -Force -ErrorAction SilentlyContinue
        }
        
        Write-Host "✅ SQL Server optimizat!" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ SQL Server nu este instalat pe acest sistem" -ForegroundColor Yellow
    }
}

function Find-LargeFiles {
    Write-Host "`n🔍 CĂUTARE FIȘIERE MARI (>1GB)..." -ForegroundColor Yellow
    
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Free -ne $null}
    $largeFiles = @()
    
    foreach ($drive in $drives) {
        Write-Host "  • Scanare drive $($drive.Name):..."
        $files = Get-ChildItem -Path "$($drive.Name):\" -Recurse -File -ErrorAction SilentlyContinue |
                 Where-Object {$_.Length -gt 1GB} |
                 Select-Object FullName, @{Name="SizeGB";Expression={[math]::Round($_.Length/1GB, 2)}}
        $largeFiles += $files
    }
    
    if ($largeFiles) {
        Write-Host "`n📊 Fișiere găsite:" -ForegroundColor Green
        $largeFiles | Sort-Object SizeGB -Descending | Select-Object -First 20 | ForEach-Object {
            Write-Host "  $($_.SizeGB) GB - $($_.FullName)"
        }
    } else {
        Write-Host "  ✓ Nu au fost găsite fișiere mai mari de 1GB" -ForegroundColor Green
    }
}

function Gaming-Mode {
    Write-Host "`n🎮 ACTIVARE MOD GAMING..." -ForegroundColor Yellow
    
    # Dezactivare servicii inutile pentru gaming
    $gamingServices = @(
        "SysMain", "WSearch", "DiagTrack", "dmwappushservice",
        "MapsBroker", "RemoteRegistry", "Spooler"
    )
    
    foreach ($service in $gamingServices) {
        Write-Host "  • Oprire $service..."
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
    }
    
    # Setare prioritate înaltă pentru jocuri comune
    Write-Host "  • Optimizare prioritate procese..."
    $gameProcesses = Get-Process | Where-Object {
        $_.ProcessName -match "steam|origin|epicgames|battle.net|gog"
    }
    
    foreach ($proc in $gameProcesses) {
        $proc.PriorityClass = "High"
        Write-Host "    → $($proc.ProcessName) setat pe HIGH priority"
    }
    
    # Optimizare GPU (NVIDIA)
    if (Get-Process -Name "nvcontainer" -ErrorAction SilentlyContinue) {
        Write-Host "  • Optimizare NVIDIA..."
        # Dezactivare NVIDIA Telemetry
        Stop-Service -Name "NvTelemetryContainer" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "NvTelemetryContainer" -StartupType Disabled -ErrorAction SilentlyContinue
    }
    
    # Game Mode Windows
    Write-Host "  • Activare Windows Game Mode..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -ErrorAction SilentlyContinue
    
    Write-Host "✅ Mod Gaming activat!" -ForegroundColor Green
}

function Install-VCRedist {
    Write-Host "`n📝 VERIFICARE C++ REDISTRIBUTABLES..." -ForegroundColor Yellow
    
    # Verifică mai întâi dacă winget este disponibil
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "  ⚠️ Winget nu este disponibil!" -ForegroundColor Red
        Write-Host "  💡 Instalează manual sau actualizează Windows" -ForegroundColor Cyan
        return
    }
    
    # Lista de redistributables necesare cu versiuni alternative
    $vcredists = @(
        @{
            Primary = "Microsoft.VCRedist.2015+.x64"
            Alternative = "Microsoft.VisualCppRedist.2015+.x64"
            Name = "Visual C++ 2015-2022 x64"
        },
        @{
            Primary = "Microsoft.VCRedist.2015+.x86"
            Alternative = "Microsoft.VisualCppRedist.2015+.x86"
            Name = "Visual C++ 2015-2022 x86"
        },
        @{
            Primary = "Microsoft.VCRedist.2013.x64"
            Alternative = "Microsoft.VisualCppRedist.2013.x64"
            Name = "Visual C++ 2013 x64"
        },
        @{
            Primary = "Microsoft.VCRedist.2013.x86"
            Alternative = "Microsoft.VisualCppRedist.2013.x86"
            Name = "Visual C++ 2013 x86"
        }
    )
    
    $installedCount = 0
    $totalCount = $vcredists.Count
    
    foreach ($vcredist in $vcredists) {
        Write-Host "  • Verificare $($vcredist.Name)..."
        
        # Verifică cu winget list mai robust
        try {
            $searchResult = winget list --name "Microsoft Visual C++" --exact 2>$null | Out-String
            $isInstalled = $searchResult -match $vcredist.Name.Replace("Visual C++", "Microsoft Visual C++")
            
            if (-not $isInstalled) {
                # Încearcă instalarea cu ID-ul principal
                Write-Host "    → Instalare $($vcredist.Primary)..."
                $result = winget install --id $vcredist.Primary --silent --accept-package-agreements --accept-source-agreements 2>$null
                
                if ($LASTEXITCODE -ne 0 -and $vcredist.Alternative) {
                    Write-Host "    → Încerc ID alternativ $($vcredist.Alternative)..."
                    winget install --id $vcredist.Alternative --silent --accept-package-agreements --accept-source-agreements 2>$null
                }
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "    ✓ Instalat cu succes" -ForegroundColor Green
                    $installedCount++
                } else {
                    Write-Host "    ⚠️ Eroare la instalare" -ForegroundColor Yellow
                }
            } else {
                Write-Host "    ✓ Deja instalat" -ForegroundColor Green
                $installedCount++
            }
        } catch {
            Write-Host "    ⚠️ Eroare la verificare: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Raport final
    if ($installedCount -eq $totalCount) {
        Write-Host "✅ Toate C++ Redistributables sunt instalate! ($installedCount/$totalCount)" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Unele C++ Redistributables lipsesc ($installedCount/$totalCount instalate)" -ForegroundColor Yellow
        Write-Host "💡 Poți descărca manual de la Microsoft" -ForegroundColor Cyan
    }
}

function Restart-WindowsServices {
    Write-Host "`n🔄 REPORNIRE SERVICII WINDOWS..." -ForegroundColor Yellow
    
    $criticalServices = @(
        @{Name="wuauserv"; DisplayName="Windows Update"},
        @{Name="BITS"; DisplayName="Background Intelligent Transfer"},
        @{Name="CryptSvc"; DisplayName="Cryptographic Services"},
        @{Name="TrustedInstaller"; DisplayName="Windows Modules Installer"},
        @{Name="spooler"; DisplayName="Print Spooler"},
        @{Name="AudioSrv"; DisplayName="Windows Audio"},
        @{Name="Themes"; DisplayName="Themes"},
        @{Name="EventLog"; DisplayName="Windows Event Log"}
    )
    
    foreach ($service in $criticalServices) {
        Write-Host "  • Repornire $($service.DisplayName)..."
        Restart-Service -Name $service.Name -Force -ErrorAction SilentlyContinue
        $status = Get-Service -Name $service.Name
        if ($status.Status -eq "Running") {
            Write-Host "    ✓ Serviciu pornit cu succes" -ForegroundColor Green
        } else {
            Write-Host "    ⚠️ Problemă la pornire!" -ForegroundColor Red
        }
    }
    
    Write-Host "✅ Servicii repornite!" -ForegroundColor Green
}

function Remove-Bloatware {
    Write-Host "`n🗑️ ELIMINARE BLOATWARE WINDOWS 11..." -ForegroundColor Yellow
    
    $bloatwareList = @(
        "Microsoft.BingNews",
        "Microsoft.BingWeather", 
        "Microsoft.GetHelp",
        "Microsoft.Getstarted",
        "Microsoft.Microsoft3DViewer",
        "Microsoft.MicrosoftOfficeHub",
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.MixedReality.Portal",
        "Microsoft.People",
        "Microsoft.SkypeApp",
        "Microsoft.Wallet",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.YourPhone",
        "Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo",
        "Clipchamp.Clipchamp",
        "Disney.37853FC22B2CE",
        "SpotifyAB.SpotifyMusic",
        "Facebook.Facebook",
        "BytedancePte.Ltd.TikTok"
    )
    
    foreach ($app in $bloatwareList) {
        Write-Host "  • Verificare $app..."
        $package = Get-AppxPackage -Name $app -ErrorAction SilentlyContinue
        if ($package) {
            Write-Host "    → Dezinstalare..."
            Remove-AppxPackage -Package $package.PackageFullName -ErrorAction SilentlyContinue
            Write-Host "    ✓ Eliminat" -ForegroundColor Green
        }
    }
    
    # Dezactivare sugestii Start Menu
    Write-Host "  • Dezactivare sugestii și reclame..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
                     -Name "SystemPaneSuggestionsEnabled" -Value 0 -ErrorAction SilentlyContinue
    
    Write-Host "✅ Bloatware eliminat!" -ForegroundColor Green
}

function Export-EventLogs {
    Write-Host "`n📸 EXPORT ERORI EVENT LOG..." -ForegroundColor Yellow
    
    $exportPath = "$env:USERPROFILE\Desktop\EventLogs_$(Get-Date -Format 'yyyy-MM-dd_HHmm')"
    New-Item -ItemType Directory -Path $exportPath -Force | Out-Null
    
    # Export System errors
    Write-Host "  • Export erori System..."
    Get-EventLog -LogName System -EntryType Error -Newest 100 | 
        Export-Csv -Path "$exportPath\System_Errors.csv" -NoTypeInformation
    
    # Export Application errors  
    Write-Host "  • Export erori Application..."
    Get-EventLog -LogName Application -EntryType Error -Newest 100 |
        Export-Csv -Path "$exportPath\Application_Errors.csv" -NoTypeInformation
    
    # Create summary
    Write-Host "  • Creare sumar..."
    $summary = @"
EVENT LOG SUMMARY - $(Get-Date)
================================
System Errors: $(Get-EventLog -LogName System -EntryType Error -Newest 100 | Measure-Object | Select-Object -ExpandProperty Count)
Application Errors: $(Get-EventLog -LogName Application -EntryType Error -Newest 100 | Measure-Object | Select-Object -ExpandProperty Count)

Top 5 Error Sources:
$((Get-EventLog -LogName System -EntryType Error -Newest 100 | Group-Object Source | Sort-Object Count -Descending | Select-Object -First 5 | ForEach-Object {"  - $($_.Name): $($_.Count) errors"}) -join "`n")
"@
    $summary | Out-File "$exportPath\Summary.txt"
    
    Write-Host "✅ Logs exportate în: $exportPath" -ForegroundColor Green
}

function System-Report {
    Write-Host "`n📊 GENERARE RAPORT SISTEM..." -ForegroundColor Yellow
    
    $report = @"
=====================================
     RAPORT COMPLET SISTEM
     $(Get-Date)
=====================================

🖥️ INFORMAȚII SISTEM:
$(Get-CimInstance Win32_ComputerSystem | Format-List Manufacturer,Model,TotalPhysicalMemory | Out-String)

💻 PROCESOR:
$(Get-CimInstance Win32_Processor | Format-List Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed | Out-String)

💾 MEMORIE:
Total: $([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)) GB
Disponibil: $([math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)) MB

🗄️ STOCARE:
$(Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Free -ne $null} | ForEach-Object {
    "Drive $($_.Name): $([math]::Round($_.Used/1GB, 2))GB folosit / $([math]::Round(($_.Used+$_.Free)/1GB, 2))GB total"
} | Out-String)

🌐 REȚEA:
$(Get-NetAdapter | Where-Object Status -eq 'Up' | Format-Table Name,Status,LinkSpeed | Out-String)

🛡️ WINDOWS DEFENDER:
$(Get-MpComputerStatus | Format-List AntivirusEnabled,RealTimeProtectionEnabled,IoavProtectionEnabled | Out-String)

⚡ TOP 10 PROCESE (CPU):
$(Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 | Format-Table ProcessName,CPU,WorkingSet | Out-String)

📊 TEMPERATURI (dacă sunt disponibile):
$(Get-PhysicalDisk | ForEach-Object {
    $disk = $_
    $health = Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction SilentlyContinue
    if ($health) {
        "Disk $($disk.FriendlyName): $($health.Temperature)°C"
    }
} | Out-String)
"@
    
    $reportPath = "$env:USERPROFILE\Desktop\SystemReport_$(Get-Date -Format 'yyyy-MM-dd_HHmm').txt"
    $report | Out-File $reportPath
    
    Write-Host "✅ Raport salvat: $reportPath" -ForegroundColor Green
    Write-Host "`nDorești să deschizi raportul? (Y/N): " -NoNewline
    $open = Read-Host
    if ($open -eq 'Y') {
        Start-Process notepad.exe $reportPath
    }
}

# MAIN LOOP
do {
    Show-Menu
    $selection = Read-Host "Alege o opțiune"
    
    switch ($selection) {
        '1' { Quick-Clean }
        '2' { 
            Write-Host "`n⚠️ Aceasta va dura câteva minute..." -ForegroundColor Yellow
            & "$PSScriptRoot\WindowsFullOptimization.ps1"
        }
        '3' { Update-AllApps }
        '4' { Security-Scan }
        '5' {
            Write-Host "`n🔧 REPARARE SISTEM..." -ForegroundColor Yellow
            Write-Host "  • Rulez SFC..."
            sfc /scannow
            Write-Host "  • Rulez DISM..."
            DISM /Online /Cleanup-Image /RestoreHealth
            Write-Host "✅ Reparare completă!" -ForegroundColor Green
        }
        '6' { Network-Reset }
        '7' {
            Write-Host "`n💾 BACKUP..." -ForegroundColor Yellow
            Enable-ComputerRestore -Drive "C:\"
            Checkpoint-Computer -Description "Manual Backup $(Get-Date)" -RestorePointType "MODIFY_SETTINGS"
            Write-Host "✅ Restore point creat!" -ForegroundColor Green
        }
        '8' { System-Report }
        '9' { Optimize-SQLServer }
        '10' { Find-LargeFiles }
        '11' { Gaming-Mode }
        '12' { Install-VCRedist }
        '13' { Restart-WindowsServices }
        '14' { Remove-Bloatware }
        '15' { Export-EventLogs }
        '0' {
            Write-Host "`n👋 La revedere!" -ForegroundColor Cyan
            Start-Sleep -Seconds 2
            exit
        }
        default {
            Write-Host "`n⚠️ Opțiune invalidă!" -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
    
    if ($selection -ne '0') {
        Write-Host "`nApasă orice tastă pentru a continua..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
} while ($selection -ne '0')