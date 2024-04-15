# Quick LAN Speedtest

## Overview

This PowerShell script is designed to perform a LAN speed test by copying a 1GB test file from a network share to a local destination directory. The script checks for the presence of the test file at both the source and destination, handles downloading the file to the source if it is not present, and logs detailed actions and outcomes.

## Features

- **File Validation**: Checks if the `1GB.bin` file exists at the source and destination paths.
- **Automatic Download**: If the `1GB.bin` file is not found at the source, it is downloaded automatically.
- **File Deletion**: If the file exists at the destination, it is deleted before the test to ensure accurate measurement.
- **Progress Display**: Shows progress during file download and copying to enhance user experience.
- **Detailed Logging**: Logs details about file existence, actions taken (download, delete, copy), and any errors. It also records the time taken for the transfer and the resulting speed.

## How It Works

The script operates by asking the user for the source (network share) and destination directories. It then proceeds with the following steps:

1. **Check and Prepare Destination**: Verifies the existence of the `1GB.bin` file at the destination and deletes it if present.
2. **Source Validation and Download**: Checks the source for the `1GB.bin` file; if not found, downloads it from a predefined URL.
3. **File Transfer**: Copies the file from the source to the destination, displaying progress during the operation.
4. **Logging**: Records all actions, results, and any errors in a log file within the destination directory, named with the format `lantest_results-yyyy.MM.dd-HH.mm.log`.

## Usage

To use the script, it is recommended to run PowerShell in non-elevated mode or through the Run dialog (Win + R) as long as it won't be an elevated session. The reason for using a non-elevated session is so it can see and recognize existing shares for the client. Execute the following command to download and run the script:

```powershell
irm https://raw.githubusercontent.com/OlsenSM91/Quick-Lan-Speedtest/main/lanspeedtest.ps1 | iex
```

Upon running, the script will prompt you to enter the accessible server share path and then the local destination directory. Follow the on-screen instructions to complete the speed test.

## Conclusion

This script provides an easy and effective way to measure the speed of your LAN by transferring a test file from a network share to your local machine. It ensures robust handling of common scenarios like missing files and provides clear progress updates, making it suitable for both casual users and network administrators.
