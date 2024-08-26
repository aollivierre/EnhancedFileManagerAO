function Verify-CopyOperation {
    <#
    .SYNOPSIS
    Verifies that files have been correctly copied between a source and destination directory.

    .DESCRIPTION
    The Verify-CopyOperation function compares the contents of a source directory with a destination directory to ensure that all files and directories have been successfully copied. 
    It reports missing files, extra files, and provides detailed information about any discrepancies found during the verification process.

    .PARAMETER SourcePath
    The path to the source directory whose contents are being copied and need verification.

    .PARAMETER DestinationPath
    The path to the destination directory where the files from the source have been copied.

    .EXAMPLE
    Verify-CopyOperation -SourcePath "C:\Source" -DestinationPath "C:\Destination"
    Verifies the copied contents between C:\Source and C:\Destination, checking for any discrepancies such as missing or extra files.

    .OUTPUTS
    Custom objects detailing missing, extra, or mismatched files between the source and destination.

    .NOTES
    The function uses recursion to verify subdirectories and outputs the results to the console.
    Any discrepancies between the source and destination directories are logged for analysis.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Provide the source directory path.")]
        [string]$SourcePath,

        [Parameter(Mandatory = $true, HelpMessage = "Provide the destination directory path.")]
        [string]$DestinationPath
    )

    begin {
        Write-EnhancedLog -Message "Verifying copy operation..." -Level "Notice"
        Log-Params -Params @{
            SourcePath = $SourcePath
            DestinationPath = $DestinationPath
        }

        $sourceItems = Get-ChildItem -Path $SourcePath -Recurse -File
        $destinationItems = Get-ChildItem -Path $DestinationPath -Recurse -File

        # Use a generic list for better performance compared to using an array with +=
        $verificationResults = [System.Collections.Generic.List[PSCustomObject]]::new()
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
                            FileSize     = $item.Length
                            LastModified = $item.LastWriteTime
                        })
                }
                else {
                    # Compare file sizes and timestamps
                    $destItem = Get-Item -Path $correspondingPath
                    if ($item.Length -ne $destItem.Length -or $item.LastWriteTime -ne $destItem.LastWriteTime) {
                        $verificationResults.Add([PSCustomObject]@{
                                Status       = "Mismatch"
                                SourcePath   = $item.FullName
                                ExpectedPath = $correspondingPath
                                SourceSize   = $item.Length
                                DestinationSize = $destItem.Length
                                SourceModified  = $item.LastWriteTime
                                DestinationModified = $destItem.LastWriteTime
                            })
                    }
                }
            }

            foreach ($item in $destinationItems) {
                $relativePath = $item.FullName.Substring($DestinationPath.Length)
                $correspondingPath = Join-Path -Path $SourcePath -ChildPath $relativePath

                if (-not (Test-Path -Path $correspondingPath)) {
                    $verificationResults.Add([PSCustomObject]@{
                            Status       = "Extra"
                            ActualPath   = $item.FullName
                            FileSize     = $item.Length
                            LastModified = $item.LastWriteTime
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

            # Uncomment when troubleshooting
            # $verificationResults | Out-GridView
        }
        else {
            Write-EnhancedLog -Message "All items verified successfully. No discrepancies found." -Level "Notice"
        }

        Write-EnhancedLog -Message ("Total items in source: $SourcePath " + $sourceItems.Count) -Level "INFO"
        Write-EnhancedLog -Message ("Total items in destination: $DestinationPath " + $destinationItems.Count) -Level "INFO"

        # Return the verification results for further processing
        return $verificationResults
    }
}