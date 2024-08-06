function Copy-FilesWithRobocopy {
    <#
    .SYNOPSIS
    Copies files from a source directory to a destination directory using Robocopy.

    .DESCRIPTION
    The Copy-FilesWithRobocopy function copies files from a source directory to a destination directory based on a specified file pattern. It uses Robocopy to perform the file copy operation. The function includes validation of the source and destination directories, disk space checks, and logs the Robocopy process.

    .PARAMETER Source
    The source directory from which files will be copied.

    .PARAMETER Destination
    The destination directory to which files will be copied.

    .PARAMETER FilePattern
    The file pattern to match files that should be copied.

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
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Destination,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$FilePattern,
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
        Write-EnhancedLog -Message "Starting Copy-FilesWithRobocopy function" -Level "INFO"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Validate Robocopy, source and destination directories once
        Test-Robocopy
        Test-Directory -Path $Source
        Write-EnhancedLog -Message "Validated source directory: $Source" -Level "INFO"

        Test-Directory -Path $Destination
        Write-EnhancedLog -Message "Validated destination directory: $Destination" -Level "INFO"

        # Check disk space once
        Check-DiskSpace -Path $Destination -RequiredSpaceGB $RequiredSpaceGB

        # Prepare Robocopy log file path
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $logFilePath = "$env:TEMP\RobocopyLog_$timestamp.log"
        Write-EnhancedLog -Message "Robocopy log file will be saved to: $logFilePath" -Level "INFO"
    }

    process {
        try {
            $robocopyPath = "C:\Windows\System32\Robocopy.exe"
            $robocopyArgs = @(
                $Source, 
                $Destination, 
                $FilePattern, 
                "/E", 
                "/R:$RetryCount", 
                "/W:$WaitTime",
                "/LOG:$logFilePath"
            )

            # Add exclude arguments if provided
            if ($Exclude) {
                $excludeDirs = $Exclude | ForEach-Object { "/XD $_" }
                $excludeFiles = $Exclude | ForEach-Object { "/XF $_" }
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

            Handle-RobocopyExitCode -ExitCode $process.ExitCode
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while copying files with Robocopy: $_" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    end {
        Write-EnhancedLog -Message "Copy-FilesWithRobocopy function execution completed." -Level "INFO"
    }
}
