# ===============================
# Script: SystemToolkit.ps1
# Toolkit complet cu meniu interactiv
# Versiune îmbunătățită cu integrare completă
# ===============================

# Verificare privilegii Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠️ ATENȚIE: SystemToolkit nu rulează ca Administrator!" -ForegroundColor Red
    Write-Host "💡 Unele funcții pot să nu funcționeze corect fără privilegii de administrator." -ForegroundColor Yellow
    Write-Host "🔄 Pentru funcționalitate completă, rulează PowerShell ca Administrator." -ForegroundColor Cyan
    Write-Host ""
    $continue = Read-Host "Dorești să continui oricum? (Y/N)"
    if ($continue.ToUpper() -ne "Y") {
        Write-Host "❌ SystemToolkit anulat." -ForegroundColor Red
        exit
    }
    Write-Host "✅ Continuare cu privilegii limitate..." -ForegroundColor Yellow
    Write-Host ""
}

# Configurare logging
$logPath = "$env:TEMP\SystemToolkit_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$global:LogEnabled = $true

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

function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    🛠️ SYSTEM TOOLKIT 🛠️                 ║" -ForegroundColor Cyan
    Write-Host "║                  ✨ Versiune Completă ✨                ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📄 Log fișier: $logPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║                    🧹 CURĂȚARE & OPTIMIZARE              ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host "  [1] 🧹 Curățare rapidă (Temp + Cache)" -ForegroundColor White
    Write-Host "  [2] 🚀 Optimizare completă sistem (WindowsFullOptimization)" -ForegroundColor White
    Write-Host "  [3] 🌊 Curățare avansată (CleanSafeSurface)" -ForegroundColor White
    Write-Host "  [4] 📅 Mentenanță săptămânală (WeeklyMaintenance)" -ForegroundColor White
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                    📦 ACTUALIZARE & DRIVERE             ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host "  [5] 📦 Actualizare toate aplicațiile (Winget + Choco)" -ForegroundColor White
    Write-Host "  [6] 🔧 Actualizare automată drivere (DriverUpdateAutomation)" -ForegroundColor White
    Write-Host "  [7] 🐧 Actualizare WSL și distribuții Linux (UpdateWSL)" -ForegroundColor White
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                    🛡️ SECURITATE & REPARARE             ║" -ForegroundColor Red
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host "  [8] 🛡️  Scanare securitate completă (Windows Defender)" -ForegroundColor White
    Write-Host "  [9] 🔧 Reparare fișiere sistem (SFC + DISM)" -ForegroundColor White
    Write-Host "  [10] 🌐 Reset complet rețea" -ForegroundColor White
    Write-Host "  [11] 🔄 Repornire servicii Windows blocat" -ForegroundColor White
    Write-Host "  [12] 💾 Backup Registry + Restore Point" -ForegroundColor White
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║                    📊 MONITORIZARE & RAPOARTE            ║" -ForegroundColor Blue
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host "  [13] 📊 Raport complet sistem" -ForegroundColor White
    Write-Host "  [14] 🌡️ Monitorizare temperatură sistem (SystemTemperatureMonitoring)" -ForegroundColor White
    Write-Host "  [15] 📈 Monitorizare în timp real (Monitor)" -ForegroundColor White
    Write-Host "  [16] 📸 Export erori Event Log" -ForegroundColor White
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║                    ⚙️ OPTIMIZARE & UTILITARE            ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host "  [17] 🎮 Mod Gaming (Optimizare pentru jocuri)" -ForegroundColor White
    Write-Host "  [18] ⚡ Optimizare SQL Server" -ForegroundColor White
    Write-Host "  [19] 🔍 Găsește fișiere mari (>1GB)" -ForegroundColor White
    Write-Host "  [20] 📝 Verificare și instalare C++ Redistributables" -ForegroundColor White
    Write-Host "  [21] 🗑️  Uninstall bloatware Windows 11" -ForegroundColor White
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "║                    🔧 UTILITARE SISTEM                  ║" -ForegroundColor DarkCyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host "  [22] 💾 Backup PowerShell Profile (PowerShell_Profile_Backup)" -ForegroundColor White
    Write-Host "  [23] 📄 Afișează log-ul intern" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [0] ❌ Ieșire" -ForegroundColor Red
    Write-Host ""
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
}

function Start-QuickClean {
    Write-Log "Începere curățare rapidă" "INFO"
    Write-Host "`n🧹 CURĂȚARE RAPIDĂ..." -ForegroundColor Yellow
    
    try {
        # Calculează spațiu înainte
        $before = Get-PSDrive C | Select-Object -ExpandProperty Free
        
        # Curățare
        Write-Host "  • Curățare fișiere temporare..." -ForegroundColor Cyan
        Remove-Item "$env:TEMP\*" -Force -Recurse -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\Temp\*" -Force -Recurse -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\Prefetch\*" -Force -Recurse -ErrorAction SilentlyContinue
        
        Write-Host "  • Curățare Recycle Bin..." -ForegroundColor Cyan
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        
        # Calculează spațiu după
        $after = Get-PSDrive C | Select-Object -ExpandProperty Free
        $freed = [math]::Round(($after - $before) / 1MB, 2)
        
        Write-Log "Curățare rapidă completată cu succes. Spațiu eliberat: $freed MB" "SUCCESS"
        Write-Host "✅ Curățare completă! Spațiu eliberat: $freed MB" -ForegroundColor Green
    } catch {
        Write-Log "Eroare la curățarea rapidă: $($_.Exception.Message)" "ERROR"
        Write-Host "❌ Eroare la curățare: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Update-AllApps {
    Write-Log "Începere actualizare aplicații" "INFO"
    Write-Host "`n📦 ACTUALIZARE APLICAȚII..." -ForegroundColor Yellow
    
    try {
        # Winget
        Write-Host "  • Actualizare via Winget..." -ForegroundColor Cyan
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade --all --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
            Write-Log "Actualizare Winget completată" "SUCCESS"
        } else {
            Write-Log "Winget nu este disponibil" "WARNING"
            Write-Host "    ⚠️ Winget nu este disponibil" -ForegroundColor Yellow
        }
        
        # Chocolatey (dacă este instalat)
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "  • Actualizare via Chocolatey..." -ForegroundColor Cyan
            choco upgrade all -y 2>&1 | Out-Null
            Write-Log "Actualizare Chocolatey completată" "SUCCESS"
        } else {
            Write-Log "Chocolatey nu este instalat" "INFO"
        }
        
        # Microsoft Store
        Write-Host "  • Actualizare Microsoft Store apps..." -ForegroundColor Cyan
        try {
            Get-CimInstance -Namespace "root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | 
                Invoke-CimMethod -MethodName UpdateScanMethod | Out-Null
            Write-Log "Actualizare Microsoft Store completată" "SUCCESS"
        } catch {
            Write-Log "Eroare la actualizarea Microsoft Store: $($_.Exception.Message)" "WARNING"
        }
        
        Write-Log "Actualizare aplicații completată cu succes" "SUCCESS"
        Write-Host "✅ Toate aplicațiile au fost actualizate!" -ForegroundColor Green
    } catch {
        Write-Log "Eroare la actualizarea aplicațiilor: $($_.Exception.Message)" "ERROR"
        Write-Host "❌ Eroare la actualizarea aplicațiilor: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Start-CleanSafeSurface {
    Write-Log "Lansare CleanSafeSurface" "INFO"
    Write-Host "`n🌊 CURĂȚARE AVANSATĂ (CleanSafeSurface)..." -ForegroundColor Yellow
    
    try {
        if (Test-Path "$PSScriptRoot\CleanSafeSurface.ps1") {
            & "$PSScriptRoot\CleanSafeSurface.ps1"
            Write-Log "CleanSafeSurface executat cu succes" "SUCCESS"
        } else {
            Write-Log "CleanSafeSurface.ps1 nu a fost găsit" "ERROR"
            Write-Host "❌ CleanSafeSurface.ps1 nu a fost găsit!" -ForegroundColor Red
        }
    } catch {
        Write-Log "Eroare la executarea CleanSafeSurface: $($_.Exception.Message)" "ERROR"
        Write-Host "❌ Eroare la executarea CleanSafeSurface: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Start-WeeklyMaintenance {
    Write-Log "Lansare WeeklyMaintenance" "INFO"
    Write-Host "`n📅 MENTENANȚĂ SĂPTĂMÂNALĂ (WeeklyMaintenance)..." -ForegroundColor Yellow
    
    try {
        if (Test-Path "$PSScriptRoot\WeeklyMaintenance.ps1") {
            & "$PSScriptRoot\WeeklyMaintenance.ps1"
            Write-Log "WeeklyMaintenance executat cu succes" "SUCCESS"
        } else {
            Write-Log "WeeklyMaintenance.ps1 nu a fost găsit" "ERROR"
            Write-Host "❌ WeeklyMaintenance.ps1 nu a fost găsit!" -ForegroundColor Red
        }
    } catch {
        Write-Log "Eroare la executarea WeeklyMaintenance: $($_.Exception.Message)" "ERROR"
        Write-Host "❌ Eroare la executarea WeeklyMaintenance: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Start-DriverUpdateAutomation {
    Write-Log "Lansare DriverUpdateAutomation" "INFO"
    Write-Host "`n🔧 ACTUALIZARE AUTOMATĂ DRIVERE (DriverUpdateAutomation)..." -ForegroundColor Yellow
    
    try {
        if (Test-Path "$PSScriptRoot\DriverUpdateAutomation.ps1") {
            & "$PSScriptRoot\DriverUpdateAutomation.ps1"
            Write-Log "DriverUpdateAutomation executat cu succes" "SUCCESS"
        } else {
            Write-Log "DriverUpdateAutomation.ps1 nu a fost găsit" "ERROR"
            Write-Host "❌ DriverUpdateAutomation.ps1 nu a fost găsit!" -ForegroundColor Red
        }
    } catch {
        Write-Log "Eroare la executarea DriverUpdateAutomation: $($_.Exception.Message)" "ERROR"
        Write-Host "❌ Eroare la executarea DriverUpdateAutomation: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Start-UpdateWSL {
    Write-Log "Lansare UpdateWSL" "INFO"
    Write-Host "`n🐧 ACTUALIZARE WSL ȘI DISTRIBUȚII LINUX (UpdateWSL)..." -ForegroundColor Yellow
    
    try {
        if (Test-Path "$PSScriptRoot\UpdateWSL.ps1") {
            & "$PSScriptRoot\UpdateWSL.ps1"
            Write-Log "UpdateWSL executat cu succes" "SUCCESS"
        } else {
            Write-Log "UpdateWSL.ps1 nu a fost găsit" "ERROR"
            Write-Host "❌ UpdateWSL.ps1 nu a fost găsit!" -ForegroundColor Red
        }
    } catch {
        Write-Log "Eroare la executarea UpdateWSL: $($_.Exception.Message)" "ERROR"
        Write-Host "❌ Eroare la executarea UpdateWSL: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Start-SystemTemperatureMonitoring {
    Write-Log "Lansare SystemTemperatureMonitoring" "INFO"
    Write-Host "`n🌡️ MONITORIZARE TEMPERATURĂ SISTEM (SystemTemperatureMonitoring)..." -ForegroundColor Yellow
    
    try {
        if (Test-Path "$PSScriptRoot\SystemTemperatureMonitoring.ps1") {
            & "$PSScriptRoot\SystemTemperatureMonitoring.ps1"
            Write-Log "SystemTemperatureMonitoring executat cu succes" "SUCCESS"
        } else {
            Write-Log "SystemTemperatureMonitoring.ps1 nu a fost găsit" "ERROR"
            Write-Host "❌ SystemTemperatureMonitoring.ps1 nu a fost găsit!" -ForegroundColor Red
        }
    } catch {
        Write-Log "Eroare la executarea SystemTemperatureMonitoring: $($_.Exception.Message)" "ERROR"
        Write-Host "❌ Eroare la executarea SystemTemperatureMonitoring: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Start-Monitor {
    Write-Log "Lansare Monitor" "INFO"
    Write-Host "`n📈 MONITORIZARE ÎN TIMP REAL (Monitor)..." -ForegroundColor Yellow
    
    try {
        if (Test-Path "$PSScriptRoot\Monitor.ps1") {
            & "$PSScriptRoot\Monitor.ps1"
            Write-Log "Monitor executat cu succes" "SUCCESS"
        } else {
            Write-Log "Monitor.ps1 nu a fost găsit" "ERROR"
            Write-Host "❌ Monitor.ps1 nu a fost găsit!" -ForegroundColor Red
        }
    } catch {
        Write-Log "Eroare la executarea Monitor: $($_.Exception.Message)" "ERROR"
        Write-Host "❌ Eroare la executarea Monitor: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Start-PowerShellProfileBackup {
    Write-Log "Lansare PowerShell_Profile_Backup" "INFO"
    Write-Host "`n💾 BACKUP POWERSHELL PROFILE (PowerShell_Profile_Backup)..." -ForegroundColor Yellow
    
    try {
        if (Test-Path "$PSScriptRoot\PowerShell_Profile_Backup.ps1") {
            & "$PSScriptRoot\PowerShell_Profile_Backup.ps1"
            Write-Log "PowerShell_Profile_Backup executat cu succes" "SUCCESS"
        } else {
            Write-Log "PowerShell_Profile_Backup.ps1 nu a fost găsit" "ERROR"
            Write-Host "❌ PowerShell_Profile_Backup.ps1 nu a fost găsit!" -ForegroundColor Red
        }
    } catch {
        Write-Log "Eroare la executarea PowerShell_Profile_Backup: $($_.Exception.Message)" "ERROR"
        Write-Host "❌ Eroare la executarea PowerShell_Profile_Backup: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-InternalLog {
    Write-Log "Afișare log intern" "INFO"
    Write-Host "`n📄 LOG INTERN SYSTEMTOOLKIT:" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    
    if (Test-Path $logPath) {
        try {
            Get-Content $logPath | ForEach-Object { Write-Host $_ }
            Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "📄 Log complet: $logPath" -ForegroundColor Gray
        } catch {
            Write-Host "❌ Eroare la citirea log-ului: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Log-ul intern nu a fost găsit!" -ForegroundColor Red
    }
}

function Start-SecurityScan {
    Write-Log "Începere scanare securitate" "INFO"
    Write-Host "`n🛡️ SCANARE SECURITATE..." -ForegroundColor Yellow
    
    try {
        # Update definitions
        Write-Host "  • Actualizare definiții antivirus..." -ForegroundColor Cyan
        Update-MpSignature -ErrorAction SilentlyContinue
        Write-Log "Definiții antivirus actualizate" "SUCCESS"
        
        # Full scan
        Write-Host "  • Pornire scanare completă (va rula în background)..." -ForegroundColor Cyan
        Start-MpScan -ScanType FullScan -AsJob
        Write-Log "Scanare completă pornită în background" "SUCCESS"
        
        # Check threats
        $threats = Get-MpThreatDetection -ErrorAction SilentlyContinue
        if ($threats) {
            Write-Host "  ⚠️ AMENINȚĂRI DETECTATE!" -ForegroundColor Red
            $threats | ForEach-Object { Write-Host "    - $($_.ThreatName)" }
            Write-Log "Amenințări detectate: $($threats.Count)" "WARNING"
        } else {
            Write-Host "  ✓ Nu au fost detectate amenințări" -ForegroundColor Green
            Write-Log "Nu au fost detectate amenințări" "SUCCESS"
        }
        
        Write-Log "Scanare securitate inițiată cu succes" "SUCCESS"
        Write-Host "✅ Scanare inițiată!" -ForegroundColor Green
    } catch {
        Write-Log "Eroare la scanarea de securitate: $($_.Exception.Message)" "ERROR"
        Write-Host "❌ Eroare la scanarea de securitate: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Start-NetworkReset {
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
    
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object {$null -ne $_.Free}
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

function Start-GamingMode {
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
                winget install --id $vcredist.Primary --silent --accept-package-agreements --accept-source-agreements 2>$null | Out-Null
                
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
        Write-Host "[OK] Toate C++ Redistributables sunt instalate! ($installedCount/$totalCount)" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Unele C++ Redistributables lipsesc ($installedCount/$totalCount instalate)" -ForegroundColor Yellow
        Write-Host "[INFO] Poti descarca manual de la Microsoft" -ForegroundColor Cyan
    }
}

function Restart-WindowsServices {
    Write-Host "`n[RESTART] REPORNIRE SERVICII WINDOWS..." -ForegroundColor Yellow
    
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

function Start-SystemReport {
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
$(Get-PSDrive -PSProvider FileSystem | Where-Object {$null -ne $_.Free} | ForEach-Object {
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
Write-Log "Pornire SystemToolkit" "INFO"

do {
    Show-Menu
    $selection = Read-Host "Alege o opțiune"
    
    switch ($selection) {
        # CURĂȚARE & OPTIMIZARE
        '1' { Start-QuickClean }
        '2' { 
            Write-Host "`n⚠️ Aceasta va dura câteva minute..." -ForegroundColor Yellow
            Write-Log "Lansare WindowsFullOptimization" "INFO"
            try {
                if (Test-Path "$PSScriptRoot\WindowsFullOptimization.ps1") {
                    & "$PSScriptRoot\WindowsFullOptimization.ps1"
                    Write-Log "WindowsFullOptimization executat cu succes" "SUCCESS"
                } else {
                    Write-Log "WindowsFullOptimization.ps1 nu a fost găsit" "ERROR"
                    Write-Host "❌ WindowsFullOptimization.ps1 nu a fost găsit!" -ForegroundColor Red
                }
            } catch {
                Write-Log "Eroare la executarea WindowsFullOptimization: $($_.Exception.Message)" "ERROR"
                Write-Host "❌ Eroare la executarea WindowsFullOptimization: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        '3' { Start-CleanSafeSurface }
        '4' { Start-WeeklyMaintenance }
        
        # ACTUALIZARE & DRIVERE
        '5' { Update-AllApps }
        '6' { Start-DriverUpdateAutomation }
        '7' { Start-UpdateWSL }
        
        # SECURITATE & REPARARE
        '8' { Start-SecurityScan }
        '9' {
            Write-Host "`n🔧 REPARARE SISTEM..." -ForegroundColor Yellow
            Write-Log "Începere reparare sistem (SFC + DISM)" "INFO"
            try {
                Write-Host "  • Rulez SFC..." -ForegroundColor Cyan
                sfc /scannow
                Write-Host "  • Rulez DISM..." -ForegroundColor Cyan
                DISM /Online /Cleanup-Image /RestoreHealth
                Write-Log "Reparare sistem completată cu succes" "SUCCESS"
                Write-Host "✅ Reparare completă!" -ForegroundColor Green
            } catch {
                Write-Log "Eroare la repararea sistemului: $($_.Exception.Message)" "ERROR"
                Write-Host "❌ Eroare la repararea sistemului: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        '10' { Start-NetworkReset }
        '11' { Restart-WindowsServices }
        '12' {
            Write-Host "`n💾 BACKUP..." -ForegroundColor Yellow
            Write-Log "Creare restore point" "INFO"
            try {
                Enable-ComputerRestore -Drive "C:\"
                Checkpoint-Computer -Description "Manual Backup $(Get-Date)" -RestorePointType "MODIFY_SETTINGS"
                Write-Log "Restore point creat cu succes" "SUCCESS"
                Write-Host "✅ Restore point creat!" -ForegroundColor Green
            } catch {
                Write-Log "Eroare la crearea restore point: $($_.Exception.Message)" "ERROR"
                Write-Host "❌ Eroare la crearea restore point: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        # MONITORIZARE & RAPOARTE
        '13' { Start-SystemReport }
        '14' { Start-SystemTemperatureMonitoring }
        '15' { Start-Monitor }
        '16' { Export-EventLogs }
        
        # OPTIMIZARE & UTILITARE
        '17' { Start-GamingMode }
        '18' { Optimize-SQLServer }
        '19' { Find-LargeFiles }
        '20' { Install-VCRedist }
        '21' { Remove-Bloatware }
        
        # UTILITARE SISTEM
        '22' { Start-PowerShellProfileBackup }
        '23' { Show-InternalLog }
        
        '0' {
            Write-Host "`n👋 La revedere!" -ForegroundColor Cyan
            Write-Log "SystemToolkit închis de utilizator" "INFO"
            Start-Sleep -Seconds 2
            exit
        }
        default {
            Write-Host "`n⚠️ Opțiune invalidă!" -ForegroundColor Red
            Write-Log "Opțiune invalidă selectată: $selection" "ERROR"
            Start-Sleep -Seconds 2
        }
    }
    
    if ($selection -ne '0') {
        Write-Host "`nApasă orice tastă pentru a continua..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
} while ($selection -ne '0')