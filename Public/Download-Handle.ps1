function Download-Handle {
    <#
    .SYNOPSIS
    Downloads and extracts Handle64.exe from the official Sysinternals Handle package.

    .DESCRIPTION
    The Download-Handle function downloads the Handle package from the official Sysinternals website, extracts Handle64.exe, and places it in the specified target folder.

    .PARAMETER TargetFolder
    The target folder where Handle64.exe will be stored.

    .EXAMPLE
    $params = @{
        TargetFolder = "C:\ProgramData\SystemTools"
    }
    Download-Handle @params
    Downloads Handle64.exe to the specified target folder.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetFolder
    )

    Begin {
        Write-EnhancedLog -Message "Starting Download-Handle function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Ensure the target folder exists
        Ensure-TargetFolderExists -TargetFolder $TargetFolder
        Write-EnhancedLog -Message "Removing existing Handle from target folder: $TargetFolder" -Level "INFO"
        
        Remove-ExistingHandle -TargetFolder $TargetFolder
    }

    Process {
        try {
            # Define the URL for Handle download
            $url = "https://download.sysinternals.com/files/Handle.zip"
            # Full path for the downloaded file
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $zipPath = Join-Path -Path $TargetFolder -ChildPath "Handle_$timestamp.zip"

            # Download the Handle.zip file with retry logic
            Write-EnhancedLog -Message "Downloading Handle.zip from: $url to: $zipPath" -Level "INFO"
            
            $downloadParams = @{
                Source      = $url
                Destination = $zipPath
                MaxRetries  = 3
            }
            Start-FileDownloadWithRetry @downloadParams

            # Extract Handle64.exe from the zip file
            Write-EnhancedLog -Message "Extracting Handle.zip to: $TargetFolder\Handle" -Level "INFO"
            Expand-Archive -Path $zipPath -DestinationPath "$TargetFolder\Handle" -Force

            # Specific extraction of Handle64.exe
            $extractedFolderPath = Join-Path -Path $TargetFolder -ChildPath "Handle"
            $Handle64Path = Join-Path -Path $extractedFolderPath -ChildPath "Handle64.exe"
            $finalPath = Join-Path -Path $TargetFolder -ChildPath "Handle64.exe"

            # Move Handle64.exe to the desired location
            if (Test-Path -Path $Handle64Path) {
                Write-EnhancedLog -Message "Moving Handle64.exe from: $Handle64Path to: $finalPath" -Level "INFO"
                Move-Item -Path $Handle64Path -Destination $finalPath

                # Remove the downloaded zip file and extracted folder
                Write-EnhancedLog -Message "Removing downloaded zip file and extracted folder" -Level "INFO"
                Remove-Item -Path $zipPath -Force
                Remove-Item -Path $extractedFolderPath -Recurse -Force

                Write-EnhancedLog -Message "Handle64.exe has been successfully downloaded and moved to: $finalPath" -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "Handle64.exe not found in the extracted files." -Level "ERROR"
                throw "Handle64.exe not found after extraction."
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Download-Handle function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Download-Handle function" -Level "Notice"
    }
}

# Example usage
# $params = @{
#     TargetFolder = "C:\ProgramData\SystemTools"
# }
# Download-Handle @params
