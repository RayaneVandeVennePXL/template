
$newName = Read-Host "Vul nieuwe hostname in"

Rename-Computer -NewName $newName -Force


Write-Host "Hostname aangepast naar $newName. De server herstart over 2 seconden..." -ForegroundColor Cyan

Start-Sleep -Seconds 2
Restart-Computer
