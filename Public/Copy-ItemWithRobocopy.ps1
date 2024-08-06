function Copy-ItemsWithRobocopy {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    Begin {
        Write-EnhancedLog -Message "Starting Copy-ItemsWithRobocopy function" -Level "INFO"
        Log-Params -Params @{
            SourcePath = $SourcePath
            DestinationPath = $DestinationPath
        }

        # Ensure the destination directory 'DownloadsBackup' exists
        $finalDestinationPath = Join-Path -Path $DestinationPath -ChildPath "DownloadsBackup"
        if (-not (Test-Path -Path $finalDestinationPath)) {
            New-Item -ItemType Directory -Force -Path $finalDestinationPath | Out-Null
        }
    }

    Process {
        try {
            # Use Robocopy for copying. /E is for copying subdirectories including empty ones. /R:0 and /W:0 are for no retries and no wait between retries.
            # Ensure to add a trailing backslash to the source path to copy its contents
            $robocopyArgs = @("${SourcePath}\", $finalDestinationPath, "/E", "/R:0", "/W:0")

            $result = robocopy @robocopyArgs
            switch ($LASTEXITCODE) {
                0 { Write-EnhancedLog -Message "No files were copied. No files were mismatched. No failures were encountered." -Level "INFO" }
                1 { Write-EnhancedLog -Message "All files were copied successfully." -Level "INFO" }
                2 { Write-EnhancedLog -Message "There are some additional files in the destination directory that are not present in the source directory. No files were copied." -Level "INFO" }
                3 { Write-EnhancedLog -Message "Some files were copied. Additional files were present. No failure was encountered." -Level "INFO" }
                4 { Write-EnhancedLog -Message "Some files were mismatched. No files were copied." -Level "INFO" }
                5 { Write-EnhancedLog -Message "Some files were copied. Some files were mismatched. No failure was encountered." -Level "INFO" }
                6 { Write-EnhancedLog -Message "Additional files and mismatched files exist. No files were copied." -Level "INFO" }
                7 { Write-EnhancedLog -Message "Files were copied, a file mismatch was present, and additional files were present." -Level "INFO" }
                8 { Write-EnhancedLog -Message "Several files did not copy." -Level "ERROR" }
                default { Write-EnhancedLog -Message "Robocopy failed with exit code $LASTEXITCODE" -Level "ERROR" }
            }
        } catch {
            Write-EnhancedLog -Message "An error occurred in Copy-ItemsWithRobocopy function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Copy-ItemsWithRobocopy function" -Level "INFO"
    }
}
