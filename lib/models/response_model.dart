class GrokResponse {
  final String content;
  final bool success;
  final String? error;
  final DateTime timestamp;

  GrokResponse({
    required this.content,
    required this.success,
    this.error,
    required this.timestamp,
  });

  factory GrokResponse.fromJson(Map<String, dynamic> json) {
    return GrokResponse(
      content: json['content'] ?? '',
      success: true,
      error: null,
      timestamp: DateTime.now(),
    );
  }

  factory GrokResponse.error(String message) {
    return GrokResponse(
      content: '',
      success: false,
      error: message,
      timestamp: DateTime.now(),
    );
  }
}

class CommandExecution {
  final String command;
  final String output;
  final String? error;
  final int exitCode;
  final DateTime executedAt;

  CommandExecution({
    required this.command,
    required this.output,
    this.error,
    required this.exitCode,
    required this.executedAt,
  });
}
