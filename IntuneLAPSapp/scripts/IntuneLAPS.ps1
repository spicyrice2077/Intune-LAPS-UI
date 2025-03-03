# -------------------------------------------------------------------------------------
# Check if Microsoft.Graph module is installed
# -------------------------------------------------------------------------------------
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        "Microsoft.Graph module is required! Please run the Dependencies installer before continuing.",
        "Missing Dependency",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    exit
}


# -------------------------------------------------------------------------------------
# If not in PowerShell 7, attempt to relaunch in pwsh.exe and exit current session.
# -------------------------------------------------------------------------------------
if ($PSVersionTable.PSVersion.Major -lt 7) {
    $myScriptPath = $MyInvocation.MyCommand.Definition
    if (Test-Path $myScriptPath) {
        try {
            Start-Process pwsh -WindowStyle Hidden -ArgumentList '-NoProfile', '-ExecutionPolicy Bypass', '-File', "`"$myScriptPath`""
            exit
        }
        catch {
            exit
        }
    }
    else {
        exit
    }
}

Add-Type -Name Win32Utils -Namespace System -MemberDefinition '
    [DllImport("Kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("User32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'
$consolePtr = [System.Win32Utils]::GetConsoleWindow()
if ($consolePtr -ne [IntPtr]::Zero) {
    [System.Win32Utils]::ShowWindow($consolePtr, 0)  # 0 hides the window
}


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# -------------------------------------------------------------------------------------
# Create the GUI form
# -------------------------------------------------------------------------------------

$form = New-Object System.Windows.Forms.Form
$form.Text = "Intune LAPS Password Viewer"

# -- You can adjust the default start size here:
$form.Size = New-Object System.Drawing.Size(800, 600)

$form.StartPosition = "CenterScreen"
$form.BackColor = "#1E1E1E"

# -- You can adjust the minimum size here:
$form.MinimumSize = New-Object System.Drawing.Size(800, 600)  # Prevent making it too small

# ==================== Login/Logout Button (top-left) ====================
$authBtn = New-Object System.Windows.Forms.Button
$authBtn.Text      = "Login"
$authBtn.Location  = New-Object System.Drawing.Point(20, 10)
$authBtn.Size      = New-Object System.Drawing.Size(120, 35)
$authBtn.BackColor = "#333333"
$authBtn.ForeColor = "White"
# Anchor top-left
$authBtn.Anchor    = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$form.Controls.Add($authBtn)

# ==================== User Label (to the right of Login) ====================
$userLabel = New-Object System.Windows.Forms.Label
$userLabel.Text      = "User: Not logged in"
$userLabel.Location  = New-Object System.Drawing.Point(150, 17)
$userLabel.Size      = New-Object System.Drawing.Size(190, 20)
$userLabel.ForeColor = "White"
$userLabel.BackColor = "#1E1E1E"
$userLabel.AutoSize  = $false
$userLabel.TextAlign = "MiddleLeft"
# Anchor top-left as well
$userLabel.Anchor    = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$form.Controls.Add($userLabel)

# ==================== Device Name Label ====================
$Label = New-Object System.Windows.Forms.Label
$Label.Text     = "Device Name:"
$Label.Location = New-Object System.Drawing.Point(20, 60)
$Label.AutoSize = $true
$Label.ForeColor = "White"
$Label.Anchor   = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$form.Controls.Add($Label)

# ==================== Device Name TextBox ====================
$DeviceIdBox = New-Object System.Windows.Forms.TextBox
$DeviceIdBox.Location  = New-Object System.Drawing.Point(20, 85)
$DeviceIdBox.Size      = New-Object System.Drawing.Size(300, 20)
$DeviceIdBox.ForeColor = "White"
$DeviceIdBox.BackColor = "DimGray"
$DeviceIdBox.Anchor    = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$form.Controls.Add($DeviceIdBox)

# ==================== Get Password Button ====================
$FetchButton = New-Object System.Windows.Forms.Button
$FetchButton.Text      = "Get Password"
$FetchButton.Location  = New-Object System.Drawing.Point(20, 120)
$FetchButton.Size      = New-Object System.Drawing.Size(300, 35)
$FetchButton.ForeColor = "White"
$FetchButton.BackColor = "DarkSlateGray"
$FetchButton.Anchor    = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$form.Controls.Add($FetchButton)

# ==================== Copy Password Button ====================
$CopyButton = New-Object System.Windows.Forms.Button
$CopyButton.Text      = "Copy Password"
$CopyButton.Location  = New-Object System.Drawing.Point(20, 165)
$CopyButton.Size      = New-Object System.Drawing.Size(300, 35)
$CopyButton.ForeColor = "White"
$CopyButton.BackColor = "DarkSlateGray"
$CopyButton.Enabled   = $false
$CopyButton.Anchor    = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$form.Controls.Add($CopyButton)

# ==================== Output TextBox (anchored right/bottom) ====================
$OutputBox = New-Object System.Windows.Forms.TextBox
# Place the OutputBox further right, so we have a left column of ~340 px
$OutputBox.Location = New-Object System.Drawing.Point(340, 10)
$OutputBox.Size     = New-Object System.Drawing.Size(440, 550)
$OutputBox.Multiline = $true
$OutputBox.ForeColor = "LimeGreen"
$OutputBox.BackColor = "Black"
$OutputBox.Font      = New-Object System.Drawing.Font("Consolas", 10)
$OutputBox.ReadOnly  = $true
# Anchor top, right, bottom, left so it expands
$OutputBox.Anchor    = [System.Windows.Forms.AnchorStyles]"Top,Bottom,Right,Left"
$form.Controls.Add($OutputBox)

# -------------------------------------------------------------------------------------
# Script-wide variable to hold the last password
# -------------------------------------------------------------------------------------
$Script:LastPassword = $null

# ==================== Get Password Logic ====================
$FetchButton.Add_Click({
    $DeviceId = $DeviceIdBox.Text.Trim()
    if ($DeviceId -eq "") {
        [System.Windows.Forms.MessageBox]::Show(
            "Please enter a Device ID.",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return
    }

    $OutputBox.Text = "Getting Password..."

    try {
        $LapsPassword = Get-LapsAADPassword -DeviceIds $DeviceId -IncludePasswords -AsPlainText

        if ($LapsPassword) {
            $formattedOutput = @"
DeviceName             : $($LapsPassword.DeviceName)
DeviceId               : $($LapsPassword.DeviceId)
Account                : $($LapsPassword.Account)
Password               : $($LapsPassword.Password)
PasswordExpirationTime : $($LapsPassword.PasswordExpirationTime)
PasswordUpdateTime     : $($LapsPassword.PasswordUpdateTime)
"@
            $OutputBox.Text = $formattedOutput
            $CopyButton.Enabled = $true
            $Script:LastPassword = $LapsPassword.Password
        }
        else {
            $OutputBox.Text = "No LAPS password found for the given Device ID."
            $CopyButton.Enabled = $false
        }
    }
    catch {
        $OutputBox.Text = "Error fetching password: $_"
        $CopyButton.Enabled = $false
    }
})

# ==================== Copy Password to Clipboard ====================
$CopyButton.Add_Click({
    if ($Script:LastPassword -and $Script:LastPassword -ne "") {
        Set-Clipboard -Value $Script:LastPassword
        [System.Windows.Forms.MessageBox]::Show(
            "Password copied to clipboard.",
            "Success",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "No password available to copy.",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
})

# ==================== Auth Logic (Login/Logout) ====================
$authBtn.Add_Click({
    if ($authBtn.Text -eq "Login") {
        try {
            # If you want device code flow: Connect-MgGraph -Device -Scopes ...
            Connect-MgGraph -Scopes "DeviceLocalCredential.Read.All"

            $currentContext = Get-MgContext
            $currentUser = $currentContext.Account

            if ($currentUser) {
                $OutputBox.Text = "Successfully connected as: $currentUser"
                $userLabel.Text = "User: $currentUser"
                $authBtn.Text   = "Logout"
            }
            else {
                $OutputBox.Text = "Could not determine a valid user context."
            }
        }
        catch {
            $OutputBox.Text = "Failed to connect: $($_.Exception.Message)"
        }
    }
    else {
        Disconnect-MgGraph
        $OutputBox.Text      = "Disconnected from Microsoft Graph."
        $userLabel.Text      = "User: Not logged in"
        $authBtn.Text        = "Login"
        $Script:LastPassword = $null
        $CopyButton.Enabled  = $false
    }
})

# -------------------------------------------------------------------------------------
# Show the form
# -------------------------------------------------------------------------------------
[void]$form.ShowDialog()
