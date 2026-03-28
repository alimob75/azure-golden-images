$ErrorActionPreference = 'Stop'

try {
    $usedLetters = (Get-Volume | Where-Object { $_.DriveLetter } | Select-Object -ExpandProperty DriveLetter | Sort-Object)

    $driveCandidates = @('F','G','H','I','J','K','L','M','N','O','P','Q','R','S','U','V','W','X','Y','Z')
    $availableLetter = ($driveCandidates | Where-Object { $_ -notin $usedLetters } | Select-Object -First 1)

    $rawDisks = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' -and $_.Number -ne 0 }

    if (-not $rawDisks) {
        Write-Output "No raw data disks found, nothing to do."
        exit 0
    }

    foreach ($disk in $rawDisks) {
        $existingPartition = Get-Partition -DiskNumber $disk.Number -ErrorAction SilentlyContinue
        if ($existingPartition) {
            $vol = $existingPartition | Get-Volume -ErrorAction SilentlyContinue
            if ($vol -and $vol.FileSystem) {
                Write-Output "Disk $($disk.Number) is already initialized and formatted, skipping."
                continue
            }
        }

        if (-not $availableLetter) {
            throw "Critical: no available drive letter found."
        }

        Initialize-Disk -Number $disk.Number -PartitionStyle GPT -ErrorAction Stop | Out-Null
        $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -DriveLetter $availableLetter -ErrorAction Stop

        $volume = Get-Volume -DriveLetter $availableLetter -ErrorAction SilentlyContinue
        if (-not $volume -or -not $volume.FileSystem) {
            Format-Volume -DriveLetter $availableLetter -FileSystem NTFS -Confirm:$false -ErrorAction Stop | Out-Null
        }

        $finalVolume = Get-Volume -DriveLetter $availableLetter -ErrorAction SilentlyContinue
        if (-not $finalVolume -or $finalVolume.FileSystem -ne 'NTFS') {
            throw "Critical: disk $($disk.Number) was not formatted correctly on $availableLetter`:"
        }

        Write-Output "Disk $($disk.Number) initialized, partitioned, and formatted on $availableLetter`:"
        $availableLetter = ($driveCandidates | Where-Object { $_ -notin (Get-Volume | Where-Object { $_.DriveLetter } | Select-Object -ExpandProperty DriveLetter) } | Select-Object -First 1)
    }

    exit 0
}
catch {
    Write-Error "Critical failure: $($_.Exception.Message)"
    exit 1
}
