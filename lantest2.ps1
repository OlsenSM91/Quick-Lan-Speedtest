# Display ASCII art and version info
Write-Host "
.____                    _________                        .______________              __   
|    |   _____    ____  /   _____/_____   ____   ____   __| _/\__    ___/___   _______/  |_ 
|    |   \__  \  /    \ \_____  \\____ \_/ __ \_/ __ \ / __ |   |    |_/ __ \ /  ___/\   __\
|    |___ / __ \|   |  \/        \  |_> >  ___/\  ___// /_/ |   |    |\  ___/ \___ \  |  |  
|_______ (____  /___|  /_______  /   __/ \___  >\___  >____ |   |____| \___  >____  > |__|  
        \/    \/     \/        \/|__|        \/     \/     \/              \/     \/        

Version: 0.1
Author: Steven Olsen
Company: Computer Networking Solutions Inc.

Description: Performs simple LAN Speed Test to troubleshoot local area networking issues
"

# Function to get and display network shares
function Get-NetworkShares {
    $netShares = @()
    try {
        $sharesOutput = net use
        $sharesLines = $sharesOutput -split '\r?\n' | Where-Object { $_ -match '^\s*OK\s+' }
        $i = 0
        foreach ($line in $sharesLines) {
            if ($line -match '\\\\[^\\]+\S*') {
                $i++
                $share = $matches[0].Trim()
                Write-Host "$i. $share"
                $netShares += $share
            }
        }
    } catch {
        Write-Host "Failed to retrieve network shares: $($_.Exception.Message)"
    }
    $netShares += "Enter manual"
    return $netShares
}

# Get list of shares and allow user to choose
$availableShares = Get-NetworkShares
if ($availableShares.Count -eq 0) {
    Write-Host "No network shares available. Please ensure you are connected to the network."
    exit
}
$sourceIndex = Read-Host "Enter the number of the source share to use or type 'Enter manual' to specify manually"
if ($sourceIndex -eq "Enter manual") {
    $sourceDirectory = Read-Host "Enter the manual source location (example: \\SERVER\Share)"
} elseif ($sourceIndex -lt 1 -or $sourceIndex -gt $availableShares.Count) {
    Write-Host "Invalid selection. Exiting script."
    exit
} else {
    $sourceDirectory = $availableShares[$sourceIndex - 1]
}

$destinationDirectory = Read-Host "Enter the destination location (example: C:\CNS4U)"

# Construct the file paths
$sourceFile = Join-Path -Path $sourceDirectory -ChildPath "1GB.bin"
$destinationFile = Join-Path -Path $destinationDirectory -ChildPath "1GB.bin"

# Check and delete the file at destination if it exists
if (Test-Path -Path $destinationFile) {
    Remove-Item -Path $destinationFile
    $deleteMessage = "1GB.bin file existed at destination and was deleted."
} else {
    $deleteMessage = "No 1GB.bin file existed at destination."
}

# Function to download the file with progress
function Download-FileWithProgress {
    param([string]$Url, [string]$DestinationPath)
    $httpClient = New-Object System.Net.Http.HttpClient

    try {
        # Start the asynchronous request
        $response = $httpClient.GetAsync($Url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result

        if ($response.IsSuccessStatusCode) {
            # Open the destination file for writing
            $fileStream = [System.IO.FileStream]::new($DestinationPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
            $stream = $response.Content.ReadAsStreamAsync().Result
            $totalRead = 0
            $buffer = New-Object byte[] 8192
            while (($read = $stream.Read($buffer, 0, $buffer.Length)) -ne 0) {
                $fileStream.Write($buffer, 0, $read)
                $totalRead += $read
                $totalSize = $response.Content.Headers.ContentLength
                $percentComplete = ($totalRead / $totalSize) * 100
                Write-Progress -Activity "Downloading" -Status "Progress: $percentComplete%" -PercentComplete $percentComplete
            }
            $fileStream.Close()
            $stream.Close()
            Write-Host "Download complete."
        } else {
            Write-Host "Failed to download file. Status: $($response.StatusCode)"
        }
    } catch {
        Write-Host "An error occurred: $($_.Exception.Message)"
    } finally {
        $httpClient.Dispose()
    }
}


# Check if the file exists at the source
if (-Not (Test-Path -Path $sourceFile)) {
    # File does not exist, download it
    Write-Host "1GB.bin file not found at source. Downloading from the web..."
    $url = "https://ash-speed.hetzner.com/1GB.bin"
    Download-FileWithProgress -Url $url -DestinationPath $sourceFile
    $downloadMessage = "1GB.bin file was downloaded from the web."
} else {
    $downloadMessage = "1GB.bin file found at source."
}

# Ensure the destination directory exists
if (-Not (Test-Path -Path $destinationDirectory)) {
    New-Item -ItemType Directory -Path $destinationDirectory
}

# Measure start time
$start = Get-Date

# Initialize errorMessage to null each time to avoid stale error data
$errorMessage = $null

# Copy the file with progress
try {
    if (-Not (Test-Path -Path $sourceFile)) {
        throw "Source file does not exist at the path: $sourceFile"
    }

    $stream = [System.IO.File]::OpenRead($sourceFile)
    if ($stream) {
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
        $copyMessage = "File copied successfully."
    } else {
        throw "Failed to open the source file stream."
    }
} catch {
    $errorMessage = $_.Exception.Message
    $copyMessage = "Error copying file: $errorMessage"
}

# Measure end time
$end = Get-Date

# Calculate duration
$duration = $end - $start
$fileSizeMB = $fileSize / 1MB  # Size in MB

# Calculate speed in MB/s
$speed = $fileSizeMB / $duration.TotalSeconds

# Prepare log content
$logContent = @"
Date: $(Get-Date)
Selected source directory: $sourceDirectory
$deleteMessage
$downloadMessage
$copyMessage
Time taken: $duration
Transfer speed: $speed MB/s
"@

# Add error message to log only if it exists
if ($errorMessage) {
    $logContent += "Error: $errorMessage`r`n"
}

# Log results
$logFileName = "lantest_results-$(Get-Date -Format 'yyyy.MM.dd-HH.mm').log"
$logFilePath = Join-Path -Path $destinationDirectory -ChildPath $logFileName
$logContent | Out-File -FilePath $logFilePath -Append

# Output log file path
Write-Host "Results logged to: $logFilePath"
