# Define target directory
$targetDir = "C:\Program Files\IntuneLAPS"

# Ensure running as admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator."
    exit
}

# Create target directory if it doesn't exist
if (-not (Test-Path -Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    Write-Output "Created directory: $targetDir"
} else {
    Write-Output "Directory already exists: $targetDir"
}

# Get the directory where this script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Copy README.pdf
$readmeSource = Join-Path -Path $scriptDir -ChildPath "README.pdf"
$readmeDestination = Join-Path -Path $targetDir -ChildPath "README.pdf"

if (Test-Path -Path $readmeSource) {
    Copy-Item -Path $readmeSource -Destination $readmeDestination -Force
    Write-Output "Copied README.pdf to $targetDir"
} else {
    Write-Warning "README.pdf not found in $scriptDir"
}

# Function to copy folder contents
function Copy-FolderContents {
    param (
        [string]$sourceFolder,
        [string]$destinationFolder
    )
    if (Test-Path -Path $sourceFolder) {
        if (-not (Test-Path -Path $destinationFolder)) {
            New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
        }
        Copy-Item -Path (Join-Path $sourceFolder '*') -Destination $destinationFolder -Recurse -Force
        Write-Output "Copied contents of $sourceFolder to $destinationFolder"
    } else {
        Write-Warning "$sourceFolder not found."
    }
}

# Copy contents of IntuneLAPSapp
Copy-FolderContents -sourceFolder (Join-Path $scriptDir "IntuneLAPSapp") -destinationFolder (Join-Path $targetDir "IntuneLAPSapp")

# Copy contents of Dependencies
Copy-FolderContents -sourceFolder (Join-Path $scriptDir "Dependencies") -destinationFolder (Join-Path $targetDir "Dependencies")

# Create shortcut for all users on the desktop
$exePath = Join-Path $targetDir "IntuneLAPSapp\IntuneLAPS.exe"
if (Test-Path -Path $exePath) {
    $publicDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')
    $shortcutPath = Join-Path $publicDesktop "IntuneLAPS.lnk"

    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = $exePath
    $Shortcut.WorkingDirectory = [System.IO.Path]::GetDirectoryName($exePath)
    $Shortcut.Description = "Launch IntuneLAPS"
    $Shortcut.Save()

    Write-Output "Shortcut created at: $shortcutPath"
} else {
    Write-Warning "IntuneLAPS.exe not found at expected location: $exePath"
}

# Run IntuneLAPS_Dependencies_Auto.ps1 if it exists
$dependenciesScript = Join-Path $targetDir "Dependencies\scripts\IntuneLAPS_Dependencies_Auto.ps1"
if (Test-Path -Path $dependenciesScript) {
    Write-Output "Running IntuneLAPS_Dependencies_Auto.ps1..."

    # Run the script in a new process to avoid scope issues
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$dependenciesScript`"" -Wait

    Write-Output "Dependencies script completed."
} else {
    Write-Warning "Dependencies script not found: $dependenciesScript"
}

Write-Output "All tasks completed successfully."
