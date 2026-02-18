enum BotRunStatus { idle, running, completed, error }

class BotStatus {
  final BotRunStatus status;
  final int progress;
  final int total;
  final String currentNumber;
  final String message;
  final String? startTime;
  final bool withMedia;

  const BotStatus({
    this.status = BotRunStatus.idle,
    this.progress = 0,
    this.total = 0,
    this.currentNumber = '',
    this.message = '',
    this.startTime,
    this.withMedia = false,
  });

  factory BotStatus.fromJson(Map<String, dynamic> json) {
    BotRunStatus runStatus;
    switch (json['status'] as String?) {
      case 'running':
        runStatus = BotRunStatus.running;
        break;
      case 'completed':
        runStatus = BotRunStatus.completed;
        break;
      case 'error':
        runStatus = BotRunStatus.error;
        break;
      default:
        runStatus = BotRunStatus.idle;
    }
    return BotStatus(
      status: runStatus,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      currentNumber: json['current_number']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      startTime: json['start_time']?.toString(),
      withMedia: json['with_media'] as bool? ?? false,
    );
  }

  double get progressFraction => total > 0 ? progress / total : 0.0;

  bool get isRunning => status == BotRunStatus.running;
  bool get isIdle => status == BotRunStatus.idle;
  bool get isDone => status == BotRunStatus.completed;
  bool get hasError => status == BotRunStatus.error;
}
