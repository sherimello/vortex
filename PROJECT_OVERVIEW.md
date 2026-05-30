# Vortex Agent - Complete Project Overview

## 📋 Table of Contents

1. [Project Summary](#project-summary)
2. [Project Structure](#project-structure)
3. [Architecture](#architecture)
4. [Technologies Used](#technologies-used)
5. [Installation](#installation)
6. [Configuration](#configuration)
7. [Usage](#usage)
8. [API Integration](#api-integration)
9. [Key Features](#key-features)
10. [File Structure](#file-structure)

---

## 🎯 Project Summary

**Vortex Agent** is a sophisticated Windows application built with Flutter that leverages Grok AI to provide intelligent command execution, file operations, and system automation through a beautiful, modern UI.

### Core Functionality

```
User Input (Ctrl+Q)
    ↓
Glassmorphic Dialog UI
    ↓
Send to Grok AI
    ↓
Parse AI Response
    ↓
Execute Windows Command
    ↓
Display Results
    ↓
User Reviews Output
```

### Key USPs

- 🎨 **Modern UI**: Glassmorphism design with smooth animations
- 🚀 **Always Available**: Global Ctrl+Q hotkey from anywhere
- 🧠 **AI-Powered**: Uses Grok AI for intelligent command planning
- 📁 **File Management**: Full CRUD operations on files and folders
- 🔧 **Command Execution**: Run any Windows command/script
- 💾 **Persistent**: Runs in background even after closing
- ⚙️ **Easy Setup**: Simple configuration through settings UI

---

## 📁 Project Structure

```
vortex_agent/
├── lib/
│   ├── main.dart                          # Application entry point
│   ├── services/
│   │   ├── service_locator.dart          # Service management & initialization
│   │   ├── grok_service.dart             # Grok AI API integration
│   │   ├── file_operation_service.dart   # File system operations
│   │   ├── hotkey_service.dart           # Global hotkey handler (Ctrl+Q)
│   │   └── storage_service.dart          # Persistent storage (SharedPreferences)
│   ├── models/
│   │   └── response_model.dart           # Data models (GrokResponse, CommandExecution)
│   ├── screens/
│   │   ├── settings_screen.dart          # Settings & configuration UI
│   │   └── result_screen.dart            # Command results display
│   ├── widgets/
│   │   └── glassmorphic_input.dart       # Glassmorphic dialog component
│   └── utils/
│       └── (future utility functions)
├── windows/
│   ├── runner/                            # Windows native code
│   ├── enable_autostart.bat               # Auto-start setup script
│   └── CMakeLists.txt                     # Windows build configuration
├── build/                                 # Build output (after build)
├── pubspec.yaml                           # Flutter dependencies
├── README.md                              # Comprehensive documentation
├── SETUP_GUIDE.md                         # Step-by-step setup instructions
├── QUICK_REFERENCE.md                     # Quick lookup guide
├── PROJECT_OVERVIEW.md                    # This file
└── build.bat                              # Automated build script
```

---

## 🏗️ Architecture

### Layered Architecture

```
┌─────────────────────────────────────┐
│         UI Layer (Screens)          │
│  - SettingsScreen                   │
│  - ResultScreen                     │
│  - MainScreen                       │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Widget Layer (Components)      │
│  - GlassmorphicInput                │
│  - UI Components                    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│       Service Layer (Business Logic)│
│  - GrokService (API)                │
│  - FileOperationService             │
│  - HotKeyService                    │
│  - StorageService                   │
│  - ServiceLocator                   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Model Layer (Data Models)      │
│  - GrokResponse                     │
│  - CommandExecution                 │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│    External Services & APIs         │
│  - Grok AI API (X.AI)               │
│  - Windows File System              │
│  - Windows Registry                 │
│  - System Process Execution         │
└─────────────────────────────────────┘
```

### Data Flow

```
┌─────────────────────────────────────────┐
│  User presses Ctrl+Q                    │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│  HotKeyService detects hotkey press     │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│  Overlay dialog appears                 │
│  (GlassmorphicInput widget)             │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│  User enters command and presses Enter  │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│  GrokService sends to Grok API          │
│  POST /v1/chat/completions              │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│  Grok AI analyzes and responds with:    │
│  - ACTION description                   │
│  - COMMAND to execute                   │
│  - RESULT expectations                  │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│  Parse response to extract COMMAND      │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│  FileOperationService.executeCommand()  │
│  Runs command via Process.run()         │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│  ResultScreen displays:                 │
│  - Grok analysis                        │
│  - Command output                       │
│  - Any errors                           │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│  User reviews and closes                │
│  (StorageService stores history)        │
└─────────────────────────────────────────┘
```

---

## 🛠️ Technologies Used

### Frontend
- **Flutter**: UI framework
- **GetX**: State management & navigation
- **Material Design 3**: Modern design system
- **Glassmorphism**: Beautiful blur effect UI

### Backend Services
- **Grok AI API**: Intelligent command planning
- **hotkey_manager**: Global hotkey listening (Ctrl+Q)
- **window_manager**: Window control (minimize, frameless, etc.)

### Data & Storage
- **SharedPreferences**: Lightweight persistent storage for settings
- **Hive**: Optional for larger data storage

### System Integration
- **Process class**: Command execution
- **File/Directory classes**: File system operations
- **Registry**: Windows settings (auto-start)

### Development
- **logger**: Logging for debugging
- **dio**: HTTP client for API calls
- **path**: Cross-platform path handling

---

## 🚀 Installation

### Quick Start (5 minutes)

```bash
# 1. Clone/Download and navigate to project
cd c:\dev\vortex\vortex_agent

# 2. Install dependencies
flutter pub get

# 3. Build
flutter build windows --release

# 4. Run
.\build\windows\x64\runner\Release\vortex_agent.exe
```

### Full Installation (with setup)

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed step-by-step instructions.

---

## ⚙️ Configuration

### API Key Setup

**In the app:**
1. Click Settings (⚙️)
2. Enter Grok API key
3. Click "Test API Connection"
4. Save

**Get your key:**
- Visit https://console.x.ai/api/keys
- Sign up if needed
- Create API key
- Copy and paste into Vortex

### Auto-Start Setup

**Option 1: Through Settings UI**
- Settings → Toggle "Auto Start" → Save

**Option 2: Using Batch Script**
- Run `windows\enable_autostart.bat` as Administrator

### Customization

Edit `lib/main.dart` to customize:
- Hotkey (currently Ctrl+Q, line with `PhysicalKeyboardKey.keyQ`)
- Window size (line with `setSize`)
- Colors and theme
- Startup behavior

---

## 💬 Usage

### Basic Usage

```
Press Ctrl+Q
↓
Type command (e.g., "Open Notepad")
↓
Press Enter
↓
See results
↓
Press Escape to close
```

### Command Examples

**File Operations:**
```
Create a file at C:\test.txt with "hello"
Read C:\Users\test.txt
Delete C:\temp\folder
List all files in Downloads
Create folder C:\Users\Projects
```

**Application Launcher:**
```
Open Notepad
Launch Visual Studio Code
Start Google Chrome
Open File Explorer to C:\Users
```

**System Queries:**
```
Get current Windows version
Show disk usage
List running processes
Check system memory
```

**Complex Operations:**
```
Find all .pdf files in Documents
Create a backup of my Desktop
Organize Downloads folder by file type
Search for files modified today
```

---

## 🔗 API Integration

### Grok API Endpoint

```
Endpoint: https://api.x.ai/v1/chat/completions
Method: POST
Model: grok-2-1212
```

### Request Format

```json
{
  "model": "grok-2-1212",
  "messages": [
    {
      "role": "system",
      "content": "You are a Windows command assistant..."
    },
    {
      "role": "user",
      "content": "User's command here"
    }
  ],
  "temperature": 0.7,
  "max_tokens": 1000
}
```

### Response Format

```json
{
  "choices": [
    {
      "message": {
        "content": "ACTION: ...\nCOMMAND: ...\nRESULT: ..."
      }
    }
  ]
}
```

### API Key Storage

- Stored in Windows SharedPreferences (encrypted by OS)
- Never logged or transmitted except to Grok API
- Can be changed anytime in Settings

---

## ✨ Key Features Explained

### 1. Global Hotkey (Ctrl+Q)

- **Implementation**: `hotkey_manager` package
- **Behavior**: Works from anywhere on Windows
- **Customizable**: Change in `lib/services/hotkey_service.dart`
- **Fallback**: Can use Settings button in main window

### 2. Glassmorphism UI

- **Effect**: Frosted glass look with blur
- **Uses**: `glassmorphism` package
- **Customization**: Edit `lib/widgets/glassmorphic_input.dart`
- **Performance**: Optimized for Windows

### 3. AI Command Planning

- **Process**:
  1. User enters natural language command
  2. Sent to Grok with specialized system prompt
  3. Grok responds with structured plan
  4. App extracts and executes suggested command
  5. Results shown to user

### 4. File Operations

- Create/update files and folders
- Read file contents
- Delete files/folders recursively
- List directory contents
- Recursive directory creation

### 5. Command Execution

- Runs any Windows cmd.exe command
- Captures stdout and stderr
- Shows exit code
- Real-time output display

### 6. Background Service

- App continues running when minimized
- Ctrl+Q works even with app hidden
- Auto-start on Windows boot
- System tray integration ready

---

## 📊 File Structure Details

### Services Layer

**GrokService** - Handles all Grok AI communication
- `executeCommand(String)` - Sends command to Grok
- `setApiKey(String)` - Sets authentication
- Error handling and logging

**FileOperationService** - Handles all file/system operations
- `executeCommand(String)` - Runs Windows commands
- `readFile(String)`, `writeFile(String, String)` - File I/O
- `createDirectory(String)`, `deleteDirectory(String)` - Folder ops
- `openApplication(String)` - Launch applications
- `listDirectory(String)` - Directory listing

**HotKeyService** - Manages global hotkey
- `registerHotkey()` - Setup Ctrl+Q listener
- `unregisterAllHotkeys()` - Cleanup

**StorageService** - Persistent data storage
- `setApiKey(String)` - Save API key
- `getApiKey()` - Retrieve API key
- `setAutoStart(bool)` - Auto-start setting
- `saveCommandHistory()` - Store command history

**ServiceLocator** - Service dependency management
- Singleton pattern
- Centralizes initialization
- Provides access to all services

### Screens

**SettingsScreen** - Configuration UI
- API key input with visibility toggle
- Auto-start toggle
- Test connection button
- About dialog

**ResultScreen** - Output display
- Shows Grok analysis
- Shows command output
- Displays errors
- Auto-scroll to bottom
- Close button

### Widgets

**GlassmorphicInput** - Command dialog
- Glassmorphic styling
- Text input field
- Execute/Cancel buttons
- Loading indicator
- Auto-focus on open

---

## 🔐 Security Considerations

### API Key Protection
- Stored in Windows encrypted storage
- Not logged or displayed in console
- Can be changed at any time
- Test connection doesn't reveal key content

### Command Execution
- Commands run with user's permissions
- No automatic elevation to admin
- User can review Grok's suggestion before execution
- Errors are caught and displayed

### Data Privacy
- No telemetry or tracking
- No analytics collection
- Settings stored locally only
- Command history stored locally

---

## 🐛 Debugging

### Enable Logging

Add to `main.dart`:
```dart
Logger.level = Level.trace; // Verbose logging
```

### Check Logs

Logs appear in debug console when running:
```bash
flutter run -d windows
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Hotkey not working | Restart app, check if another app uses Ctrl+Q |
| API errors | Verify key, internet, API credits |
| Commands fail | Check command syntax, permissions |
| Slow performance | Restart app, close result windows |

---

## 📈 Future Enhancements

- [ ] Command templates
- [ ] Advanced scheduling
- [ ] Voice commands
- [ ] Plugin system
- [ ] Multi-language support
- [ ] Dark/Light theme toggle
- [ ] Advanced analytics
- [ ] Task recording and replay
- [ ] Cloud sync of settings
- [ ] Custom shortcuts per command

---

## 📝 Development Workflow

### Making Changes

```bash
# 1. Edit files in lib/
# 2. Run in development
flutter run -d windows

# 3. Hot reload (press r in console)
# 4. Test changes
# 5. Rebuild for release
flutter build windows --release
```

### Adding Dependencies

```bash
flutter pub add package_name
flutter pub get
flutter pub upgrade
```

### Code Organization

- Keep services focused and single-responsibility
- Use models for data structures
- Put UI in screens and widgets
- Use constants for magic numbers
- Add comments for complex logic

---

## 🎓 Learning Resources

- [Flutter Documentation](https://flutter.dev)
- [Dart Language Guide](https://dart.dev)
- [GetX Documentation](https://github.com/jonataslaw/getx)
- [Material Design](https://material.io/design)
- [Grok API Docs](https://api.x.ai)
- [X.AI Console](https://console.x.ai)

---

## 📞 Support & Feedback

### Getting Help

1. Check README.md for features
2. Check SETUP_GUIDE.md for setup issues
3. Check QUICK_REFERENCE.md for quick lookup
4. Review code comments and logging

### Reporting Issues

Include:
- Windows version
- Flutter version (`flutter --version`)
- Error message/log
- Steps to reproduce
- Screenshots if applicable

---

## 📄 License

This project is provided as-is for personal and commercial use.

---

## 🎉 Conclusion

Vortex Agent is a comprehensive solution for Windows users who want AI-assisted command execution with a beautiful, modern interface. It combines cutting-edge UI design with practical system automation capabilities.

**Happy coding!** 🚀

---

**Last Updated**: May 19, 2026  
**Version**: 1.0.0  
**Status**: Production Ready
