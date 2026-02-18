import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/bot_provider.dart';
import '../services/python_service.dart';
import 'home_screen.dart';

/// Shown on startup while the Python Flask server is launching.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'Initializing…';
  bool _failed = false;
  final List<String> _log = [];

  late final PythonService _pythonService;

  @override
  void initState() {
    super.initState();

    // Resolve paths relative to the executable
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    // When running `flutter run`, the exe is inside build/windows/x64/runner/Debug/
    // The project root is 5 levels up. We try multiple candidate paths.
    final candidates = [
      // Running as built Windows app (release/debug build)
      _resolve(exeDir, '../../../../../'),
      // Running via flutter run from project dir
      Directory.current.path,
      // One level up from current dir (if CWD is whatsapp_automator_ui/)
      _resolve(Directory.current.path, '../'),
    ];

    String workingDir = Directory.current.path;
    String scriptPath = 'api_server.py';

    for (final candidate in candidates) {
      final f = File('$candidate/api_server.py');
      if (f.existsSync()) {
        workingDir = candidate;
        scriptPath = 'api_server.py';
        break;
      }
    }

    _pythonService = PythonService(
      serverScript: scriptPath,
      workingDir: workingDir,
    );

    _startServer(workingDir);
  }

  String _resolve(String base, String relative) {
    return Uri.directory(base).resolve(relative).toFilePath();
  }

  Future<void> _startServer(String workingDir) async {
    _addLog('Working directory: $workingDir');
    _setStatus('Starting Python API server…');

    final ok = await _pythonService.start(
      onStdout: (line) => _addLog(line.trim()),
      onStderr: (line) => _addLog('[ERR] ${line.trim()}'),
    );

    if (!mounted) return;

    if (ok) {
      _setStatus('Server ready! Loading app…');
      // Give the provider a moment to connect
      await context.read<BotProvider>().checkConnection();
      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        _failed = true;
        _status =
            'Could not start the Python server.\nMake sure Python is installed and api_server.py exists.';
      });
    }
  }

  void _setStatus(String msg) {
    if (mounted) setState(() => _status = msg);
  }

  void _addLog(String line) {
    if (line.isEmpty) return;
    if (mounted) setState(() => _log.add(line));
  }

  @override
  void dispose() {
    // Don't stop the server here — keep it alive for the app session.
    // PythonService is stored in main so it stays alive.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo ───────────────────────────────────────────────
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.message_rounded,
                    size: 52,
                    color: cs.onPrimaryContainer,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(end: 1.05, duration: 900.ms, curve: Curves.easeInOut),

                const SizedBox(height: 28),

                Text(
                  'WhatsApp Automator',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 8),

                Text(
                  'Bulk Message Sender',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurface.withOpacity(0.6)),
                ).animate().fadeIn(delay: 350.ms),

                const SizedBox(height: 40),

                // ── Status ─────────────────────────────────────────────
                if (!_failed) ...[
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                  ),
                ] else ...[
                  Icon(Icons.error_outline_rounded,
                      color: cs.error, size: 42),
                  const SizedBox(height: 12),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.error, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: () {
                      setState(() {
                        _failed = false;
                        _log.clear();
                        _status = 'Retrying…';
                      });
                      _startServer(_pythonService.workingDir);
                    },
                  ),
                ],

                // ── Log output ─────────────────────────────────────────
                if (_log.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: ListView.builder(
                      reverse: true,
                      itemCount: _log.length,
                      itemBuilder: (_, i) => Text(
                        _log[_log.length - 1 - i],
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
