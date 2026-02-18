import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/bot_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  bool _isTestingConnection = false;
  bool? _lastTestResult;

  @override
  void initState() {
    super.initState();
    final prov = context.read<BotProvider>();
    _urlController = TextEditingController(text: prov.serverUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BotProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Connection section ──────────────────────────────────────────
          _SectionTitle(icon: Icons.wifi_rounded, title: 'API Server Connection'),
          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status row
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: prov.isConnecting
                              ? Colors.orange
                              : prov.isConnected
                                  ? Colors.green
                                  : cs.error,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        prov.isConnecting
                            ? 'Connecting…'
                            : prov.isConnected
                                ? 'Connected to API server'
                                : 'Not connected',
                        style: TextStyle(
                          color: prov.isConnecting
                              ? Colors.orange
                              : prov.isConnected
                                  ? Colors.green
                                  : cs.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // URL input
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'http://localhost:5000',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.link_rounded),
                      helperText:
                          'For desktop: http://localhost:5000\n'
                          'For Android on same Wi-Fi: http://192.168.x.x:5000',
                      helperMaxLines: 2,
                    ),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                  ),
                  const SizedBox(height: 14),

                  // Buttons row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: _isTestingConnection
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.wifi_find_rounded),
                          label: Text(_isTestingConnection
                              ? 'Testing…'
                              : 'Test Connection'),
                          onPressed:
                              _isTestingConnection ? null : _testConnection,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Save & Connect'),
                          onPressed: _save,
                        ),
                      ),
                    ],
                  ),

                  // Test result
                  if (_lastTestResult != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _lastTestResult!
                            ? Colors.green.shade50
                            : cs.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _lastTestResult!
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: _lastTestResult!
                                ? Colors.green.shade700
                                : cs.error,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _lastTestResult!
                                ? 'Server is reachable!'
                                : 'Cannot reach server. Is it running?',
                            style: TextStyle(
                              color: _lastTestResult!
                                  ? Colors.green.shade700
                                  : cs.onErrorContainer,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 24),

          // ── How to start server ────────────────────────────────────────
          _SectionTitle(
              icon: Icons.terminal_rounded, title: 'Starting the API Server'),
          const SizedBox(height: 10),

          Card(
            color: cs.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InstructionRow(
                    number: 1,
                    text: 'Open a terminal in the project folder:',
                    code: 'cd path/to/Whatsapp-Automator-main',
                  ),
                  _InstructionRow(
                    number: 2,
                    text: 'Install Python dependencies (first time only):',
                    code:
                        'pip install flask flask-cors colorama selenium webdriver-manager',
                  ),
                  _InstructionRow(
                    number: 3,
                    text: 'Start the API server:',
                    code: 'python api_server.py',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '💡 On Windows: double-click start_server.bat',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          // ── Android connection help ────────────────────────────────────
          _SectionTitle(
              icon: Icons.phone_android_rounded,
              title: 'Connecting from Android'),
          const SizedBox(height: 10),

          Card(
            color: cs.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To use the app from an Android device, both the phone and PC must be on the same Wi-Fi network.',
                    style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 12),
                  _InstructionRow(
                    number: 1,
                    text: 'Find your PC\'s local IP address:',
                    code: 'ipconfig  (Windows)',
                  ),
                  _InstructionRow(
                    number: 2,
                    text:
                        'Set the server URL in this app to your PC\'s IP:',
                    code: 'http://192.168.1.X:5000',
                  ),
                  _InstructionRow(
                    number: 3,
                    text: 'Allow firewall access on port 5000 (Windows):',
                    code:
                        'netsh advfirewall firewall add rule name="Flask API" dir=in action=allow protocol=TCP localport=5000',
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 24),

          // ── About section ─────────────────────────────────────────────
          _SectionTitle(icon: Icons.info_rounded, title: 'About'),
          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _AboutRow(
                      label: 'App', value: 'WhatsApp Automator UI'),
                  _AboutRow(label: 'Version', value: '1.0.0'),
                  _AboutRow(
                      label: 'Platform', value: 'Flutter (Android & Windows)'),
                  _AboutRow(
                      label: 'Backend',
                      value: 'Python + Flask + Selenium'),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _lastTestResult = null;
    });
    // Temporarily update API service URL for testing
    final prov = context.read<BotProvider>();
    final url = _urlController.text.trim().replaceAll(RegExp(r'/$'), '');
    // Create temp service
    final tempUrl = url.isEmpty ? prov.serverUrl : url;
    // Save temporarily and test
    await prov.setServerUrl(tempUrl);
    final ok = prov.isConnected;
    setState(() {
      _isTestingConnection = false;
      _lastTestResult = ok;
    });
  }

  Future<void> _save() async {
    final url = _urlController.text.trim().replaceAll(RegExp(r'/$'), '');
    if (url.isEmpty) return;
    await context.read<BotProvider>().setServerUrl(url);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<BotProvider>().isConnected
              ? '✅ Connected to $url'
              : '❌ Could not connect to $url'),
          backgroundColor: context.read<BotProvider>().isConnected
              ? Colors.green
              : Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

// ─── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 6),
        Text(title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold, color: cs.primary)),
      ],
    );
  }
}

// ─── Instruction row ──────────────────────────────────────────────────────────

class _InstructionRow extends StatelessWidget {
  final int number;
  final String text;
  final String code;
  const _InstructionRow(
      {required this.number, required this.text, required this.code});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: cs.primaryContainer,
                child: Text('$number',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text,
                    style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withOpacity(0.8))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Text(
                code,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── About row ────────────────────────────────────────────────────────────────

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: cs.onSurface.withOpacity(0.6), fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
