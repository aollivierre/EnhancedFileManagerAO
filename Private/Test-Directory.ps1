function Test-Directory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Path
    )

    begin {
        Write-EnhancedLog -Message "Starting Test-Directory function" -Level "INFO"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    process {
        try {
            if (-Not (Test-Path -Path $Path -PathType Container)) {
                Write-EnhancedLog -Message "The path '$Path' is not a valid directory." -Level "ERROR"
                throw "The path '$Path' is not a valid directory."
            } else {
                Write-EnhancedLog -Message "The path '$Path' is a valid directory." -Level "INFO"
            }
        } catch {
            Write-EnhancedLog -Message "An error occurred during directory validation: $_" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    end {
        Write-EnhancedLog -Message "Test-Directory function execution completed." -Level "INFO"
    }
}
