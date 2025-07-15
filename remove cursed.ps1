<#
.SYNOPSIS
    Reverts changes made by the malicious extension loader script.
.DESCRIPTION
    - Removes leftover extension files from %TEMP%.
    - Restores Chrome/Edge shortcuts by removing "--load-extension" arguments.
.NOTES
    Run as Administrator to ensure full cleanup.
#>

# ------ Phase 1: Delete leftover extension files in TEMP ------
Write-Host "Scanning for leftover extension files in TEMP..." -ForegroundColor Cyan

# Search for folders containing "extension.zip" or "manifest.json" in TEMP
$tempDir = [System.IO.Path]::GetTempPath()
$suspiciousFolders = Get-ChildItem -Path $tempDir -Directory -Recurse -ErrorAction SilentlyContinue | 
    Where-Object {
        Test-Path "$($_.FullName)\extension.zip" -PathType Leaf -ErrorAction SilentlyContinue -or
        (Get-ChildItem -Path $_.FullName -Filter "manifest.json" -File -Recurse -ErrorAction SilentlyContinue)
    }

if ($suspiciousFolders) {
    Write-Host "Found suspicious folders in TEMP:" -ForegroundColor Yellow
    $suspiciousFolders | ForEach-Object { Write-Host "-> $($_.FullName)" }

    # Delete the folders
    $suspiciousFolders | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Deleted suspicious temp folders." -ForegroundColor Green
} else {
    Write-Host "No leftover extension files found in TEMP." -ForegroundColor Green
}

# ------ Phase 2: Revert modified shortcuts ------
Write-Host "Scanning for modified Chrome/Edge shortcuts..." -ForegroundColor Cyan

# Define common shortcut locations
$userProfile = [Environment]::GetFolderPath("UserProfile")
$searchPaths = @(
    "$userProfile\Desktop",
    "$userProfile\OneDrive\Desktop",
    "$userProfile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup",
    "$userProfile\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
)

# Include 1 level deep subfolders
$allPaths = $searchPaths | Where-Object { Test-Path $_ } | ForEach-Object {
    $_
    Get-ChildItem -Path $_ -Directory -Depth 1 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
}

# Find all .lnk files
$shell = New-Object -ComObject WScript.Shell
$modifiedShortcuts = 0

$allPaths | ForEach-Object {
    Get-ChildItem -Path $_ -Filter *.lnk -File -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $shortcut = $shell.CreateShortcut($_.FullName)
            $target = $shortcut.TargetPath
            $args = $shortcut.Arguments

            # Check if this is a Chrome/Edge shortcut with --load-extension
            if (($target -like "*chrome.exe*" -or $target -like "*msedge.exe*") -and 
                $args -match "--load-extension") {
                
                # Remove the --load-extension argument
                $newArgs = $args -replace '--load-extension[ =][^ ]+', ''
                $shortcut.Arguments = $newArgs.Trim()
                $shortcut.Save()

                Write-Host "Fixed shortcut: $($_.FullName)" -ForegroundColor Green
                $modifiedShortcuts++
            }
        } catch {
            Write-Host "Failed to process shortcut: $($_.FullName)" -ForegroundColor Red
        }
    }
}

# Summary
Write-Host "`nCleanup completed!" -ForegroundColor Cyan
Write-Host "- Deleted leftover folders: $($suspiciousFolders.Count)" -ForegroundColor Yellow
Write-Host "- Fixed modified shortcuts: $modifiedShortcuts" -ForegroundColor Yellow

# ------ Optional: Check for installed extensions (manual step) ------
Write-Host "`n[Manual Step] Check browser extensions:" -ForegroundColor Magenta
Write-Host "1. Open Chrome/Edge and go to: chrome://extensions" -ForegroundColor Magenta
Write-Host "2. Remove any suspicious extensions." -ForegroundColor Magenta