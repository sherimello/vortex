import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:win32/win32.dart';
import '../services/service_locator.dart';
import '../services/smart_router_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _groqKeyController;
  late TextEditingController _cohereKeyController;
  late ServiceLocator _services;

  bool _autoStart = true;
  bool _groqKeyVisible = false;
  bool _cohereKeyVisible = false;
  bool _testingConnection = false;

  static const _kBg = Colors.black;
  static const _kSurface = Color(0xFF111111);
  static const _kBorder = Color(0xFF2A2A2A);
  static const _kTitle = Colors.blue;
  static const _kText = Colors.white;
  static const _kTextSec = Colors.white70;
  static const _kTextMuted = Colors.white38;

  @override
  void initState() {
    super.initState();
    _services = ServiceLocator();
    _groqKeyController = TextEditingController();
    _cohereKeyController = TextEditingController();
    _loadSettings();
  }

  void _loadSettings() {
    _groqKeyController.text = _services.storageService.getApiKey() ?? '';
    _cohereKeyController.text =
        _services.storageService.getCohereApiKey() ?? '';
    _autoStart = _services.storageService.getAutoStart();
    setState(() {});
  }

  @override
  void dispose() {
    _groqKeyController.dispose();
    _cohereKeyController.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: error ? Colors.red.shade700 : const Color(0xFF1C2333),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = _services.smartRouter;

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(31),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(31),
        child: Scaffold(
          backgroundColor: _kBg,
          primary: false,
          appBar: AppBar(
            backgroundColor: _kSurface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              color: _kTextSec,
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Settings',
              style: TextStyle(
                color: _kText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: _kBorder),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _routingStatusBar(router),
                const SizedBox(height: 20),

                _sectionLabel('Groq API Key'),
                const SizedBox(height: 10),
                _card(
                  child: _apiKeyContent(
                    controller: _groqKeyController,
                    visible: _groqKeyVisible,
                    onToggle: () =>
                        setState(() => _groqKeyVisible = !_groqKeyVisible),
                    hint: 'gsk_...',
                    label: 'Groq (preferred — fast free tier)',
                    url: 'https://console.groq.com/keys',
                    steps: const [
                      'Go to console.groq.com and sign in (or create a free account).',
                      'In the left sidebar click "API Keys".',
                      'Click "Create API Key", give it a name, copy the key.',
                      'Paste it above — keys start with gsk_',
                    ],
                    statusWidget: _providerStatusDot(
                      ready: router.groqReady,
                      configured: router.groqKeyConfigured,
                      onCooldown: router.groqOnCooldown,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _sectionLabel('Cohere API Key'),
                const SizedBox(height: 10),
                _card(
                  child: _apiKeyContent(
                    controller: _cohereKeyController,
                    visible: _cohereKeyVisible,
                    onToggle: () =>
                        setState(() => _cohereKeyVisible = !_cohereKeyVisible),
                    hint: 'Enter your Cohere API key',
                    label: 'Cohere (fallback — higher quota)',
                    url: 'https://dashboard.cohere.com/api-keys',
                    steps: const [
                      'Go to dashboard.cohere.com and sign in (or create a free account).',
                      'Click "API Keys" in the left sidebar.',
                      'Click "New Trial Key" (free) or "New Production Key".',
                      'Copy the key and paste it above.',
                    ],
                    statusWidget: _providerStatusDot(
                      ready: router.cohereReady,
                      configured: router.cohereKeyConfigured,
                      onCooldown: router.cohereOnCooldown,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _sectionLabel('Application'),
                const SizedBox(height: 10),
                _card(child: _autoStartContent()),
                const SizedBox(height: 20),

                _sectionLabel('Actions'),
                const SizedBox(height: 10),
                _actionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Routing status bar ───────────────────────────────────────────────────

  Widget _routingStatusBar(SmartRouterService router) {
    final groqOk = router.groqReady;
    final cohereOk = router.cohereReady;
    final groqCooldown = router.groqOnCooldown;
    final cohereCooldown = router.cohereOnCooldown;

    String label;
    Color color;
    IconData icon;

    if (!router.groqKeyConfigured && !router.cohereKeyConfigured) {
      label = 'No API keys configured';
      color = Colors.red.shade400;
      icon = Icons.error_outline;
    } else if (groqOk && cohereOk) {
      label = 'Groq preferred  •  Cohere fallback  •  Auto-routing active';
      color = const Color(0xFF30D158);
      icon = Icons.shuffle_rounded;
    } else if (groqOk) {
      label =
          'Groq active${cohereCooldown ? "  •  Cohere on cooldown" : "  •  Add Cohere key for fallback"}';
      color = Colors.blue;
      icon = Icons.bolt_rounded;
    } else if (cohereOk) {
      label =
          'Cohere active${groqCooldown ? "  •  Groq on cooldown" : "  •  Add Groq key for primary"}';
      color = Colors.orange;
      icon = Icons.bolt_rounded;
    } else {
      label = 'Both providers unavailable — check keys';
      color = Colors.red.shade400;
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _providerStatusDot({
    required bool ready,
    required bool configured,
    required bool onCooldown,
  }) {
    if (!configured) return const SizedBox.shrink();
    final color = onCooldown
        ? Colors.orange
        : ready
        ? const Color(0xFF30D158)
        : Colors.red.shade400;
    final tip = onCooldown
        ? 'Cooldown'
        : ready
        ? 'Ready'
        : 'Invalid key';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          tip,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Shared widgets ───────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: _kTitle,
      letterSpacing: 0.6,
    ),
  );

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _kSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kBorder),
    ),
    child: child,
  );

  Widget _apiKeyContent({
    required TextEditingController controller,
    required bool visible,
    required VoidCallback onToggle,
    required String hint,
    required String label,
    required String url,
    required List<String> steps,
    Widget? statusWidget,
  }) {
    const infoAccent = Color(0xFF90CAF9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kTextSec,
                ),
              ),
            ),
            ?statusWidget,
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: !visible,
          style: TextStyle(color: _kText, fontSize: 13),
          cursorColor: Colors.blue,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _kTextMuted, fontSize: 13),
            filled: true,
            fillColor: _kBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                visible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: _kTextMuted,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: infoAccent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: infoAccent.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 13, color: infoAccent),
                  const SizedBox(width: 6),
                  Text(
                    'How to get your API key',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: infoAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...steps.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.key + 1}.  ',
                        style: TextStyle(fontSize: 11.5, color: _kTextMuted),
                      ),
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _kTextSec,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                ),
                child: Row(
                  children: [
                    Icon(Icons.open_in_new, size: 12, color: infoAccent),
                    const SizedBox(width: 5),
                    Text(
                      url,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: infoAccent,
                        decoration: TextDecoration.underline,
                        decorationColor: infoAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _autoStartContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Auto Start',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kTextSec,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Launch on system startup',
              style: TextStyle(fontSize: 12, color: _kTextMuted),
            ),
          ],
        ),
        Switch(
          value: _autoStart,
          onChanged: (v) async {
            setState(() => _autoStart = v);
            await _services.storageService.setAutoStart(v);
            await ServiceLocator.applyAutoStart(v);
          },
          activeThumbColor: Colors.blue,
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? Colors.blue.withValues(alpha: 0.35)
                : _kBorder,
          ),
        ),
      ],
    );
  }

  Widget _actionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _actionBtn(
          label: 'Save Settings',
          icon: Icons.save_outlined,
          color: Colors.blue,
          onPressed: _saveSettings,
        ),
        const SizedBox(height: 8),
        _actionBtn(
          label: 'Test Connection',
          icon: Icons.network_check_outlined,
          color: const Color(0xFF30D158),
          onPressed: _testingConnection ? null : _testConnection,
        ),
        const SizedBox(height: 8),
        _actionBtn(
          label: 'About Vortex Agent',
          icon: Icons.info_outline,
          color: _kTextMuted,
          onPressed: _showAbout,
        ),
      ],
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    final effectiveColor = onPressed == null
        ? color.withValues(alpha: 0.4)
        : color;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: effectiveColor),
      label: Text(label, style: TextStyle(color: effectiveColor, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(
          color: color.withValues(alpha: onPressed == null ? 0.15 : 0.35),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: color.withValues(
          alpha: onPressed == null ? 0.02 : 0.06,
        ),
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  void _saveSettings() {
    bool savedAny = false;

    if (_groqKeyController.text.isNotEmpty) {
      _services.storageService.setApiKey(_groqKeyController.text);
      _services.grokService.setApiKey(_groqKeyController.text);
      _services.smartRouter.resetGroqState();
      savedAny = true;
    }

    if (_cohereKeyController.text.isNotEmpty) {
      _services.storageService.setCohereApiKey(_cohereKeyController.text);
      _services.cohereService.setApiKey(_cohereKeyController.text);
      _services.smartRouter.resetCohereState();
      savedAny = true;
    }

    if (!savedAny) {
      _snack('Enter at least one API key', error: true);
      return;
    }

    setState(() {});
    _snack('Settings saved');
  }

  Future<void> _testConnection() async {
    final groqKey = _groqKeyController.text.trim();
    final cohereKey = _cohereKeyController.text.trim();

    if (groqKey.isEmpty && cohereKey.isEmpty) {
      _snack('Enter at least one API key first', error: true);
      return;
    }

    setState(() => _testingConnection = true);

    if (groqKey.isNotEmpty) {
      _services.grokService.setApiKey(groqKey);
      _snack('Testing Groq…');
      final r = await _services.grokService.executeCommand(
        'Say OK in one word',
      );
      if (!mounted) return;
      _snack(
        r.success ? '✓ Groq connected' : '✗ Groq: ${r.error}',
        error: !r.success,
      );
      await Future.delayed(const Duration(milliseconds: 800));
    }

    if (cohereKey.isNotEmpty && mounted) {
      _services.cohereService.setApiKey(cohereKey);
      _snack('Testing Cohere…');
      final r = await _services.cohereService.executeCommand(
        'Say OK in one word',
      );
      if (!mounted) return;
      _snack(
        r.success ? '✓ Cohere connected' : '✗ Cohere: ${r.error}',
        error: !r.success,
      );
    }

    if (mounted) setState(() => _testingConnection = false);
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: _kBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vortex Agent',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _kText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'v1.0.0',
                style: TextStyle(fontSize: 12, color: _kTextMuted),
              ),
              const SizedBox(height: 16),
              Text(
                'AI-powered Windows automation. Describe any task in plain English — Vortex breaks it into steps and executes them.',
                style: TextStyle(fontSize: 13, color: _kTextSec, height: 1.5),
              ),
              const SizedBox(height: 16),
              _aboutRow(
                Icons.keyboard_outlined,
                'Ctrl+Q — toggle command palette',
              ),
              _aboutRow(Icons.keyboard_return_outlined, 'Enter — execute task'),
              _aboutRow(
                Icons.settings_outlined,
                'Settings icon — open this screen',
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close', style: TextStyle(color: _kTitle)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aboutRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 14, color: _kTextMuted),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(fontSize: 12, color: _kTextSec)),
      ],
    ),
  );
}
