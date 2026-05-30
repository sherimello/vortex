import 'dart:io';
import 'grok_service.dart';
import 'cohere_service.dart';
import 'smart_router_service.dart';
import 'ai_service_base.dart';
import 'file_operation_service.dart';
import 'storage_service.dart';
import 'hotkey_service.dart';
import 'app_discovery_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  late GrokService _grokService;
  late CohereService _cohereService;
  late SmartRouterService _smartRouter;
  late FileOperationService _fileService;
  late StorageService _storageService;
  late HotKeyService _hotKeyService;
  late AppDiscoveryService _appDiscoveryService;

  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  Future<void> initialize() async {
    _storageService = StorageService();
    await _storageService.initialize();

    _grokService = GrokService();
    final groqKey = _storageService.getApiKey();
    if (groqKey != null && groqKey.isNotEmpty) {
      _grokService.setApiKey(groqKey);
    }

    _cohereService = CohereService();
    final cohereKey = _storageService.getCohereApiKey();
    if (cohereKey != null && cohereKey.isNotEmpty) {
      _cohereService.setApiKey(cohereKey);
    }

    _smartRouter = SmartRouterService(
      groq: _grokService,
      cohere: _cohereService,
    );

    _fileService = FileOperationService();
    _appDiscoveryService = AppDiscoveryService(_fileService);
    _hotKeyService = HotKeyService();
    await _hotKeyService.initialize();

    // Register auto-start in Windows by default (user can disable in Settings)
    await applyAutoStart(_storageService.getAutoStart());
  }

  /// Writes/removes the app from HKCU Run key so it launches on Windows startup.
  static Future<void> applyAutoStart(bool enable) async {
    if (!Platform.isWindows) return;
    const appName = 'VortexAgent';
    final exePath = Platform.resolvedExecutable;
    if (enable) {
      await Process.run('reg', [
        'add',
        r'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
        '/v', appName,
        '/t', 'REG_SZ',
        '/d', '"$exePath"',
        '/f',
      ]);
    } else {
      await Process.run('reg', [
        'delete',
        r'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
        '/v', appName,
        '/f',
      ]);
    }
  }

  AiServiceBase get activeAiService => _smartRouter;

  GrokService get grokService => _grokService;
  CohereService get cohereService => _cohereService;
  SmartRouterService get smartRouter => _smartRouter;
  FileOperationService get fileService => _fileService;
  StorageService get storageService => _storageService;
  HotKeyService get hotKeyService => _hotKeyService;
  AppDiscoveryService get appDiscoveryService => _appDiscoveryService;
}
