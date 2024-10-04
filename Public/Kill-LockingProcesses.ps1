function Stop-ProcessTree {
    param (
        [int]$ParentId
    )

    # Get all child processes of the parent
    $childProcesses = Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq $ParentId }

    # Recursively stop all child processes
    foreach ($childProcess in $childProcesses) {
        Stop-ProcessTree -ParentId $childProcess.ProcessId
    }

    # Finally, stop the parent process
    Stop-Process -Id $ParentId -Force
}

# Usage example:
# Stop-ProcessTree -ParentId <ProcessId>


function Kill-LockingProcesses {
    <#
    .SYNOPSIS
    Kills processes that are locking a specified file.

    .DESCRIPTION
    The Kill-LockingProcesses function finds processes that are locking a specified file and terminates them forcefully.

    .PARAMETER LockedFile
    The path to the locked file.

    .EXAMPLE
    Kill-LockingProcesses -LockedFile "C:\Path\To\LockedFile.txt"
    Finds and kills processes locking the specified file.

    .NOTES
    This function relies on the Find-LockingProcesses function to identify locking processes.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LockedFile
    )

    Begin {
        Write-EnhancedLog -Message "Starting Kill-LockingProcesses function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Manage-LockingProcesses -FilePath $FilePath -HandlePath $HandlePath
            Manage-LockingProcesses -FilePath $LockedFile -HandlePath "C:\ProgramData\SystemTools\handle64.exe"
    
            Write-EnhancedLog -Message "Getting processes locking file: $LockedFile" -Level "INFO"
            $lockingProcesses = Get-LockingProcess -FilePath $LockedFile -HandlePath "C:\ProgramData\SystemTools\handle64.exe"
        
            if ($lockingProcesses) {
                foreach ($process in $lockingProcesses) {
                    $retryCount = 0
                    $processKilled = $false
    
                    while (-not $processKilled -and $retryCount -lt 3) {
                        try {
                            Write-EnhancedLog -Message "Attempting to kill process $($process.ProcessName) (ID: $($process.ProcessId)) locking the file $LockedFile using taskkill.exe" -Level "INFO"
    
                            # Try killing the process using taskkill.exe (with /T for tree)
                            & "C:\Windows\System32\taskkill.exe" /PID $process.ProcessId /F /T
    
                            Write-EnhancedLog -Message "Successfully killed process $($process.ProcessName) (ID: $($process.ProcessId)) using taskkill.exe" -Level "INFO"
                            $processKilled = $true
                        }
                        catch {
                            Write-EnhancedLog -Message "Failed to kill process $($process.ProcessName) (ID: $($process.ProcessId)) using taskkill.exe - $($_.Exception.Message)" -Level "WARNING"
    
                            # Retry using Stop-ProcessTree as fallback
                            if ($retryCount -eq 2) {
                                Write-EnhancedLog -Message "Attempting to kill process $($process.ProcessName) (ID: $($process.ProcessId)) using Stop-ProcessTree" -Level "WARNING"
                                Stop-ProcessTree -ParentId $process.ProcessId
                                Write-EnhancedLog -Message "Successfully killed process $($process.ProcessName) (ID: $($process.ProcessId)) using Stop-ProcessTree" -Level "INFO"
                                $processKilled = $true
                            }
                        }
    
                        # Wait for 5 seconds before retrying
                        if (-not $processKilled) {
                            Write-EnhancedLog -Message "Retrying to kill process $($process.ProcessName) (ID: $($process.ProcessId)) in 5 seconds..." -Level "INFO"
                            Start-Sleep -Seconds 5
                            $retryCount++
                        }
                    }
    
                    if (-not $processKilled) {
                        Write-EnhancedLog -Message "Failed to kill process $($process.ProcessName) (ID: $($process.ProcessId)) after 3 attempts." -Level "CRITICAL"
                    }
                }
            }
            else {
                Write-EnhancedLog -Message "No processes found locking the file: $LockedFile" -Level "INFO"
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while killing locking processes: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }
    
    

    End {
        Write-EnhancedLog -Message "Exiting Kill-LockingProcesses function" -Level "Notice"
    }
}

# Example usage
# Kill-LockingProcesses -LockedFile "C:\Path\To\LockedFile.txt"
