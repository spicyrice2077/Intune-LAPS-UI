# Initialize
$installCommands = @()
$needsInstall = $false

# Check NuGet provider
if (-not (Get-PackageProvider -ListAvailable | Where-Object { $_.Name -eq "NuGet" -and $_.Version -ge "2.8.5.201" })) {
    Write-Output "MISSING: Adding NuGet provider install to queue..."
    $installCommands += "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force"
    $needsInstall = $true
} else {
    Write-Output "NuGet provider is already installed."
}

# Check winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Output "MISSING: winget is not installed. Please install manually from the Microsoft Store."
} else {
    Write-Output "winget already installed."

    # Check PowerShell 7
    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
        Write-Output "MISSING: Adding PowerShell 7 install to queue..."
        $installCommands += "winget install --id Microsoft.PowerShell --source winget --accept-package-agreements --accept-source-agreements"
        $needsInstall = $true
    } else {
        Write-Output "PowerShell 7 is already installed."
    }
}

# Check Microsoft.Graph module
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Output "MISSING: Adding Microsoft.Graph module install to queue..."
    $installCommands += "Install-Module Microsoft.Graph -Scope AllUsers -Force"
    $needsInstall = $true
} else {
    Write-Output "Microsoft.Graph module is already installed."
}

# Execute installation if needed
if ($needsInstall) {
    Write-Output "Starting installation process..."
    Write-Output "Microsoft.Graph installs take a while. Be patient."
    $installScript = $installCommands -join "; "

    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -NoExit -Command `"$installScript; Start-Sleep -Seconds 5; exit`"" -WindowStyle Minimized -Wait

    Write-Output "Installation completed. Please restart this script if you want to validate again."
} else {
    Write-Output "No installations required. Everything is up to date!"
}
