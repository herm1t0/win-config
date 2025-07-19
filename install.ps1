function Test-ScriptIntegrity {
    $scriptUrl = https://raw.githubusercontent.com/herm1t0/win-config/refs/heads/main/install.ps1
    $hashUrl = https://raw.githubusercontent.com/herm1t0/win-config/refs/heads/main/releaseHash
    $releaseHash = Invoke-RestMethod -Uri $hashUrl
    $scriptContent = Invoke-RestMethod -Uri $scriptUrl

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($scriptContent)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha256.ComputeHash($bytes)
    $hashString = [System.BitConverter]::ToString($hashBytes).Replace("-", "")

    if ($releaseHash -ne $hashString) {
        Write-Warning "Non equal"
    }
    else {
        Write-Warning "Equal"
    }


}
