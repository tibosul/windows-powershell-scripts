# ===============================
# Script: UpdateWSL.ps1
# Actualizare WSL și distribuții Linux
# Versiune îmbunătățită cu logging și verificări
# ===============================

# Verificare privilegii Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠️ ATENȚIE: Scriptul nu rulează ca Administrator!" -ForegroundColor Red
    Write-Host "💡 Unele funcții pot să nu funcționeze corect fără privilegii de administrator." -ForegroundColor Yellow
    Write-Host "🔄 Pentru funcționalitate completă, rulează PowerShell ca Administrator." -ForegroundColor Cyan
    Write-Host ""
    $continue = Read-Host "Dorești să continui oricum? (Y/N)"
    if ($continue.ToUpper() -ne "Y") {
        Write-Host "❌ Script anulat." -ForegroundColor Red
        exit
    }
    Write-Host "✅ Continuare cu privilegii limitate..." -ForegroundColor Yellow
    Write-Host ""
}

# Configurare logging
$logPath = "$env:TEMP\WSLUpdate_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
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

function Test-WSLInstalled {
    Write-Log "Verificare instalare WSL" "INFO"
    try {
        wsl --version 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "WSL este instalat și funcțional" "SUCCESS"
            return $true
        } else {
            Write-Log "WSL nu pare să fie instalat corect" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Eroare la verificarea WSL: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Get-WSLDistributions {
    Write-Log "Colectare distribuții WSL instalate" "INFO"
    try {
        $distributions = wsl --list --verbose 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Distribuții WSL colectate cu succes" "SUCCESS"
            return $distributions
        } else {
            Write-Log "Eroare la colectarea distribuțiilor WSL" "ERROR"
            return $null
        }
    } catch {
        Write-Log "Eroare la colectarea distribuțiilor: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Update-WSLCore {
    Write-Log "Începere actualizare WSL core" "INFO"
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                  ACTUALIZARE WSL CORE                    ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    try {
        Write-Host "🔄 Actualizare WSL la ultima versiune..." -ForegroundColor Yellow
        $updateResult = wsl --update 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "WSL actualizat cu succes" "SUCCESS"
            Write-Host "✅ WSL actualizat cu succes!" -ForegroundColor Green
        } else {
            Write-Log "Eroare la actualizarea WSL: $updateResult" "ERROR"
            Write-Host "❌ Eroare la actualizarea WSL: $updateResult" -ForegroundColor Red
            return $false
        }

        Write-Host ""
        Write-Host "🔄 Repornire WSL pentru aplicarea update-urilor..." -ForegroundColor Yellow
        wsl --shutdown 2>&1 | Out-Null
        Start-Sleep -Seconds 3
        
        Write-Log "WSL repornit cu succes" "SUCCESS"
        Write-Host "✅ WSL repornit cu succes!" -ForegroundColor Green
        
        return $true
    } catch {
        Write-Log "Eroare la actualizarea WSL core: $($_.Exception.Message)" "ERROR"
        Write-Host "❌ Eroare la actualizarea WSL core: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Update-WSLDistribution {
    param([string]$DistributionName)
    
    Write-Log "Începere actualizare distribuție: $DistributionName" "INFO"
    Write-Host ""
    Write-Host "🐧 ACTUALIZARE DISTRIBUȚIE: $DistributionName" -ForegroundColor Yellow
    Write-Host ""

    try {
        # Verifică dacă distribuția există
        Write-Host "🔍 Verificare distribuție..." -ForegroundColor Cyan
        wsl -d $DistributionName -- echo "test" 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Distribuția $DistributionName nu există sau nu este funcțională" "ERROR"
            Write-Host "❌ Distribuția $DistributionName nu există sau nu este funcțională!" -ForegroundColor Red
            return $false
        }

        Write-Host "🔄 Actualizare lista de pachete..." -ForegroundColor Yellow
        $updateResult = wsl -d $DistributionName -- sudo apt update -y 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Lista de pachete actualizată pentru $DistributionName" "SUCCESS"
            Write-Host "✅ Lista de pachete actualizată!" -ForegroundColor Green
        } else {
            Write-Log "Eroare la actualizarea listei de pachete pentru ${DistributionName}: $updateResult" "WARNING"
            Write-Host "⚠️ Eroare la actualizarea listei de pachete: $updateResult" -ForegroundColor Yellow
        }

        Write-Host "🔄 Actualizare pachete..." -ForegroundColor Yellow
        $upgradeResult = wsl -d $DistributionName -- sudo apt upgrade -y 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Pachete actualizate cu succes pentru $DistributionName" "SUCCESS"
            Write-Host "✅ Pachete actualizate cu succes!" -ForegroundColor Green
        } else {
            Write-Log "Eroare la actualizarea pachetelor pentru ${DistributionName}: $upgradeResult" "WARNING"
            Write-Host "⚠️ Eroare la actualizarea pachetelor: $upgradeResult" -ForegroundColor Yellow
        }

        Write-Host "🔄 Curățare pachete vechi..." -ForegroundColor Yellow
        $cleanupResult = wsl -d $DistributionName -- sudo apt autoremove -y 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Pachete vechi curățate pentru $DistributionName" "SUCCESS"
            Write-Host "✅ Pachete vechi curățate!" -ForegroundColor Green
        } else {
            Write-Log "Eroare la curățarea pachetelor vechi pentru ${DistributionName}: $cleanupResult" "WARNING"
            Write-Host "⚠️ Eroare la curățarea pachetelor vechi: $cleanupResult" -ForegroundColor Yellow
        }

        Write-Log "Actualizare distribuție $DistributionName finalizată" "SUCCESS"
        return $true
        
    } catch {
        Write-Log "Eroare la actualizarea distribuției ${DistributionName}: $($_.Exception.Message)" "ERROR"
        Write-Host "❌ Eroare la actualizarea distribuției ${DistributionName}: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Show-WSLStatus {
    Write-Log "Afișare status WSL" "INFO"
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                        STATUS WSL                        ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    # Versiune WSL
    Write-Host "🐧 VERSIUNE WSL:" -ForegroundColor Yellow
    try {
        $wslVersion = wsl --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host $wslVersion -ForegroundColor White
            Write-Log "Versiune WSL afișată cu succes" "INFO"
        } else {
            Write-Host "❌ Nu s-a putut obține versiunea WSL" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Eroare la obținerea versiunii WSL" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "📦 DISTRIBUȚII INSTALATE:" -ForegroundColor Yellow
    try {
        $distributions = wsl --list --verbose 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host $distributions -ForegroundColor White
            Write-Log "Distribuții WSL afișate cu succes" "INFO"
        } else {
            Write-Host "❌ Nu s-au putut obține distribuțiile WSL" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Eroare la obținerea distribuțiilor WSL" -ForegroundColor Red
    }
}

function Start-WSLUpdate {
    Write-Log "Pornire aplicație actualizare WSL" "INFO"
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║               ACTUALIZARE WSL ȘI DISTRIBUȚII             ║" -ForegroundColor Cyan
    Write-Host "║                   Versiune îmbunătățită                  ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📄 Log fișier: $logPath" -ForegroundColor Gray
    Write-Host ""

    # Verifică instalarea WSL
    if (-not (Test-WSLInstalled)) {
        Write-Host "❌ WSL nu este instalat sau nu funcționează corect!" -ForegroundColor Red
        Write-Host "💡 Instalează WSL prin: wsl --install" -ForegroundColor Yellow
        Write-Log "WSL nu este instalat, script oprit" "ERROR"
        return
    }

    # Afișează status WSL
    Show-WSLStatus

    Write-Host ""
    Write-Host "🔄 Începere actualizare WSL..." -ForegroundColor Cyan
    
    # Actualizează WSL core
    if (Update-WSLCore) {
        Write-Host ""
        Write-Host "🔄 Începere actualizare distribuții..." -ForegroundColor Cyan
        
        # Obține distribuțiile instalate
        $distributions = Get-WSLDistributions
        if ($distributions) {
            # Lista de distribuții comune pentru actualizare
            $commonDistros = @("Ubuntu", "Ubuntu-20.04", "Ubuntu-22.04", "Ubuntu-24.04", "Debian", "Kali-linux")
            
            foreach ($distro in $commonDistros) {
                if ($distributions -match $distro) {
                    Write-Host ""
                    Update-WSLDistribution -DistributionName $distro
                }
            }
        }
    }

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                    ACTUALIZARE COMPLETĂ!                 ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎉 WSL și distribuțiile sunt actualizate!" -ForegroundColor Green
    Write-Host "📄 Log complet: $logPath" -ForegroundColor Gray
    Write-Host "💡 Repornește terminalul WSL pentru a vedea modificările." -ForegroundColor Yellow
    
    Write-Log "Actualizare WSL completată cu succes" "SUCCESS"
}

# Rulează funcția principală dacă script-ul este executat direct
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Start-WSLUpdate
}