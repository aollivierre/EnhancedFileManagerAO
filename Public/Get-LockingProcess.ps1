
function Get-LockingProcess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$HandlePath  # Path to handle64.exe
    )

    Begin {
        Write-EnhancedLog -Message "Starting Get-LockingProcess function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        $DownloadHandleParams = @{
            TargetFolder = "C:\ProgramData\SystemTools"
        }
        Download-Handle @DownloadHandleParams
        


        # Validate the HandlePath
        if (-not (Test-Path -Path $HandlePath)) {
            Write-EnhancedLog -Message "Handle executable not found at path: $HandlePath" -Level "ERROR"
            throw "Handle executable not found at path: $HandlePath"
        }

        Write-EnhancedLog -Message "Handle executable found at path: $HandlePath" -Level "INFO"
    }

    Process {
        try {
            Write-EnhancedLog -Message "Identifying processes locking file: $FilePath using Handle" -Level "INFO"
            $handleOutput = &"$HandlePath" $FilePath 2>&1
            $processes = @()

            if ($handleOutput) {
                Write-EnhancedLog -Message "Processing output from Handle" -Level "INFO"
                foreach ($line in $handleOutput) {
                    if ($line -match 'pid:\s*(\d+)\s*type:\s*\w+\s*([^\s]+)\s*') {
                        $processId = $matches[1]
                        $processName = $matches[2]
                        $processes += [PSCustomObject]@{
                            ProcessId   = $processId
                            ProcessName = $processName
                        }
                        Write-EnhancedLog -Message "Found locking process: ID = $processId, Name = $processName" -Level "INFO"
                    }
                }
            }
            else {
                Write-EnhancedLog -Message "No output received from Handle. No locking processes found for file: $FilePath" -Level "WARNING"
            }

            return $processes
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while identifying locking processes: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Get-LockingProcess function" -Level "Notice"
    }
}