import 'package:flutter/material.dart';
import '../services/agent_service.dart';

class AgentResultView extends StatefulWidget {
  final List<AgentEvent> events;
  final String taskInput;
  final bool isProcessing;
  final VoidCallback onClose;

  const AgentResultView({
    super.key,
    required this.events,
    required this.taskInput,
    required this.isProcessing,
    required this.onClose,
  });

  @override
  State<AgentResultView> createState() => _AgentResultViewState();
}

class _AgentResultViewState extends State<AgentResultView> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(AgentResultView old) {
    super.didUpdateWidget(old);
    if (old.events.length != widget.events.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // ── Colors ─────────────────────────────────────────────────────────────────

  static const _subSurface = Color(0xFF0A0A0A);
  static const _subBorder  = Color(0xFF1A1A1A);
  static const _codeBg     = Color(0xFF0A0A0A);
  static const _codeBorder = Color(0xFF2A2A2A);
  static const _codeText   = Color(0xFF79C0FF);
  static const _codeInlineBg = Color(0x1A79C0FF);
  static const _textPrimary   = Color(0xE0FFFFFF);
  static const _textSecondary = Colors.white60;
  static const _textMuted     = Colors.white30;
  Color _successColor(bool isError) =>
      isError ? Colors.redAccent : Colors.greenAccent.withValues(alpha: 0.85);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _header(),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: widget.events.length,
              itemBuilder: (_, i) => _eventRow(widget.events[i]),
            ),
          ),
          if (!widget.isProcessing) _footer(),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          if (widget.isProcessing)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.blue,
                ),
              ),
            ),
          Expanded(
            child: Text(
              widget.taskInput,
              style: const TextStyle(color: _textSecondary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: widget.onClose,
            child: const Icon(Icons.close, size: 16, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _eventRow(AgentEvent event) {
    if (event.type == AgentEventType.chatAnswer) {
      return _chatAnswerBlock(event.message);
    }
    if (event.type == AgentEventType.planning &&
        widget.events.any((e) => e.type == AgentEventType.chatAnswer)) {
      return const SizedBox.shrink();
    }

    final (icon, color) = _iconAndColor(event.type);
    final isStep = event.stepIndex != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isStep)
                      Text(
                        '${event.stepIndex}/${event.totalSteps}  ',
                        style: const TextStyle(color: _textMuted, fontSize: 11),
                      ),
                    Expanded(
                      child: Text(
                        event.message,
                        style: TextStyle(color: color, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
                if (event.output != null && event.output!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _codeBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _codeBorder),
                    ),
                    child: SelectableText(
                      event.output!,
                      style: TextStyle(
                        color: _successColor(
                          event.type == AgentEventType.stepFailed ||
                              event.type == AgentEventType.taskFailed,
                        ),
                        fontSize: 11,
                        fontFamily: 'Courier New',
                        height: 1.45,
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

  Widget _chatAnswerBlock(String text) {
    final segments = _splitCodeFences(text);
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _subSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _subBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...segments.expand<Widget>((seg) {
            if (seg.isCode) return [_chatCodeBlock(seg.text)];
            return seg.text.split('\n').map(_markdownLine);
          }),
        ],
      ),
    );
  }

  Widget _chatCodeBlock(String code) => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _codeBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _codeBorder),
        ),
        child: SelectableText(
          code,
          style: const TextStyle(
            color: _codeText,
            fontSize: 11.5,
            fontFamily: 'Courier New',
            height: 1.5,
          ),
        ),
      );

  Widget _markdownLine(String line) {
    if (line.startsWith('### ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 2),
        child: _inlineText(line.substring(4), bold: true, size: 13.5),
      );
    }
    if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 3),
        child: _inlineText(line.substring(3), bold: true, size: 14.5),
      );
    }
    if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 4),
        child: _inlineText(line.substring(2), bold: true, size: 15.5),
      );
    }
    if (line.startsWith('- ') || line.startsWith('* ')) {
      return Padding(
        padding: const EdgeInsets.only(left: 10, top: 3, bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 7, right: 8),
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0x80448AFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Expanded(child: _inlineText(line.substring(2))),
          ],
        ),
      );
    }
    final numMatch = RegExp(r'^(\d+)\.\s+(.+)').firstMatch(line);
    if (numMatch != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 10, top: 3, bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${numMatch.group(1)}.  ',
              style: const TextStyle(
                  color: Color(0x80448AFF), fontSize: 13, height: 1.55),
            ),
            Expanded(child: _inlineText(numMatch.group(2)!)),
          ],
        ),
      );
    }
    if (line.isEmpty) return const SizedBox(height: 5);
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: _inlineText(line),
    );
  }

  Widget _inlineText(String text, {bool bold = false, double size = 13.0}) {
    const baseColor = _textPrimary;
    final baseStyle = TextStyle(
      color: baseColor,
      fontSize: size,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      height: 1.6,
    );
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*|`([^`]+)`');
    int cursor = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start)));
      }
      if (m.group(1) != null) {
        spans.add(TextSpan(
          text: m.group(1),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ));
      } else if (m.group(2) != null) {
        spans.add(TextSpan(
          text: ' ${m.group(2)} ',
          style: const TextStyle(
            fontFamily: 'Courier New',
            fontSize: 11.5,
            color: _codeText,
            backgroundColor: _codeInlineBg,
          ),
        ));
      }
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }

  List<_TextSegment> _splitCodeFences(String text) {
    final result = <_TextSegment>[];
    final pattern = RegExp(r'```[a-z]*\n?([\s\S]*?)```', multiLine: true);
    int cursor = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > cursor) {
        final prose = text.substring(cursor, m.start).trim();
        if (prose.isNotEmpty) result.add(_TextSegment(prose, isCode: false));
      }
      final code = m.group(1)?.trim() ?? '';
      if (code.isNotEmpty) result.add(_TextSegment(code, isCode: true));
      cursor = m.end;
    }
    if (cursor < text.length) {
      final tail = text.substring(cursor).trim();
      if (tail.isNotEmpty) result.add(_TextSegment(tail, isCode: false));
    }
    return result.isEmpty ? [_TextSegment(text, isCode: false)] : result;
  }

  (IconData, Color) _iconAndColor(AgentEventType t) => switch (t) {
        AgentEventType.planning =>
          (Icons.psychology_outlined, Colors.blueAccent),
        AgentEventType.stepStarted =>
          (Icons.play_circle_outline, const Color(0xFFFB923C)),
        AgentEventType.stepWaiting =>
          (Icons.timer_outlined, const Color(0xFFFACC15)),
        AgentEventType.stepCompleted =>
          (Icons.check_circle_outline, Colors.greenAccent),
        AgentEventType.stepFailed =>
          (Icons.error_outline, Colors.redAccent),
        AgentEventType.taskCompleted =>
          (Icons.done_all, Colors.greenAccent),
        AgentEventType.taskFailed =>
          (Icons.cancel_outlined, Colors.redAccent),
        AgentEventType.chatAnswer =>
          (Icons.chat_bubble_outline, Colors.white70),
      };

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: widget.onClose,
            style: TextButton.styleFrom(
              foregroundColor: _textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _TextSegment {
  final String text;
  final bool isCode;
  const _TextSegment(this.text, {required this.isCode});
}
