# 1. Prompt user for the new hostname
$newName = Read-Host "Enter new hostname"

# 2. Rename the computer
Write-Host "Renaming computer to $newName..." -ForegroundColor Yellow
Rename-Computer -NewName $newName -Force

# 3. Generate and set a new unique MachineGUID
# This prevents identification conflicts in tools like ManageEngine
$newGuid = [guid]::NewGuid().ToString()
$registryPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography"
Set-ItemProperty -Path "Registry::$registryPath" -Name "MachineGuid" -Value $newGuid
Write-Host "New MachineGUID generated: $newGuid" -ForegroundColor Magenta

# 4. Finalize and Restart
Write-Host "Hostname changed to $newName. The server will restart in 5 seconds..." -ForegroundColor Cyan
Start-Sleep -Seconds 5
Restart-Computer
