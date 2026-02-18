class LogEntry {
  final String filename;
  final String type; // 'sent' | 'not_sent'
  final int count;
  final List<String> numbers;

  const LogEntry({
    required this.filename,
    required this.type,
    required this.count,
    required this.numbers,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      filename: json['filename']?.toString() ?? '',
      type: json['type']?.toString() ?? 'sent',
      count: (json['count'] as num?)?.toInt() ?? 0,
      numbers: List<String>.from(json['numbers'] as List? ?? []),
    );
  }

  bool get isSent => type == 'sent';

  /// Extract a human-readable label from the filename.
  /// e.g. "12-02-2025_143000_sent.txt" → "12-02-2025 14:30:00"
  String get label {
    final withoutExt = filename
        .replaceAll('_sent.txt', '')
        .replaceAll('_notsent.txt', '');
    final parts = withoutExt.split('_');
    if (parts.length >= 2) {
      final timePart = parts[1];
      final formatted = '${timePart.substring(0, 2)}:'
          '${timePart.substring(2, 4)}:'
          '${timePart.substring(4, 6)}';
      return '${parts[0]}  $formatted';
    }
    return withoutExt;
  }
}
