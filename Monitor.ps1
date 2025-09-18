# Monitor.ps1 - Monitorizare live a sistemului
Write-Host "📊 MONITOR SISTEM - Apasa 'q' + Enter pentru iesire" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

# Variabile pentru cache si performanta
$lastCpuTime = Get-Date
$cpuCounter = '\Processor(_Total)\% Processor Time'

while($true) {
    # Verifica input utilizator
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.KeyChar -eq 'q' -or $key.KeyChar -eq 'Q') {
            Write-Host "`n👋 Monitorizare oprita." -ForegroundColor Green
            break
        }
    }

    Clear-Host
    Write-Host "📊 MONITORIZARE LIVE - Apasa 'q' pentru iesire" -ForegroundColor Cyan
    Write-Host "Ultima actualizare: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
    Write-Host ("-" * 50)

    try {
        # CPU usage cu tratare erori
        $cpuUsage = try {
            [math]::Round((Get-Counter $cpuCounter -ErrorAction Stop).CounterSamples.CookedValue, 2)
        } catch {
            "N/A"
        }
        Write-Host "🔥 CPU: $cpuUsage%" -ForegroundColor $(if($cpuUsage -is [double] -and $cpuUsage -gt 80) {"Red"} else {"White"})

        # Memory usage
        $processes = Get-Process -ErrorAction SilentlyContinue
        if ($processes) {
            $memUsageGB = [math]::Round(($processes | Measure-Object WorkingSet -Sum).Sum / 1GB, 2)
            Write-Host "💾 RAM utilizat: $memUsageGB GB" -ForegroundColor $(if($memUsageGB -gt 8) {"Red"} elseif($memUsageGB -gt 6) {"Yellow"} else {"White"})
        }

        # Disk space
        $diskFree = [math]::Round((Get-PSDrive C -ErrorAction SilentlyContinue).Free / 1GB, 2)
        Write-Host "💽 C:\ liber: $diskFree GB" -ForegroundColor $(if($diskFree -lt 10) {"Red"} elseif($diskFree -lt 50) {"Yellow"} else {"White"})

        Write-Host "`n🔝 TOP 5 PROCESE (CPU):" -ForegroundColor Yellow
        $topProcesses = $processes | Sort-Object CPU -Descending | Select-Object -First 5 ProcessName, CPU, @{Name="RAM(MB)";Expression={[math]::Round($_.WorkingSet/1MB,1)}}
        $topProcesses | Format-Table -AutoSize | Out-Host

    } catch {
        Write-Host "⚠️ Eroare la citirea datelor sistem" -ForegroundColor Red
    }

    Write-Host "`n⏱️ Actualizare in 3 secunde..." -ForegroundColor Gray
    Start-Sleep -Seconds 3
}