function Validate-FileExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (-Not (Test-Path -Path $FilePath)) {
        Write-EnhancedLog -Message "File '$FilePath' does not exist." -Level "ERROR"
        throw "File '$FilePath' does not exist."
    }
}


