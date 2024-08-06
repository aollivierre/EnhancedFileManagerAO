function Copy-FileToPublicAndTemp {
    <#
    .SYNOPSIS
    Copies a specified file to the public desktop and C:\temp, making it available to all users and in the temp directory.

    .DESCRIPTION
    This function copies a specified file to the public desktop and C:\temp, ensuring it is available to all users and also in the temp directory. Enhanced logging is used for feedback and error handling.

    .PARAMETER SourceFilePath
    The path of the file to be copied.

    .EXAMPLE
    Copy-FileToPublicAndTemp -SourceFilePath "C:\Path\To\fcremove.exe"

    This example copies the file "fcremove.exe" to the public desktop and C:\temp, making it available to all users and in the temp directory.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceFilePath
    )

    begin {
        Write-EnhancedLog -Message 'Starting Copy-FileToPublicAndTemp function' -Level 'INFO'
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    process {
        try {
            if (-not (Test-Path -Path $SourceFilePath)) {
                Write-EnhancedLog -Message "Source file not found: $SourceFilePath" -Level "ERROR"
                throw "Source file not found: $SourceFilePath"
            }

            # Define the destination paths
            $publicDesktopPath = 'C:\Users\Public\Desktop'
            $tempPath = 'C:\temp'

            # Ensure the public desktop directory exists
            $publicDesktopParams = @{
                Path      = $publicDesktopPath
                ItemType  = 'Directory'
                Force     = $true
                ErrorAction = 'Stop'
            }
            if (-not (Test-Path -Path $publicDesktopPath)) {
                Write-EnhancedLog -Message "Public desktop path not found. Creating directory." -Level "INFO"
                New-Item @publicDesktopParams | Out-Null
            }

            # Ensure the temp directory exists
            $tempParams = @{
                Path      = $tempPath
                ItemType  = 'Directory'
                Force     = $true
                ErrorAction = 'Stop'
            }
            if (-not (Test-Path -Path $tempPath)) {
                Write-EnhancedLog -Message "Temp path not found. Creating directory." -Level "INFO"
                New-Item @tempParams | Out-Null
            }

            # Copy the file to the public desktop
            $destinationFilePathPublic = Join-Path -Path $publicDesktopPath -ChildPath (Split-Path -Leaf $SourceFilePath)
            $copyParamsPublic = @{
                Path        = $SourceFilePath
                Destination = $destinationFilePathPublic
                Force       = $true
                ErrorAction = 'Stop'
            }
            Write-EnhancedLog -Message "Copying file to: $destinationFilePathPublic" -Level "INFO"
            Copy-Item @copyParamsPublic
            Write-EnhancedLog -Message "File copied to: $destinationFilePathPublic" -Level "INFO"

            # Copy the file to the temp directory
            $destinationFilePathTemp = Join-Path -Path $tempPath -ChildPath (Split-Path -Leaf $SourceFilePath)
            $copyParamsTemp = @{
                Path        = $SourceFilePath
                Destination = $destinationFilePathTemp
                Force       = $true
                ErrorAction = 'Stop'
            }
            Write-EnhancedLog -Message "Copying file to: $destinationFilePathTemp" -Level "INFO"
            Copy-Item @copyParamsTemp
            Write-EnhancedLog -Message "File copied to: $destinationFilePathTemp" -Level "INFO"

        } catch {
            Write-EnhancedLog -Message "An error occurred while copying the file: $_" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    end {
        Write-EnhancedLog -Message 'Copy-FileToPublicAndTemp function completed' -Level 'INFO'
    }
}
