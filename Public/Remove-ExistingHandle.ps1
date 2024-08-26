function Remove-ExistingHandle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetFolder
    )

    # Full path for Handle64.exe
    $Handle64Path = Join-Path -Path $TargetFolder -ChildPath "Handle64.exe"

    try {
        # Check if Handle64.exe exists
        if (Test-Path -Path $Handle64Path) {
            Write-EnhancedLog -Message "Removing existing Handle64.exe from: $TargetFolder" -Level "INFO"
            # Remove Handle64.exe
            Remove-Item -Path $Handle64Path -Force
            Write-EnhancedLog -Message "Handle64.exe has been removed from: $TargetFolder" -Level "INFO"
        }
        else {
            Write-EnhancedLog -Message "No Handle64.exe file found in: $TargetFolder" -Level "INFO"
        }
    }
    catch {
        # Handle any errors during the removal
        Write-EnhancedLog -Message "An error occurred while trying to remove Handle64.exe: $($_.Exception.Message)" -Level "ERROR"
        Handle-Error -ErrorRecord $_
    }
}
