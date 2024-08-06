function Handle-RobocopyExitCode {
    <#
    .SYNOPSIS
    Handles the exit code from a Robocopy operation.

    .DESCRIPTION
    The Handle-RobocopyExitCode function interprets the exit code returned by a Robocopy operation and logs an appropriate message. The exit codes provide information about the success or failure of the operation and any additional conditions encountered.

    .PARAMETER ExitCode
    The exit code returned by Robocopy.

    .EXAMPLE
    Handle-RobocopyExitCode -ExitCode 0
    Logs a message indicating no files were copied, no files were mismatched, and no failures were encountered.

    .EXAMPLE
    Handle-RobocopyExitCode -ExitCode 1
    Logs a message indicating all files were copied successfully.

    .NOTES
    This function is typically used internally after executing a Robocopy command to handle and log the exit status.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$ExitCode
    )

    begin {
        Write-EnhancedLog -Message "Starting Handle-RobocopyExitCode function" -Level "INFO"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    process {
        try {
            switch ($ExitCode) {
                0 { Write-EnhancedLog -Message "No files were copied. No files were mismatched. No failures were encountered." -Level "INFO" }
                1 { Write-EnhancedLog -Message "All files were copied successfully." -Level "INFO" }
                2 { Write-EnhancedLog -Message "There are some additional files in the destination directory that are not present in the source directory. No files were copied." -Level "INFO" }
                3 { Write-EnhancedLog -Message "Some files were copied. Additional files were present. No failure was encountered." -Level "INFO" }
                4 { Write-EnhancedLog -Message "Some files were mismatched. No files were copied." -Level "INFO" }
                5 { Write-EnhancedLog -Message "Some files were copied. Some files were mismatched. No failure was encountered." -Level "INFO" }
                6 { Write-EnhancedLog -Message "Additional files and mismatched files exist. No files were copied." -Level "INFO" }
                7 { Write-EnhancedLog -Message "Files were copied, a file mismatch was present, and additional files were present." -Level "INFO" }
                8 { Write-EnhancedLog -Message "Several files did not copy." -Level "ERROR" }
                default { Write-EnhancedLog -Message "Robocopy failed with exit code $ExitCode" -Level "ERROR" }
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while handling the Robocopy exit code: $_" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    end {
        Write-EnhancedLog -Message "Handle-RobocopyExitCode function execution completed." -Level "INFO"
    }
}
