import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Manages the lifecycle of the Python Flask API server process.
/// On Windows Desktop the app auto-starts `python api_server.py`.
class PythonService {
  Process? _process;
  final String _serverScript;
  final String _workingDir;

  PythonService({
    required String serverScript,
    required String workingDir,
  })  : _serverScript = serverScript,
        _workingDir = workingDir;

  /// Public read-only access to the working directory (used by SplashScreen).
  String get workingDir => _workingDir;

  bool get isRunning => _process != null;

  /// Starts `python api_server.py` in the project root and waits until the
  /// Flask server is accepting connections.
  Future<bool> start({
    void Function(String line)? onStdout,
    void Function(String line)? onStderr,
  }) async {
    if (_process != null) return true;

    try {
      debugPrint('[PythonService] Starting server: python $_serverScript');
      debugPrint('[PythonService] Working dir  : $_workingDir');

      _process = await Process.start(
        'python',
        [_serverScript],
        workingDirectory: _workingDir,
        runInShell: true,
      );

      // Pipe stdout
      _process!.stdout
          .transform(const SystemEncoding().decoder)
          .listen((line) {
        debugPrint('[Python] $line');
        onStdout?.call(line);
      });

      // Pipe stderr
      _process!.stderr
          .transform(const SystemEncoding().decoder)
          .listen((line) {
        debugPrint('[Python ERR] $line');
        onStderr?.call(line);
      });

      // Handle unexpected termination
      _process!.exitCode.then((code) {
        debugPrint('[PythonService] Process exited with code $code');
        _process = null;
      });

      // Poll until Flask is ready (max 30 s)
      final api = ApiService(baseUrl: 'http://localhost:5000');
      const maxAttempts = 30;
      for (var i = 0; i < maxAttempts; i++) {
        await Future.delayed(const Duration(seconds: 1));
        if (await api.ping()) {
          debugPrint('[PythonService] Server ready after ${i + 1}s');
          return true;
        }
      }

      debugPrint('[PythonService] Timeout waiting for server.');
      return false;
    } catch (e) {
      debugPrint('[PythonService] Failed to start: $e');
      _process = null;
      return false;
    }
  }

  /// Kills the Python server process.
  Future<void> stop() async {
    if (_process != null) {
      debugPrint('[PythonService] Stopping server…');
      _process!.kill(ProcessSignal.sigterm);
      await _process!.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _process!.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
      _process = null;
      debugPrint('[PythonService] Server stopped.');
    }
  }
}
