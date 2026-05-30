import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:logger/logger.dart';

class HotKeyService {
  final Logger _logger = Logger();
  final List<Function> _callbacks = [];

  Future<void> initialize() async {
    try {
      await hotKeyManager.unregisterAll();
      _logger.i('Hotkey service initialized');
    } catch (e) {
      _logger.e('Error initializing hotkey service: $e');
    }
  }

  Future<void> registerHotkey(
      {required String hotkey, required Function onTriggered}) async {
    try {
      final HotKey hk = HotKey(
        key: PhysicalKeyboardKey.keyQ,
        modifiers: [HotKeyModifier.control],
        scope: HotKeyScope.system,
      );

      await hotKeyManager.register(
        hk,
        keyDownHandler: (_) {
          _logger.i('Ctrl+Q pressed');
          onTriggered();
        },
      );

      _callbacks.add(onTriggered);
      _logger.i('Hotkey registered: $hotkey');
    } catch (e) {
      _logger.e('Error registering hotkey: $e');
    }
  }

  Future<void> unregisterAllHotkeys() async {
    try {
      await hotKeyManager.unregisterAll();
      _callbacks.clear();
      _logger.i('All hotkeys unregistered');
    } catch (e) {
      _logger.e('Error unregistering hotkeys: $e');
    }
  }
}
