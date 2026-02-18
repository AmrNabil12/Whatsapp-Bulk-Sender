import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/log_entry.dart';
import '../providers/bot_provider.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BotProvider>().loadLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BotProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Logs',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh logs',
            onPressed: prov.loadLogs,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: prov.isLoadingLogs
          ? const Center(child: CircularProgressIndicator())
          : prov.logs.isEmpty
              ? _EmptyLogsView(onRefresh: prov.loadLogs)
              : RefreshIndicator(
                  onRefresh: prov.loadLogs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: prov.logs.length,
                    itemBuilder: (context, index) {
                      return _LogEntryCard(
                        entry: prov.logs[index],
                        index: index,
                      );
                    },
                  ),
                ),
    );
  }
}

// ─── Empty view ───────────────────────────────────────────────────────────────

class _EmptyLogsView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyLogsView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded,
              size: 72, color: cs.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No logs yet',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Logs will appear here after you send messages.',
            style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

// ─── Log entry card ───────────────────────────────────────────────────────────

class _LogEntryCard extends StatelessWidget {
  final LogEntry entry;
  final int index;
  const _LogEntryCard({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSent = entry.isSent;

    final cardColor = isSent ? Colors.green.shade50 : cs.errorContainer;
    final badgeColor = isSent ? Colors.green.shade600 : cs.error;
    final iconData =
        isSent ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Card(
      color: Theme.of(context).brightness == Brightness.dark
          ? (isSent
              ? Colors.green.shade900.withOpacity(0.3)
              : cs.errorContainer)
          : cardColor,
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: badgeColor.withOpacity(0.15),
          child: Icon(iconData, color: badgeColor, size: 22),
        ),
        title: Text(
          isSent ? 'Sent Successfully' : 'Not Sent / Failed',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSent ? Colors.green.shade800 : cs.error),
        ),
        subtitle: Text(
          '${entry.count} number${entry.count != 1 ? 's' : ''}  •  ${entry.label}',
          style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.6)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${entry.count}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                    fontSize: 13),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        children: [
          if (entry.numbers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No numbers recorded.',
                  style:
                      TextStyle(color: cs.onSurface.withOpacity(0.5))),
            )
          else
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Copy-all button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy all', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        final text = entry.numbers.join('\n');
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Numbers copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  // Numbers list
                  ...entry.numbers.asMap().entries.map(
                        (e) => _NumberRow(
                          index: e.key,
                          number: e.value,
                          isSent: isSent,
                        ).animate().fadeIn(delay: (e.key * 30).ms),
                      ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.1);
  }
}

// ─── Number row ───────────────────────────────────────────────────────────────

class _NumberRow extends StatelessWidget {
  final int index;
  final String number;
  final bool isSent;
  const _NumberRow(
      {required this.index, required this.number, required this.isSent});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Text(
            '${index + 1}.',
            style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withOpacity(0.4),
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              number,
              style: const TextStyle(
                  fontFamily: 'monospace', fontWeight: FontWeight.w500),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Clipboard.setData(ClipboardData(text: number));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied: $number'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.copy, size: 14, color: cs.primary),
            ),
          ),
        ],
      ),
    );
  }
}
