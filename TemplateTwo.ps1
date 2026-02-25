# 1. Haal de prefix uit de DNS Suffix (bv. 'tess' of 'sensors')
$dnsSuffix = (Get-NetAdapter | Get-DnsClient).ConnectionSpecificSuffix | Where-Object {$_} | Select-Object -First 1
$prefix = $dnsSuffix.Split('.')[0]

# 2. Bouw het dynamische pad
$networkPath = "\\$prefix.sensors.elex.be\install"

Write-Host "Checking connectivity for site: $prefix..." -ForegroundColor Gray

# 3. Fetch test: Bestaat het pad? Zo niet -> Fallback naar Ieper
if (!(Test-Path $networkPath)) {
    Write-Host "Path $networkPath not reachable. Falling back to Ieper (sensors)..." -ForegroundColor Yellow
    $networkPath = "\\install.sensors.elex.be\install"
    $siteName = "Ieper (Fallback)"
} else {
    Write-Host "Site $prefix confirmed!" -ForegroundColor Green
    $siteName = $prefix.ToUpper()
}

# 4. Network Authentication Loop
while ($true) {
    $username = Read-Host "Enter username for $siteName"
    Write-Host "Connecting to $networkPath..." -ForegroundColor Cyan
    net use $networkPath /user:$username *
    if ($LASTEXITCODE -eq 0) { Write-Host "Connected!" -ForegroundColor Green; break }
    else { Write-Host "Login failed. Try again." -ForegroundColor Red }
}

# 5. ManageEngine Installatie
$localME = "C:\Scripts\ManageEngineClient.exe"
$remoteME = "$networkPath\mdt\Applications\ManageEngine\ManageEngineClient.exe"

if (Test-Path $remoteME) {
    Copy-Item $remoteME $localME -Force
    Write-Host "Installing ManageEngine..." -ForegroundColor Green
    $proc = Start-Process $localME -ArgumentList "-silent" -PassThru
    $proc.WaitForExit()
    
    # Wachten tot MSI installer klaar is met opruimen
    while (Get-Process msiexec -ErrorAction SilentlyContinue) { Start-Sleep -Seconds 2 }
}

# 6. QEMU Guest Agent
if (!(Get-Service -Name QEMU-Guest-Agent -ErrorAction SilentlyContinue)) {
    Write-Host "Installing QEMU Guest Agent..." -ForegroundColor Yellow
    $qemuUrl = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win-guest-tools.exe"
    Invoke-WebRequest $qemuUrl -OutFile "C:\Scripts\qemu-tools.exe"
    (Start-Process "C:\Scripts\qemu-tools.exe" -ArgumentList "/passive", "/norestart" -PassThru).WaitForExit()
}

# 7. Cleanup & Finish
net use $networkPath /delete /y
Write-Host "All installations complete. Final reboot in 5s..." -ForegroundColor Cyan
Start-Sleep -Seconds 5
Restart-Computer
