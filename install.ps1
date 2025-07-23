enum AppSource {
    WinGet
    #Scoop
}

$AppList = @(
    # WinGet apps
    [PSCustomObject] @{
        Name   = "DirectX"
        ID     = "Microsoft.DirectX"
        Source = [AppSource]::WinGet
    }
    [PSCustomObject] @{
        Name   = "Microsoft Visual C++ 2015-2022"
        ID     = "Microsoft.VCRedist.2015+.x64"
        Source = [AppSource]::WinGet
    }
    [PSCustomObject] @{
        Name   = "PowerShell 7"
        ID     = "Microsoft.PowerShell"
        Source = [AppSource]::WinGet
    }
    [PSCustomObject] @{
        Name   = "WindowsTerminal"
        ID     = "Microsoft.WindowsTerminal"
        Source = [AppSource]::WinGet
    }
    [PSCustomObject] @{
        Name   = "MozillaFirefox"
        ID     = "Mozilla.Firefox"
        Source = [AppSource]::WinGet
    }
    [PSCustomObject] @{
        Name   = "MsiAfterburner"
        ID     = "Guru3D.Afterburner"
        Source = [AppSource]::WinGet
    }
    [PSCustomObject] @{
        Name   = "NVCleanstall"
        ID     = "TechPowerUp.NVCleanstall"
        Source = [AppSource]::WinGet
    }
    [PSCustomObject] @{
        Name   = "GoodbyeDPI UI"
        ID     = "Storik4pro.GoodbyeDPI-UI"
        Source = [AppSource]::WinGet
    }
    [PSCustomObject] @{
        Name   = "NanaZip"
        ID     = "M2Team.NanaZip"
        Source = [AppSource]::WinGet
    }
    [PSCustomObject] @{
        Name   = "UniGetUI"
        ID     = "MartiCliment.UniGetUI"
        Source = [AppSource]::WinGet
    }
    [PSCustomObject] @{
        Name   = "StartIsBack++"
        ID     = "StartIsBack.StartIsBack"
        Source = [AppSource]::WinGet
    }
    [PSCustomObject] @{
        Name   = "MPC-HC"
        ID     = "clsid2.mpc-hc"
        Source = [AppSource]::WinGet
    }
    [PSCustomObject] @{
        Name   = "Git"
        ID     = "Git.Git"
        Source = [AppSource]::WinGet
    }
    [PSCustomObject] @{
        Name   = "Visual Studio Code"
        ID     = "Microsoft.VisualStudioCode"
        Source = [AppSource]::WinGet
    }
    [PSCustomObject] @{
        Name   = "qBittorrent"
        ID     = "qBittorrent.qBittorrent.lt2"
        Source = [AppSource]::WinGet
    }
    [PSCustomObject] @{
        Name   = "Oh My Posh"
        ID     = "JanDeDobbeleer.OhMyPosh"
        Source = [AppSource]::WinGet
    }
    [PSCustomObject] @{
        Name   = "Flow Launcher"
        ID     = "Flow-Launcher.low-Launcher"
        Source = [AppSource]::WinGet
    }
)

function Install-Application {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$App
    )
    switch ($App.Source) {
        ([AppSource]::WinGet) {
            Write-Host "Now installing $($App.Name) via $($App.Source)" -ForegroundColor Yellow
            winget install $App.ID
            if ($LASTEXITCODE -ne 0 ) {
                Write-Error "A error occurred while installing $($App.Name)."
                return $false
            }
            Write-Host "$($App.Name) successfully installed."
            return $true
        }
        Default {
            Write-Error "Error: Unknown source $($App.Source)"
            return $false
        }
    }
}
function Test-InternetConnection {
    Write-Host "Testing internet connection..." -ForegroundColor Yellow
    try {
        Test-Connection -ComputerName www.google.com -Count 3 -Delay 1 -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        Write-Warning "Internet connection isn't available. Please check your connection."
        return $false
    }
}

function Test-WindowsActivation {
    Write-Host "Testing Windows activation..." -ForegroundColor Yellow
    if ((Get-CIMInstance -Query "SELECT * FROM SoftwareLicensingProduct WHERE LicenseStatus = 1").LicenseStatus) {
        return $true
    }
    else {
        Write-Warning "Windows activation wasn't found."
        return $false
    }
}

function Install-WindowsActivation {
    try {
        Write-Host "Starting Windows activation script..." -ForegroundColor Yellow
        Invoke-RestMethod https://get.activated.win | Invoke-Expression -ErrorAction Stop
        return $true
    }
    catch {
        Write-Error "Error: $_"
        return $false
    }
    
}

function Test-WinGetInstallation {
    Write-Host "Testing WinGet installation..." -ForegroundColor Yellow
    try {
        winget --version
        return $true
    }
    catch {
        Write-Warning "WinGet installation wasn't found."
        return $false
    }
}

function Install-WinGet {
    try {
        Write-Host "Installing WinGet PowerShell module from PSGallery..." -ForegroundColor Yellow
        Install-PackageProvider -Name NuGet -Force -ErrorAction Stop | Out-Null
        Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -ErrorAction Stop | Out-Null
        Write-Host "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..." -ForegroundColor Yellow
        Repair-WinGetPackageManager -AllUsers -ErrorAction Stop
        Write-Host "WinGet installation is complete." -ForegroundColor Yellow
        return $true # Success
    }
    catch {
        Write-Error "Error: $_"
        return $false # Failure
    }
}

function Test-ScriptIntegrity {
    try {
        Write-Host "Testing script hash integrity..." -ForegroundColor Yellow
        $scriptUrl = "https://raw.githubusercontent.com/herm1t0/win-config/refs/heads/main/install.ps1"
        $hashUrl = "https://raw.githubusercontent.com/herm1t0/win-config/refs/heads/main/releaseHash"
        $releaseHash = (Invoke-RestMethod -Uri $hashUrl).Trim()
        $scriptContent = Invoke-RestMethod -Uri $scriptUrl

        $bytes = [System.Text.Encoding]::UTF8.GetBytes($scriptContent)
        $hash = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)).Replace("-", "")
        Write-Host $releaseHash
        Write-Host $hash

        return ($releaseHash -eq $hash)
    }
    catch {
        Write-Warning "Error testing script integrity: $_"
        return $false
    }
    
}

function Set-GitUserVars {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Enter the git user.name")]
        [string] $Name,
        [Parameter(Mandatory = $true, HelpMessage = "Enter the git user.email")]
        [string] $Email
    )
    git config --global user.name $Name
    git config --global user.email $Email
}

function Main {

    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Warning "Script needs to be run as Administrator!"
        Write-Host "Press any key to exit."
        Read-Host
        break
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if (!(Test-InternetConnection)) { break }

    if (!(Test-ScriptIntegrity)) {
        Write-Warning "Hash mismatch! Aborting..."
        break
    }
    Write-Host "Successfully verified script hash" -ForegroundColor Yellow

    if (!(Test-WindowsActivation)) { if (!(Install-WindowsActivation)) { break } }

    if (!(Test-WinGetInstallation)) { if (!(Install-WinGet)) { break } }

    foreach ($app in $AppList) { if (!(Install-Application -App $app)) { break } }

    Set-GitUserVars

    Invoke-RestMethod "https://christitus.com/win" | Invoke-Expression -ErrorAction Stop

    Write-Host "Script execution succeeded." -ForegroundColor Yellow
    Write-Host "Press any key to exit."
    Read-Host
}

Main