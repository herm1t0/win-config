$AppList = @(
    # WinGet apps
    [PSCustomObject] @{
        Name = "DirectX"
        ID   = "Microsoft.DirectX"
    }
    [PSCustomObject] @{
        Name = "Microsoft Visual C++ 2015-2022"
        ID   = "Microsoft.VCRedist.2015+.x64"
    }
    [PSCustomObject] @{
        Name = "PowerShell 7"
        ID   = "Microsoft.PowerShell"
    }
    [PSCustomObject] @{
        Name = "WindowsTerminal"
        ID   = "Microsoft.WindowsTerminal"
    }
    [PSCustomObject] @{
        Name = "MozillaFirefox"
        ID   = "Mozilla.Firefox"
    }
    [PSCustomObject] @{
        Name = "MsiAfterburner"
        ID   = "Guru3D.Afterburner"
    }
    [PSCustomObject] @{
        Name = "NVCleanstall"
        ID   = "TechPowerUp.NVCleanstall"
    }
    [PSCustomObject] @{
        Name = "GoodbyeDPI UI"
        ID   = "Storik4pro.GoodbyeDPI-UI"
    }
    [PSCustomObject] @{
        Name = "NanaZip"
        ID   = "M2Team.NanaZip"
    }
    [PSCustomObject] @{
        Name = "UniGetUI"
        ID   = "MartiCliment.UniGetUI"
    }
    [PSCustomObject] @{
        Name = "MPC-HC"
        ID   = "clsid2.mpc-hc"
    }
    [PSCustomObject] @{
        Name = "Git"
        ID   = "Git.Git"
    }
    [PSCustomObject] @{
        Name = "Visual Studio Code"
        ID   = "Microsoft.VisualStudioCode"
    }
    [PSCustomObject] @{
        Name = "qBittorrent"
        ID   = "qBittorrent.qBittorrent.lt2"
    }
    [PSCustomObject] @{
        Name = "Oh My Posh"
        ID   = "JanDeDobbeleer.OhMyPosh"
    }
    [PSCustomObject] @{
        Name = "Flow Launcher"
        ID   = "Flow-Launcher.low-Launcher"
    }
    [PSCustomObject] @{
        Name = "Double Commander"
        ID   = "alexx2000.DoubleCommander"
    }
)

function Install-Application
{
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$App
    )
    Write-Host "Now installing $($App.Name)" -ForegroundColor Yellow
    winget install --id $App.ID --exact --source winget --accept-source-agreements --disable-interactivity --silent --accept-package-agreements --force
    if ($LASTEXITCODE -ne 0 )
    {
        Write-Error "A error occurred while installing $($App.Name)."
        return $false
    }
    Write-Host "$($App.Name) successfully installed."
    return $true
}
function Test-InternetConnection
{
    Write-Host "Testing internet connection..." -ForegroundColor Yellow
    try
    {
        Test-Connection -ComputerName www.google.com -Count 3 -Delay 1 -ErrorAction Stop | Out-Null
        return $true
    }
    catch
    {
        Write-Warning "Internet connection isn't available. Please check your connection."
        return $false
    }
}

function Test-WindowsActivation
{
    Write-Host "Testing Windows activation..." -ForegroundColor Yellow
    if ((Get-CIMInstance -Query "SELECT * FROM SoftwareLicensingProduct WHERE LicenseStatus = 1").LicenseStatus)
    {
        return $true
    }
    else
    {
        Write-Warning "Windows activation wasn't found."
        return $false
    }
}

function Install-WindowsActivation
{
    try
    {
        Write-Host "Starting Windows activation script..." -ForegroundColor Yellow
        Invoke-RestMethod https://get.activated.win | Invoke-Expression -ErrorAction Stop
        return $true
    }
    catch
    {
        Write-Error "Error: $_"
        return $false
    }
    
}

function Test-WinGetInstallation
{
    Write-Host "Testing WinGet installation..." -ForegroundColor Yellow
    try
    {
        winget --version
        return $true
    }
    catch
    {
        Write-Warning "WinGet installation wasn't found."
        return $false
    }
}

function Install-WinGet
{
    try
    {
        Write-Host "Installing WinGet PowerShell module from PSGallery..." -ForegroundColor Yellow
        Install-PackageProvider -Name NuGet -Force -ErrorAction Stop | Out-Null
        Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -ErrorAction Stop | Out-Null
        Write-Host "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..." -ForegroundColor Yellow
        Repair-WinGetPackageManager -AllUsers -ErrorAction Stop
        Write-Host "WinGet installation is complete." -ForegroundColor Yellow
        return $true # Success
    }
    catch
    {
        Write-Error "Error: $_"
        return $false # Failure
    }
}

function Set-GitUserVars
{
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Enter the git user.name")]
        [string] $Name,
        [Parameter(Mandatory = $true, HelpMessage = "Enter the git user.email")]
        [string] $Email
    )
    git config --global user.name $Name
    git config --global user.email $Email
}

function Set-WindowsDefenderStatus
{
    param (
        [Parameter(Mandatory = $true)]
        [bool] $Enabled
    )
    $output = "$env:TEMP\defender-control.exe"
    if ($Enabled)
    { 
        $url = "https://github.com/pgkt04/defender-control/releases/latest/download/enable-defender.exe" 
    }
    else
    {
        $url = "https://github.com/pgkt04/defender-control/releases/latest/download/disable-defender.exe" 
    }

    try
    {
        Write-Host "Working on Windows Defender..." -ForegroundColor Yellow
        Invoke-RestMethod -Uri $url -OutFile $output -UseBasicParsing -ErrorAction Stop
        Start-Process -FilePath $output -Wait
        Remove-Item $output -Force
    }
    catch
    {
        Write-Error "Error: $_"
    }
}

function Set-DefaultFileManager
{
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Explorer", "DoubleCommander")]
        [string] $Name
    )

    switch ($Name)
    {
        "Explorer"
        { 
            # Win + E hotkey bind
            $regPath = "HKCU:\SOFTWARE\Classes\CLSID\{52205fd8-5dfb-447d-801a-d0b52f2e83e1}"
            Remove-Item -Path $regPath -Recurse -Force

            # Shell integration
            Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Drive\Shell" -Name "(Default)" -Value "none"
            Remove-Item -Path "Registry::HKEY_CLASSES_ROOT\Drive\shell\open\command" -Recurse -Force
            Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell" -Name "(Default)" -Value "none"
            Remove-Item -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\open\command" -Recurse -Force

        }
        "DoubleCommander"
        { 
            # Win + E hotkey bind
            $regPath = "HKCU:\SOFTWARE\Classes\CLSID\{52205fd8-5dfb-447d-801a-d0b52f2e83e1}"
            New-Item -Path "$regPath\shell\opennewwindow\command" -Force
            Set-ItemProperty -Path "$regPath\shell\opennewwindow\command" -Name "(Default)" -Value '"C:\Program Files\Double Commander\doublecmd.exe" "-C"'
            Set-ItemProperty -Path "$regPath\shell\opennewwindow\command" -Name "DelegateExecute" -Value ""

            # Shell integration
            New-Item -Path "Registry::HKEY_CLASSES_ROOT\Drive\shell\open\command" -Force
            New-Item -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\open\command" -Force
            Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Drive\Shell" -Name "(Default)" -Value "open"
            Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell" -Name "(Default)" -Value "open"
            Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Drive\shell\open\command" -Name "(Default)" -Value 'C:\Program Files\Double Commander\doublecmd.exe -C -P L -T "%1"'
            Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\open\command" -Name "(Default)" -Value 'C:\Program Files\Double Commander\doublecmd.exe -C -P L -T "%1"'
        }
        Default
        {
            Write-Error "Error: $_"
        }
    }
}

function Main
{

    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
    {
        Write-Warning "Script needs to be run as Administrator!"
        Write-Host "Press any key to exit."
        Read-Host
        break
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if (!(Test-InternetConnection)) { break }

    if (!(Test-WindowsActivation))
    {
        if (!(Install-WindowsActivation))
        { 
            break
        }
    }

    if (!(Test-WinGetInstallation))
    {
        if (!(Install-WinGet))
        {
            break 
        } 
    }

    foreach ($app in $AppList)
    {
        if (!(Install-Application -App $app)) { continue } 
    }

    Set-GitUserVars
    
    Set-WindowsDefenderStatus -Enabled $false

    Set-DefaultFileManager -Name DoubleCommander

    Invoke-RestMethod "https://christitus.com/win" | Invoke-Expression -ErrorAction Stop

    Write-Host "Script execution succeeded." -ForegroundColor Yellow
    Write-Host "Press any key to exit."
    Read-Host
}

Main
