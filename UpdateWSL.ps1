# Rulează ca Administrator!

Write-Host "=== Actualizare WSL la ultima versiune ==="
wsl --update

Write-Host "=== Repornește WSL pentru a aplica update-urile ==="
wsl --shutdown

Write-Host "=== Actualizare pachete în distro-ul implicit (Ubuntu) ==="
wsl -d Ubuntu-24.04 -- sudo apt update -y
wsl -d Ubuntu-24.04 -- sudo apt upgrade -y
wsl -d Ubuntu-24.04 -- sudo apt autoremove -y

Write-Host "=== Gata! WSL și Ubuntu sunt la zi. ==="