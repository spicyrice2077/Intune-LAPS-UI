# Intune-LAPS-UI
# Info

This installer/app consists of two PowerShell scripts and two .exe files.

- IntuneLAPS\Dependencies\IntuneLAPSDependencies.exe runs the following script below.
    - IntuneLAPS\Dependencies\scripts\IntuneLAPS_Dependencies.ps1
- IntuneLAPS\IntuneLAPSapp\IntuneLAPS.exe runs the following script below.
    - IntuneLAPS\IntuneLAPSapp\scripts\IntuneLAPS.ps1

---

# Install Process

Start by opening the Dependencies folder:

- Run IntuneLAPSDependencies.exe as administrator
- Click "Check Dependencies"
- Wait patiently. Graph module takes some time to complete installation.

---

# Running the app

- Run IntuneLAPS.exe
- Click "Login"
    - This will open a web browser where you should use your admin account email
    - You should see your account name in the app after logging in
- Fill in the device name and click "Get Password"
- You may get an additional browser prompt to login; simply login again as requested
- Successful output will look something like this:
---

# Troubleshooting Issues

The .exe files may fail to run the PowerShell scripts if they have the "mark of the web" security flag.

- You can resolve this by opening PowerShell and entering the following command for **both** scripts: (You may need to adjust the path to reflect the actual location of the PowerShell scripts)

```powershell
Unblock-File -Path "C:\Users\username\Downloads\IntuneLAPS\IntuneLAPSapp\scripts\IntuneLAPS_Dependencies.ps1"
```
