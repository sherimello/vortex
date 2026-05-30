import 'package:logger/logger.dart';
import '../models/response_model.dart';
import 'ai_service_base.dart';
import 'groq_service.dart';
import 'cohere_service.dart';

/// Routes every request to the best available provider.
///
/// Priority: Groq first (free quota is tight but fast) → Cohere fallback
/// (more generous quota). Both providers are used based on:
///   • API key presence
///   • Per-provider cooldown after rate-limit/auth errors
///   • Request complexity (auto-selects model tier within each provider)
class SmartRouterService extends AiServiceBase {
  final GroqService groq;
  final CohereService cohere;
  final Logger _logger = Logger();

  // Per-provider runtime state
  DateTime? _groqCooldownUntil;
  DateTime? _cohereCooldownUntil;
  bool _groqKeyInvalid = false;
  bool _cohereKeyInvalid = false;
  String _lastUsedProvider = 'groq';

  SmartRouterService({required this.groq, required this.cohere});

  // ── Public status accessors (used by settings screen) ─────────────────────

  bool get groqKeyConfigured => groq.apiKey != null && groq.apiKey!.isNotEmpty;
  bool get cohereKeyConfigured => cohere.apiKey.isNotEmpty;

  bool get groqOnCooldown =>
      _groqCooldownUntil != null &&
      DateTime.now().isBefore(_groqCooldownUntil!);

  bool get cohereOnCooldown =>
      _cohereCooldownUntil != null &&
      DateTime.now().isBefore(_cohereCooldownUntil!);

  bool get groqReady => groqKeyConfigured && !_groqKeyInvalid && !groqOnCooldown;
  bool get cohereReady =>
      cohereKeyConfigured && !_cohereKeyInvalid && !cohereOnCooldown;

  Duration? get groqCooldownRemaining {
    if (!groqOnCooldown) return null;
    return _groqCooldownUntil!.difference(DateTime.now());
  }

  String get activeProvider => _lastUsedProvider;

  // Resets error/cooldown state after the user saves a new API key.
  void resetGroqState() {
    _groqKeyInvalid = false;
    _groqCooldownUntil = null;
    _logger.i('Router: Groq state reset');
  }

  void resetCohereState() {
    _cohereKeyInvalid = false;
    _cohereCooldownUntil = null;
    _logger.i('Router: Cohere state reset');
  }

  // ── AiServiceBase implementation ──────────────────────────────────────────

  @override
  Future<GrokResponse> processRequest(
    String userInput, {
    Map<String, String>? installedApps,
  }) async {
    final isComplex = _isComplexRequest(userInput);

    // Try Groq first
    if (groqReady) {
      groq.autoSelectModel(isComplex);
      _logger.i('Router → groq/${groq.currentModel}');
      final result =
          await groq.processRequest(userInput, installedApps: installedApps);
      if (result.success) {
        _lastUsedProvider = 'groq';
        return result;
      }
      _handleError('groq', result.error ?? '');

      if (!cohereReady) {
        // Surface Groq's error if Cohere can't help
        return _noFallbackError(result.error ?? 'Groq request failed');
      }
    }

    // Fallback to Cohere (has more quota than Groq)
    if (cohereReady) {
      cohere.autoSelectModel(isComplex);
      _logger.i('Router → cohere/${cohere.currentModel}');
      final result =
          await cohere.processRequest(userInput, installedApps: installedApps);
      if (result.success) {
        _lastUsedProvider = 'cohere';
        return result;
      }
      _handleError('cohere', result.error ?? '');
      return result;
    }

    // Both unavailable
    if (!groqKeyConfigured && !cohereKeyConfigured) {
      return GrokResponse.error(
          'No API keys configured. Open Settings to add your Groq or Cohere key.');
    }
    if (groqOnCooldown || cohereOnCooldown) {
      final wait = groqCooldownRemaining?.inSeconds ?? 30;
      return GrokResponse.error(
          'Rate limit reached. Retry in ~${wait}s. '
          'Adding a Cohere key reduces wait time (higher quota).');
    }
    return GrokResponse.error(
        'No AI provider available. Check API keys in Settings.');
  }

  @override
  Future<GrokResponse> planTask(
    String userInput, {
    Map<String, String>? installedApps,
  }) =>
      processRequest(userInput, installedApps: installedApps);

  @override
  Future<GrokResponse> executeCommand(String userInput) async {
    if (groqReady) {
      groq.autoSelectModel(false); // always fast model for quick commands
      return groq.executeCommand(userInput);
    }
    if (cohereReady) {
      cohere.autoSelectModel(false);
      return cohere.executeCommand(userInput);
    }
    return GrokResponse.error('No API provider available');
  }

  @override
  Future<List<String>> fetchModels() async => [];

  @override
  void setModel(String model) {} // no-op — models are auto-selected

  @override
  String get currentModel =>
      _lastUsedProvider == 'groq' ? groq.currentModel : cohere.currentModel;

  // ── Private helpers ───────────────────────────────────────────────────────

  void _handleError(String provider, String error) {
    final lower = error.toLowerCase();
    final isAuth = lower.contains('401') ||
        lower.contains('invalid api key') ||
        lower.contains('authentication') ||
        lower.contains('unauthorized') ||
        lower.contains('invalid_api_key');
    final isRateLimit = lower.contains('429') ||
        lower.contains('413') ||
        lower.contains('rate limit') ||
        lower.contains('too large') ||
        lower.contains('tpm') ||
        lower.contains('quota') ||
        lower.contains('exceeded');

    if (provider == 'groq') {
      if (isAuth) {
        _groqKeyInvalid = true;
        _logger.w('Router: Groq key invalid');
      } else if (isRateLimit) {
        _groqCooldownUntil = DateTime.now().add(const Duration(seconds: 65));
        _logger.w('Router: Groq on 65s cooldown (TPM window reset)');
      }
    } else {
      if (isAuth) {
        _cohereKeyInvalid = true;
        _logger.w('Router: Cohere key invalid');
      } else if (isRateLimit) {
        _cohereCooldownUntil = DateTime.now().add(const Duration(seconds: 30));
        _logger.w('Router: Cohere on 30s cooldown');
      }
    }
  }

  GrokResponse _noFallbackError(String providerError) {
    if (!groqKeyConfigured && !cohereKeyConfigured) {
      return GrokResponse.error(
          'No API keys configured. Open Settings to add your Groq or Cohere key.');
    }
    if (_groqKeyInvalid) {
      return GrokResponse.error(
          'Groq API key is invalid. Update it in Settings. '
          '(Add a Cohere key as fallback.)');
    }
    return GrokResponse.error(providerError);
  }

  // Complex = requests that produce large outputs (full source files,
  // multi-step plans with code). Simple = app launch, questions, small scripts.
  static bool _isComplexRequest(String task) {
    if (task.length > 120) return true;
    return RegExp(
      r'(create|write|build|generate|develop|make)\s+.{0,40}'
      r'(game|app|application|script|program|website|tool|widget|bot|server|api|dashboard|extension|class|function)',
      caseSensitive: false,
    ).hasMatch(task);
  }
}
