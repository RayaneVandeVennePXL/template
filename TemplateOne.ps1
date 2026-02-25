# 1. Hostname Setup
$newName = Read-Host "Enter new hostname"
Write-Host "Renaming to $newName..." -ForegroundColor Yellow
Rename-Computer -NewName $newName -Force

# 2. De trigger zetten voor het tweede script (na de reboot)
$runOncePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
$secondScript = "powershell.exe -ExecutionPolicy Bypass -File C:\Scripts\SiteConfig.ps1"
Set-ItemProperty -Path $runOncePath -Name "SiteConfigTask" -Value $secondScript

Write-Host "Hostname set. Rebooting to apply changes..." -ForegroundColor Cyan
Start-Sleep -Seconds 3
Restart-Computer
