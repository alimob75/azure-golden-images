$ErrorActionPreference = 'Stop'

try {
    $dPartition = Get-Partition -DriveLetter 'D' -ErrorAction SilentlyContinue

    if (-not $dPartition) {
        Write-Output "D: not found, nothing to do."
        exit 0
    }

    $pagefileOnD = Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'D:\pagefile.sys' }
    if ($pagefileOnD) {
        Remove-CimInstance -InputObject $pagefileOnD -ErrorAction Stop
        Write-Output "Removed pagefile from D:."
    }

    $currentT = Get-Partition -DriveLetter 'T' -ErrorAction SilentlyContinue
    if (-not $currentT) {
        Set-Partition -DriveLetter 'D' -NewDriveLetter 'T' -ErrorAction Stop
        Write-Output "Changed D: to T:."
    }
    else {
        Write-Output "T: already exists, skipping drive-letter change."
    }

    $pagefileOnT = Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'T:\pagefile.sys' }
    if (-not $pagefileOnT) {
        New-CimInstance -ClassName Win32_PageFileSetting -Property @{ Name = 'T:\pagefile.sys'; InitialSize = 0; MaximumSize = 0 } -ErrorAction Stop | Out-Null
        Write-Output "Created pagefile on T:."
    }
    else {
        Write-Output "Pagefile already exists on T:, skipping."
    }

    if (-not (Get-Partition -DriveLetter 'T' -ErrorAction SilentlyContinue)) {
        throw "Critical: drive T: was not found after change."
    }

    if (-not (Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'T:\pagefile.sys' })) {
        throw "Critical: pagefile on T: was not created."
    }

    Write-Output "Temporary disk migration completed successfully."
    exit 0
}
catch {
    Write-Error "Critical failure: $($_.Exception.Message)"
    exit 1
}
