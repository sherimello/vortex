import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/response_model.dart';
import 'ai_service_base.dart';
import 'agent_prompts.dart';

class CohereService extends AiServiceBase {
  static const String _baseUrl = 'https://api.cohere.com/v2';
  late Dio _dio;
  final Logger _logger = Logger();
  String _apiKey = '';
  String _model = 'command-r-plus';

  static const List<String> defaultModels = [
    'command-r-plus',
    'command-r-plus-08-2024',
    'command-r',
    'command-r-08-2024',
    'command-r7b-12-2024',
    'command',
    'command-light',
    'command-nightly',
  ];

  CohereService() {
    _dio = Dio();
  }

  void setApiKey(String key) {
    _apiKey = key;
    _dio.options.headers = {
      'Authorization': 'Bearer $key',
      'Content-Type': 'application/json',
    };
  }

  String get apiKey => _apiKey;

  @override
  void setModel(String model) => _model = model;

  void autoSelectModel(bool isComplex) {
    _model = isComplex ? 'command-r-plus' : 'command-r7b-12-2024';
  }

  @override
  String get currentModel => _model;

  @override
  Future<List<String>> fetchModels() async {
    if (_apiKey.isEmpty) return defaultModels;
    try {
      final response = await _dio.get(
        '$_baseUrl/models',
        options: Options(
          validateStatus: (status) => true,
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      if (response.statusCode == 200) {
        final models = response.data['models'] as List?;
        if (models != null && models.isNotEmpty) {
          final names = models
              .map((m) => m['name']?.toString() ?? '')
              .where((n) => n.isNotEmpty)
              .toList()
            ..sort();
          return names;
        }
      }
      _logger.w('Could not fetch Cohere models (${response.statusCode}), using defaults');
    } catch (e) {
      _logger.e('Error fetching Cohere models: $e');
    }
    return defaultModels;
  }

  @override
  Future<GrokResponse> planTask(String userInput,
      {Map<String, String>? installedApps}) async {
    if (_apiKey.isEmpty) return GrokResponse.error('Cohere API key not configured');

    String contextualInput = userInput;
    if (installedApps != null && installedApps.isNotEmpty) {
      final appLines =
          installedApps.entries.map((e) => '  • ${e.key}: ${e.value}').join('\n');
      contextualInput =
          'INSTALLED APPS ON THIS MACHINE (use these exact paths — do NOT use Find-App for these):\n$appLines\n\nUSER REQUEST: $userInput';
    }
    return _chat(AgentPrompts.agentSystemPrompt, contextualInput,
        temperature: 0.2, maxTokens: 4000);
  }

  @override
  Future<GrokResponse> processRequest(String userInput,
      {Map<String, String>? installedApps}) async {
    if (_apiKey.isEmpty) return GrokResponse.error('Cohere API key not configured');

    String contextualInput = userInput;
    if (installedApps != null && installedApps.isNotEmpty) {
      final appLines =
          installedApps.entries.map((e) => '  • ${e.key}: ${e.value}').join('\n');
      contextualInput =
          'INSTALLED APPS ON THIS MACHINE (use these exact paths — do NOT use Find-App for these):\n$appLines\n\nUSER REQUEST: $userInput';
    }

    return _chat(AgentPrompts.combinedSystemPrompt, contextualInput,
        temperature: 0.2, maxTokens: 4096);
  }

  @override
  Future<GrokResponse> executeCommand(String userInput) async {
    if (_apiKey.isEmpty) return GrokResponse.error('Cohere API key not configured');
    return _chat(AgentPrompts.commandSystemPrompt, userInput,
        temperature: 0.7, maxTokens: 1000);
  }

  // Sends a chat request and automatically continues if the model hits its
  // per-call output limit (finish_reason == MAX_TOKENS). Each continuation
  // replays the full conversation with the accumulated output as assistant
  // history, effectively multiplying the usable output by up to (1 + maxCont).
  Future<GrokResponse> _chat(
    String systemPrompt,
    String userInput, {
    double temperature = 0.7,
    int maxTokens = 4096,
    int maxContinuations = 3,
  }) async {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userInput},
    ];

    final buffer = StringBuffer();
    int round = 0;

    try {
      while (true) {
        final response = await _dio.post(
          '$_baseUrl/chat',
          data: {
            'model': _model,
            'messages': messages,
            'temperature': temperature,
            'max_tokens': maxTokens,
          },
          options: Options(
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 90),
            validateStatus: (status) => true,
          ),
        );

        if (response.statusCode != 200) {
          final apiError = response.data?['message'] ??
              response.data?.toString() ??
              'Unknown error';
          return GrokResponse.error('Cohere ${response.statusCode}: $apiError');
        }

        final contentList = response.data['message']?['content'] as List?;
        final chunk = contentList?.isNotEmpty == true
            ? contentList![0]['text']?.toString() ?? ''
            : '';
        buffer.write(chunk);

        final finishReason =
            response.data['finish_reason']?.toString().toUpperCase() ?? '';
        _logger.i(
            'Cohere round $round: ${chunk.length} chars, finish=$finishReason');

        // Stop if generation completed normally or we've hit the continuation cap
        if (finishReason != 'MAX_TOKENS' || round >= maxContinuations) break;

        // Append partial output as assistant turn, then ask to continue
        messages.add({'role': 'assistant', 'content': buffer.toString()});
        messages.add({
          'role': 'user',
          'content':
              'Continue exactly where you left off. Do not repeat anything.',
        });
        round++;
      }

      final full = buffer.toString();
      _logger.i(
          'Cohere total: ${full.length} chars over ${round + 1} call(s)');
      return GrokResponse(content: full, success: true, timestamp: DateTime.now());
    } on DioException catch (e) {
      final body = e.response?.data?['message'] ??
          e.response?.data?.toString() ??
          e.message;
      return GrokResponse.error('Cohere error: $body');
    } catch (e) {
      return GrokResponse.error('Unexpected error: $e');
    }
  }
}
