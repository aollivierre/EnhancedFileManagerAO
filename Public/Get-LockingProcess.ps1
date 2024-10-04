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
    
            # Run Handle and suppress copyright and EULA lines
            $handleOutput = &"$HandlePath" $FilePath 2>&1 | Where-Object {
                $_ -notmatch "Sysinternals|Copyright|Handle viewer|EULA" -and $_.Trim() -ne ""
            }
            $processes = @()
    
            if ($handleOutput) {
                Write-EnhancedLog -Message "Processing output from Handle" -Level "INFO"
    
                # Refine the parsing logic to ignore invalid lines
                foreach ($line in $handleOutput) {
                    if ($line -match '^\s*([^\s]+)\s+pid:\s*(\d+)\s+type:\s*\w+\s*(.*)$') {
                        $processName = $matches[1]
                        $processId = $matches[2]
    
                        # Add to the processes array
                        $processes += [PSCustomObject]@{
                            ProcessId   = $processId
                            ProcessName = $processName
                            FilePath    = $FilePath
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