function Get-ChromiumProfilesFull {
    param (
        [string]$BrowserName,
        [string]$BasePath
    )

    $LocalStatePath = Join-Path $BasePath 'Local State'
    if (-not (Test-Path $LocalStatePath)) {
        Write-Warning "$BrowserName not installed or Local State missing."
        return
    }

    try {
        $localState = Get-Content $LocalStatePath -Raw | ConvertFrom-Json
        $infoCache = $localState.profile.info_cache
    } catch {
        Write-Warning "Failed to parse Local State for $BrowserName"
        return
    }

    $results = foreach ($profileKey in $infoCache.PSObject.Properties.Name) {
        $profileData = $infoCache.$profileKey

        $displayName = $profileData.name
        $email = $null

        if ($profileData.PSObject.Properties["account_info"]) {
            $accountInfo = $profileData.account_info
            if ($accountInfo.Count -gt 0) {
                $email = $accountInfo[0].email
            }
        }

        if (-not $email -and $profileData.PSObject.Properties["user_name"]) {
            $email = $profileData.user_name
        }

        [PSCustomObject]@{
            Browser      = $BrowserName
            Profile_ID   = $profileKey
            Profile_Name = $displayName
            Email        = $email
        }
    }

    return $results
}

function Get-FirefoxProfiles {
    $iniPath = "$env:APPDATA\Mozilla\Firefox\profiles.ini"
    if (-not (Test-Path $iniPath)) {
        Write-Warning "Firefox not installed or no profiles.ini found."
        return
    }

    $iniContent = Get-Content $iniPath -Raw
    $profiles = @()
    $currentProfile = @{}

    foreach ($line in $iniContent -split "`n") {
        $trimmed = $line.Trim()
        if ($trimmed -eq "") { continue }

        if ($trimmed -like "[Profile*]") {
            if ($currentProfile.Count -gt 0) {
                $profiles += [PSCustomObject]@{
                    Browser      = "Firefox"
                    Profile_ID   = $currentProfile["Path"]
                    Profile_Name = $currentProfile["Name"]
                    Email        = "(N/A)"
                }
                $currentProfile = @{}
            }
        } elseif ($trimmed -match "^(.+?)=(.+)$") {
            $currentProfile[$matches[1]] = $matches[2]
        }
    }

    # Add last profile
    if ($currentProfile.Count -gt 0) {
        $profiles += [PSCustomObject]@{
            Browser      = "Firefox"
            Profile_ID   = $currentProfile["Path"]
            Profile_Name = $currentProfile["Name"]
            Email        = "(N/A)"
        }
    }

    return $profiles
}

# === RUN ALL BROWSERS ===
$allProfiles = @()

$allProfiles += Get-ChromiumProfilesFull -BrowserName "Chrome" -BasePath "$env:LOCALAPPDATA\Google\Chrome\User Data"
$allProfiles += Get-ChromiumProfilesFull -BrowserName "Edge" -BasePath "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
$allProfiles += Get-ChromiumProfilesFull -BrowserName "Brave" -BasePath "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
$allProfiles += Get-ChromiumProfilesFull -BrowserName "Opera" -BasePath "$env:APPDATA\Opera Software\Opera Stable"
$allProfiles += Get-FirefoxProfiles

# Output results
$allProfiles | Format-Table -AutoSize
