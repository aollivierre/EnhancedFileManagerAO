# function Remove-EnhancedItem {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string]$Path,

#         [Parameter(Mandatory = $false)]
#         [switch]$ForceKillProcesses, # Option to force kill processes locking the files

#         [Parameter(Mandatory = $false)]
#         [int]$MaxRetries = 3, # Maximum number of retries

#         [Parameter(Mandatory = $false)]
#         [int]$RetryInterval = 5         # Interval between retries in seconds
#     )

#     Begin {
#         Write-EnhancedLog -Message "Starting Remove-EnhancedItem function for path: $Path" -Level "Notice"
#         Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
#     }

#     Process {
#         # Validate before removal
#         $validationResultsBefore = Validate-PathExistsWithLogging -Paths $Path

#         if ($validationResultsBefore.TotalValidatedFiles -gt 0) {
#             $retryCount = 0
#             $removedSuccessfully = $false

#             while (-not $removedSuccessfully -and $retryCount -lt $MaxRetries) {
#                 try {
#                     Write-EnhancedLog -Message "Attempting to remove item: $Path (Attempt $($retryCount + 1) of $MaxRetries)" -Level "INFO"
#                     Remove-Item -Path $Path -Recurse -Force
#                     $removedSuccessfully = $true
#                     Write-EnhancedLog -Message "Successfully removed item: $Path" -Level "INFO"
#                 }
#                 catch {
#                     Write-EnhancedLog -Message "Error encountered while trying to remove item: $Path - $($_.Exception.Message)" -Level "ERROR"

#                     # Check if the error is due to the file being locked by another process
#                     if ($_.Exception.Message -match "being used by another process") {
#                         Write-EnhancedLog -Message "Identifying processes locking the file or directory..." -Level "WARNING"

#                         # Identify processes locking the file using Sysinternals Handle or similar tool
#                         $lockingProcessesParams = @{
#                             FilePath   = $Path
#                             HandlePath = "C:\ProgramData\SystemTools\handle64.exe"
#                         }
#                         $lockingProcesses = Get-LockingProcess @lockingProcessesParams

#                         if ($lockingProcesses) {
#                             Write-EnhancedLog -Message "Processes locking the file or directory:" -Level "INFO"
#                             $lockingProcesses | ForEach-Object {
#                                 Write-EnhancedLog -Message "Process ID: $($_.ProcessId), Process Name: $($_.ProcessName)" -Level "INFO"
#                             }

#                             # Optionally force kill processes
#                             if ($ForceKillProcesses) {
#                                 $lockingProcesses | ForEach-Object {
#                                     try {
#                                         Write-EnhancedLog -Message "Attempting to kill process ID: $($_.ProcessId), Process Name: $($_.ProcessName)" -Level "WARNING"
#                                         Stop-Process -Id $_.ProcessId -Force
#                                         Write-EnhancedLog -Message "Successfully killed process ID: $($_.ProcessId), Process Name: $($_.ProcessName)" -Level "INFO"
#                                     }
#                                     catch {
#                                         Write-EnhancedLog -Message "Failed to kill process ID: $($_.ProcessId), Process Name: $($_.ProcessName) - $($_.Exception.Message)" -Level "ERROR"
#                                     }
#                                 }
#                             }

#                             # Add a short delay before retrying to allow processes to terminate
#                             Start-Sleep -Seconds 2
#                         }
#                         else {
#                             Write-EnhancedLog -Message "No locking processes identified." -Level "WARNING"
#                         }
#                     }

#                     # Increment retry count and wait before retrying
#                     $retryCount++
#                     if ($retryCount -lt $MaxRetries) {
#                         Write-EnhancedLog -Message "Retrying removal in $RetryInterval seconds..." -Level "INFO"
#                         Start-Sleep -Seconds $RetryInterval
#                     }
#                 }
#             }

#             # Validate after removal
#             $validationResultsAfter = Validate-PathExistsWithLogging -Paths $Path

#             if ($removedSuccessfully -and $validationResultsAfter.TotalValidatedFiles -eq 0) {
#                 Write-EnhancedLog -Message "Item $Path successfully removed." -Level "CRITICAL"
#             }
#             else {
#                 Write-EnhancedLog -Message "Failed to remove item: $Path after $MaxRetries attempts." -Level "CRITICAL"
#                 throw "Failed to remove item: $Path after $MaxRetries attempts."
#             }
#         }
#         else {
#             Write-EnhancedLog -Message "Item $Path does not exist. No action taken." -Level "WARNING"
#         }
#     }

#     End {
#         Write-EnhancedLog -Message "Exiting Remove-EnhancedItem function" -Level "Notice"
#     }
# }




function Remove-EnhancedItem {
    <#
    .SYNOPSIS
    Removes a file or directory with enhanced logging and retry mechanisms.

    .DESCRIPTION
    This function attempts to remove the specified file or directory, with the option to forcefully kill processes that may be locking the file. It retries removal for a specified number of attempts if the file is locked, with a customizable delay between retries.

    .PARAMETER Path
    The full path of the file or directory to be removed.

    .PARAMETER ForceKillProcesses
    A switch that, when enabled, forces the termination of any processes that are locking the specified file or directory.

    .PARAMETER MaxRetries
    The maximum number of times the function will attempt to remove the item if it fails due to a locking process or other error. The default is 3 retries.

    .PARAMETER RetryInterval
    The number of seconds to wait between retries. The default is 5 seconds.

    .EXAMPLE
    Remove-EnhancedItem -Path "C:\temp\open.txt"

    Attempts to remove the file at C:\temp\open.txt, with the default retry mechanism if the file is locked.

    .EXAMPLE
    Remove-EnhancedItem -Path "C:\temp\open.txt" -ForceKillProcesses

    Attempts to remove the file at C:\temp\open.txt, forcefully terminating any locking processes if necessary.

    .EXAMPLE
    Remove-EnhancedItem -Path "C:\temp\open.txt" -MaxRetries 5 -RetryInterval 10

    Attempts to remove the file at C:\temp\open.txt, with a maximum of 5 retries and a 10-second wait between retries.

    .NOTES
    Author: Your Name
    Date: YYYY-MM-DD
    Version: 1.0
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$ForceKillProcesses, # Option to force kill processes locking the files

        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 3, # Maximum number of retries

        [Parameter(Mandatory = $false)]
        [int]$RetryInterval = 5 # Interval between retries in seconds
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
    
                # Verify the removal
                if (-not (Test-Path -Path $Path)) {
                    Write-EnhancedLog -Message "Successfully removed item: $Path" -Level "INFO"
                    $removedSuccessfully = $true
                }
                else {
                    Write-EnhancedLog -Message "Item $Path still exists after removal attempt." -Level "WARNING"


                    Write-EnhancedLog -Message "Error encountered while trying to remove item: $Path - $($_.Exception.Message)" -Level "ERROR"
    
                    # Use -like for simpler matching of the error message
                    # if ($_.Exception.Message -like "*being used by another process*") {
                    Write-EnhancedLog -Message "Identifying processes locking the file or directory..." -Level "WARNING"
        
                    # This will call Manage-LockingProcesses to attempt to identify and stop processes
                    Manage-LockingProcesses -FilePath $Path -HandlePath "C:\ProgramData\SystemTools\handle64.exe"
        
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
        
                        if ($ForceKillProcesses) {
                            $lockingProcesses | ForEach-Object {
                                try {
                                    Write-EnhancedLog -Message "Attempting to kill process ID: $($_.ProcessId), Process Name: $($_.ProcessName)" -Level "WARNING"
                                    & "C:\Windows\System32\taskkill.exe" /PID $_.ProcessId /F /T
                                    Write-EnhancedLog -Message "Successfully killed process ID: $($_.ProcessId), Process Name: $($_.ProcessName)" -Level "INFO"
                                }
                                catch {
                                    Write-EnhancedLog -Message "Failed to kill process ID: $($_.ProcessId), Process Name: $($_.ProcessName) - $($_.Exception.Message)" -Level "ERROR"
                                }
                            }
                            Start-Sleep -Seconds 5 # Delay to allow processes to terminate
                        }
                    }
                    else {
                        Write-EnhancedLog -Message "No locking processes identified." -Level "WARNING"
                    }

                }
            }


            catch {
                Write-EnhancedLog -Message "Error encountered while trying to remove item: $Path - $($_.Exception.Message)" -Level "ERROR"
                Write-EnhancedLog -Message "Identifying processes locking the file or directory..." -Level "WARNING"
                # This will call Manage-LockingProcesses to attempt to identify and stop processes
                Manage-LockingProcesses -FilePath $Path -HandlePath "C:\ProgramData\SystemTools\handle64.exe"
                Handle-Error -ErrorRecord $_
                throw
            }

            # catch {
             
            # }
            # else {
            #     Write-EnhancedLog -Message "Unexpected error occurred: $($_.Exception.Message)" -Level "ERROR"
            # }
            # }
    
            # Retry if the item wasn't removed
            if (-not $removedSuccessfully) {
                $retryCount++
                if ($retryCount -lt $MaxRetries) {
                    Write-EnhancedLog -Message "Retrying removal in $RetryInterval seconds (Attempt $($retryCount + 1) of $MaxRetries)..." -Level "INFO"
                    Start-Sleep -Seconds $RetryInterval
                }
                else {
                    Write-EnhancedLog -Message "Failed to remove item: $Path after $MaxRetries attempts." -Level "CRITICAL"
                    throw "Failed to remove item: $Path after $MaxRetries attempts."
                }
            }
        }
    }
    
    
    
    

    End {
        Write-EnhancedLog -Message "Exiting Remove-EnhancedItem function" -Level "Notice"
    }
}
