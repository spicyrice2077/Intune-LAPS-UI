Add-Type -AssemblyName System.Windows.Forms

# Function: Test if running as Administrator
function Test-Admin {
    $adminCheck = [System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()
    return $adminCheck.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Create Form (Dark Theme)
$form = New-Object System.Windows.Forms.Form
$form.Text = "Dependency Checker"
$form.Size = New-Object System.Drawing.Size(500,400)
$form.StartPosition = "CenterScreen"
$form.BackColor = "#1E1E1E"  # Dark background
$form.FormBorderStyle = "FixedSingle"  # Prevent resizing
$form.MaximizeBox = $false  # Disable maximize button

# Create Output Box (Dark Theme)
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.Size = New-Object System.Drawing.Size(450,280)
$outputBox.Location = New-Object System.Drawing.Point(20,50)
$outputBox.BackColor = "#252526"  # Dark gray background
$outputBox.ForeColor = "#32CD32"  # Lime Green Text
$outputBox.Font = New-Object System.Drawing.Font("Consolas",10)  # Consistent font

# Create Check Button (Styled for Dark Mode)
$checkButton = New-Object System.Windows.Forms.Button
$checkButton.Text = "Check Dependencies"
$checkButton.Location = New-Object System.Drawing.Point(150,10)
$checkButton.Size = New-Object System.Drawing.Size(200,30)
$checkButton.BackColor = "#333333"  # Darker button
$checkButton.ForeColor = "#32CD32"  # Lime Green Text
$checkButton.FlatStyle = "Flat"  # Modern button style
$checkButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

# Function: Install Dependencies
function Install-Dependencies {
    # Clear previous output
    $outputBox.Clear()

    # Check for admin rights
    if (-not (Test-Admin)) {
        $outputBox.AppendText("ERROR: This script must be run as Administrator.`r`n")
        return
    }

    $outputBox.AppendText("Checking for dependencies...`r`n")

    $installCommands = @()
    $needsInstall = $false

    # NuGet provider
    if (-not (Get-PackageProvider -ListAvailable | Where-Object { $_.Name -eq "NuGet" -and $_.Version -ge "2.8.5.201" })) {
        $outputBox.AppendText("MISSING: Adding NuGet provider install to queue...`r`n")
        $installCommands += "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force"
        $needsInstall = $true
    } else {
        $outputBox.AppendText("NuGet provider is already installed.`r`n")
    }

    # winget
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        $outputBox.AppendText("MISSING: winget is not installed. Please install manually from the Microsoft Store.`r`n")
    } else {
        $outputBox.AppendText("winget already installed.`r`n")

        # PowerShell 7
        if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
            $outputBox.AppendText("MISSING: Adding PowerShell 7 install to queue...`r`n")
            $installCommands += "winget install --id Microsoft.PowerShell --source winget --accept-package-agreements --accept-source-agreements"
            $needsInstall = $true
        } else {
            $outputBox.AppendText("PowerShell 7 is already installed.`r`n")
        }
    }

    # Microsoft.Graph
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        $outputBox.AppendText("MISSING: Adding Microsoft.Graph module install to queue...`r`n")
        $installCommands += "Install-Module Microsoft.Graph -Scope AllUsers -Force"
        $needsInstall = $true
    } else {
        $outputBox.AppendText("Microsoft.Graph module is already installed.`r`n")
    }

    # Only run installation commands if something is actually missing
    if ($needsInstall) {
        $outputBox.AppendText("Starting installation process...`r`n")
        $outputBox.AppendText("Microsoft.Graph installs take a while. Be patient.`r`n")
        $installScript = $installCommands -join "; "

        # Run the commands only if needed
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -NoExit -Command `"$installScript; Start-Sleep -Seconds 5; exit`"" -WindowStyle Minimized -Wait

        # After installation, notify user instead of rerunning the function
        $outputBox.AppendText("Installation completed. Please restart the app if you wish to run this again.`r`n")
    } else {
        $outputBox.AppendText("No installations required. Everything is up to date!`r`n")
    }
}

# Check for admin rights on startup
if (-not (Test-Admin)) {
    [System.Windows.Forms.MessageBox]::Show("This script must be run as Administrator.", "Permission Error", "OK", "Error")
    exit
}

# Assign function to button click
$checkButton.Add_Click({ Install-Dependencies })

# Add controls to form
$form.Controls.Add($checkButton)
$form.Controls.Add($outputBox)

# Show form
$form.ShowDialog()
