# 1. Hostname Setup
$newName = Read-Host "Enter new hostname"
Write-Host "Renaming to $newName..." -ForegroundColor Yellow
Rename-Computer -NewName $newName -Force


# 3. Network Authentication Loop
$networkPath = "\\install.sensors.elex.be\install"
while ($true) {
    $username = Read-Host "Enter your username"
    Write-Host "Connecting to $networkPath. Enter password for ${username}:" -ForegroundColor Cyan
    
    net use $networkPath /user:$username *
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Success!" -ForegroundColor Green
        break
    } else {
        Write-Host "Login failed. Check username/password and try again." -ForegroundColor Red
    }
}

# 4. ManageEngine Install
$localDest = "C:\Scripts\ManageEngineClient.exe"
$remoteFile = "$networkPath\mdt\Applications\ManageEngine\ManageEngineClient.exe"
if (Test-Path $remoteFile) {
    Copy-Item -Path $remoteFile -Destination $localDest -Force
    Write-Host "Installing ManageEngine..." -ForegroundColor Green
    $proc = Start-Process $localDest -ArgumentList "-silent" -PassThru
    $proc.WaitForExit()
} else {
    Write-Host "Error: ManageEngine installer not found on network path." -ForegroundColor Red
}

# 5. Cleanup and Reboot
net use $networkPath /delete /y
Write-Host "Done. Rebooting in 5s..." -ForegroundColor Cyan
Start-Sleep -Seconds 5
Restart-Computer
