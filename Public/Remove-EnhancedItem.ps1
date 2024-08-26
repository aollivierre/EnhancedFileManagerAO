function Remove-EnhancedItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$ForceKillProcesses, # Option to force kill processes locking the files

        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 3, # Maximum number of retries

        [Parameter(Mandatory = $false)]
        [int]$RetryInterval = 5         # Interval between retries in seconds
    )

    Begin {
        Write-EnhancedLog -Message "Starting Remove-EnhancedItem function for path: $Path" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        $retryCount = 0
        $removedSuccessfully = $false

        while (-not $removedSuccessfully -and $retryCount -lt $MaxRetries) {
            try {
                Write-EnhancedLog -Message "Attempting to remove item: $Path (Attempt $($retryCount + 1) of $MaxRetries)" -Level "INFO"
                Remove-Item -Path $Path -Recurse -Force
                $removedSuccessfully = $true
                Write-EnhancedLog -Message "Successfully removed item: $Path" -Level "INFO"
            }
            catch {
                Write-EnhancedLog -Message "Error encountered while trying to remove item: $Path - $($_.Exception.Message)" -Level "ERROR"

                # Check if the error is due to the file being locked by another process
                if ($_.Exception.Message -match "being used by another process") {
                    Write-EnhancedLog -Message "Identifying processes locking the file or directory..." -Level "WARNING"

                    # Identify processes locking the file using Sysinternals Handle or similar tool
                    $lockingProcessesParams = @{
                        FilePath   = $Path
                        HandlePath = "C:\ProgramData\SystemTools\handle64.exe"
                    }
                    $lockingProcesses = Get-LockingProcess @lockingProcessesParams


                    if ($lockingProcesses) {
                        Write-EnhancedLog -Message "Processes locking the file or directory:" -Level "INFO"
                        $lockingProcesses | ForEach-Object {
                            Write-EnhancedLog -Message "Process ID: $($_.ProcessId), Process Name: $($_.ProcessName)" -Level "INFO"
                        }

                        # Optionally force kill processes
                        if ($ForceKillProcesses) {
                            Write-EnhancedLog -Message "Force killing processes locking the file or directory..." -Level "WARNING"
                            $lockingProcesses | ForEach-Object {
                                try {
                                    Stop-Process -Id $_.ProcessId -Force
                                    Write-EnhancedLog -Message "Successfully killed process ID: $($_.ProcessId), Process Name: $($_.ProcessName)" -Level "INFO"
                                }
                                catch {
                                    Write-EnhancedLog -Message "Failed to kill process ID: $($_.ProcessId), Process Name: $($_.ProcessName) - $($_.Exception.Message)" -Level "ERROR"
                                }
                            }
                        }
                    }
                    else {
                        Write-EnhancedLog -Message "No locking processes identified." -Level "WARNING"
                    }
                }

                # Increment retry count and wait before retrying
                $retryCount++
                if ($retryCount -lt $MaxRetries) {
                    Write-EnhancedLog -Message "Retrying removal in $RetryInterval seconds..." -Level "INFO"
                    Start-Sleep -Seconds $RetryInterval
                }
            }
        }

        if (-not $removedSuccessfully) {
            Write-EnhancedLog -Message "Failed to remove item: $Path after $MaxRetries attempts." -Level "CRITICAL"
            throw "Failed to remove item: $Path after $MaxRetries attempts."
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Remove-EnhancedItem function" -Level "Notice"
    }
}


# # Example usage with splatting
# $params = @{
#     FilePath   = "C:\Path\To\LockedFile.txt"
#     HandlePath = "C:\Users\Admin-Abdullah\Downloads\Handle\handle64.exe"
# }
# $lockingProcesses = Get-LockingProcess @params
