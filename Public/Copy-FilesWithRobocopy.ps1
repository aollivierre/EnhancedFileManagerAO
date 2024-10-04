function Copy-FilesWithRobocopy {
    <#
    .SYNOPSIS
    Copies files from a source directory to a destination directory using Robocopy and verifies the operation.

    .DESCRIPTION
    The Copy-FilesWithRobocopy function copies files from a source directory to a destination directory based on a specified file pattern using Robocopy. It validates the source and destination directories, checks disk space, logs the Robocopy process, and verifies the copy operation. It also handles locked files by finding and killing the locking processes.

    .PARAMETER Source
    The source directory from which files will be copied.

    .PARAMETER Destination
    The destination directory to which files will be copied.

    .PARAMETER FilePattern
    The file pattern to match files that should be copied. If not provided, defaults to '*'.

    .PARAMETER RetryCount
    The number of retries if a copy fails. Default is 2.

    .PARAMETER WaitTime
    The wait time between retries in seconds. Default is 5.

    .PARAMETER RequiredSpaceGB
    The required free space in gigabytes at the destination. Default is 10 GB.

    .PARAMETER Exclude
    The directories or files to exclude from the copy operation.

    .EXAMPLE
    Copy-FilesWithRobocopy -Source "C:\Source" -Destination "C:\Destination" -FilePattern "*.txt"
    Copies all .txt files from C:\Source to C:\Destination.

    .EXAMPLE
    "*.txt", "*.log" | Copy-FilesWithRobocopy -Source "C:\Source" -Destination "C:\Destination"
    Copies all .txt and .log files from C:\Source to C:\Destination using pipeline input for the file patterns.

    .EXAMPLE
    Copy-FilesWithRobocopy -Source "C:\Source" -Destination "C:\Destination" -Exclude ".git"
    Copies files from C:\Source to C:\Destination excluding the .git folder.

    .NOTES
    This function relies on the following private functions:
    - Check-DiskSpace.ps1
    - Handle-RobocopyExitCode.ps1
    - Test-Directory.ps1
    - Test-Robocopy.ps1
    - Verify-CopyOperation.ps1
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Destination,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$FilePattern = '*',  # Default to '*' if not provided
        [Parameter(Mandatory = $false)]
        [int]$RetryCount = 2,
        [Parameter(Mandatory = $false)]
        [int]$WaitTime = 5,
        [Parameter(Mandatory = $false)]
        [int]$RequiredSpaceGB = 10, # Example value for required space
        [Parameter(Mandatory = $false)]
        [string[]]$Exclude
    )

    begin {
        Write-EnhancedLog -Message "Starting Copy-FilesWithRobocopy function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Validate Robocopy, source, and destination directories
        try {
            Test-Robocopy
            Test-Directory -Path $Source
            Write-EnhancedLog -Message "Validated source directory: $Source" -Level "INFO"

            Test-Directory -Path $Destination
            Write-EnhancedLog -Message "Validated destination directory: $Destination" -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "Critical error during validation of source or destination directories or Robocopy validation." -Level "CRITICAL"
            Handle-Error -ErrorRecord $_
            throw $_
        }

        # Check disk space
        try {
            Check-DiskSpace -Path $Destination -RequiredSpaceGB $RequiredSpaceGB
        }
        catch {
            Write-EnhancedLog -Message "Critical error during disk space validation." -Level "CRITICAL"
            Handle-Error -ErrorRecord $_
            throw $_
        }

        # Prepare Robocopy log file path
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $logFilePath = "$env:TEMP\RobocopyLog_$timestamp.log"
        Write-EnhancedLog -Message "Robocopy log file will be saved to: $logFilePath" -Level "INFO"
    }

    process {
        try {
            $robocopyPath = "C:\Windows\System32\Robocopy.exe"
            $robocopyArgs = @(
                "`"$Source`"",
                "`"$Destination`"",
                $FilePattern,
                "/E",
                "/R:$RetryCount",
                "/W:$WaitTime",
                "/LOG:`"$logFilePath`""
            )

            # Add exclude arguments if provided
            if ($Exclude) {
                $excludeDirs = $Exclude | ForEach-Object { "/XD `"$($_)`"" }
                $excludeFiles = $Exclude | ForEach-Object { "/XF `"$($_)`"" }
                $robocopyArgs = $robocopyArgs + $excludeDirs + $excludeFiles

                # Log what is being excluded
                foreach ($item in $Exclude) {
                    Write-EnhancedLog -Message "Excluding: $item" -Level "INFO"
                }
            }

            Write-EnhancedLog -Message "Starting Robocopy process with arguments: $robocopyArgs" -Level "INFO"

            # Splatting Start-Process parameters
            $startProcessParams = @{
                FilePath     = $robocopyPath
                ArgumentList = $robocopyArgs
                NoNewWindow  = $true
                Wait         = $true
                PassThru     = $true
            }

            $process = Start-Process @startProcessParams

            if ($process.ExitCode -ne 0) {
                Write-EnhancedLog -Message "Robocopy process failed with exit code: $($process.ExitCode)" -Level "CRITICAL"
            }

            Handle-RobocopyExitCode -ExitCode $process.ExitCode
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while copying files with Robocopy: $_" -Level "ERROR"
            Handle-Error -ErrorRecord $_

            # Check if the error is due to a file being used by another process
            if ($_.Exception -match "because it is being used by another process") {
                Write-EnhancedLog -Message "Attempting to find and kill the process locking the file." -Level "WARNING"
                try {
                    # Find the process locking the file
                    # $lockedFile = $_.Exception.Message -match "'(.+?)'" | Out-Null
                    # $lockedFile = $matches[1]


                    $lockingProcesses = Get-LockingProcess -FilePath $LockedFile -HandlePath "C:\ProgramData\SystemTools\handle64.exe"
                    $lockedfile = $lockingProcesses.FilePath

                    # Kill the processes locking the file
                    Kill-LockingProcesses -LockedFile $lockedFile

                    # Retry the Robocopy operation
                    Write-EnhancedLog -Message "Retrying Robocopy operation after killing the locking process." -Level "INFO"
                    $process = Start-Process @startProcessParams

                    if ($process.ExitCode -ne 0) {
                        Write-EnhancedLog -Message "Robocopy process failed again with exit code: $($process.ExitCode)" -Level "CRITICAL"
                    }

                    Handle-RobocopyExitCode -ExitCode $process.ExitCode
                    Write-EnhancedLog -Message "Copy operation retried and succeeded." -Level "INFO"
                }
                catch {
                    Write-EnhancedLog -Message "Failed to find or kill the process locking the file: $lockedFile" -Level "ERROR"
                    Handle-Error -ErrorRecord $_
                    throw $_
                }
            }
            else {
                throw $_
            }
        }
    }

    end {
        Write-EnhancedLog -Message "Verifying copied files..." -Level "Notice"

        # Call Verify-CopyOperation to ensure the files were copied correctly
        Verify-CopyOperation -SourcePath $Source -DestinationPath $Destination

        Write-EnhancedLog -Message "Copy-FilesWithRobocopy function execution completed." -Level "Notice"
    }
}

# # Example usage
# $sourcePath = "C:\Source"
# $destinationPath = "C:\Destination"

# Copy-FilesWithRobocopy -Source $sourcePath -Destination $destinationPath
