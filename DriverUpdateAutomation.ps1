# ===============================
# Script: DriverUpdateAutomation.ps1
# Actualizare automată drivere sistem
# Versiune îmbunătățită cu logging și automatizare
# ===============================

# Necesită rulare ca Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "⚠️ Rulează PowerShell ca Administrator!" -ForegroundColor Red
    exit
}

# Configurare logging
$logPath = "$env:TEMP\DriverUpdate_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
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

function Update-SystemDrivers {
    Write-Log "Începere actualizare drivere prin Windows Update" "INFO"
    Write-Host "`n🔧 ACTUALIZARE AUTOMATĂ DRIVERE..." -ForegroundColor Yellow

    # Verifică Windows Update PowerShell Module
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Log "Instalare PSWindowsUpdate module" "INFO"
        try {
            Install-Module PSWindowsUpdate -Force -Scope CurrentUser
            Write-Log "PSWindowsUpdate instalat cu succes" "SUCCESS"
        }
        catch {
            Write-Log "Eroare la instalarea PSWindowsUpdate: $($_.Exception.Message)" "ERROR"
            return
        }
    }

    # Import module
    Import-Module PSWindowsUpdate -Force
    Write-Log "Module PSWindowsUpdate importat" "SUCCESS"

    Write-Log "Scanare drivere disponibile prin Windows Update" "INFO"

    # Scanează pentru drivere prin Windows Update
    try {
        $drivers = Get-WUList -Category "Drivers" -IsInstalled $false

        if ($drivers.Count -eq 0) {
            Write-Log "Toate driverele sunt actualizate" "SUCCESS"
            return
        }

        Write-Log "Găsite $($drivers.Count) drivere pentru actualizare" "INFO"
        Write-Host "`n📋 Drivere găsite pentru actualizare:" -ForegroundColor Yellow
        foreach ($driver in $drivers) {
            Write-Host "  • $($driver.Title)" -ForegroundColor White
            Write-Log "Driver disponibil: $($driver.Title)" "INFO"
        }

        # Confirmă actualizarea
        $response = Read-Host "`n❓ Dorești să instalezi aceste drivere? (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            Write-Log "Utilizatorul a confirmat instalarea driverelor" "INFO"
            Write-Host "`n⬇️ Descărcare și instalare drivere..." -ForegroundColor Cyan
            Install-WindowsUpdate -Category "Drivers" -AcceptAll -AutoReboot:$false
            Write-Log "Drivere instalate cu succes prin Windows Update" "SUCCESS"
            Write-Host "⚠️ Se recomandă repornirea sistemului." -ForegroundColor Yellow
        }
        else {
            Write-Log "Actualizare anulată de utilizator" "WARNING"
        }
    }
    catch {
        Write-Log "Eroare la scanarea driverelor: $($_.Exception.Message)" "ERROR"
    }
}

function Update-DriversWithPnpUtil {
    Write-Log "Începere actualizare drivere cu PnpUtil" "INFO"
    Write-Host "`n🔧 ACTUALIZARE DRIVERE CU PNPUTIL..." -ForegroundColor Yellow

    try {
        # Scanează pentru drivere cu probleme
        Write-Log "Scanare drivere cu probleme" "INFO"
        $problemDevices = Get-PnpDevice | Where-Object { $_.Status -eq "Error" -or $_.Status -eq "Unknown" }

        if ($problemDevices.Count -eq 0) {
            Write-Log "Nu sunt drivere cu probleme detectate" "SUCCESS"
        }
        else {
            Write-Log "Găsite $($problemDevices.Count) dispozitive cu probleme" "WARNING"
            Write-Host "`n⚠️ Dispozitive cu probleme găsite:" -ForegroundColor Yellow
            foreach ($device in $problemDevices) {
                Write-Host "  • $($device.FriendlyName) - Status: $($device.Status)" -ForegroundColor Red
                Write-Log "Dispozitiv cu probleme: $($device.FriendlyName) - Status: $($device.Status)" "WARNING"
            }
        }

        # Încearcă actualizarea automată prin PnpUtil
        Write-Log "Executare PnpUtil scan-devices" "INFO"
        & pnputil /scan-devices 2>&1 | Out-Null

        if ($LASTEXITCODE -eq 0) {
            Write-Log "Scanare completă prin PnpUtil reușită" "SUCCESS"
        }
        else {
            Write-Log "PnpUtil scanare completă cu warnings (Exit Code: $LASTEXITCODE)" "WARNING"
        }
    }
    catch {
        Write-Log "Eroare la actualizarea cu PnpUtil: $($_.Exception.Message)" "ERROR"
    }
}

function Show-DriverReport {
    Write-Log "Generare raport drivere sistem" "INFO"
    Write-Host "`n📊 RAPORT DRIVERE SISTEM..." -ForegroundColor Yellow

    try {
        # Obține toate driverele instalate folosind Get-CimInstance
        Write-Log "Colectare informații drivere cu Get-CimInstance" "INFO"
        $drivers = Get-CimInstance -ClassName Win32_PnPSignedDriver | Sort-Object DeviceName
        $totalDrivers = $drivers.Count

        Write-Log "Găsite $totalDrivers drivere instalate" "INFO"

        # Contorizează driverele după status
        $signedDrivers = ($drivers | Where-Object { $_.IsSigned -eq $true }).Count
        $unsignedDrivers = $totalDrivers - $signedDrivers

        # Afișează statistici
        Write-Host "`n📈 STATISTICI DRIVERE:" -ForegroundColor Cyan
        Write-Host "  • Total drivere instalate: $totalDrivers" -ForegroundColor White
        Write-Host "  • Drivere semnate digital: $signedDrivers" -ForegroundColor Green
        Write-Host "  • Drivere nesemnate: $unsignedDrivers" -ForegroundColor $(if($unsignedDrivers -gt 0) { "Yellow" } else { "Green" })

        Write-Log "Statistici: Total=$totalDrivers, Semnate=$signedDrivers, Nesemnate=$unsignedDrivers" "INFO"

        # Afișează driverele recente (ultimele 10)
        Write-Host "`n📅 DRIVERE INSTALATE RECENT (Top 10):" -ForegroundColor Cyan
        $recentDrivers = $drivers | Where-Object { $null -ne $_.DriverDate } |
                        Sort-Object @{Expression={[DateTime]$_.DriverDate}; Descending=$true} |
                        Select-Object -First 10

        foreach ($driver in $recentDrivers) {
            $date = if($driver.DriverDate) { ([DateTime]$driver.DriverDate).ToString("yyyy-MM-dd") } else { "N/A" }
            Write-Host "  • $($driver.DeviceName) - $date" -ForegroundColor White
            Write-Log "Driver recent: $($driver.DeviceName) - $date" "INFO"
        }

        # Verifică dispozitivele cu probleme
        Write-Host "`n⚠️ DISPOZITIVE CU PROBLEME:" -ForegroundColor Yellow
        $problemDevices = Get-PnpDevice | Where-Object { $_.Status -ne "OK" }

        if ($problemDevices.Count -eq 0) {
            Write-Log "Nu sunt dispozitive cu probleme" "SUCCESS"
        }
        else {
            Write-Log "Găsite $($problemDevices.Count) dispozitive cu probleme" "WARNING"
            foreach ($device in $problemDevices) {
                Write-Host "  • $($device.FriendlyName) - Status: $($device.Status)" -ForegroundColor Red
                Write-Log "Dispozitiv cu probleme: $($device.FriendlyName) - $($device.Status)" "WARNING"
            }
        }
        
        Write-Log "Raport drivere completat cu succes" "SUCCESS"
    }
    catch {
        Write-Log "Eroare la generarea raportului: $($_.Exception.Message)" "ERROR"
    }
}

function Update-DriversWithWinget {
    Write-Log "Începere actualizare drivere prin Winget" "INFO"
    Write-Host "`n🔧 VERIFICARE ACTUALIZĂRI DRIVERE PRIN WINGET..." -ForegroundColor Yellow

    try {
        # Verifică dacă winget este disponibil
        $wingetCheck = Get-Command winget -ErrorAction SilentlyContinue
        if (-not $wingetCheck) {
            Write-Log "Winget nu este disponibil pe acest sistem" "ERROR"
            return
        }

        Write-Log "Winget detectat, începere scanare" "SUCCESS"

        # Lista de drivere comune care pot fi actualizate prin winget
        $commonDrivers = @(
            "Nvidia.GeForceExperience",
            "AMD.AMDSoftwareAdrenalin",
            "Intel.IntelDriverAndSupportAssistant",
            "Realtek.AudioDriver",
            "Intel.GraphicsDriver"
        )

        Write-Log "Verificare $($commonDrivers.Count) drivere comune" "INFO"
        foreach ($driver in $commonDrivers) {
            Write-Log "Verificare disponibilitate: $driver" "INFO"
            winget show $driver 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Driver disponibil: $driver" "SUCCESS"
            }
            else {
                Write-Log "Driver nu este instalat/disponibil: $driver" "WARNING"
            }
        }

        # Încearcă actualizarea tuturor aplicațiilor (include și driverele)
        Write-Log "Executare actualizare completă prin Winget" "INFO"
        winget upgrade --all --silent --accept-source-agreements --accept-package-agreements | Out-Null

        Write-Log "Actualizare Winget completată cu succes" "SUCCESS"
    }
    catch {
        Write-Log "Eroare la actualizarea prin Winget: $($_.Exception.Message)" "ERROR"
    }
}

function Update-DriversWithChocolatey {
    Write-Log "Începere actualizare drivere prin Chocolatey" "INFO"
    Write-Host "`n🍫 VERIFICARE ACTUALIZĂRI DRIVERE PRIN CHOCOLATEY..." -ForegroundColor Yellow

    try {
        # Verifică dacă Chocolatey este instalat
        $chocoCheck = Get-Command choco -ErrorAction SilentlyContinue
        if (-not $chocoCheck) {
            Write-Log "Chocolatey nu este instalat pe acest sistem" "WARNING"
            Write-Host "💡 Dorești să instalezi Chocolatey? (Y/N)" -ForegroundColor Yellow
            $installChoco = Read-Host
            
            if ($installChoco -eq 'Y' -or $installChoco -eq 'y') {
                Write-Log "Instalare Chocolatey" "INFO"
                Set-ExecutionPolicy Bypass -Scope Process -Force
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                
                if (Get-Command choco -ErrorAction SilentlyContinue) {
                    Write-Log "Chocolatey instalat cu succes" "SUCCESS"
                } else {
                    Write-Log "Eroare la instalarea Chocolatey" "ERROR"
                    return
                }
            } else {
                Write-Log "Chocolatey nu a fost instalat, sări peste această secțiune" "INFO"
                return
            }
        }

        Write-Log "Chocolatey detectat, începere scanare" "SUCCESS"

        # Lista de pachete drivere comune în Chocolatey
        $chocoDrivers = @(
            "nvidia-display-driver",
            "amd-ryzen-chipset-driver",
            "intel-chipset-device-software",
            "realtek-audio-driver",
            "intel-graphics-driver"
        )

        Write-Log "Verificare $($chocoDrivers.Count) pachete drivere Chocolatey" "INFO"
        foreach ($package in $chocoDrivers) {
            Write-Log "Verificare pachet: $package" "INFO"
            $result = choco list $package --local-only 2>&1
            if ($LASTEXITCODE -eq 0 -and $result -match $package) {
                Write-Log "Pachet instalat găsit: $package" "SUCCESS"
            }
            else {
                Write-Log "Pachet nu este instalat: $package" "WARNING"
            }
        }

        # Actualizează toate pachetele instalate
        Write-Log "Executare actualizare completă prin Chocolatey" "INFO"
        choco upgrade all -y | Out-Null

        Write-Log "Actualizare Chocolatey completată cu succes" "SUCCESS"
    }
    catch {
        Write-Log "Eroare la actualizarea prin Chocolatey: $($_.Exception.Message)" "ERROR"
    }
}

function Start-AutomaticDriverUpdate {
    Write-Log "Începere actualizare automată completă" "INFO"
    Write-Host "`n🚀 RULARE AUTOMATĂ COMPLETĂ..." -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════" -ForegroundColor Magenta
    
    $startTime = Get-Date
    
    # Execută toate funcțiile în ordine
    Show-DriverReport
    Update-DriversWithPnpUtil
    Update-DriversWithWinget
    Update-DriversWithChocolatey
    Update-SystemDrivers
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Log "Actualizare automată completă finalizată în $($duration.TotalMinutes) minute" "SUCCESS"
    Write-Host "`n✅ Actualizare automată completă!" -ForegroundColor Green
    Write-Host "⏱️ Durata totală: $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor Cyan
    Write-Host "📄 Log complet: $logPath" -ForegroundColor Gray
}

function Show-DriverUpdateMenu {
    Write-Log "Pornire aplicație actualizare drivere" "INFO"
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              🔧 ACTUALIZARE AUTOMATĂ DRIVERE            ║" -ForegroundColor Cyan
    Write-Host "║                  ✨ Versiune îmbunătățită                ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📄 Log fișier: $logPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [1] 🔍 Raport drivere sistem" -ForegroundColor White
    Write-Host "  [2] 🔧 Actualizare prin Windows Update" -ForegroundColor White
    Write-Host "  [3] ⚡ Scanare și reparare cu PnpUtil" -ForegroundColor White
    Write-Host "  [4] 📦 Actualizare drivere prin Winget" -ForegroundColor White
    Write-Host "  [5] 🍫 Actualizare drivere prin Chocolatey" -ForegroundColor White
    Write-Host "  [6] 🚀 Actualizare completă (toate metodele)" -ForegroundColor White
    Write-Host "  [7] 🤖 RULARE AUTOMATĂ COMPLETĂ" -ForegroundColor Green
    Write-Host "  [8] 📄 Afișează log-ul" -ForegroundColor Yellow
    Write-Host "  [0] ❌ Înapoi" -ForegroundColor Red
    Write-Host ""

    $choice = Read-Host "Alege opțiunea"

    switch ($choice) {
        "1" { Show-DriverReport }
        "2" { Update-SystemDrivers }
        "3" { Update-DriversWithPnpUtil }
        "4" { Update-DriversWithWinget }
        "5" { Update-DriversWithChocolatey }
        "6" {
            Show-DriverReport
            Update-DriversWithPnpUtil
            Update-DriversWithWinget
            Update-DriversWithChocolatey
            Update-SystemDrivers
        }
        "7" { Start-AutomaticDriverUpdate }
        "8" { 
            if (Test-Path $logPath) {
                Write-Host "`n📄 CONȚINUT LOG:" -ForegroundColor Yellow
                Get-Content $logPath | ForEach-Object { Write-Host $_ }
            } else {
                Write-Host "❌ Log-ul nu a fost găsit!" -ForegroundColor Red
            }
        }
        "0" { return }
        default {
            Write-Log "Opțiune invalidă selectată: $choice" "ERROR"
            Write-Host "❌ Opțiune invalidă!" -ForegroundColor Red
            Start-Sleep 2
            Show-DriverUpdateMenu
        }
    }

    Write-Host "`n✅ Operațiune completă! Apasă Enter pentru a continua..."
    Read-Host
    Show-DriverUpdateMenu
}

# Rulează funcția principală dacă script-ul este executat direct
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Show-DriverUpdateMenu
}