# Ensure the script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator."
    exit
}

$targetDir = "C:\Program Files\IntuneLAPS"

if (Test-Path -Path $targetDir) {
    Remove-Item -Path $targetDir -Recurse -Force
    Write-Output "Successfully removed $targetDir"
} else {
    Write-Output "$targetDir does not exist. Nothing to remove."
}

Write-Output "Uninstall process completed."
