import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:window_manager/window_manager.dart';
import 'services/service_locator.dart';
import 'services/agent_service.dart';
import 'screens/settings_screen.dart';
import 'widgets/prompt_input.dart' show CommandInput;
import 'widgets/screen_glow.dart';
import 'widgets/agent_result_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(650, 90),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.hide();
  });

  final services = ServiceLocator();
  await services.initialize();

  runApp(const VortexAgentApp());
}

class VortexAgentApp extends StatelessWidget {
  const VortexAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Vortex Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
          surface: Colors.black,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WindowListener {
  // Adaptive window sizes based on physical screen dimensions.
  Size get _screenSize {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return view.physicalSize / view.devicePixelRatio;
  }

  Size get _inputSize => Size(
        (_screenSize.width * 0.38).clamp(520.0, 700.0),
        62,
      );

  Size get _resultSize => Size(
        (_screenSize.width * 0.46).clamp(620.0, 820.0),
        (_screenSize.height * 0.60).clamp(460.0, 640.0),
      );

  Size get _settingsSize => Size(
        (_screenSize.width * 0.38).clamp(520.0, 700.0),
        (_screenSize.height * 0.72).clamp(580.0, 800.0),
      );

  late ServiceLocator _services;
  late AgentService _agentService;
  late TextEditingController _inputController;
  late FocusNode _inputFocusNode;
  final Logger _logger = Logger();

  bool _visible = false;
  bool _isProcessing = false;
  bool _isFullScreen = false;
  bool _settingsOpen = false;
  List<AgentEvent> _events = [];
  String _taskInput = '';

  @override
  void initState() {
    super.initState();
    _services = ServiceLocator();
    _agentService = AgentService(
      aiService: _services.activeAiService,
      fileService: _services.fileService,
      appDiscoveryService: _services.appDiscoveryService,
    );
    _inputController = TextEditingController();
    _inputFocusNode = FocusNode();
    windowManager.addListener(this);
    _setupWindowProperties();
    _setupHotkey();
  }

  Future<void> _setupWindowProperties() async {
    await windowManager.setPreventClose(true);
  }

  void _setupHotkey() {
    _services.hotKeyService.registerHotkey(
      hotkey: 'Ctrl+Q',
      onTriggered: _togglePalette,
    );
  }

  void _togglePalette() {
    if (_visible && !_isProcessing) {
      _hide();
    } else if (!_visible) {
      _showPalette();
    }
  }

  Future<void> _showPalette() async {
    await _services.hotKeyService.unregisterAllHotkeys();
    await windowManager.setSize(_inputSize);
    await windowManager.center();
    await windowManager.show();
    await windowManager.focus();
    setState(() {
      _visible = true;
      _events = [];
      _inputController.clear();
    });
    _inputFocusNode.requestFocus();
  }

  Future<void> _hide() async {
    if (_settingsOpen) {
      Get.back();
    }
    if (_isFullScreen) {
      await windowManager.setIgnoreMouseEvents(false);
      await windowManager.setFullScreen(false);
    }
    await windowManager.hide();
    setState(() {
      _visible = false;
      _isProcessing = false;
      _isFullScreen = false;
      _events = [];
    });
    _setupHotkey();
  }

  Future<void> _executeTask(String task) async {
    if (task.isEmpty) return;

    _agentService = AgentService(
      aiService: _services.activeAiService,
      fileService: _services.fileService,
      appDiscoveryService: _services.appDiscoveryService,
    );

    setState(() {
      _isProcessing = true;
      _isFullScreen = true;
      _taskInput = task;
      _events = [];
    });

    await windowManager.setFullScreen(true);
    await windowManager.setIgnoreMouseEvents(true);

    _agentService.executeTask(task).listen(
      (event) {
        setState(() {
          _events.add(event);
          if (event.type == AgentEventType.taskCompleted ||
              event.type == AgentEventType.taskFailed ||
              event.type == AgentEventType.chatAnswer) {
            _isProcessing = false;
          }
        });
        if (event.type == AgentEventType.taskCompleted ||
            event.type == AgentEventType.taskFailed ||
            event.type == AgentEventType.chatAnswer) {
          _collapseFromFullScreen();
        }
      },
      onError: (e) {
        _logger.e('Agent error: $e');
        setState(() {
          _isProcessing = false;
          _events.add(
            AgentEvent(type: AgentEventType.taskFailed, message: '$e'),
          );
        });
        _collapseFromFullScreen();
      },
    );
  }

  Future<void> _collapseFromFullScreen() async {
    await windowManager.setIgnoreMouseEvents(false);
    await windowManager.setFullScreen(false);
    await windowManager.setSize(_resultSize);
    await windowManager.center();
    if (mounted) setState(() => _isFullScreen = false);
  }

  void _openSettings() async {
    await windowManager.setSize(_settingsSize);
    await windowManager.center();
    _settingsOpen = true;
    await Get.to(() => const SettingsScreen());
    _settingsOpen = false;
    if (_visible) {
      await windowManager.setSize(_inputSize);
      await windowManager.center();
    }
  }

  @override
  void onWindowClose() async => _hide();

  @override
  void dispose() {
    windowManager.removeListener(this);
    _inputController.dispose();
    _inputFocusNode.dispose();
    _services.hotKeyService.unregisterAllHotkeys();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenGlow(
      isActive: _isProcessing,
      child: Material(
        color: Colors.transparent,
        child: _isFullScreen ? _fullScreenLayout() : _normalLayout(),
      ),
    );
  }

  Widget _normalLayout() {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) => windowManager.startDragging(),
          child: const SizedBox(height: 6, width: double.infinity),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CommandInput(
            controller: _inputController,
            focusNode: _inputFocusNode,
            onSubmit: _executeTask,
            onClose: _hide,
            onSettings: _openSettings,
            isLoading: _isProcessing,
          ),
        ),
        if (_events.isNotEmpty)
          Expanded(
            child: AgentResultView(
              events: _events,
              taskInput: _taskInput,
              isProcessing: _isProcessing,
              onClose: () async {
                setState(() => _events = []);
                await windowManager.setSize(_inputSize);
                await windowManager.center();
              },
            ),
          ),
      ],
    );
  }

  Widget _fullScreenLayout() {
    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) => windowManager.startDragging(),
          child: const SizedBox(height: 6, width: double.infinity),
        ),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: (MediaQuery.of(context).size.width * 0.55).clamp(600.0, 820.0),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CommandInput(
                    controller: _inputController,
                    onSubmit: _executeTask,
                    onClose: _hide,
                    onSettings: _openSettings,
                    isLoading: _isProcessing,
                  ),
                  if (_events.isNotEmpty)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: (MediaQuery.of(context).size.height * 0.62).clamp(420.0, 620.0),
                      ),
                      child: AgentResultView(
                        events: _events,
                        taskInput: _taskInput,
                        isProcessing: _isProcessing,
                        onClose: () async {
                          setState(() => _events = []);
                          await windowManager.setSize(_inputSize);
                          await windowManager.center();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
