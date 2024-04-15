# Ask for source and destination folders
$sourceDirectory = Read-Host "Enter the source location (example: \\SERVER\Share)"
$destinationDirectory = Read-Host "Enter the destination location (example: C:\CNS4U)"

# Construct the file paths
$sourceFile = Join-Path -Path $sourceDirectory -ChildPath "1GB.bin"
$destinationFile = Join-Path -Path $destinationDirectory -ChildPath "1GB.bin"

# Check if the file exists at the source
if (-Not (Test-Path -Path $sourceFile)) {
    # File does not exist, download it
    Write-Host "1GB.bin file not found at source. Downloading from the web..."
    $url = "https://ash-speed.hetzner.com/1GB.bin"
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($url, $sourceFile)
    Write-Host "Download complete."
}

# Ensure the destination directory exists
if (-Not (Test-Path -Path $destinationDirectory)) {
    New-Item -ItemType Directory -Path $destinationDirectory
}

# Measure start time
$start = Get-Date

# Copy the file
Copy-Item -Path $sourceFile -Destination $destinationFile

# Measure end time
$end = Get-Date

# Calculate duration
$duration = $end - $start
$fileSize = (Get-Item $destinationFile).length / 1MB  # Size in MB

# Calculate speed in MB/s
$speed = $fileSize / $duration.TotalSeconds

# Display results
Write-Host "Time taken: $duration"
Write-Host "Transfer speed: $speed MB/s"
