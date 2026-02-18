import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// All communication with the Python Flask API server happens here.
class ApiService {
  String baseUrl;

  ApiService({this.baseUrl = 'http://localhost:5000'});

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  // ─── Connection ──────────────────────────────────────────────────────────

  Future<bool> ping() async {
    try {
      final res = await http.get(_uri('/api/ping')).timeout(
            const Duration(seconds: 5),
          );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Files ───────────────────────────────────────────────────────────────

  Future<List<String>> getFiles() async {
    final res = await http.get(_uri('/api/files'));
    _check(res);
    final data = json.decode(res.body) as Map<String, dynamic>;
    return List<String>.from(data['files'] as List);
  }

  Future<String> uploadFile(String filename, Uint8List bytes) async {
    final req = http.MultipartRequest('POST', _uri('/api/upload'));
    req.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    _check(res);
    final data = json.decode(res.body) as Map<String, dynamic>;
    return data['filename'] as String;
  }

  // ─── Bot control ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStatus() async {
    final res = await http.get(_uri('/api/status'));
    _check(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<void> startBot(String filename, {bool withMedia = false}) async {
    final res = await http.post(
      _uri('/api/start'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'filename': filename, 'with_media': withMedia}),
    );
    _check(res);
  }

  Future<void> stopBot() async {
    final res = await http.post(_uri('/api/stop'));
    _check(res);
  }

  Future<void> resetStatus() async {
    final res = await http.post(_uri('/api/reset'));
    _check(res);
  }

  // ─── Logs ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getLogs() async {
    final res = await http.get(_uri('/api/logs'));
    _check(res);
    final data = json.decode(res.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['logs'] as List);
  }

  // ─── Helper ──────────────────────────────────────────────────────────────

  void _check(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = 'HTTP ${res.statusCode}';
      try {
        final body = json.decode(res.body) as Map<String, dynamic>;
        msg = body['error']?.toString() ?? msg;
      } catch (_) {}
      throw ApiException(msg);
    }
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}
