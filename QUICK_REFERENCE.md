# Vortex Agent - Quick Reference

## Installation Quick Steps

```bash
# 1. Navigate to project
cd c:\dev\vortex\vortex_agent

# 2. Get dependencies
flutter pub get

# 3. Build (Windows Release)
flutter build windows --release

# 4. Run the app from:
# build\windows\x64\runner\Release\vortex_agent.exe
```

## Usage

**Open dialog**: Press `Ctrl+Q`  
**Execute command**: Press `Enter`  
**Close dialog**: Press `Escape` or click Cancel  
**Settings**: Click ⚙️ icon in main window

## First Setup

1. Launch application
2. Click Settings (⚙️)
3. Enter Grok API key (from https://console.x.ai/api/keys)
4. Click "Test API Connection"
5. Enable "Auto Start" if desired
6. Click "Save Settings"

## Command Examples

```
# Files
Create a file at C:\path\file.txt
Read C:\path\file.txt
Delete C:\path\folder

# Apps
Open Notepad
Launch VS Code
Start Chrome

# System
List files in C:\Users\Downloads
Show disk space usage
Get Windows version
```

## Settings Screen

- **Grok API Key**: Your authentication token (required)
- **Auto Start**: Launch on Windows startup
- **Test API Connection**: Verify API works
- **About**: Version info & shortcuts

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+Q` | Open/Close |
| `Enter` | Submit |
| `Escape` | Close |

## Features

✨ AI-powered Windows commands  
🔥 Global hotkey (Ctrl+Q)  
📁 File & folder operations  
🚀 App launcher  
💻 Command execution  
🎨 Beautiful UI  
⚙️ Background service  

## Troubleshooting

**Hotkey not working?**
- App must be running
- Restart application
- Restart Windows

**API errors?**
- Check internet connection
- Verify API key is correct
- Visit https://console.x.ai/api/keys
- Check API credits available

**Commands failing?**
- Verify command is valid Windows syntax
- Check user permissions
- Admin commands need elevation
- Review error in results

## File Locations

- **Executable**: `build/windows/x64/runner/Release/vortex_agent.exe`
- **Source**: `lib/main.dart`
- **Config**: Stored locally in Windows preferences
- **Auto-start script**: `windows/enable_autostart.bat`

## Development Commands

```bash
# Run in debug mode
flutter run -d windows

# Hot reload (after changes)
r  # in debug console

# Clean build
flutter clean

# Get latest packages
flutter pub upgrade

# Check dependencies
flutter pub outdated
```

## Security Reminders

🔒 Never share API key  
🔒 Review suggested commands before running  
🔒 Be careful with file deletion commands  
🔒 Some operations need admin rights  

## Support Resources

- **Grok API**: https://api.x.ai
- **X.AI Console**: https://console.x.ai
- **Flutter Docs**: https://flutter.dev
- **This Project**: README.md & SETUP_GUIDE.md

## Build Commands

```bash
# Development build
flutter run -d windows

# Release build
flutter build windows --release

# Clean and rebuild
flutter clean && flutter pub get && flutter build windows --release

# With obfuscation
flutter build windows --release --obfuscate
```

## Environment Info

- Framework: Flutter 3.11.5+
- Platform: Windows 10/11
- API: Grok AI (X.AI)
- Storage: SharedPreferences
- UI: Material Design 3 + Glassmorphism

## Next Steps

1. ✅ Install Flutter
2. ✅ Get Grok API key
3. ✅ Build application
4. ✅ Configure API key in Settings
5. ✅ Test with Ctrl+Q
6. ✅ Enable Auto-Start (optional)
7. ✅ Create desktop shortcut (optional)
8. ✅ Start using!

---

**Happy commanding!** 🚀

For detailed help, see SETUP_GUIDE.md or README.md
