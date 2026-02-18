import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bot_status.dart';
import '../models/log_entry.dart';
import '../services/api_service.dart';

class BotProvider extends ChangeNotifier {
  ApiService _api;
  Timer? _pollTimer;

  // ─── State ───────────────────────────────────────────────────────────────
  bool _isConnected = false;
  bool _isConnecting = false;
  String _serverUrl = 'http://localhost:5000';

  BotStatus _botStatus = const BotStatus();
  List<String> _availableFiles = [];
  String? _selectedFile;
  bool _withMedia = false;
  bool _isLoadingFiles = false;
  bool _isStarting = false;
  bool _isStopping = false;

  List<LogEntry> _logs = [];
  bool _isLoadingLogs = false;

  String? _errorMessage;
  String? _successMessage;

  // ─── Getters ─────────────────────────────────────────────────────────────
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get serverUrl => _serverUrl;

  BotStatus get botStatus => _botStatus;
  List<String> get availableFiles => _availableFiles;
  String? get selectedFile => _selectedFile;
  bool get withMedia => _withMedia;
  bool get isLoadingFiles => _isLoadingFiles;
  bool get isStarting => _isStarting;
  bool get isStopping => _isStopping;

  List<LogEntry> get logs => _logs;
  bool get isLoadingLogs => _isLoadingLogs;

  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  BotProvider() : _api = ApiService() {
    _loadSavedUrl().then((_) => checkConnection());
  }

  // ─── Server URL ──────────────────────────────────────────────────────────

  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('server_url');
    if (saved != null && saved.isNotEmpty) {
      _serverUrl = saved;
      _api = ApiService(baseUrl: saved);
    }
    notifyListeners();
  }

  Future<void> setServerUrl(String url) async {
    final trimmed = url.trim().replaceAll(RegExp(r'/$'), '');
    _serverUrl = trimmed;
    _api = ApiService(baseUrl: trimmed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', trimmed);
    notifyListeners();
    await checkConnection();
  }

  Future<bool> checkConnection() async {
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();
    final ok = await _api.ping();
    _isConnected = ok;
    _isConnecting = false;
    notifyListeners();
    if (ok) {
      await loadFiles();
    }
    return ok;
  }

  // ─── Files ───────────────────────────────────────────────────────────────

  Future<void> loadFiles() async {
    _isLoadingFiles = true;
    notifyListeners();
    try {
      _availableFiles = await _api.getFiles();
      if (_availableFiles.isNotEmpty &&
          (_selectedFile == null || !_availableFiles.contains(_selectedFile))) {
        _selectedFile = _availableFiles.first;
      }
    } catch (e) {
      _availableFiles = [];
      _setError('Failed to load files: $e');
    } finally {
      _isLoadingFiles = false;
      notifyListeners();
    }
  }

  void selectFile(String? file) {
    _selectedFile = file;
    notifyListeners();
  }

  void setWithMedia(bool value) {
    _withMedia = value;
    notifyListeners();
  }

  Future<bool> uploadFile(String filename, Uint8List bytes) async {
    try {
      final uploaded = await _api.uploadFile(filename, bytes);
      await loadFiles();
      _selectedFile = uploaded;
      _setSuccess('File "$uploaded" uploaded successfully!');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Upload failed: $e');
      return false;
    }
  }

  // ─── Bot control ─────────────────────────────────────────────────────────

  Future<bool> startBot() async {
    if (_selectedFile == null) {
      _setError('Please select a CSV file first.');
      return false;
    }
    _isStarting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _api.startBot(_selectedFile!, withMedia: _withMedia);
      _startPolling();
      _setSuccess('Bot started! Check WhatsApp Web to scan QR code.');
      return true;
    } catch (e) {
      _setError('Failed to start bot: $e');
      return false;
    } finally {
      _isStarting = false;
      notifyListeners();
    }
  }

  Future<void> stopBot() async {
    _isStopping = true;
    notifyListeners();
    try {
      await _api.stopBot();
      _stopPolling();
      // Immediately clear the running state in the UI
      _botStatus = const BotStatus();
      _setSuccess('Bot stopped.');
    } catch (e) {
      _setError('Failed to stop bot: $e');
    } finally {
      _isStopping = false;
      notifyListeners();
    }
  }

  Future<void> resetStatus() async {
    try {
      await _api.resetStatus();
      _botStatus = const BotStatus();
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();
    } catch (_) {}
  }

  // ─── Logs ────────────────────────────────────────────────────────────────

  Future<void> loadLogs() async {
    _isLoadingLogs = true;
    notifyListeners();
    try {
      final raw = await _api.getLogs();
      _logs = raw.map(LogEntry.fromJson).toList();
    } catch (e) {
      _setError('Failed to load logs: $e');
    } finally {
      _isLoadingLogs = false;
      notifyListeners();
    }
  }

  // ─── Polling ─────────────────────────────────────────────────────────────

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _fetchStatus(),
    );
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _fetchStatus() async {
    try {
      final data = await _api.getStatus();
      _botStatus = BotStatus.fromJson(data);
      _isConnected = true;
      if (!_botStatus.isRunning) _stopPolling();
      notifyListeners();
    } catch (_) {
      _isConnected = false;
      _stopPolling();
      notifyListeners();
    }
  }

  // ─── Messages ────────────────────────────────────────────────────────────

  void _setError(String msg) {
    _errorMessage = msg;
    _successMessage = null;
  }

  void _setSuccess(String msg) {
    _successMessage = msg;
    _errorMessage = null;
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
