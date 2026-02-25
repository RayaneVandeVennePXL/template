# 1. Hostname Setup
$newName = Read-Host "Enter new hostname"
Write-Host "Renaming to $newName..." -ForegroundColor Yellow
Rename-Computer -NewName $newName -Force

# 2. Unique Identifier
$newGuid = [guid]::NewGuid().ToString()
$registryPath = "HKLM:\SOFTWARE\Microsoft\Cryptography"
Set-ItemProperty -Path $registryPath -Name "MachineGuid" -Value $newGuid

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
    Start-Process $localDest -ArgumentList "-silent" -Wait
} else {
    Write-Host "Error: ManageEngine installer not found." -ForegroundColor Red
}

# 5. QEMU Guest Agent (Proxmox Integration)
if (!(Get-Service -Name QEMU-Guest-Agent -ErrorAction SilentlyContinue)) {
    Write-Host "Installing QEMU Guest Agent..." -ForegroundColor Yellow
    $qemuUrl = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win-guest-tools.exe"
    $qemuDest = "C:\Scripts\virtio-win-guest-tools.exe"
    
    Invoke-WebRequest -Uri $qemuUrl -OutFile $qemuDest
    Start-Process $qemuDest -ArgumentList "/passive", "/norestart" -Wait
    Write-Host "QEMU Guest Agent installed." -ForegroundColor Green
}

# 6. Cleanup and Reboot
net use $networkPath /delete /y
Write-Host "Done. Rebooting in 5s..." -ForegroundColor Cyan
Start-Sleep -Seconds 5
Restart-Computer
