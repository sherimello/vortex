# Vortex Agent - Windows AI Assistant

A powerful Flutter-based Windows application that uses Grok AI to help with file operations, command execution, and system tasks.

## Features

✨ **AI-Powered Commands**: Uses Grok AI to understand and execute complex tasks
🔥 **Global Hotkey**: Press `Ctrl+Q` to open the command interface from anywhere
📁 **File Operations**: Create, read, update, delete files and folders
🚀 **Application Launcher**: Open any Windows application on demand
💻 **Command Execution**: Run Windows commands and scripts
🎨 **Glassmorphism UI**: Beautiful modern interface with blur effects
⚙️ **Background Service**: Runs in the background even when minimized
🔒 **Secure API**: Secure storage of Grok API credentials
💾 **Command History**: Keep track of executed commands

## System Requirements

- Windows 10 or later
- Flutter SDK (3.11.5 or higher)
- Dart SDK (included with Flutter)
- 200MB free disk space
- Grok API key (get from https://console.x.ai/api/keys)

## Installation

### 1. Clone or Download the Project

```bash
cd c:\dev\vortex\vortex_agent
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Build the Windows Application

```bash
flutter build windows --release
```

The built application will be in: `build\windows\x64\runner\Release\`

### 4. Create Desktop Shortcut (Optional)

```bash
# Copy the exe to a convenient location
copy build\windows\x64\runner\Release\vortex_agent.exe "C:\Program Files\VortexAgent\vortex_agent.exe"
```

## Configuration

### Adding Your Grok API Key

1. Launch the application
2. Click the ⚙️ **Settings** button in the top-right corner
3. Enter your Grok API key (get it from https://console.x.ai/api/keys)
4. Click **Save Settings**
5. Click **Test API Connection** to verify it works

### Enable Auto-Start

1. Open Settings
2. Toggle **Auto Start** to ON
3. The app will now launch automatically when you start your computer

### Optional: Enable Windows Startup Auto-Start

For older Windows versions or if the Flutter auto-start doesn't work:

1. Run the included `enable_autostart.bat` script (right-click → Run as Administrator)
2. Or manually add the shortcut to `C:\Users\YourUsername\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\`

## Usage

### Opening the Command Interface

Press **Ctrl+Q** from anywhere on your system. A beautiful glassmorphic dialog will appear.

### Executing Commands

Examples of what you can ask:

```
# File operations
Create a file at C:\Users\Documents\test.txt with content "Hello World"
Read the contents of C:\Users\Documents\sample.txt
Delete the folder C:\temp\old_files

# Application launching
Open Notepad
Launch Visual Studio Code
Start Google Chrome

# System operations
List all files in the Downloads folder
Create a new folder in Documents called "Projects"
Open File Explorer to C:\Program Files

# Complex tasks
Search for all .txt files in Documents and show me the count
Create a backup of my Documents folder
Show me all running applications
```

### Closing the Interface

- Press **Escape** key, or
- Click **Cancel** button, or
- Click outside the dialog

## Architecture

### Core Components

```
lib/
├── main.dart                 # Application entry point
├── services/                 # Business logic layer
│   ├── grok_service.dart     # Grok API integration
│   ├── file_operation_service.dart # File system operations
│   ├── hotkey_service.dart   # Global hotkey handling
│   ├── storage_service.dart  # Settings & preferences
│   └── service_locator.dart  # Service management
├── models/                   # Data models
│   └── response_model.dart   # API response models
├── screens/                  # UI screens
│   ├── settings_screen.dart  # Settings configuration
│   └── result_screen.dart    # Command results display
└── widgets/                  # Custom UI widgets
    └── glassmorphic_input.dart # Command input dialog
```

### Technology Stack

- **Framework**: Flutter 3.11.5+
- **Backend API**: Grok AI (via X.AI)
- **State Management**: GetX
- **UI Components**: Material Design 3 + Glassmorphism
- **Storage**: SharedPreferences + Hive
- **Hotkey Handling**: hotkey_manager
- **Window Management**: window_manager
- **Logging**: logger

## Grok API Integration

### How It Works

1. User enters a command via Ctrl+Q dialog
2. App sends request to Grok API with the command
3. Grok analyzes and suggests:
   - A description of what it will do
   - The exact command to execute
   - What the user should expect
4. App parses the response and executes the suggested command
5. Results are displayed in the result window

### API Endpoint

```
POST https://api.x.ai/v1/chat/completions
```

Model: `grok-2-1212`

### System Prompt

Grok is instructed to:
- Provide clear ACTION descriptions
- Suggest safe, precise Windows commands
- Ask for confirmation on destructive operations
- Format responses with ACTION, COMMAND, and RESULT sections

## Settings Explained

### Grok API Key
Your authentication token for Grok API. Keep this confidential!

### Auto Start
When enabled, the application will launch automatically when you start Windows.

### Button: Test API Connection
Verifies that your Grok API key is valid and the connection works.

### Button: About
Shows version information and keyboard shortcuts.

## Security Considerations

⚠️ **Important**:
- Your Grok API key is stored locally in Windows encrypted storage
- Never share your API key with anyone
- Commands are executed with your user permissions
- Be cautious with commands that modify system files
- Review suggested commands before execution

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+Q` | Open/Close command interface |
| `Enter` | Execute command in dialog |
| `Escape` | Close dialogs |
| `Tab` | Navigate between fields |

## Troubleshooting

### Ctrl+Q Hotkey Not Working

- Ensure the app is running (check system tray)
- Restart the application
- Check if another application is using Ctrl+Q
- Try rebooting your system

### API Connection Fails

- Verify your internet connection
- Check that your Grok API key is correct
- Go to https://console.x.ai/api/keys to verify your key is active
- Ensure you have API credits available
- Wait a moment and try again

### Commands Not Executing

- Verify the command is valid for Windows
- Check that you have permission to execute the command
- Some commands may require administrator privileges
- Review the error message in the results window

### App Won't Start

- Ensure Flutter SDK is properly installed
- Try: `flutter clean && flutter pub get`
- Rebuild the application: `flutter build windows --release`
- Check Windows Event Viewer for error details

## Building from Source

### Development Build

```bash
flutter run -d windows
```

### Release Build

```bash
flutter build windows --release
```

Output: `build/windows/x64/runner/Release/`

### Building APK/Release Version

```bash
flutter build windows --release --obfuscate --split-debug-info=build/obfuscation
```

## API Rate Limits

- Grok API has rate limits based on your subscription
- Be mindful of API usage
- Check your X.AI console for current usage

## Advanced Features

### Command History

Previous commands are stored and can be referenced. Access through logs or storage.

### Customization

Edit `lib/main.dart` to customize:
- Hotkey (currently Ctrl+Q)
- UI colors and styling
- Window dimensions
- Default behaviors

### Extending Functionality

Add new file operations in `lib/services/file_operation_service.dart`

Example:
```dart
Future<void> unzipFile(String path, String destination) async {
  // Your implementation here
}
```

## Performance Tips

- Minimize the app when not in use (it runs in background)
- API calls take 2-5 seconds; be patient
- Close result dialogs after reviewing to free memory
- Restart the app if it feels slow (memory cleanup)

## Known Limitations

- Grok's knowledge cutoff means some recent commands may not work
- Complex scripts may need to be broken into smaller commands
- Some system-level operations require administrator privileges
- The app cannot directly execute administrator tasks without elevation

## Support & Feedback

For issues or suggestions:
1. Check the logs in the console
2. Review this README
3. Check Grok API status at https://status.x.ai/

## License

This project is provided as-is for personal and commercial use.

## Updates

To update the dependencies:

```bash
flutter pub upgrade
flutter build windows --release
```

## Future Enhancements

- [ ] Task scheduling
- [ ] Command templates
- [ ] Custom AI prompt engineering
- [ ] Voice input support
- [ ] Dark/Light theme toggle
- [ ] Advanced logging & analytics
- [ ] Plugin system for extensions
- [ ] Multi-language support

---

**Vortex Agent v1.0.0** - Your AI-powered Windows Assistant

Made with ❤️ using Flutter & Grok AI

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# vortex
