
Write-Host "Running Sysprep for Windows VM..."
    
# Enable CD/DVD-ROM (required for Azure)
reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\cdrom /v start /t REG_DWORD /d 1 /f

# Delete panther directory
Remove-Item -Path C:\Windows\Panther -Recurse -Force -ErrorAction SilentlyContinue

# Delete Qualys registry value
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Qualys' -Name 'HostID' -Force -ErrorAction SilentlyContinue

# Configure Dns Suffixes
Set-DnsClientGlobalSetting -SuffixSearchList @("rs.sdxcorp.net", "ce.sdxcorp.net", "na.sdxcorp.net") -ErrorAction SilentlyContinue

# Run sysprep with /shutdown (not /oobe as per docs)
Start-Process -FilePath C:\Windows\System32\Sysprep\Sysprep.exe -ArgumentList '/generalize /oobe /quit' -Wait

Start-Sleep 120

    
Write-Host "Sysprep finished. VM will shutdown automatically."
