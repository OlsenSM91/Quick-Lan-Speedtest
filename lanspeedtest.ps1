# Ask for source and destination folders
$sourceDirectory = Read-Host "Enter the source location (example: \\SERVER\Share)"
$destinationDirectory = Read-Host "Enter the destination location (example: C:\CNS4U)"

# Construct the file paths
$sourceFile = Join-Path -Path $sourceDirectory -ChildPath "1GB.bin"
$destinationFile = Join-Path -Path $destinationDirectory -ChildPath "1GB.bin"

# Function to download the file with progress
function Download-FileWithProgress {
    param([string]$Url, [string]$DestinationPath)
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadProgressChanged += {
        Write-Progress -Activity "Downloading" -Status "$($_.ProgressPercentage)%" -PercentComplete $_.ProgressPercentage
    }
    $webClient.DownloadFileCompleted += {
        Write-Progress -Activity "Downloading" -Completed
    }
    $webClient.DownloadFileAsync((New-Object Uri $Url), $DestinationPath)
    while ($webClient.IsBusy) { Start-Sleep -Seconds 1 }
}

# Check if the file exists at the source
if (-Not (Test-Path -Path $sourceFile)) {
    # File does not exist, download it
    Write-Host "1GB.bin file not found at source. Downloading from the web..."
    $url = "https://ash-speed.hetzner.com/1GB.bin"
    Download-FileWithProgress -Url $url -DestinationPath $sourceFile
    Write-Host "Download complete."
}

# Ensure the destination directory exists
if (-Not (Test-Path -Path $destinationDirectory)) {
    New-Item -ItemType Directory -Path $destinationDirectory
}

# Measure start time
$start = Get-Date

# Copy the file with progress
$stream = [System.IO.File]::OpenRead($sourceFile)
$fileSize = $stream.Length
$buffer = New-Object byte[] 10MB
$writeStream = [System.IO.File]::Create($destinationFile)
$totalRead = 0
do {
    $read = $stream.Read($buffer, 0, $buffer.Length)
    $writeStream.Write($buffer, 0, $read)
    $totalRead += $read
    $percentComplete = ($totalRead / $fileSize) * 100
    Write-Progress -Activity "Copying file" -Status "$percentComplete%" -PercentComplete $percentComplete
} while ($read -ne 0)
$writeStream.Close()
$stream.Close()

# Measure end time
$end = Get-Date

# Calculate duration
$duration = $end - $start
$fileSizeMB = $fileSize / 1MB  # Size in MB

# Calculate speed in MB/s
$speed = $fileSizeMB / $duration.TotalSeconds

# Output results
$results = @"
Time taken: $duration
Transfer speed: $speed MB/s
"@ 
Write-Host $results

# Log results
$logFileName = "lantest_results-$(Get-Date -Format 'yyyy.MM.dd-HH.mm').log"
$logFilePath = Join-Path -Path $destinationDirectory -ChildPath $logFileName
$results | Out-File -FilePath $logFilePath -Append

# Output log file path
Write-Host "Results logged to: $logFilePath"
