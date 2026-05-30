import 'package:logger/logger.dart';
import 'ai_service_base.dart';
import 'file_operation_service.dart';
import 'app_discovery_service.dart';

enum AgentEventType {
  planning,
  stepStarted,
  stepWaiting,
  stepCompleted,
  stepFailed,
  taskCompleted,
  taskFailed,
  chatAnswer,
}

class AgentEvent {
  final AgentEventType type;
  final String message;
  final String? output;
  final int? stepIndex;
  final int? totalSteps;

  const AgentEvent({
    required this.type,
    required this.message,
    this.output,
    this.stepIndex,
    this.totalSteps,
  });
}

class _Step {
  final int index;
  final String description;
  final String script;
  final int waitBeforeMs;

  const _Step({
    required this.index,
    required this.description,
    required this.script,
    required this.waitBeforeMs,
  });
}

class AgentService {
  final AiServiceBase aiService;
  final FileOperationService fileService;
  final AppDiscoveryService? appDiscoveryService;
  final Logger _logger = Logger();

  AgentService({
    required this.aiService,
    required this.fileService,
    this.appDiscoveryService,
  });

  Stream<AgentEvent> executeTask(String task) async* {
    yield const AgentEvent(
      type: AgentEventType.planning,
      message: 'Processing request...',
    );

    // Skip app-discovery scan for obvious questions — context is only
    // useful for TASK mode. When we do scan, filter to apps relevant to
    // the task so we don't dump hundreds of entries into the prompt.
    Map<String, String>? installedApps;
    if (appDiscoveryService != null && !_isLikelyQuestion(task)) {
      final all = await appDiscoveryService!.getInstalledApps();
      installedApps = _filterAppsForTask(task, all);
    }

    final response =
        await aiService.processRequest(task, installedApps: installedApps);
    if (!response.success) {
      yield AgentEvent(
        type: AgentEventType.taskFailed,
        message: response.error ?? 'Request failed',
      );
      return;
    }

    // Check if the model answered as a plain question (ANSWER prefix).
    final trimmed = response.content.trimLeft();
    if (trimmed.startsWith('ANSWER')) {
      final answer =
          trimmed.replaceFirst(RegExp(r'^ANSWER\s*\n?'), '').trim();
      yield AgentEvent(type: AgentEventType.chatAnswer, message: answer);
      return;
    }

    // Otherwise treat it as an automation plan.
    final steps = _parseSteps(response.content);
    if (steps.isEmpty) {
      // Model didn't use the ANSWER prefix but also produced no executable
      // steps — treat the raw text as a chat answer rather than an error.
      final content = response.content.trim();
      yield AgentEvent(
        type: content.isNotEmpty
            ? AgentEventType.chatAnswer
            : AgentEventType.taskFailed,
        message: content.isNotEmpty ? content : 'No response from AI.',
      );
      return;
    }

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];

      if (step.waitBeforeMs > 0) {
        yield AgentEvent(
          type: AgentEventType.stepWaiting,
          message:
              'Waiting ${(step.waitBeforeMs / 1000).toStringAsFixed(1)}s for previous step...',
          stepIndex: i + 1,
          totalSteps: steps.length,
        );
        await Future.delayed(Duration(milliseconds: step.waitBeforeMs));
      }

      yield AgentEvent(
        type: AgentEventType.stepStarted,
        message: step.description,
        stepIndex: i + 1,
        totalSteps: steps.length,
      );

      if (step.script.isEmpty) {
        yield AgentEvent(
          type: AgentEventType.stepCompleted,
          message: step.description,
          output: '(no command)',
          stepIndex: i + 1,
          totalSteps: steps.length,
        );
        continue;
      }

      try {
        final result = await fileService.executePowerShellScript(step.script);
        _logger.i('Step ${i + 1} exit=${result.exitCode} out=${result.output}');

        final stdOut = result.output.trim();
        final stdErr = result.error?.trim() ?? '';
        final displayOutput = [
          if (stdOut.isNotEmpty) stdOut,
          if (stdErr.isNotEmpty) '--- stderr ---\n$stdErr',
        ].join('\n');

        yield AgentEvent(
          type: result.exitCode == 0
              ? AgentEventType.stepCompleted
              : AgentEventType.stepFailed,
          message: step.description,
          output: displayOutput.isEmpty ? '(completed)' : displayOutput,
          stepIndex: i + 1,
          totalSteps: steps.length,
        );
      } catch (e) {
        _logger.e('Step ${i + 1} threw: $e');
        yield AgentEvent(
          type: AgentEventType.stepFailed,
          message: step.description,
          output: e.toString(),
          stepIndex: i + 1,
          totalSteps: steps.length,
        );
      }
    }

    yield const AgentEvent(
      type: AgentEventType.taskCompleted,
      message: 'All steps completed',
    );
  }

  // Parse the structured step format:
  //   STEP[N] wait=MS
  //   Description line
  //   ```powershell
  //   script
  //   ```
  List<_Step> _parseSteps(String response) {
    final pattern = RegExp(
      r'STEP\[(\d+)\]\s+wait=(\d+)\s*\n([^\n]+)\n```(?:powershell|ps1|bash|cmd|batch)?\s*\n([\s\S]*?)```',
      caseSensitive: false,
    );

    final matches = pattern.allMatches(response).toList();
    if (matches.isNotEmpty) {
      return matches.map((m) {
        return _Step(
          index: int.tryParse(m.group(1)!) ?? 0,
          waitBeforeMs: int.tryParse(m.group(2)!) ?? 0,
          description: m.group(3)!.trim(),
          script: m.group(4)!.trim(),
        );
      }).toList();
    }

    // Fallback: single code block = one step
    final single = RegExp(
      r'```(?:powershell|ps1|bash|cmd|batch)?\s*\n([\s\S]*?)```',
      caseSensitive: false,
    ).firstMatch(response);

    if (single != null) {
      final script = single.group(1)!.trim();
      if (script.isNotEmpty) {
        return [
          _Step(
            index: 1,
            description: 'Execute task',
            script: script,
            waitBeforeMs: 0,
          ),
        ];
      }
    }

    return [];
  }

  // Returns apps whose name shares a significant word with the task, plus PATH
  // dev tools only when the task explicitly names them.
  // Uses whole-word token matching (3+ char words) to avoid the false-positive
  // explosion of raw substring matching (e.g. app "R" matching any task with 'r').
  static Map<String, String>? _filterAppsForTask(
      String task, Map<String, String> all) {
    if (all.isEmpty) return null;

    // Tokenise: letter-starting words of 3+ chars (covers "chrome", "python", etc.)
    final wordRe = RegExp(r'\b[a-z][a-z0-9]{2,}\b');
    final taskTokens =
        wordRe.allMatches(task.toLowerCase()).map((m) => m.group(0)!).toSet();

    if (taskTokens.isEmpty) return null;

    const maxEntries = 10;
    final out = <String, String>{};
    for (final e in all.entries) {
      if (out.length >= maxEntries) break;
      final nameTokens = wordRe
          .allMatches(e.key.toLowerCase())
          .map((m) => m.group(0)!)
          .toSet();
      if (nameTokens.any(taskTokens.contains)) out[e.key] = e.value;
    }

    // Include PATH dev-tool executables only when the task names them directly.
    const pathTools = [
      'code', 'git', 'python', 'python3', 'node',
      'flutter', 'dart', 'dotnet',
    ];
    for (final k in pathTools) {
      if (out.length >= maxEntries) break;
      if (taskTokens.contains(k) && all.containsKey(k)) {
        out.putIfAbsent(k, () => all[k]!);
      }
    }

    return out.isEmpty ? null : out;
  }

  // Returns true for obvious knowledge questions so we can skip the slow
  // app-discovery scan — that context is only needed for TASK mode.
  static bool _isLikelyQuestion(String task) {
    final t = task.toLowerCase().trim();
    final questionStart = RegExp(
      r'^(what|why|how|when|where|who|which|is |are |can |does |do |did |was |were |explain |describe |tell me|compare |define |difference |hey |hi |hello |yo |sup |thanks|thank you)',
    );
    final taskWord = RegExp(
      r'(open |launch |close |create |make |run |start |install |delete |remove |move |copy |rename |download |send |play |stop |take a screenshot|type |click |search for)',
    );
    return questionStart.hasMatch(t) && !taskWord.hasMatch(t);
  }
}
