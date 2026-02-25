# 0. Site Detection Logica
$domain = (Get-ADDomainController -Discover).Site
Write-Host "Detected AD Site: $domain" -ForegroundColor White

# Map locaties aan netwerkpaden
# Voeg hier je andere sites toe (bijv. "Gent", "Antwerpen")
switch ($domain) {
    "Ieper"   { $networkPath = "\\install.sensors.elex.be\install" }
    "SiteB"   { $networkPath = "\\server.siteB.local\install" }
    "SiteC"   { $networkPath = "\\server.siteC.local\install" }
    Default   { 
        Write-Host "Site not recognized, falling back to Ieper..." -ForegroundColor Yellow
        $networkPath = "\\install.sensors.elex.be\install" 
    }
}

# 1. Network Authentication Loop
while ($true) {
    $username = Read-Host "Enter your username for $domain"
    Write-Host "Connecting to $networkPath. Password for ${username}:" -ForegroundColor Cyan
    net use $networkPath /user:$username *
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Success!" -ForegroundColor Green ; break
    } else {
        Write-Host "Login failed. Try again." -ForegroundColor Red
    }
}

# 2. ManageEngine Install
$localDest = "C:\Scripts\ManageEngineClient.exe"
$remoteFile = "$networkPath\mdt\Applications\ManageEngine\ManageEngineClient.exe"

if (Test-Path $remoteFile) {
    Copy-Item -Path $remoteFile -Destination $localDest -Force
    Write-Host "Installing ManageEngine for site: $domain..." -ForegroundColor Green
    $proc = Start-Process $localDest -ArgumentList "-silent" -PassThru
    $proc.WaitForExit()
    while (Get-Process msiexec -ErrorAction SilentlyContinue) { Start-Sleep -Seconds 2 }
}

# 3. QEMU Guest Agent
if (!(Get-Service -Name QEMU-Guest-Agent -ErrorAction SilentlyContinue)) {
    Write-Host "Installing QEMU Guest Agent..." -ForegroundColor Yellow
    $qemuUrl = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win-guest-tools.exe"
    Invoke-WebRequest -Uri $qemuUrl -OutFile "C:\Scripts\virtio-win-guest-tools.exe"
    $qemuProc = Start-Process "C:\Scripts\virtio-win-guest-tools.exe" -Argumentlist "/passive", "/norestart" -PassThru
    $qemuProc.WaitForExit()
}

# 4. Cleanup and Final Reboot
net use $networkPath /delete /y
Write-Host "All done! Final reboot..." -ForegroundColor Cyan
Start-Sleep -Seconds 5
Restart-Computer
