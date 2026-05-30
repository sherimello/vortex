import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show HardwareKeyboard, KeyDownEvent, KeyEvent, LogicalKeyboardKey;

class CommandInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSubmit;
  final VoidCallback onClose;
  final VoidCallback? onSettings;
  final bool isLoading;
  final FocusNode? focusNode;

  const CommandInput({
    super.key,
    required this.controller,
    required this.onSubmit,
    required this.onClose,
    this.onSettings,
    this.isLoading = false,
    this.focusNode,
  });

  @override
  State<CommandInput> createState() => _CommandInputState();
}

class _CommandInputState extends State<CommandInput> {
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  bool _handleKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onClose();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Colors.white;
    const hintColor = Color(0x61FFFFFF);
    const iconColor = Color(0x8CFFFFFF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: SizedBox(
        height: 22,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                enabled: !widget.isLoading,
                onSubmitted: (v) {
                  if (v.isNotEmpty) widget.onSubmit(v);
                },
                style: const TextStyle(color: textColor, fontSize: 14),
                cursorColor: Colors.blue,
                decoration: const InputDecoration(
                  hintText: 'What do you want to do?',
                  hintStyle: TextStyle(color: hintColor, fontSize: 14),
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 6),
            if (widget.isLoading)
              SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: Colors.blue.withValues(alpha: 0.85),
                ),
              )
            else ...[
              if (widget.onSettings != null)
                _btn(Icons.settings_outlined, widget.onSettings!, iconColor),
              _btn(Icons.close, widget.onClose, iconColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
