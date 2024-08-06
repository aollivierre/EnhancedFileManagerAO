function Copy-FilesToPathWithKill {
    <#
    .SYNOPSIS
    Copies all files and folders in the specified source directory to the specified destination path, and kills any processes that lock files preventing the copy operation.

    .DESCRIPTION
    This function copies all files and folders located in the specified source directory to the specified destination path. If any files are locked by other processes, the function identifies and kills those processes, then retries the copy operation.

    .PARAMETER SourcePath
    The source path from where the files and folders will be copied.

    .PARAMETER DestinationPath
    The destination path where the files and folders will be copied.

    .EXAMPLE
    Copy-FilesToPathWithKill -SourcePath "C:\Source" -DestinationPath "C:\Temp"

    This example copies all files and folders in the "C:\Source" directory to the "C:\Temp" directory.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    Begin {
        Write-EnhancedLog -Message "Starting the copy process from the Source Path $SourcePath to $DestinationPath" -Level "INFO"
        Log-Params -Params @{
            SourcePath = $SourcePath
            DestinationPath = $DestinationPath
        }

        # Ensure the destination directory exists
        if (-not (Test-Path -Path $DestinationPath)) {
            New-Item -Path $DestinationPath -ItemType Directory | Out-Null
        }
    }

    Process {
        try {
            # Attempt the copy operation
            $copyParams = @{
                Path        = "$SourcePath\*"
                Destination = $DestinationPath
                Recurse     = $true
                Force       = $true
                ErrorAction = "Stop"
            }
            Copy-Item @copyParams

            Write-EnhancedLog -Message "All items copied successfully from the Source Path $SourcePath to $DestinationPath." -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "Error occurred during the copy process: $_" -Level "ERROR"
            Handle-Error -ErrorRecord $_

            # Check if the error is due to a file being in use by another process
            if ($_.Exception -match "because it is being used by another process") {
                Write-EnhancedLog -Message "Attempting to find and kill the process locking the file." -Level "WARNING"
                try {
                    # Find the process locking the file
                    $lockedFile = $_.Exception.Message -match "'(.+?)'" | Out-Null
                    $lockedFile = $matches[1]

                    $lockingProcesses = Get-Process | Where-Object { $_.Modules | Where-Object { $_.FileName -eq $lockedFile } }

                    foreach ($process in $lockingProcesses) {
                        Write-EnhancedLog -Message "Killing process $($process.Id) locking the file $lockedFile" -Level "INFO"
                        Stop-Process -Id $process.Id -Force -Confirm:$false
                    }

                    # Retry the copy operation
                    Copy-Item @copyParams
                    Write-EnhancedLog -Message "Copy operation retried and succeeded." -Level "INFO"
                }
                catch {
                    Write-EnhancedLog -Message "Failed to find or kill the process locking the file: $lockedFile" -Level "ERROR"
                    Handle-Error -ErrorRecord $_
                }
            }
        }
    }

    End {
        Write-EnhancedLog -Message "Copy process completed." -Level "INFO"
    }
}



# Copy-FilesToPathWithKill -SourcePath "C:\Source" -DestinationPath "C:\Temp"
