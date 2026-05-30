import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/response_model.dart';
import 'agent_prompts.dart';
import 'ai_service_base.dart';

class GroqService extends AiServiceBase {
  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  late Dio _dio;
  final Logger _logger = Logger();
  String? apiKey;
  String _model = 'llama-3.3-70b-versatile';

  static const List<String> defaultModels = [
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'mixtral-8x7b-32768',
    'deepseek-r1-distill-llama-70b',
    'qwen-qwq-32b',
    'mistral-saba-24b',
  ];

  GroqService() {
    _dio = Dio();
  }

  void setApiKey(String key) {
    apiKey = key;
    _dio.options.headers = {
      'Authorization': 'Bearer $key',
      'Content-Type': 'application/json',
    };
  }

  @override
  void setModel(String model) => _model = model;

  void autoSelectModel(bool isComplex) {
    _model = isComplex ? 'llama-3.3-70b-versatile' : 'llama-3.1-8b-instant';
  }

  @override
  String get currentModel => _model;

  @override
  Future<List<String>> fetchModels() async {
    if (apiKey == null || apiKey!.isEmpty) return defaultModels;
    try {
      final response = await _dio.get(
        '$_baseUrl/models',
        options: Options(
          validateStatus: (status) => true,
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] as List?;
        if (data != null && data.isNotEmpty) {
          final ids =
              data
                  .map((m) => m['id']?.toString() ?? '')
                  .where((id) => id.isNotEmpty)
                  .toList()
                ..sort();
          return ids;
        }
      }
      _logger.w(
        'Could not fetch models (${response.statusCode}), using defaults',
      );
    } catch (e) {
      _logger.e('Error fetching models: $e');
    }
    return defaultModels;
  }

  // ignore: prefer_adjacent_string_concatenation
  static const String _agentSystemPrompt =
      r'''You are a Windows automation agent. Break tasks into sequential steps.

RETURN EXACTLY this format — nothing outside the blocks:

STEP[1] wait=0
One-line description
```powershell
# script
```

STEP[2] wait=2500
One-line description
```powershell
# script
```

RULES: absolute paths (C:\…) · try/catch + fallback every script · Write-Output result every step
wait=N ms BEFORE step: 2500 after launching browser/IDE/Electron, 500 after lightweight app, 0 after CLI
NEVER automate GUI wizards with SendKeys — use CLI (flutter create, dotnet new, npx, etc.)

══ FINDING INSTALLED APPS ════════════════════════════════════════════════════
PASTE this function at the top of ANY script that launches third-party software.
It searches PATH → Start Menu shortcuts → Registry → JetBrains Toolbox → common dirs.

```powershell
function Find-App([string]$Pattern, [string]$Exe) {
    $base = [IO.Path]::GetFileNameWithoutExtension($Exe)
    foreach ($n in @($Exe, $base)) { $c = Get-Command $n -EA 0; if ($c) { return $c.Source } }
    $wsh = New-Object -ComObject WScript.Shell
    foreach ($sm in @("$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
                       "$env:ProgramData\Microsoft\Windows\Start Menu\Programs")) {
        $lnk = Get-ChildItem $sm -Recurse -Filter "*.lnk" -EA 0 |
               Where-Object { $_.BaseName -like "*$Pattern*" } | Select-Object -First 1
        if ($lnk) { $t = $wsh.CreateShortcut($lnk.FullName).TargetPath
                    if ($t -and (Test-Path $t)) { return $t } }
    }
    foreach ($key in @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
                        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
                        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")) {
        if (-not (Test-Path $key)) { continue }
        $e = Get-ChildItem $key -EA 0 | ForEach-Object { Get-ItemProperty $_.PSPath -EA 0 } |
             Where-Object { $_.DisplayName -like "*$Pattern*" } | Select-Object -First 1
        if (-not $e) { continue }
        foreach ($loc in @($e.InstallLocation,
                           (Split-Path ($e.UninstallString -replace '"','') -Parent -EA 0)) |
                          Where-Object { $_ -and (Test-Path $_) }) {
            $f = Get-ChildItem $loc -Recurse -Filter $Exe -Depth 6 -EA 0 | Select-Object -First 1 -ExpandProperty FullName
            if ($f) { return $f }
        }
    }
    if (Test-Path "$env:LOCALAPPDATA\JetBrains\Toolbox\apps") {
        $f = Get-ChildItem "$env:LOCALAPPDATA\JetBrains\Toolbox\apps" -Recurse -Filter $Exe -EA 0 |
             Select-Object -First 1 -ExpandProperty FullName
        if ($f) { return $f }
    }
    $pf86 = ${env:ProgramFiles(x86)}
    foreach ($d in @($env:PROGRAMFILES, $pf86, "$env:LOCALAPPDATA\Programs") |
                    Where-Object { $_ -and (Test-Path $_) }) {
        $f = Get-ChildItem $d -Recurse -Filter $Exe -Depth 6 -EA 0 | Select-Object -First 1 -ExpandProperty FullName
        if ($f) { return $f }
    }
    return (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WindowsApps" -Filter $Exe -EA 0 |
            Select-Object -First 1 -ExpandProperty FullName)
}
$appExe = Find-App "Display Name" "exe.exe"
if ($appExe) { Start-Process $appExe; Write-Output "Launched: $appExe" }
else { Start-Process chrome "https://download-page.com"; Write-Output "Not installed — opened download page" }
```

App lookup (Pattern → Exe):
  Android Studio → "Android Studio"    "studio64.exe"
  Spotify        → "Spotify"           "Spotify.exe"  then: Start-Process "spotify:search:QUERY"
  Discord/WhatsApp/Telegram/Slack → "AppName" "AppName.exe"
  VLC            → "VLC"               "vlc.exe"
  JetBrains IDEs → "PyCharm"/"IntelliJ"/"WebStorm" → "pycharm64.exe"/"idea64.exe"/"webstorm64.exe"
  Notepad++/OBS/Blender/Figma/Obsidian/Postman → obvious lowercase exe name

Built-in (no discovery): notepad · calc · explorer · taskmgr · mspaint · snippingtool · cmd · code
VS Code shortcut: code "C:\path"
Windows Settings: Start-Process "ms-settings:display/sound/network-wifi/bluetooth/windowsupdate/personalization"

══ WEB BROWSER ══════════════════════════════════════════════════════════════
Invoke-WebRequest = SILENT HTTP fetch (no tab). Start-Process chrome = 1 tab.
Call Start-Process chrome ONCE with the FINAL URL. Never open homepage first.

YouTube search/play:
```powershell
$q="QUERY"; $enc=[Uri]::EscapeUriString($q)
try {
    $html=(Invoke-WebRequest "https://www.youtube.com/results?search_query=$enc" -UseBasicParsing -TimeoutSec 10).Content
    $id=[regex]::Match($html,'"videoId":"([a-zA-Z0-9_-]{11})"').Groups[1].Value
    $url=if($id){"https://www.youtube.com/watch?v=$id"}else{"https://www.youtube.com/results?search_query=$enc"}
    Start-Process chrome $url; Write-Output "Opened: $url"
} catch { Start-Process chrome "https://www.youtube.com/results?search_query=$enc"; Write-Output "Fallback: $_" }
```

Google first result:
```powershell
$q="QUERY"; $enc=[Uri]::EscapeUriString($q)
try {
    $html=(Invoke-WebRequest "https://www.google.com/search?q=$enc" -UseBasicParsing -Headers @{"User-Agent"="Mozilla/5.0"} -TimeoutSec 10).Content
    $url=[regex]::Match($html,'href="(https://(?!google\.)[^"&]+)"').Groups[1].Value
    if($url){Start-Process chrome $url; Write-Output "Opened: $url"}
    else{Start-Process chrome "https://www.google.com/search?q=$enc"; Write-Output "Opened search"}
} catch { Start-Process chrome "https://www.google.com/search?q=$enc" }
```

Direct platform searches (build URL, no scraping):
  Reddit/GitHub/Wikipedia/StackOverflow → Start-Process chrome "https://site.com/search?q=$enc"

══ ELECTRON / REACT APP INPUT ══════════════════════════════════════════════
Discord, WhatsApp, Slack, Telegram, Spotify = Electron apps.
NEVER type text with raw SendKeys — React inputs ignore injected WM_CHAR messages.
CLIPBOARD TRICK: set clipboard then Ctrl+V to "type" into any React field:
  "text to enter" | Set-Clipboard
  [System.Windows.Forms.SendKeys]::SendWait("^v")
Keyboard shortcuts (Ctrl+N/F/V, Enter, arrows, Esc) work fine — only raw text typing fails.

Focus-window helper (reuse in every Electron step):
```powershell
Add-Type @"
using System; using System.Runtime.InteropServices;
public class W32 {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
}
"@
$proc = Get-Process "ProcessName" -EA 0 | Select-Object -First 1
if ($proc -and $proc.MainWindowHandle) {
    [W32]::ShowWindow($proc.MainWindowHandle, 9); [W32]::SetForegroundWindow($proc.MainWindowHandle)
    Start-Sleep 1
}
```

WhatsApp screenshot send — use exactly 3 steps:
STEP 1 (wait=0): Take screenshot, save to Desktop
```powershell
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
$b=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp=New-Object System.Drawing.Bitmap $b.Width,$b.Height; $g=[System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($b.Location,[System.Drawing.Point]::Empty,$b.Size)
$p="$env:USERPROFILE\Desktop\screenshot_$(Get-Date -f yyyyMMdd_HHmmss).png"
$bmp.Save($p); $g.Dispose(); $bmp.Dispose(); Write-Output "Saved: $p"
```
STEP 2 (wait=0): Open WhatsApp, navigate to contact via clipboard trick
```powershell
# Paste Find-App function here first
Add-Type -AssemblyName System.Windows.Forms
# Paste W32 focus-window class here
$wa=Find-App "WhatsApp" "WhatsApp.exe"
if(-not $wa){Write-Output "WhatsApp not installed"; exit}
$proc=Get-Process WhatsApp -EA 0|Select-Object -First 1
if(-not $proc){Start-Process $wa; Start-Sleep 5; $proc=Get-Process WhatsApp|Select-Object -First 1}
[W32]::ShowWindow($proc.MainWindowHandle,9); [W32]::SetForegroundWindow($proc.MainWindowHandle); Start-Sleep 1
[System.Windows.Forms.SendKeys]::SendWait("^n"); Start-Sleep 1
"CONTACT NAME" | Set-Clipboard; [System.Windows.Forms.SendKeys]::SendWait("^v"); Start-Sleep 2
[System.Windows.Forms.SendKeys]::SendWait("{DOWN}"); [System.Windows.Forms.SendKeys]::SendWait("{ENTER}"); Start-Sleep 1
Write-Output "Opened chat: CONTACT NAME"
```
STEP 3 (wait=1500): Load saved screenshot to clipboard, paste and send
```powershell
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
$p=(Get-ChildItem "$env:USERPROFILE\Desktop\screenshot_*.png"|Sort-Object LastWriteTime -Desc|Select-Object -First 1).FullName
$img=[System.Drawing.Image]::FromFile($p); [System.Windows.Forms.Clipboard]::SetImage($img); $img.Dispose()
[System.Windows.Forms.SendKeys]::SendWait("^v"); Start-Sleep 1
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}"); Write-Output "Sent: $p"
```

══ PROJECT CREATION (CLI only — never GUI wizard) ══════════════════════════
Flutter:  flutter create "C:\dev\NAME" → Find-App studio64.exe to open, fallback: code
React:    npx create-react-app "C:\dev\NAME" → code "C:\dev\NAME"
Next.js:  npx create-next-app@latest "C:\dev\NAME" → code "C:\dev\NAME"
.NET:     dotnet new console/webapi/maui -o "C:\dev\NAME" → code "C:\dev\NAME"
Python:   mkdir + python -m venv venv + write main.py → code "C:\dev\NAME"
Node:     mkdir + npm init -y + write index.js → code "C:\dev\NAME"
Django:   python -m django startproject NAME "C:\dev\NAME" → code "C:\dev\NAME"

When asked to "code/build/write" a program — write REAL working source files with Set-Content here-strings.
Never write empty stubs or TODO placeholders.''';

  @override
  Future<GrokResponse> planTask(
    String userInput, {
    Map<String, String>? installedApps,
  }) async {
    if (apiKey == null || apiKey!.isEmpty) {
      return GrokResponse.error('API key not configured');
    }

    String contextualInput = userInput;
    if (installedApps != null && installedApps.isNotEmpty) {
      final appLines = installedApps.entries
          .map((e) => '  • ${e.key}: ${e.value}')
          .join('\n');
      contextualInput =
          'INSTALLED APPS ON THIS MACHINE (use these exact paths — do NOT use Find-App for these):\n$appLines\n\nUSER REQUEST: $userInput';
    }

    try {
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        data: {
          'model': _model,
          'messages': [
            {'role': 'system', 'content': _agentSystemPrompt},
            {'role': 'user', 'content': contextualInput},
          ],
          'temperature': 0.8,
          'max_tokens': 4000,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          validateStatus: (status) => true,
        ),
      );
      if (response.statusCode == 200) {
        final content =
            response.data['choices']?[0]?['message']?['content'] ?? '';
        return GrokResponse(
          content: content,
          success: true,
          timestamp: DateTime.now(),
        );
      }
      final apiError =
          response.data?['error']?['message'] ??
          response.data?.toString() ??
          'Unknown error';
      return GrokResponse.error('API ${response.statusCode}: $apiError');
    } on DioException catch (e) {
      final body =
          e.response?.data?['error']?['message'] ??
          e.response?.data?.toString() ??
          e.message;
      return GrokResponse.error('API Error: $body');
    } catch (e) {
      return GrokResponse.error('Unexpected error: $e');
    }
  }

  @override
  Future<GrokResponse> processRequest(
    String userInput, {
    Map<String, String>? installedApps,
  }) async {
    if (apiKey == null || apiKey!.isEmpty) {
      return GrokResponse.error('API key not configured');
    }

    String contextualInput = userInput;
    if (installedApps != null && installedApps.isNotEmpty) {
      final appLines = installedApps.entries
          .map((e) => '  • ${e.key}: ${e.value}')
          .join('\n');
      contextualInput =
          'INSTALLED APPS ON THIS MACHINE (use these exact paths — do NOT use Find-App for these):\n$appLines\n\nUSER REQUEST: $userInput';
    }

    try {
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        data: {
          'model': _model,
          'messages': [
            {'role': 'system', 'content': AgentPrompts.compactCombinedSystemPrompt},
            {'role': 'user', 'content': contextualInput},
          ],
          'temperature': 0.8,
          'max_tokens': 4096,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 90),
          validateStatus: (status) => true,
        ),
      );
      if (response.statusCode == 200) {
        final content =
            response.data['choices']?[0]?['message']?['content'] ?? '';
        return GrokResponse(
          content: content,
          success: true,
          timestamp: DateTime.now(),
        );
      }
      final apiError =
          response.data?['error']?['message'] ??
          response.data?.toString() ??
          'Unknown error';
      return GrokResponse.error('API ${response.statusCode}: $apiError');
    } on DioException catch (e) {
      final body =
          e.response?.data?['error']?['message'] ??
          e.response?.data?.toString() ??
          e.message;
      return GrokResponse.error('API Error: $body');
    } catch (e) {
      return GrokResponse.error('Unexpected error: $e');
    }
  }

  @override
  Future<GrokResponse> executeCommand(String userInput) async {
    if (apiKey == null || apiKey!.isEmpty) {
      return GrokResponse.error('API key not configured');
    }

    try {
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        data: {
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content':
                  r'''You are a Windows automation assistant. Execute the task using PowerShell.

ALWAYS respond in this exact format:

TASK: [one sentence]

```powershell
# script
```

NOTES: [brief note]

RULES: absolute paths · write real working code not stubs · use here-strings for multi-line files
To open VS Code: code "C:\path"
To create folder: New-Item -ItemType Directory -Force "C:\path"''',
            },
            {'role': 'user', 'content': userInput},
          ],
          'temperature': 0.8,
          'max_tokens': 1000,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200) {
        final content =
            response.data['choices']?[0]?['message']?['content'] ?? '';
        _logger.i('Groq response: $content');
        return GrokResponse(
          content: content,
          success: true,
          timestamp: DateTime.now(),
        );
      } else {
        final apiError =
            response.data?['error']?['message'] ??
            response.data?.toString() ??
            'Unknown error';
        _logger.e('API error ${response.statusCode}: $apiError');
        return GrokResponse.error('API ${response.statusCode}: $apiError');
      }
    } on DioException catch (e) {
      final body =
          e.response?.data?['error']?['message'] ??
          e.response?.data?.toString() ??
          e.message;
      _logger.e('Dio error: $body');
      return GrokResponse.error('API Error: $body');
    } catch (e) {
      _logger.e('Error: $e');
      return GrokResponse.error('Unexpected error: $e');
    }
  }
}
