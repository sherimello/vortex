# 🎯 Vortex Agent - Getting Started Checklist

## Pre-Setup Checklist

Before you begin, ensure you have:

- [ ] Windows 10 or later
- [ ] Administrator access (for some setup steps)
- [ ] Internet connection
- [ ] At least 500MB free disk space
- [ ] Grok API key (from https://console.x.ai/api/keys)

---

## Installation Checklist

### Phase 1: Flutter Setup (If Needed)

- [ ] Download Flutter from https://flutter.dev/docs/get-started/install/windows
- [ ] Extract Flutter to `C:\src\flutter`
- [ ] Add Flutter to Windows PATH
- [ ] Verify: Run `flutter --version` in Command Prompt
- [ ] Verify: Run `dart --version` in Command Prompt

### Phase 2: Project Setup

- [ ] Navigate to: `c:\dev\vortex\vortex_agent`
- [ ] Open Command Prompt or PowerShell
- [ ] Run: `flutter pub get`
- [ ] Wait for dependencies to download (2-5 minutes)
- [ ] Check for errors in console output

### Phase 3: Build

- [ ] Run: `flutter build windows --release`
- [ ] Wait for build to complete (5-10 minutes)
- [ ] Verify: Check for build success message
- [ ] Verify: File exists at `build\windows\x64\runner\Release\vortex_agent.exe`

---

## Configuration Checklist

### Get API Key

- [ ] Visit https://console.x.ai
- [ ] Sign in or create account
- [ ] Go to https://console.x.ai/api/keys
- [ ] Create new API key
- [ ] Copy the key to safe location (notepad)
- [ ] Do NOT share this key with anyone

### First Launch

- [ ] Double-click `build\windows\x64\runner\Release\vortex_agent.exe`
- [ ] Wait for application window to appear (2-3 seconds)
- [ ] See "Welcome" screen with instructions
- [ ] Application is now running

### Configure API Key

- [ ] Click Settings button (⚙️) in top-right corner
- [ ] In "Grok API Key" field, paste your API key
- [ ] Click "Test API Connection" button
- [ ] You should see success message: "API Connection Successful"
- [ ] Click "Save Settings"
- [ ] See confirmation: "Settings saved successfully"

### Enable Auto-Start (Optional)

- [ ] Still in Settings screen
- [ ] Toggle "Auto Start" switch to ON
- [ ] Click "Save Settings"
- [ ] Application will now start when you restart Windows

---

## Verification Checklist

### Test Core Functionality

- [ ] Close Settings screen
- [ ] Press `Ctrl+Q` on your keyboard
- [ ] Glassmorphic dialog appears with input field
- [ ] Type: `"Open Notepad"`
- [ ] Press Enter or click Execute
- [ ] Results window appears (may take 3-5 seconds)
- [ ] See Grok's analysis and command output
- [ ] Notepad application opens
- [ ] Close Notepad
- [ ] Press Escape or click Close to dismiss results
- [ ] Ctrl+Q dialog closes

### Test File Operations

- [ ] Press Ctrl+Q again
- [ ] Type: `"Create a file at C:\Users\Documents\test.txt with content 'Hello Vortex'"`
- [ ] Press Enter
- [ ] Wait for results
- [ ] Open File Explorer to Documents folder
- [ ] Verify: `test.txt` file exists
- [ ] Open file and verify content

### Test Settings

- [ ] Press Ctrl+Q
- [ ] Close the dialog (press Escape)
- [ ] Click Settings (⚙️)
- [ ] Verify API key field shows your key (masked as dots)
- [ ] Verify Auto Start toggle shows your setting
- [ ] Click "About" button
- [ ] See version info and shortcuts
- [ ] Close About dialog
- [ ] Close Settings screen

---

## Post-Setup Checklist

### Create Convenient Access

- [ ] Right-click on `vortex_agent.exe` → Send to → Desktop
- [ ] Create shortcut on Desktop ✓
- [ ] Or manually add to Start Menu
- [ ] Pin to Taskbar (optional)

### Testing in Different Scenarios

- [ ] Test Ctrl+Q from Desktop
- [ ] Test Ctrl+Q from inside another application
- [ ] Test Ctrl+Q from File Explorer
- [ ] Test Ctrl+Q from web browser
- [ ] Verify hotkey works everywhere

### Minimize to Background Test

- [ ] Open Settings
- [ ] Close Settings (click back)
- [ ] Click Minimize button
- [ ] App minimizes to background
- [ ] Press Ctrl+Q - dialog should appear
- [ ] Verify Ctrl+Q still works when minimized

---

## Troubleshooting Checklist

If something doesn't work, go through these:

### Build Issues

- [ ] Clear cache: `flutter clean`
- [ ] Re-download packages: `flutter pub get`
- [ ] Retry build: `flutter build windows --release`
- [ ] Check internet connection
- [ ] Verify Flutter installation: `flutter doctor`

### Ctrl+Q Not Working

- [ ] Ensure app is running (not closed)
- [ ] Try pressing slowly (full key press)
- [ ] Restart application
- [ ] Check if another app uses Ctrl+Q
- [ ] Restart Windows
- [ ] Try from different applications

### API Key Errors

- [ ] Verify internet connection is active
- [ ] Check API key is copied correctly (no extra spaces)
- [ ] Go to https://console.x.ai/api/keys
- [ ] Verify key exists and is active
- [ ] Check you have API credits/quota
- [ ] Try "Test API Connection" again
- [ ] Copy key again and re-enter in Settings

### Commands Not Executing

- [ ] Check command syntax is valid Windows commands
- [ ] Review error message in results window
- [ ] Try simpler command first (e.g., "Open Notepad")
- [ ] Some commands need administrator privileges
- [ ] Check you have permission for file operations
- [ ] Review Grok's suggested command in results

### App Crashes on Startup

- [ ] Run `flutter clean && flutter pub get`
- [ ] Run `flutter build windows --release`
- [ ] Check Windows Event Viewer for error details
- [ ] Try running as Administrator
- [ ] Restart your computer
- [ ] Reinstall Flutter if issue persists

---

## Daily Usage Checklist

Each time you use Vortex Agent:

- [ ] Application is running
- [ ] API key is configured (first time only)
- [ ] Internet connection is active
- [ ] Plan your command before execution
- [ ] Review Grok's suggestion before confirming
- [ ] Be cautious with file deletion commands
- [ ] Close result window after viewing
- [ ] Minimize app when not in immediate use
- [ ] Check for any error messages

---

## Security Checklist

- [ ] API key is kept private and secure
- [ ] Never shared API key with anyone
- [ ] Only enter commands you understand
- [ ] Review file operations before execution
- [ ] Keep Windows updated and secured
- [ ] Use strong passwords for sensitive accounts
- [ ] Avoid running suspicious commands
- [ ] Be careful with admin-level operations

---

## Documentation Reading Checklist

Before starting, familiarize yourself with:

**Must Read:**
- [ ] QUICK_REFERENCE.md (5 minutes)
- [ ] SETUP_GUIDE.md (15 minutes)

**Recommended:**
- [ ] README.md (full features & troubleshooting)
- [ ] PROJECT_OVERVIEW.md (technical details)

**Reference:**
- [ ] PROJECT_SUMMARY.md (what was created)

---

## Advanced Setup (Optional)

If you want to go further:

- [ ] Customize hotkey (edit hotkey_service.dart)
- [ ] Change UI colors (edit screen files)
- [ ] Modify window size (edit main.dart)
- [ ] Add custom file operations (edit file_operation_service.dart)
- [ ] Create custom system prompts (edit grok_service.dart)
- [ ] Build installer for distribution
- [ ] Create automated tasks

---

## Completion Checklist

You're done when you have:

✅ Flutter installed and verified  
✅ Project built successfully  
✅ Application runs without errors  
✅ API key configured and tested  
✅ Ctrl+Q hotkey works  
✅ Sample commands execute successfully  
✅ Auto-start enabled (optional)  
✅ Desktop shortcut created (optional)  
✅ Documented your setup  
✅ Read essential documentation  

---

## Next Steps

After completing setup:

1. **Explore Commands**: Try different types of commands
2. **Create Shortcuts**: Make frequently used commands easy to access
3. **Customize UI**: Adjust colors and styling to your preference
4. **Extend Features**: Add your own custom operations
5. **Share Experience**: Let others know about Vortex Agent

---

## Quick Reference for Common Issues

| Issue | Quick Fix |
|-------|-----------|
| Hotkey not working | Restart app, check if another app uses Ctrl+Q |
| API errors | Verify internet, check API key, verify credits |
| Build fails | `flutter clean && flutter pub get && flutter build windows --release` |
| App crashes | Try running as Administrator |
| Commands fail | Check command syntax, review error in results |

---

## Support Resources

- 📖 **Documentation**: See included .md files
- 🔗 **Grok API**: https://api.x.ai
- 🎮 **X.AI Console**: https://console.x.ai  
- 📚 **Flutter**: https://flutter.dev
- 🐍 **Dart**: https://dart.dev

---

## Congratulations! 🎉

Once you've completed this checklist, you have successfully:

✨ Set up Vortex Agent  
✨ Configured Grok AI integration  
✨ Verified all core functionality  
✨ Tested hotkey and commands  
✨ Enabled background service  

**You're now ready to use Vortex Agent!** 🚀

---

## Final Tips

- **Keep it secure**: Don't share your API key
- **Be thoughtful**: Review commands before execution
- **Have fun**: Explore what Grok can help you with
- **Stay organized**: Use command history effectively
- **Customize**: Make it your own

---

**Date Completed**: _______________  
**Setup Time**: _______________  
**First Command**: _______________

---

**Happy automation!** 🤖✨

*Vortex Agent - Your AI-powered Windows Assistant*
