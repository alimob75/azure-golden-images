
Write-Host "Running Sysprep for Windows VM..."
    
# Enable CD/DVD-ROM (required for Azure)
reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\cdrom /v start /t REG_DWORD /d 1 /f

# Delete panther directory
Remove-Item -Path C:\Windows\Panther -Recurse -Force -ErrorAction SilentlyContinue

# Run sysprep with /shutdown (not /oobe as per docs)
Start-Process -FilePath C:\Windows\System32\Sysprep\Sysprep.exe -ArgumentList '/generalize /shutdown' -Wait

    
Write-Host "Sysprep finished. VM will shutdown automatically."
