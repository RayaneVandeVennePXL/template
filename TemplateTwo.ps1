# 1. DNS Suffix detection
$dnsSuffix = (Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -and $_.DNSDomain }).DNSDomain | Select-Object -First 1
if ($dnsSuffix) {
    $networkPath = "\\$dnsSuffix\install"
    $siteLabel = $dnsSuffix.Split('.')[0].ToUpper()
} else {
    $networkPath = "\\install.sensors.elex.be\install"
    $siteLabel = "IEPER (FALLBACK)"
}
Write-Host "Site: $siteLabel | Path: $networkPath" -ForegroundColor Cyan


# 2. Download QEMU (geen background job meer)
Write-Host "Downloading QEMU tools..." -ForegroundColor Gray
Invoke-WebRequest "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win-guest-tools.exe" `
    -OutFile "C:\Scripts\qemu-tools.exe"
Write-Host "QEMU download completed." -ForegroundColor Green


# 3. Network Authentication Loop
while ($true) {
    $username = Read-Host "Enter username for $siteLabel"
    $password = Read-Host "Enter password" -AsSecureString
    $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
    
    net use $networkPath /user:$username $plainPassword
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Connected!" -ForegroundColor Green
        break
    } else {
        if ($siteLabel -ne "IEPER (FALLBACK)") {
            Write-Host "Site $siteLabel not reachable, falling back to Ieper..." -ForegroundColor Yellow
            $networkPath = "\\install.sensors.elex.be\install"
            $siteLabel = "IEPER (FALLBACK)"
            net use $networkPath /user:$username $plainPassword
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Connected to Ieper!" -ForegroundColor Green
                break
            }
        }
        Write-Host "Login failed. Try again." -ForegroundColor Red
    }
}


# 4. ManageEngine Install
$localME = "C:\Scripts\ManageEngineClient.exe"
$remoteME = "$networkPath\mdt\Applications\ManageEngine\ManageEngineClient.exe"

if (Test-Path $remoteME) {
    Copy-Item $remoteME $localME -Force
    Write-Host "Installing ManageEngine..." -ForegroundColor Green
    $proc = Start-Process $localME -ArgumentList "-silent" -PassThru
    $proc.WaitForExit()
} else {
    Write-Host "Error: ManageEngine installer not found." -ForegroundColor Red
}


# 5. Install QEMU
Write-Host "Installing/Updating QEMU Guest Agent..." -ForegroundColor Yellow
$qemuProc = Start-Process "C:\Scripts\qemu-tools.exe" -ArgumentList "/passive", "/norestart" -PassThru
$qemuProc.WaitForExit()


# 6. Create local mlx admin account
Add-Type -AssemblyName System.Web
$mlxPassword = [System.Web.Security.Membership]::GeneratePassword(16, 3)
New-LocalUser -Name "mlx" -Password (ConvertTo-SecureString $mlxPassword -AsPlainText -Force) -FullName "MLX Admin" -PasswordNeverExpires
Add-LocalGroupMember -Group "Administrators" -Member "mlx"
Write-Host "MLX admin account created." -ForegroundColor Green

# Reset Administrator password to random (not saved)
$adminPassword = [System.Web.Security.Membership]::GeneratePassword(16, 3)
Set-LocalUser -Name "Administrator" -Password (ConvertTo-SecureString $adminPassword -AsPlainText -Force)
Write-Host "Administrator password has been reset." -ForegroundColor Green

# Write mlx password to desktop
$desktopPath = [Environment]::GetFolderPath("Desktop")
"MLX Admin Password: $mlxPassword" | Out-File "$desktopPath\mlx_password.txt"
Write-Host "Password written to $desktopPath\mlx_password.txt" -ForegroundColor Yellow
Read-Host "Save the password in the vault, then press Enter to reboot"


# 7. Cleanup & Reboot
net use $networkPath /delete /y
net use "\\install.sensors.elex.be\install" /delete /y 2>$null
Write-Host "Done. Rebooting in 5s..." -ForegroundColor Cyan
Start-Sleep -Seconds 5
Restart-Computer
