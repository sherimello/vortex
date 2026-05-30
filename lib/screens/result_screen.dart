import 'package:flutter/material.dart';

class ResultScreen extends StatefulWidget {
  final String commandInput;
  final String result;
  final String? error;
  final bool isLoading;
  final Function() onClose;

  const ResultScreen({
    super.key,
    required this.commandInput,
    required this.result,
    this.error,
    required this.isLoading,
    required this.onClose,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Auto scroll to bottom when result updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(ResultScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result != widget.result) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  static const _kBg = Colors.black;
  static const _kSurface = Color(0xFF111111);
  static const _kBorder = Color(0xFF2A2A2A);

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final w = (screen.width * 0.46).clamp(560.0, 820.0);
    final h = (screen.height * 0.60).clamp(440.0, 640.0);

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: const Border(
                bottom: BorderSide(color: Colors.white, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Command Execution Result',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Input: ${widget.commandInput}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: Colors.white70),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: widget.isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Processing your command...',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.error != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.5),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Error: ${widget.error}',
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontFamily: 'Courier',
                                ),
                              ),
                            ),
                          if (widget.error != null) const SizedBox(height: 16),
                          SelectableText(
                            widget.result.isEmpty ? 'No output' : widget.result,
                            style: TextStyle(
                              color: Colors.green[300],
                              fontSize: 13,
                              fontFamily: 'Courier',
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: _kSurface,
              border: Border(top: BorderSide(color: Colors.white, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: widget.onClose,
                  icon: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white60,
                  ),
                  label: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
