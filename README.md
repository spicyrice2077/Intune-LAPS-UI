# Intune-LAPS-UI
# Info

This app is a powershell wrapper that interacts with Microsoft Graph to grab the LAPS password of the intended device.
- IntuneLAPS\IntuneLAPSapp\IntuneLAPS.exe runs the following script - IntuneLAPS\IntuneLAPSapp\scripts\IntuneLAPS.ps1
  
![Alt text](https://github.com/spicyrice2077/Intune-LAPS-UI/blob/main/Preview.png)
---

# Install Process (Manual)

Start by opening the Dependencies folder:

- Run IntuneLAPSDependencies.exe as administrator
- Click "Check Dependencies"
- Wait patiently. Graph module takes some time to complete installation.

---

# Install Process (Auto)

Start by opening the Dependencies folder:

- Run Install.ps1
  
---

# Running the app

- Run IntuneLAPS.exe
- Click "Login"
    - This will open a web browser where you should use your admin account email
    - You should see your account name in the app after logging in
- Fill in the device name and click "Get Password"
- You may get an additional browser prompt to login; simply login again as requested
---

# Troubleshooting Issues

The .exe files may fail to run the PowerShell scripts if they have the "mark of the web" security flag.
- You can resolve this by opening PowerShell and entering the following command for **both** scripts: (You may need to adjust the path to reflect the actual location of the PowerShell scripts)

```powershell
Unblock-File -Path "C:\Users\username\Downloads\IntuneLAPS\IntuneLAPSapp\scripts\IntuneLAPS_Dependencies.ps1"
```
