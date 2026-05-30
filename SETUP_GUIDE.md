# Vortex Agent Setup Guide

This guide will walk you through setting up the Vortex Agent application on your Windows system.

## Prerequisites Check

Before starting, ensure you have:

- ✅ Windows 10/11 installed
- ✅ Internet connection
- ✅ A Grok API key (from https://console.x.ai/api/keys)

## Step 1: Install Flutter (If Not Already Installed)

### Option A: Using Chocolatey (Recommended)

```powershell
# Open PowerShell as Administrator and run:
choco install flutter
```

### Option B: Manual Installation

1. Download Flutter from https://flutter.dev/docs/get-started/install/windows
2. Extract to `C:\src\flutter`
3. Add `C:\src\flutter\bin` to your system PATH
4. Run `flutter doctor` to verify installation

### Verify Installation

```bash
flutter --version
dart --version
```

## Step 2: Get Your Grok API Key

1. Visit https://console.x.ai/api/keys
2. Sign in or create an account at https://console.x.ai
3. Create a new API key
4. Copy the key (you'll need this later)
5. Keep it safe and don't share it!

## Step 3: Build the Application

### Open Command Prompt or PowerShell

```bash
# Navigate to the project directory
cd c:\dev\vortex\vortex_agent

# Get dependencies
flutter pub get

# Build for Windows (Release mode)
flutter build windows --release
```

This will take 2-5 minutes depending on your system.

### After Build Completes

The built application is at:
```
c:\dev\vortex\vortex_agent\build\windows\x64\runner\Release\vortex_agent.exe
```

## Step 4: Create Application Shortcut (Optional)

### Option A: Create in Program Files

```powershell
# Create folder
mkdir "C:\Program Files\VortexAgent"

# Copy executable
copy "C:\dev\vortex\vortex_agent\build\windows\x64\runner\Release\vortex_agent.exe" "C:\Program Files\VortexAgent\"

# Create shortcut on Desktop
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Vortex Agent.lnk")
$Shortcut.TargetPath = "C:\Program Files\VortexAgent\vortex_agent.exe"
$Shortcut.Save()
```

### Option B: Create Shortcut Manually

1. Right-click on `vortex_agent.exe`
2. Select "Create shortcut"
3. Place the shortcut on Desktop or in Start Menu

## Step 5: First Run

1. Double-click `vortex_agent.exe` or the shortcut
2. The application window will open
3. You'll see the welcome screen with instructions

## Step 6: Configure API Key

1. Click the **Settings** button (⚙️ icon) in the top-right
2. Paste your Grok API key in the "Grok API Key" field
3. Click **Test API Connection** to verify it works
4. You should see a success message
5. Click **Save Settings**

## Step 7: Enable Auto-Start (Optional)

To have Vortex Agent launch automatically when you start Windows:

### Option A: Using Settings

1. Open Settings (⚙️ button)
2. Toggle **Auto Start** to ON
3. Click **Save Settings**

### Option B: Using Batch Script

1. Open Command Prompt as Administrator
2. Run the auto-start script:
   ```bash
   cd c:\dev\vortex\vortex_agent\windows
   enable_autostart.bat
   ```

## Step 8: Test the Application

1. Press `Ctrl+Q` on your keyboard
2. A glassmorphic dialog should appear
3. Type a simple command like: `"Open Notepad"`
4. Press Enter or click Execute
5. You should see the results in the output window

## Congratulations! 🎉

Your Vortex Agent is now fully set up and ready to use!

## Quick Start Examples

Try these commands to get familiar with the app:

### File Operations
```
Create a file at C:\Users\Documents\test.txt with content "Hello Vortex"
Read C:\Users\Documents\test.txt
Delete C:\Users\Documents\test.txt
```

### Application Launching
```
Open Notepad
Launch Visual Studio Code
Start Google Chrome
```

### System Information
```
Show me the current Windows version
List all files in the Downloads folder
Show disk space usage
```

## Daily Usage

### To Use Vortex Agent

1. Press **Ctrl+Q** anywhere on your desktop
2. Type your command or question
3. Press **Enter** to execute
4. View results in the output window
5. Press **Escape** or click Close to dismiss

### To Access Settings

1. Click the **Settings** icon (⚙️) in the application window
2. Or open the Settings screen anytime

### To Minimize to Background

1. Click the **Minimize** button in the top-right (or any minimize action)
2. The app will run in the background
3. Press **Ctrl+Q** anytime to bring it back

## Troubleshooting

### "Ctrl+Q is not working"

- Make sure the application is running
- Try pressing Ctrl+Q slowly (full key press)
- Restart the application
- Check if another app is using Ctrl+Q
- Try restarting your computer

### "API Key Error"

- Verify your API key is correct
- Check your internet connection
- Visit https://console.x.ai/api/keys to ensure your key is active
- Ensure you have API credits
- Click "Test API Connection" to diagnose

### "Commands are not executing"

- Check the error message in the results window
- Verify the command is valid for Windows
- Some operations need administrator rights
- Try a simpler command first

### "App crashes on startup"

- Run: `flutter clean && flutter pub get`
- Rebuild: `flutter build windows --release`
- Check Windows Event Viewer for detailed errors

## Uninstalling

### If installed in Program Files

1. Delete the folder `C:\Program Files\VortexAgent`
2. Delete desktop shortcuts
3. Run `enable_autostart.bat` again to remove registry entries, or manually:
   ```powershell
   reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "VortexAgent" /f
   ```

### If using direct .exe

Simply delete the executable file and any shortcuts.

## Advanced Usage

### Custom Commands

Vortex Agent can execute any Windows command that works in CMD:

```
# PowerShell commands
Get all running processes and show me the top 10 by memory
Search for all .txt files larger than 1MB in my Documents

# System administration
Get system information including RAM and disk space
Enable Windows Defender antivirus
Show network adapter information

# File management
Create a backup zip of my Documents folder
Organize my Downloads folder by file type
Find duplicate files in a specific folder
```

### Performance Optimization

- Keep the app minimized when not in use
- Close result windows after reviewing
- Clear temporary files periodically
- Restart the app if it becomes slow

## Keyboard Shortcuts

| Keys | Action |
|------|--------|
| `Ctrl+Q` | Open/Close command dialog |
| `Enter` | Submit command |
| `Escape` | Close dialog |
| `Tab` | Navigate UI elements |

## Security Tips

⚠️ **Important Security Notes:**

1. **Never share your API key** with anyone
2. **Be cautious with suggested commands** - review before executing
3. **Keep your Windows system updated** for security
4. **Use strong passwords** for sensitive accounts
5. **Don't store sensitive info** in files you create via Vortex

## Getting Help

If you encounter issues:

1. Check this guide's Troubleshooting section
2. Review the README.md file for more info
3. Check application logs (if available)
4. Visit https://console.x.ai for API-related help
5. Check Grok API documentation at https://api.x.ai

## Updates

To keep Vortex Agent up to date:

```bash
# Navigate to project folder
cd c:\dev\vortex\vortex_agent

# Get latest dependencies
flutter pub upgrade

# Rebuild
flutter build windows --release

# Replace old executable
copy build\windows\x64\runner\Release\vortex_agent.exe "C:\Program Files\VortexAgent\"
```

## What's Next?

1. ✅ Start using Ctrl+Q to access your AI assistant
2. 📚 Explore different types of commands
3. ⚙️ Customize settings to your preference
4. 📌 Pin shortcuts to your taskbar
5. 🚀 Integrate with your workflow

---

**Welcome to Vortex Agent!** Your AI-powered Windows assistant is ready to help. 🚀

For more information, see README.md or visit the project documentation.
