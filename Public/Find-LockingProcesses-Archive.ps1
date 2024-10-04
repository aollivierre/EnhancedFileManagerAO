# function Find-LockingProcesses {
#     <#
#     .SYNOPSIS
#     Finds processes that are locking a specified file.

#     .DESCRIPTION
#     The Find-LockingProcesses function identifies processes that are locking a specified file by checking the modules loaded by each process.

#     .PARAMETER LockedFile
#     The path to the locked file.

#     .EXAMPLE
#     $lockingProcesses = Find-LockingProcesses -LockedFile "C:\Path\To\LockedFile.txt"
#     Finds processes locking the specified file and returns the processes.

#     .NOTES
#     This function relies on the Get-Process cmdlet and its ability to enumerate loaded modules.
#     #>

#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string]$LockedFile
#     )

#     Begin {
#         Write-EnhancedLog -Message "Starting Find-LockingProcesses function" -Level "Notice"
#         Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
#     }

#     Process {
#         try {
#             Write-EnhancedLog -Message "Finding processes locking file: $LockedFile" -Level "INFO"
#             $lockingProcesses = Get-Process | Where-Object { $_.Modules | Where-Object { $_.FileName -eq $LockedFile } }
#             if ($lockingProcesses) {
#                 foreach ($process in $lockingProcesses) {
#                     Write-EnhancedLog -Message "Process locking the file: $($process.ProcessName) (ID: $($process.Id))" -Level "INFO"
#                 }
#             } else {
#                 Write-EnhancedLog -Message "No processes found locking the file: $LockedFile" -Level "INFO"
#             }
#             return $lockingProcesses
#         }
#         catch {
#             Write-EnhancedLog -Message "An error occurred while finding locking processes: $($_.Exception.Message)" -Level "ERROR"
#             Handle-Error -ErrorRecord $_
#         }
#     }

#     End {
#         Write-EnhancedLog -Message "Exiting Find-LockingProcesses function" -Level "Notice"
#     }
# }

# # Example usage
# # $lockingProcesses = Find-LockingProcesses -LockedFile "C:\Path\To\LockedFile.txt"
