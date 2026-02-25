# 1. Hostname Setup
$newName = Read-Host "Enter new hostname"
Write-Host "Renaming to $newName..." -ForegroundColor Yellow
Rename-Computer -NewName $newName -Force

# 2. Download Script 2 van GitHub
if (!(Test-Path "C:\Scripts")) { New-Item -Path "C:\Scripts" -ItemType Directory -Force }

# Gebruik de RAW link voor PowerShell downloads
$script2Url = "https://raw.githubusercontent.com/RayaneVandeVennePXL/template/main/TemplateTwo.ps1"
Invoke-WebRequest -Uri $script2Url -OutFile "C:\Scripts\TemplateTwo.ps1"

# 3. Zet de RunOnce trigger voor de boot NA de herstart
$runOncePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
$secondScript = "powershell.exe -ExecutionPolicy Bypass -File C:\Scripts\TemplateTwo.ps1"
Set-ItemProperty -Path $runOncePath -Name "SiteConfigTask" -Value $secondScript

Write-Host "Hostname set and Script 2 downloaded. Rebooting in 5s..." -ForegroundColor Cyan
Start-Sleep -Seconds 5
Restart-Computer
