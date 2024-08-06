
function Test-Robocopy {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RobocopyPath = "C:\Windows\System32\Robocopy.exe"
    )

    begin {
        Write-EnhancedLog -Message "Starting Test-Robocopy function" -Level "INFO"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    process {
        try {
            if (-Not (Test-Path -Path $RobocopyPath)) {
                Write-EnhancedLog -Message "Robocopy.exe is not available at the specified path: $RobocopyPath" -Level "ERROR"
                throw "Robocopy.exe is not available at the specified path: $RobocopyPath"
            }
            else {
                Write-EnhancedLog -Message "Robocopy.exe is available at the specified path: $RobocopyPath" -Level "INFO"
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred during Robocopy availability check: $_" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    end {
        Write-EnhancedLog -Message "Test-Robocopy function execution completed." -Level "INFO"
    }
}
