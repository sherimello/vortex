import 'dart:convert';
import 'package:logger/logger.dart';
import 'file_operation_service.dart';

class AppDiscoveryService {
  final FileOperationService _fileService;
  final Logger _logger = Logger();

  Map<String, String> _cache = {};
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  AppDiscoveryService(this._fileService);

  bool get _cacheValid =>
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheDuration &&
      _cache.isNotEmpty;

  Future<Map<String, String>> getInstalledApps({bool forceRefresh = false}) async {
    if (!forceRefresh && _cacheValid) return _cache;
    try {
      final result = await _fileService.executePowerShellScript(_discoveryScript);
      if (result.exitCode == 0 && result.output.isNotEmpty) {
        final jsonStr = result.output.trim();
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        _cache = decoded.map((k, v) => MapEntry(k, v.toString()));
        _cacheTime = DateTime.now();
        _logger.i('Discovered ${_cache.length} installed apps');
        return _cache;
      }
    } catch (e) {
      _logger.e('App discovery failed: $e');
    }
    return _cache;
  }

  void invalidateCache() {
    _cache = {};
    _cacheTime = null;
  }

  static const String _discoveryScript = r'''
$apps = @{}

# --- UWP / Microsoft Store apps via Get-StartApps (fast, covers all Start Menu apps) ---
try {
    Get-StartApps | Where-Object { $_.AppId -like '*!*' -and $_.Name } | ForEach-Object {
        $n = ($_.Name -replace '\s*\(.*\)$', '').Trim()
        if ($n -and -not $apps.ContainsKey($n)) {
            $apps[$n] = "shell:AppsFolder\$($_.AppId)"
        }
    }
} catch {}

# --- UWP / Store apps deep scan via AppxPackage + manifest (catches apps not in Start Menu) ---
try {
    $skip = '^(Microsoft\.Windows|Microsoft\.Net|Microsoft\.UI|Microsoft\.VCLibs|Windows\.|Microsoft\.Direct|Microsoft\.Advertising)'
    Get-AppxPackage | Where-Object {
        -not $_.IsFramework -and
        $_.SignatureKind -notin @('System') -and
        $_.Name -notmatch $skip
    } | ForEach-Object {
        try {
            $manifestPath = Join-Path $_.InstallLocation 'AppxManifest.xml'
            if (-not (Test-Path $manifestPath)) { return }
            [xml]$manifest = Get-Content $manifestPath -EA 0
            $app = $manifest.Package.Applications.Application | Select-Object -First 1
            if (-not $app) { return }
            $appEntryId = $app.Id
            $displayName = $manifest.Package.Properties.DisplayName
            # Skip resource-reference placeholders like "ms-resource:AppName"
            if (-not $displayName -or $displayName -match '^ms-resource' -or $displayName -match '^\s*$') {
                $displayName = $_.Name -replace '^[^.]+\.', '' -replace 'Desktop$', '' -replace 'Beta$', ' Beta' -replace 'App$', ''
            }
            $displayName = $displayName.Trim()
            if ($displayName -and $appEntryId -and -not $apps.ContainsKey($displayName)) {
                $apps[$displayName] = "shell:AppsFolder\$($_.PackageFamilyName)!$appEntryId"
            }
        } catch {}
    }
} catch {}

# --- Start Menu shortcuts (Win32 apps) ---
$wsh = New-Object -ComObject WScript.Shell
foreach ($sm in @("$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
                   "$env:ProgramData\Microsoft\Windows\Start Menu\Programs")) {
    if (-not (Test-Path $sm)) { continue }
    Get-ChildItem $sm -Recurse -Filter "*.lnk" -EA 0 | ForEach-Object {
        try {
            $lnk = $wsh.CreateShortcut($_.FullName)
            $target = $lnk.TargetPath
            if ($target -and (Test-Path $target) -and $target -match '\.exe$') {
                $name = $_.BaseName -replace '\s*\(.*\)$', '' -replace '\s+\d+$', ''
                if (-not $apps.ContainsKey($name)) { $apps[$name] = $target }
            }
        } catch {}
    }
}

# --- Registry uninstall entries ---
foreach ($key in @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")) {
    if (-not (Test-Path $key)) { continue }
    Get-ChildItem $key -EA 0 | ForEach-Object {
        try {
            $p = Get-ItemProperty $_.PSPath -EA 0
            if (-not $p.DisplayName) { return }
            $name = $p.DisplayName -replace '\s*\(.*\)$', '' -replace '\s+\d+(\.\d+)*$', ''
            if ($apps.ContainsKey($name)) { return }
            if ($p.DisplayIcon) {
                $ico = ($p.DisplayIcon -split ',')[0].Trim('"')
                if ($ico -match '\.exe$' -and (Test-Path $ico)) {
                    $apps[$name] = $ico; return
                }
            }
            if ($p.InstallLocation -and (Test-Path $p.InstallLocation)) {
                $exe = Get-ChildItem $p.InstallLocation -Filter "*.exe" -Depth 3 -EA 0 |
                       Where-Object { $_.BaseName -notmatch 'uninstall|setup|update|crash|helper' } |
                       Sort-Object Length -Descending | Select-Object -First 1
                if ($exe) { $apps[$name] = $exe.FullName; return }
            }
        } catch {}
    }
}

# --- JetBrains Toolbox (deep nesting) ---
$tbRoot = "$env:LOCALAPPDATA\JetBrains\Toolbox\apps"
if (Test-Path $tbRoot) {
    Get-ChildItem $tbRoot -Recurse -Filter "*.exe" -EA 0 |
        Where-Object { $_.BaseName -match '64$' -or $_.Name -match 'idea|pycharm|webstorm|clion|rider|goland|rubymine|phpstorm|datagrip|fleet' } |
        ForEach-Object {
            $name = $_.BaseName -replace '64$', '' -replace '-', ' '
            if (-not $apps.ContainsKey($name)) { $apps[$name] = $_.FullName }
        }
}

# --- PATH executables (well-known dev tools) ---
foreach ($cmd in @('code','git','node','npm','python','python3','flutter','dart','dotnet','java','mvn','gradle','docker','kubectl','az','aws')) {
    $c = Get-Command $cmd -EA 0
    if ($c -and -not $apps.ContainsKey($cmd)) { $apps[$cmd] = $c.Source }
}

# Output as JSON
$apps | ConvertTo-Json -Compress
''';
}
