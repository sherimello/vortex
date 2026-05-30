import '../models/response_model.dart';

abstract class AiServiceBase {
  Future<List<String>> fetchModels();
  void setModel(String model);
  String get currentModel;
  Future<GrokResponse> planTask(String userInput, {Map<String, String>? installedApps});
  Future<GrokResponse> executeCommand(String userInput);

  /// Single-call entry point: classifies the input as a question or a task
  /// and returns either an "ANSWER\n..." response or a STEP-format plan.
  Future<GrokResponse> processRequest(String userInput,
      {Map<String, String>? installedApps});
}
