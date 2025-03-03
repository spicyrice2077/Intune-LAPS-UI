# Ensure UTF-8 BOM encoding if saving this script manually
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$graphInstalled = $false
$exeExists = $false

# Check if Microsoft.Graph module is available
if (Get-Module -ListAvailable -Name Microsoft.Graph) {
    $graphInstalled = $true
} else {
    Write-Warning "Microsoft.Graph module is not installed."
}

# Check if IntuneLAPS.exe exists
$exePath = "C:\Program Files\IntuneLAPS\IntuneLAPSapp\IntuneLAPS.exe"
if (Test-Path -Path $exePath) {
    $exeExists = $true
} else {
    Write-Warning "IntuneLAPS.exe not found at $exePath"
}

# Detection logic
if ($graphInstalled -and $exeExists) {
    # Required for Intune to confirm detection — any non-empty string will work
    Write-Output "IntuneLAPS detected"
    exit 0  # App detected
} else {
    Write-Output "IntuneLAPS not detected"
    exit 1  # App not detected
}
