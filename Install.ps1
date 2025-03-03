# Define target directory
$targetDir = "C:\Program Files\IntuneLAPS"
$logFile = Join-Path -Path $targetDir -ChildPath "install_log.txt"

function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -Append -FilePath $logFile
    Write-Output $message
}

# Ensure running as admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator."
    exit
}

# Create target directory if it doesn't exist
if (-not (Test-Path -Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    Write-Log "Created directory: $targetDir"
} else {
    Write-Log "Directory already exists: $targetDir"
}

# Start logging
Write-Log "=== Starting IntuneLAPS Installation ==="

# Get the directory where this script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Copy README.pdf
$readmeSource = Join-Path -Path $scriptDir -ChildPath "README.pdf"
$readmeDestination = Join-Path -Path $targetDir -ChildPath "README.pdf"

if (Test-Path -Path $readmeSource) {
    Copy-Item -Path $readmeSource -Destination $readmeDestination -Force
    Write-Log "Copied README.pdf to $targetDir"
} else {
    Write-Log "README.pdf not found in $scriptDir"
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
        Write-Log "Copied contents of $sourceFolder to $destinationFolder"
    } else {
        Write-Log "$sourceFolder not found."
    }
}

# Copy contents of IntuneLAPSapp
Copy-FolderContents -sourceFolder (Join-Path $scriptDir "IntuneLAPSapp") -destinationFolder (Join-Path $targetDir "IntuneLAPSapp")

# Copy contents of Dependencies
Copy-FolderContents -sourceFolder (Join-Path $scriptDir "Dependencies") -destinationFolder (Join-Path $targetDir "Dependencies")

# Run IntuneLAPS_Dependencies_Auto.ps1 if it exists
$dependenciesScript = Join-Path $targetDir "Dependencies\scripts\IntuneLAPS_Dependencies_Auto.ps1"
if (Test-Path -Path $dependenciesScript) {
    Write-Log "Running IntuneLAPS_Dependencies_Auto.ps1..."

    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$dependenciesScript`"" -Wait

    Write-Log "Dependencies script completed."
} else {
    Write-Log "Dependencies script not found: $dependenciesScript"
}

# Check if Microsoft Graph module is installed
$graphModule = Get-Module -ListAvailable -Name Microsoft.Graph -ErrorAction SilentlyContinue

if ($null -eq $graphModule) {
    Write-Log "Microsoft Graph module not found. Desktop shortcut will not be created."
} else {
    Write-Log "Microsoft Graph module found. Proceeding to create desktop shortcut."

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

        Write-Log "Shortcut created at: $shortcutPath"
    } else {
        Write-Log "IntuneLAPS.exe not found at expected location: $exePath"
    }
}

Write-Log "=== IntuneLAPS Installation Completed Successfully ==="
Write-Output "All tasks completed successfully. See log at: $logFile"
