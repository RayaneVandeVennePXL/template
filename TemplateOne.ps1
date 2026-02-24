# 1. Hostname Setup
$newName = Read-Host "Enter new hostname"
Write-Host "Renaming to $newName..." -ForegroundColor Yellow
Rename-Computer -NewName $newName -Force

# 2. Unique Identifier
$newGuid = [guid]::NewGuid().ToString()
$registryPath = "HKLM:\SOFTWARE\Microsoft\Cryptography"
Set-ItemProperty -Path $registryPath -Name "MachineGuid" -Value $newGuid

# 3. Network Authentication
$networkPath = "\\install.sensors.elex.be\install"
$userEmail = Read-Host "Enter your Elex email (e.g. user@elex.be)"

Write-Host "Connecting to $networkPath..." -ForegroundColor Cyan
net use $networkPath /user:$userEmail *

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Authentication failed." -ForegroundColor Red
    pause ; exit
}

# 4. Copy and Install
$localDest = "C:\Scripts\ManageEngineClient.exe"
$remoteFile = "$networkPath\mdt\Applications\ManageEngine\ManageEngineClient.exe"

Copy-Item -Path $remoteFile -Destination $localDest -Force

Write-Host "Installing ManageEngine..." -ForegroundColor Green
Start-Process $localDest -ArgumentList "-silent" -Wait

# 5. Cleanup and Reboot
net use $networkPath /delete /y
Write-Host "Done. Rebooting in 5s..." -ForegroundColor Cyan
Start-Sleep -Seconds 5
Restart-Computer
