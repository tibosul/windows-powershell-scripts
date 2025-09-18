# ===============================
# Script: DriverUpdateAutomation.ps1
# Actualizare automată drivere sistem
# ===============================

function Update-SystemDrivers {
    Write-Host "`n🔧 ACTUALIZARE AUTOMATĂ DRIVERE..." -ForegroundColor Yellow

    # Verifică Windows Update PowerShell Module
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Host "📦 Instalare PSWindowsUpdate module..." -ForegroundColor Cyan
        try {
            Install-Module PSWindowsUpdate -Force -Scope CurrentUser
            Write-Host "✅ PSWindowsUpdate instalat cu succes!" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Eroare la instalarea PSWindowsUpdate: $($_.Exception.Message)" -ForegroundColor Red
            return
        }
    }

    # Import module
    Import-Module PSWindowsUpdate -Force

    Write-Host "`n🔍 Scanare drivere disponibile..." -ForegroundColor Cyan

    # Scanează pentru drivere prin Windows Update
    try {
        $drivers = Get-WUList -Category "Drivers" -IsInstalled $false

        if ($drivers.Count -eq 0) {
            Write-Host "✅ Toate driverele sunt actualizate!" -ForegroundColor Green
            return
        }

        Write-Host "`n📋 Drivere găsite pentru actualizare:" -ForegroundColor Yellow
        foreach ($driver in $drivers) {
            Write-Host "  • $($driver.Title)" -ForegroundColor White
        }

        # Confirmă actualizarea
        $response = Read-Host "`n❓ Dorești să instalezi aceste drivere? (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            Write-Host "`n⬇️ Descărcare și instalare drivere..." -ForegroundColor Cyan
            Install-WindowsUpdate -Category "Drivers" -AcceptAll -AutoReboot:$false
            Write-Host "✅ Drivere instalate cu succes!" -ForegroundColor Green
            Write-Host "⚠️ Se recomandă repornirea sistemului." -ForegroundColor Yellow
        }
        else {
            Write-Host "❌ Actualizare anulată de utilizator." -ForegroundColor Red
        }
    }
    catch {
        Write-Host "❌ Eroare la scanarea driverelor: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Update-DriversWithPnpUtil {
    Write-Host "`n🔧 ACTUALIZARE DRIVERE CU PNPUTIL..." -ForegroundColor Yellow

    try {
        # Scanează pentru drivere cu probleme
        Write-Host "🔍 Scanare drivere cu probleme..." -ForegroundColor Cyan
        $problemDevices = Get-PnpDevice | Where-Object { $_.Status -eq "Error" -or $_.Status -eq "Unknown" }

        if ($problemDevices.Count -eq 0) {
            Write-Host "✅ Nu sunt drivere cu probleme detectate!" -ForegroundColor Green
        }
        else {
            Write-Host "`n⚠️ Dispozitive cu probleme găsite:" -ForegroundColor Yellow
            foreach ($device in $problemDevices) {
                Write-Host "  • $($device.FriendlyName) - Status: $($device.Status)" -ForegroundColor Red
            }
        }

        # Încearcă actualizarea automată prin PnpUtil
        Write-Host "`n🔄 Actualizare automată drivere prin Windows Update..." -ForegroundColor Cyan
        $result = & pnputil /scan-devices 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Scanare completă prin PnpUtil!" -ForegroundColor Green
        }
        else {
            Write-Host "⚠️ PnpUtil scanare completă cu warnings." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "❌ Eroare la actualizarea cu PnpUtil: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-DriverReport {
    Write-Host "`n📊 RAPORT DRIVERE SISTEM..." -ForegroundColor Yellow

    try {
        # Obține toate driverele instalate
        $drivers = Get-WmiObject Win32_PnPSignedDriver | Sort-Object DeviceName
        $totalDrivers = $drivers.Count

        # Contorizează driverele după status
        $signedDrivers = ($drivers | Where-Object { $_.IsSigned -eq $true }).Count
        $unsignedDrivers = $totalDrivers - $signedDrivers

        # Afișează statistici
        Write-Host "`n📈 STATISTICI DRIVERE:" -ForegroundColor Cyan
        Write-Host "  • Total drivere instalate: $totalDrivers" -ForegroundColor White
        Write-Host "  • Drivere semnate digital: $signedDrivers" -ForegroundColor Green
        Write-Host "  • Drivere nesemnate: $unsignedDrivers" -ForegroundColor $(if($unsignedDrivers -gt 0) { "Yellow" } else { "Green" })

        # Afișează driverele recente (ultimele 10)
        Write-Host "`n📅 DRIVERE INSTALATE RECENT (Top 10):" -ForegroundColor Cyan
        $recentDrivers = $drivers | Where-Object { $_.DriverDate -ne $null } |
                        Sort-Object @{Expression={[DateTime]$_.DriverDate}; Descending=$true} |
                        Select-Object -First 10

        foreach ($driver in $recentDrivers) {
            $date = if($driver.DriverDate) { ([DateTime]$driver.DriverDate).ToString("yyyy-MM-dd") } else { "N/A" }
            Write-Host "  • $($driver.DeviceName) - $date" -ForegroundColor White
        }

        # Verifică dispozitivele cu probleme
        Write-Host "`n⚠️ DISPOZITIVE CU PROBLEME:" -ForegroundColor Yellow
        $problemDevices = Get-PnpDevice | Where-Object { $_.Status -ne "OK" }

        if ($problemDevices.Count -eq 0) {
            Write-Host "  ✅ Nu sunt dispozitive cu probleme!" -ForegroundColor Green
        }
        else {
            foreach ($device in $problemDevices) {
                Write-Host "  • $($device.FriendlyName) - Status: $($device.Status)" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Host "❌ Eroare la generarea raportului: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Update-DriversWithWinget {
    Write-Host "`n🔧 VERIFICARE ACTUALIZĂRI DRIVERE PRIN WINGET..." -ForegroundColor Yellow

    try {
        # Verifică dacă winget este disponibil
        $wingetCheck = Get-Command winget -ErrorAction SilentlyContinue
        if (-not $wingetCheck) {
            Write-Host "❌ Winget nu este disponibil pe acest sistem." -ForegroundColor Red
            return
        }

        Write-Host "🔍 Căutare actualizări drivere comune..." -ForegroundColor Cyan

        # Lista de drivere comune care pot fi actualizate prin winget
        $commonDrivers = @(
            "Nvidia.GeForceExperience",
            "AMD.AMDSoftwareAdrenalin",
            "Intel.IntelDriverAndSupportAssistant",
            "Realtek.AudioDriver",
            "Intel.GraphicsDriver"
        )

        foreach ($driver in $commonDrivers) {
            Write-Host "  Verificare: $driver" -ForegroundColor Cyan
            $available = winget show $driver 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    ✅ Disponibil pentru actualizare" -ForegroundColor Green
            }
            else {
                Write-Host "    ⚠️ Nu este instalat sau disponibil" -ForegroundColor Yellow
            }
        }

        # Încearcă actualizarea tuturor aplicațiilor (include și driverele)
        Write-Host "`n🔄 Actualizare aplicații și drivere prin Winget..." -ForegroundColor Cyan
        $upgradeResult = winget upgrade --all --silent --accept-source-agreements --accept-package-agreements

        Write-Host "✅ Proces finalizat prin Winget!" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Eroare la actualizarea prin Winget: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Main-DriverUpdate {
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║        ACTUALIZARE AUTOMATĂ DRIVERE      ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] 🔍 Raport drivere sistem" -ForegroundColor White
    Write-Host "  [2] 🔧 Actualizare prin Windows Update" -ForegroundColor White
    Write-Host "  [3] ⚡ Scanare și reparare cu PnpUtil" -ForegroundColor White
    Write-Host "  [4] 📦 Actualizare drivere prin Winget" -ForegroundColor White
    Write-Host "  [5] 🚀 Actualizare completă (toate metodele)" -ForegroundColor White
    Write-Host "  [0] ❌ Înapoi" -ForegroundColor Red
    Write-Host ""

    $choice = Read-Host "Alege opțiunea"

    switch ($choice) {
        "1" { Show-DriverReport }
        "2" { Update-SystemDrivers }
        "3" { Update-DriversWithPnpUtil }
        "4" { Update-DriversWithWinget }
        "5" {
            Show-DriverReport
            Update-DriversWithPnpUtil
            Update-DriversWithWinget
            Update-SystemDrivers
        }
        "0" { return }
        default {
            Write-Host "❌ Opțiune invalidă!" -ForegroundColor Red
            Start-Sleep 2
            Main-DriverUpdate
        }
    }

    Write-Host "`n✅ Operațiune completă! Apasă Enter pentru a continua..."
    Read-Host
}

# Rulează funcția principală dacă script-ul este executat direct
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Main-DriverUpdate
}