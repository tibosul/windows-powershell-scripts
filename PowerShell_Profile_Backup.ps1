# ===============================================
# PowerShell Profile pentru Steli - FINAL
# NU schimbă directorul de lucru DELOC
# ===============================================

# 1. SETĂRI GENERALE
# -----------------
# NU SCHIMBĂM NIMIC LA LOCAȚIE! PowerShell se deschide normal unde trebuie

# Execution Policy pentru sesiunea curentă
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force -ErrorAction SilentlyContinue

# Encoding UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# 2. ALIASURI PENTRU SCRIPTURILE TALE
# ------------------------------------
# Toate funcționează cu cale completă din orice folder

function Start-Clean {
    & "C:\Scripts\CleanSafeSurface.ps1"
}
Set-Alias clean Start-Clean
Set-Alias cc Start-Clean

function Start-Maintenance {
    & "C:\Scripts\WeeklyMaintenance.ps1"
}
Set-Alias maintenance Start-Maintenance
Set-Alias wm Start-Maintenance

function Start-Toolkit {
    & "C:\Scripts\SystemToolkit.ps1"
}
Set-Alias toolkit Start-Toolkit
Set-Alias tk Start-Toolkit

function Start-Optimize {
    & "C:\Scripts\WindowsFullOptimization.ps1"
}
Set-Alias optimize Start-Optimize
Set-Alias opt Start-Optimize

function Start-Monitor {
    & "C:\Scripts\Monitor.ps1"
}
Set-Alias monitor Start-Monitor
Set-Alias mon Start-Monitor

# Update toate aplicațiile
Set-Alias update "winget upgrade --all --include-unknown"

# 3. FUNCȚII UTILE
# ----------------

# Funcție pentru a rula orice script ca Administrator
function Run-AsAdmin {
    param([string]$ScriptName)

    # Verifică mai întâi în folderul curent
    if (Test-Path ".\$ScriptName.ps1") {
        $scriptPath = (Get-Item ".\$ScriptName.ps1").FullName
    }
    # Apoi verifică în C:\Scripts
    elseif (Test-Path "C:\Scripts\$ScriptName.ps1") {
        $scriptPath = "C:\Scripts\$ScriptName.ps1"
    }
    else {
        Write-Host "❌ Script-ul $ScriptName nu a fost găsit!" -ForegroundColor Red
        return
    }

    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
}
Set-Alias admin Run-AsAdmin

# Funcție pentru listare TOATE COMENZILE disponibile
function Show-Help {
    Write-Host "`n╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         🚀 COMENZI DISPONIBILE              ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan

    Write-Host "`n📂 SCRIPTURI SISTEM:" -ForegroundColor Yellow
    Write-Host "  clean, cc      - Curățare rapidă sistem"
    Write-Host "  maintenance, wm- Maintenance săptămânal complet"
    Write-Host "  toolkit, tk    - Meniu interactiv cu 15+ opțiuni"
    Write-Host "  optimize, opt  - Optimizare completă Windows"
    Write-Host "  monitor, mon   - Monitorizare live resurse"
    Write-Host "  update         - Actualizare toate aplicațiile"

    Write-Host "`n🔧 FUNCȚII UTILE:" -ForegroundColor Yellow
    Write-Host "  sysinfo        - Informații complete despre sistem"
    Write-Host "  admin <nume>   - Rulează un script ca Administrator"
    Write-Host "  backup         - Backup rapid (Documents -> D:\Backups)"
    Write-Host "  sql            - Manager pentru SQL Server"
    Write-Host "  cpp <file>     - Compilare rapidă C++ (dacă ai g++)"

    Write-Host "`n📍 NAVIGARE RAPIDĂ:" -ForegroundColor Yellow
    Write-Host "  scripts, cds   - Mergi la C:\Scripts"
    Write-Host "  dev            - Mergi la C:\Dev"
    Write-Host "  proj           - Mergi la C:\Dev\Projects"
    Write-Host "  desk           - Mergi la Desktop"
    Write-Host "  down           - Mergi la Downloads"
    Write-Host "  docs           - Mergi la Documents"

    Write-Host "`n💡 TIPS:" -ForegroundColor Green
    Write-Host "  • Toate comenzile funcționează din orice folder"
    Write-Host "  • PowerShell nu își schimbă locația la pornire"
    Write-Host "  • În VS Code se va deschide în folderul proiectului"
    Write-Host "  • Scrie 'help' oricând pentru acest meniu"

    Write-Host "`n📂 Scripturi disponibile în C:\Scripts:" -ForegroundColor Cyan
    if (Test-Path C:\Scripts) {
        Get-ChildItem C:\Scripts\*.ps1 | ForEach-Object {
            $size = [math]::Round($_.Length / 1KB, 2)
            Write-Host "  • $($_.BaseName) ($size KB)" -ForegroundColor Gray
        }
    }
    Write-Host ""
}
Set-Alias help Show-Help
Set-Alias ? Show-Help
Set-Alias comenzi Show-Help

# Funcție pentru navigare la Scripts
function Go-Scripts {
    Set-Location C:\Scripts
    Write-Host "📂 Ai navigat la C:\Scripts" -ForegroundColor Green
    Get-ChildItem *.ps1 | Format-Table Name, Length, LastWriteTime -AutoSize
}
Set-Alias scripts Go-Scripts
Set-Alias cds Go-Scripts

# Shortcuts pentru navigare
function dev { Set-Location C:\Dev }
function desk { Set-Location $env:USERPROFILE\Desktop }
function down { Set-Location $env:USERPROFILE\Downloads }
function docs { Set-Location $env:USERPROFILE\Documents }
function proj {
    if (Test-Path C:\Dev\Projects) {
        Set-Location C:\Dev\Projects
    } else {
        Write-Host "Folderul C:\Dev\Projects nu există" -ForegroundColor Yellow
    }
}

# Funcție pentru informații sistem
function Get-SysInfo {
    Write-Host "`n💻 SISTEM INFORMATION" -ForegroundColor Magenta
    Write-Host "=====================" -ForegroundColor Magenta

    $cs = Get-CimInstance Win32_ComputerSystem
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    $video = Get-CimInstance Win32_VideoController

    Write-Host "🖥️  Computer: $($cs.Manufacturer) $($cs.Model)"
    Write-Host "🪟 Windows: $($os.Caption) Build $($os.BuildNumber)"
    Write-Host "🧠 CPU: $($cpu.Name)"
    Write-Host "🎮 GPU: $($video.Name)"
    Write-Host "💾 RAM: $([math]::Round($cs.TotalPhysicalMemory / 1GB, 2)) GB"

    Write-Host "`n💿 DISCURI:" -ForegroundColor Yellow
    Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Free -ne $null} | ForEach-Object {
        $percentUsed = [math]::Round((($_.Used) / ($_.Used + $_.Free)) * 100, 2)
        $color = if ($percentUsed -gt 90) {"Red"} elseif ($percentUsed -gt 75) {"Yellow"} else {"Green"}
        Write-Host "  $($_.Name): " -NoNewline
        Write-Host "$percentUsed% folosit" -ForegroundColor $color -NoNewline
        Write-Host " ($([math]::Round($_.Free/1GB, 2)) GB liber)"
    }

    Write-Host "`n🌐 REȚEA:" -ForegroundColor Yellow
    Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object {
        Write-Host "  $($_.Name): $($_.LinkSpeed)"
    }

    $uptime = (Get-Date) - $os.LastBootUpTime
    Write-Host "`n⏱️  Uptime: $($uptime.Days) zile, $($uptime.Hours) ore, $($uptime.Minutes) minute"
}
Set-Alias sysinfo Get-SysInfo

# Funcție pentru backup rapid
function Quick-Backup {
    param(
        [string]$Source = "$env:USERPROFILE\Documents",
        [string]$Destination = "D:\Backups"
    )

    $date = Get-Date -Format "yyyy-MM-dd_HHmm"
    $backupPath = "$Destination\Backup_$date"

    Write-Host "📦 Creare backup..." -ForegroundColor Yellow
    Write-Host "  De la: $Source"
    Write-Host "  Către: $backupPath"

    if (!(Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    robocopy $Source $backupPath /E /XO /R:1 /W:1 /MT:16 /NP

    Write-Host "✅ Backup completat!" -ForegroundColor Green
}
Set-Alias backup Quick-Backup

# Compilare rapidă C/C++
function Compile-Cpp {
    param(
        [Parameter(Mandatory=$true)]
        [string]$File,
        [string]$Output = $null
    )

    if (-not $Output) {
        $Output = [System.IO.Path]::GetFileNameWithoutExtension($File) + ".exe"
    }

    Write-Host "🔨 Compilare $File..." -ForegroundColor Yellow

    if (Get-Command g++ -ErrorAction SilentlyContinue) {
        g++ -o $Output $File -std=c++17 -Wall -O2
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Compilat cu succes: $Output" -ForegroundColor Green
            Write-Host "  Rulează cu: .\$Output" -ForegroundColor Cyan
        } else {
            Write-Host "❌ Eroare la compilare!" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ g++ nu este instalat! Instalează MinGW sau Visual Studio" -ForegroundColor Red
    }
}
Set-Alias cpp Compile-Cpp

# SQL Server Manager
function SQL-Manager {
    Write-Host "`n🗄️ SQL SERVER MANAGER" -ForegroundColor Cyan

    $sqlServices = Get-Service -Name "*SQL*" -ErrorAction SilentlyContinue

    if ($sqlServices) {
        Write-Host "`nServicii SQL găsite:" -ForegroundColor Yellow
        $sqlServices | Format-Table Name, Status, StartType -AutoSize

        Write-Host "`nOpțiuni:" -ForegroundColor Green
        Write-Host "  1. Pornește toate serviciile SQL"
        Write-Host "  2. Oprește toate serviciile SQL"
        Write-Host "  3. Restart toate serviciile SQL"
        Write-Host "  4. Deschide SQL Server Management Studio"
        Write-Host "  0. Anulare"

        Write-Host "`nAlege opțiunea (timeout 30 secunde): " -NoNewline
        
        # Timeout de 30 secunde pentru răspuns
        $timeout = 30
        $startTime = Get-Date
        $choice = ""
        
        while (((Get-Date) - $startTime).TotalSeconds -lt $timeout -and $choice -eq "") {
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                if ($key.Key -eq "Enter") {
                    Write-Host ""
                    break
                } elseif ($key.KeyChar -match '[0-4]') {
                    $choice = $key.KeyChar
                    Write-Host $choice
                    break
                }
            }
            Start-Sleep -Milliseconds 100
        }
        
        if ($choice -eq "") {
            Write-Host "`n⏱️ Timeout - nicio opțiune selectată" -ForegroundColor Yellow
            return
        }

        switch ($choice) {
            '1' {
                $sqlServices | Start-Service -ErrorAction SilentlyContinue
                Write-Host "✅ Servicii pornite" -ForegroundColor Green
            }
            '2' {
                $sqlServices | Stop-Service -Force -ErrorAction SilentlyContinue
                Write-Host "✅ Servicii oprite" -ForegroundColor Green
            }
            '3' {
                $sqlServices | Restart-Service -Force -ErrorAction SilentlyContinue
                Write-Host "✅ Servicii restartate" -ForegroundColor Green
            }
            '4' {
                $ssms = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 19\Common7\IDE\Ssms.exe"
                if (Test-Path $ssms) {
                    Start-Process $ssms
                } else {
                    $ssms = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\Ssms.exe"
                    if (Test-Path $ssms) {
                        Start-Process $ssms
                    } else {
                        Write-Host "SSMS nu este instalat în locația standard" -ForegroundColor Red
                    }
                }
            }
            '0' {
                Write-Host "Anulat" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "❌ SQL Server nu este instalat" -ForegroundColor Red
    }
}
Set-Alias sql SQL-Manager

# 4. PERSONALIZARE PROMPT
# ------------------------
function prompt {
    $location = Get-Location
    $time = Get-Date -Format "HH:mm"

    # Admin mode check
    if ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544') {
        Write-Host "[$time] " -NoNewline -ForegroundColor Red
        Write-Host "ADMIN " -NoNewline -ForegroundColor Red -BackgroundColor DarkRed
    } else {
        Write-Host "[$time] " -NoNewline -ForegroundColor Cyan
    }

    # Current location
    Write-Host "$location" -NoNewline -ForegroundColor Green

    # Git branch if in a repo
    if (Test-Path .git) {
        $branch = git branch --show-current 2>$null
        if ($branch) {
            Write-Host " [$branch]" -NoNewline -ForegroundColor Yellow
        }
    }

    Write-Host " >" -NoNewline -ForegroundColor White
    return " "
}

# 5. MESAJ DE BUN VENIT
# ----------------------
Clear-Host
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      🚀 PowerShell Profile Loaded! 🚀      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  👋 Salut, $env:USERNAME!" -ForegroundColor Yellow
Write-Host "  📅 $(Get-Date -Format 'dddd, dd MMMM yyyy HH:mm')" -ForegroundColor Gray
Write-Host "  📂 Locație curentă: $(Get-Location)" -ForegroundColor Gray
Write-Host ""
Write-Host "  💡 Scrie " -NoNewline
Write-Host "help" -ForegroundColor Green -NoNewline
Write-Host " sau " -NoNewline
Write-Host "comenzi" -ForegroundColor Green -NoNewline
Write-Host " pentru lista completă de comenzi"
Write-Host ""

# Verifică dacă ești Admin
if ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544') {
    Write-Host "  ⚠️  Rulezi ca ADMINISTRATOR" -ForegroundColor Red -BackgroundColor DarkRed
    Write-Host ""
}

# Quick system check
$diskC = Get-PSDrive C -ErrorAction SilentlyContinue
if ($diskC) {
    $percentFree = [math]::Round(($diskC.Free / ($diskC.Used + $diskC.Free)) * 100, 2)
    if ($percentFree -lt 15) {
        Write-Host "  ⚠️  Spațiu redus pe C: doar $percentFree% liber!" -ForegroundColor Red
        Write-Host ""
    }
}

# Verifică dacă sunt actualizări disponibile (nu blochează)
$job = Start-Job -ScriptBlock {
    try {
        $updates = winget upgrade --include-unknown 2>$null
        if ($updates -match "upgrades available") {
            $count = ($updates | Select-String "upgrades available").Matches[0].Value.Split()[0]
            return $count
        }
    } catch {
        # Ignoră erorile
    }
    return 0
}

# Așteaptă max 3 secunde pentru verificare (redus de la 2 pentru mai multă siguranță)
$result = Wait-Job $job -Timeout 3
if ($result) {
    try {
        $updateCount = Receive-Job $job -ErrorAction SilentlyContinue
        if ($updateCount -gt 0) {
            Write-Host "  📦 $updateCount actualizări disponibile (scrie 'update' pentru a instala)" -ForegroundColor Yellow
            Write-Host ""
        }
    } catch {
        # Ignoră erorile la citirea rezultatului
    }
}
# Curăță job-ul indiferent de rezultat
Remove-Job $job -Force -ErrorAction SilentlyContinue

# END OF PROFILE
# NU SCHIMBĂ DIRECTORUL!