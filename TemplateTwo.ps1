# 1. DNS Suffix detectie
$dnsSuffix = (Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -and $_.DNSDomain }).DNSDomain | Select-Object -First 1
if ($dnsSuffix) {
    $networkPath = "\\$dnsSuffix\install"
    $siteLabel = $dnsSuffix.Split('.')[0].ToUpper()
} else {
    $networkPath = "\\install.sensors.elex.be\install"
    $siteLabel = "IEPER (FALLBACK)"
}
Write-Host "Site: $siteLabel | Path: $networkPath" -ForegroundColor Cyan

# 2. Start QEMU download op achtergrond
$qemuJob = Start-Job {
    Invoke-WebRequest "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win-guest-tools.exe" -OutFile "C:\Scripts\qemu-tools.exe"
}
Write-Host "QEMU download started in background..." -ForegroundColor Gray

# 3. Network Authentication Loop
while ($true) {
    $username = Read-Host "Enter username for $siteLabel"
    $password = Read-Host "Enter password" -AsSecureString
    $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
    
    net use $networkPath /user:$username $plainPassword
    if ($LASTEXITCODE -eq 0) { Write-Host "Connected!" -ForegroundColor Green; break }
    else { Write-Host "Login failed. Try again." -ForegroundColor Red }
}

# 4. ManageEngine Install (met fallback naar Ieper)
$localME = "C:\Scripts\ManageEngineClient.exe"
$remoteME = "$networkPath\mdt\Applications\ManageEngine\ManageEngineClient.exe"

if (!(Test-Path $remoteME)) {
    Write-Host "ManageEngine not found on $siteLabel, falling back to Ieper..." -ForegroundColor Yellow
    $fallbackPath = "\\install.sensors.elex.be\install"
    net use $fallbackPath /user:$username $plainPassword
    $remoteME = "$fallbackPath\mdt\Applications\ManageEngine\ManageEngineClient.exe"
}

if (Test-Path $remoteME) {
    Copy-Item $remoteME $localME -Force
    Write-Host "Installing ManageEngine..." -ForegroundColor Green
    $proc = Start-Process $localME -ArgumentList "-silent" -PassThru
    $proc.WaitForExit()
} else {
    Write-Host "Error: ManageEngine installer not found on any site." -ForegroundColor Red
}

# 5. Wacht tot QEMU download klaar is en installeer
Write-Host "Waiting for QEMU download to finish..." -ForegroundColor Gray
Wait-Job $qemuJob
Remove-Job $qemuJob
Write-Host "Installing/Updating QEMU Guest Agent..." -ForegroundColor Yellow
$qemuProc = Start-Process "C:\Scripts\qemu-tools.exe" -ArgumentList "/passive", "/norestart" -PassThru
$qemuProc.WaitForExit()

# 6. Cleanup & Reboot
net use $networkPath /delete /y
net use "\\install.sensors.elex.be\install" /delete /y 2>$null
Write-Host "Done. Rebooting in 5s..." -ForegroundColor Cyan
Start-Sleep -Seconds 5
Restart-Computer
