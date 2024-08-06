function Verify-CopyOperation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    begin {
        Write-EnhancedLog -Message "Verifying copy operation..." -Level "INFO"
        Log-Params -Params @{
            SourcePath = $SourcePath
            DestinationPath = $DestinationPath
        }

        $sourceItems = Get-ChildItem -Path $SourcePath -Recurse
        $destinationItems = Get-ChildItem -Path $DestinationPath -Recurse

        # Use a generic list for better performance compared to using an array with +=
        $verificationResults = New-Object System.Collections.Generic.List[Object]
    }

    process {
        try {
            foreach ($item in $sourceItems) {
                $relativePath = $item.FullName.Substring($SourcePath.Length)
                $correspondingPath = Join-Path -Path $DestinationPath -ChildPath $relativePath

                if (-not (Test-Path -Path $correspondingPath)) {
                    $verificationResults.Add([PSCustomObject]@{
                            Status       = "Missing"
                            SourcePath   = $item.FullName
                            ExpectedPath = $correspondingPath
                        })
                }
            }

            foreach ($item in $destinationItems) {
                $relativePath = $item.FullName.Substring($DestinationPath.Length)
                $correspondingPath = Join-Path -Path $SourcePath -ChildPath $relativePath

                if (-not (Test-Path -Path $correspondingPath)) {
                    $verificationResults.Add([PSCustomObject]@{
                            Status     = "Extra"
                            SourcePath = $correspondingPath
                            ActualPath = $item.FullName
                        })
                }
            }
        }
        catch {
            Write-EnhancedLog -Message "Error during verification process: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    end {
        if ($verificationResults.Count -gt 0) {
            Write-EnhancedLog -Message "Discrepancies found. See detailed log." -Level "WARNING"
            $verificationResults | Format-Table -AutoSize | Out-String | ForEach-Object { 
                Write-EnhancedLog -Message $_ -Level "INFO" 
            }

            #Uncomment when troubelshooting
            $verificationResults | Out-GridView
        }
        else {
            Write-EnhancedLog -Message "All items verified successfully. No discrepancies found." -Level "INFO"
        }

        Write-EnhancedLog -Message ("Total items in source: " + $sourceItems.Count) -Level "INFO"
        Write-EnhancedLog -Message ("Total items in destination: " + $destinationItems.Count) -Level "INFO"
    }
}


# # Define the source and destination paths
# $sourcePath = "C:\Source"
# $destinationPath = "C:\Destination"

# # Example usage of the Verify-CopyOperation function
# Verify-CopyOperation -SourcePath $sourcePath -DestinationPath $destinationPath

