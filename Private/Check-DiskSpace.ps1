function Check-DiskSpace {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [int]$RequiredSpaceGB
    )

    begin {
        Write-EnhancedLog -Message "Starting Check-DiskSpace function" -Level "INFO"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    process {
        try {
            $drive = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -eq ([System.IO.Path]::GetPathRoot($Path)) }
            if ($drive -and ($drive.Free -lt ($RequiredSpaceGB * 1GB))) {
                Write-EnhancedLog -Message "Not enough disk space on drive $($drive.Root). Required: $RequiredSpaceGB GB, Available: $([math]::round($drive.Free / 1GB, 2)) GB." -Level "ERROR"
                throw "Not enough disk space on drive $($drive.Root)."
            } else {
                Write-EnhancedLog -Message "Sufficient disk space available on drive $($drive.Root)." -Level "INFO"
            }
        } catch {
            Write-EnhancedLog -Message "An error occurred during disk space check: $_" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    end {
        Write-EnhancedLog -Message "Check-DiskSpace function execution completed." -Level "INFO"
    }
}
