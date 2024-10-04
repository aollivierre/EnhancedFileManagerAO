function Show-LockingProcessWarningForm {
    param (
        [array]$Processes,
        [string]$FilePath
    )
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object system.windows.forms.Form
    $form.Text = "Processes Locking File"
    $form.Size = New-Object System.Drawing.Size(400, 300)
    $form.StartPosition = "CenterScreen"
    
    # Create a label for warning
    $label = New-Object system.windows.forms.Label
    $label.Text = "The following processes are locking the file: $FilePath. Please close them to proceed."
    $label.Size = New-Object System.Drawing.Size(360, 40)
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $form.Controls.Add($label)

    # Create a listbox to show locking processes
    $listBox = New-Object system.windows.forms.ListBox
    $listBox.Size = New-Object System.Drawing.Size(350, 100)
    $listBox.Location = New-Object System.Drawing.Point(20, 70)
    $Processes | ForEach-Object { $listBox.Items.Add("Process: $($_.ProcessName) (ID: $($_.ProcessId))") }
    $form.Controls.Add($listBox)

    # Create a refresh button
    $refreshButton = New-Object system.windows.forms.Button
    $refreshButton.Text = "Refresh"
    $refreshButton.Location = New-Object System.Drawing.Point(220, 200)
    $refreshButton.Add_Click({
        $form.DialogResult = [System.Windows.Forms.DialogResult]::Retry
        $form.Close()
    })
    $form.Controls.Add($refreshButton)

    # Create a cancel button
    $cancelButton = New-Object system.windows.forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Location = New-Object System.Drawing.Point(120, 200)
    $cancelButton.Add_Click({
        $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.Close()
    })
    $form.Controls.Add($cancelButton)

    # Show the form
    $form.Topmost = $true
    return $form.ShowDialog()
}


function Manage-LockingProcesses {
    param (
        [string]$FilePath,
        [string]$HandlePath
    )

    try {
        Write-EnhancedLog -Message "Starting Manage-LockingProcesses function" -Level "NOTICE"

        # Loop until no locking processes are found
        do {
            # Get locking processes and ensure it's treated as an array
            $lockingProcesses = @(Get-LockingProcess -FilePath $FilePath -HandlePath $HandlePath)

            if ($lockingProcesses.Count -gt 0) {
                # Log and show locking processes
                Write-EnhancedLog -Message "Processes found locking the file: $FilePath" -Level "WARNING"
                $lockingProcesses | ForEach-Object {
                    Write-EnhancedLog -Message "Process: $($_.ProcessName) (ID: $($_.ProcessId))" -Level "WARNING"
                }

                # Show the Windows Form with process warning
                $result = Show-LockingProcessWarningForm -Processes $lockingProcesses -FilePath $FilePath

                # If user cancels, stop the script
                if ($result -eq [System.Windows.Forms.DialogResult]::Cancel) {
                    Write-EnhancedLog -Message "User canceled the process management." -Level "ERROR"
                    throw "User canceled the process management."
                }

            }
            else {
                Write-EnhancedLog -Message "No processes are locking the file: $FilePath" -Level "INFO"
                break
            }

            # Sleep before the next check
            Start-Sleep -Seconds 5

        } until ($lockingProcesses.Count -eq 0)

    }
    catch {
        Handle-Error -ErrorRecord $_
    }
    finally {
        Write-EnhancedLog -Message "Exiting Manage-LockingProcesses function" -Level "NOTICE"
    }
}



# Manage-LockingProcesses -FilePath $FilePath -HandlePath $HandlePath