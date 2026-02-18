import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/bot_status.dart';
import '../providers/bot_provider.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<BotProvider>();
      if (prov.isConnected) prov.loadFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BotProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Messages',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (prov.isConnected)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh file list',
              onPressed: prov.loadFiles,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: !prov.isConnected
          ? _OfflineView(onRetry: prov.checkConnection)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Feedback banners ────────────────────────────────────
                if (prov.errorMessage != null)
                  _Banner(
                    message: prov.errorMessage!,
                    isError: true,
                    onDismiss: prov.clearMessages,
                  ).animate().fadeIn(),
                if (prov.successMessage != null)
                  _Banner(
                    message: prov.successMessage!,
                    isError: false,
                    onDismiss: prov.clearMessages,
                  ).animate().fadeIn(),

                // ── Live progress card (shown while running) ─────────────
                if (prov.botStatus.isRunning || prov.botStatus.isDone)
                  _ProgressCard(status: prov.botStatus, prov: prov)
                      .animate()
                      .fadeIn()
                      .slideY(begin: -0.1),

                // ── File selector card ───────────────────────────────────
                _SectionHeader(
                    icon: Icons.folder_open_rounded,
                    title: 'Select Contact File'),
                const SizedBox(height: 8),
                _FilePickerCard(prov: prov).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 20),

                // ── Options card ─────────────────────────────────────────
                _SectionHeader(
                    icon: Icons.tune_rounded, title: 'Options'),
                const SizedBox(height: 8),
                _OptionsCard(prov: prov).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 20),

                // ── CSV format helper ────────────────────────────────────
                _CsvFormatCard().animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 28),

                // ── Action buttons ───────────────────────────────────────
                _ActionButtons(prov: prov).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 16),
              ],
            ),
    );
  }
}

// ─── Offline view ─────────────────────────────────────────────────────────────

class _OfflineView extends StatelessWidget {
  final Future<bool> Function() onRetry;
  const _OfflineView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 72, color: cs.error),
            const SizedBox(height: 16),
            Text('Server not reachable',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Make sure the Python API server is running.\nRun start_server.bat or: python api_server.py',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection'),
              onPressed: () => onRetry(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 6),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
      ],
    );
  }
}

// ─── File picker card ─────────────────────────────────────────────────────────

class _FilePickerCard extends StatelessWidget {
  final BotProvider prov;
  const _FilePickerCard({required this.prov});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Dropdown ────────────────────────────────────────────────
            if (prov.isLoadingFiles)
              const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              ))
            else if (prov.availableFiles.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: cs.error, size: 20),
                      const SizedBox(width: 8),
                      const Text('No CSV files found in data/ folder'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload a file below or add one to the data/ folder on the server.',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurface.withOpacity(0.6)),
                  ),
                ],
              )
            else
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Contact CSV file',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.table_chart_outlined),
                ),
                // ignore: deprecated_member_use
                value: prov.selectedFile,
                items: prov.availableFiles
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: prov.botStatus.isRunning
                    ? null
                    : (v) => prov.selectFile(v),
              ),

            const SizedBox(height: 14),

            // ── Upload button ────────────────────────────────────────────
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload CSV from device'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: prov.botStatus.isRunning ? null : () => _pickFile(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    if (context.mounted) {
      final ok = await context
          .read<BotProvider>()
          .uploadFile(file.name, file.bytes!);
      if (ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploaded: ${file.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

// ─── Options card ─────────────────────────────────────────────────────────────

class _OptionsCard extends StatelessWidget {
  final BotProvider prov;
  const _OptionsCard({required this.prov});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.attach_file_rounded,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        title: const Text('Send with media',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text(
            'Copy the media file first (CTRL+C), then enable this option'),
        value: prov.withMedia,
        onChanged:
            prov.botStatus.isRunning ? null : (v) => prov.setWithMedia(v),
      ),
    );
  }
}

// ─── CSV format helper ────────────────────────────────────────────────────────

class _CsvFormatCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text('CSV file format',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: cs.primary)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: const Text(
                'header_row\n"01012345678,Hello Ahmed!"\n"01098765432,Hi there!"',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Each row must be quoted: "phone,message"\n'
              'The first row is skipped as header. Quotes are required so the whole row is treated as one field.',
              style: TextStyle(
                  fontSize: 11, color: cs.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Progress card ────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final BotStatus status;
  final BotProvider prov;
  const _ProgressCard({required this.status, required this.prov});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRunning = status.isRunning;
    final isDone = status.isDone;

    Color bg = isRunning
        ? Colors.blue.shade50
        : isDone
            ? Colors.green.shade50
            : cs.errorContainer;
    Color fg = isRunning
        ? Colors.blue.shade800
        : isDone
            ? Colors.green.shade800
            : cs.onErrorContainer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: bg,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isRunning)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: fg),
                    ),
                  if (!isRunning)
                    Icon(
                        isDone
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: fg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isRunning
                          ? 'Sending messages…'
                          : isDone
                              ? 'Completed!'
                              : 'Stopped / Error',
                      style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ),
                  if (!isRunning)
                    TextButton(
                      onPressed: prov.resetStatus,
                      child: Text('Reset', style: TextStyle(color: fg)),
                    ),
                ],
              ),
              if (status.message.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(status.message,
                    style: TextStyle(color: fg.withOpacity(0.8), fontSize: 13)),
              ],
              if (status.total > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: status.progressFraction,
                    minHeight: 8,
                    color: fg,
                    backgroundColor: fg.withOpacity(0.2),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${status.progress} / ${status.total}',
                      style:
                          TextStyle(fontSize: 12, color: fg.withOpacity(0.7)),
                    ),
                    Text(
                      '${(status.progressFraction * 100).round()}%',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: fg),
                    ),
                  ],
                ),
              ],
              if (status.currentNumber.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Current: ${status.currentNumber}',
                  style: TextStyle(
                      fontSize: 12,
                      color: fg.withOpacity(0.7),
                      fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Action buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final BotProvider prov;
  const _ActionButtons({required this.prov});

  @override
  Widget build(BuildContext context) {
    final isRunning = prov.botStatus.isRunning;
    final cs = Theme.of(context).colorScheme;

    if (isRunning) {
      return FilledButton.icon(
        icon: prov.isStopping
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.stop_circle_outlined),
        label:
            Text(prov.isStopping ? 'Stopping…' : 'Stop Bot'),
        style: FilledButton.styleFrom(backgroundColor: cs.error),
        onPressed: prov.isStopping ? null : prov.stopBot,
      );
    }

    return Column(
      children: [
        FilledButton.icon(
          icon: prov.isStarting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.rocket_launch_rounded),
          label: Text(prov.isStarting ? 'Starting…' : 'Start Sending'),
          onPressed:
              (prov.isStarting || prov.selectedFile == null || !prov.isConnected)
                  ? null
                  : () async {
                      final ok = await prov.startBot();
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                prov.errorMessage ?? 'Failed to start bot'),
                            backgroundColor: cs.error,
                          ),
                        );
                      }
                    },
        ),
      ],
    );
  }
}

// ─── Banner ───────────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;
  const _Banner(
      {required this.message,
      required this.isError,
      required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? cs.errorContainer : Colors.green.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? cs.error : Colors.green.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    color: isError ? cs.onErrorContainer : Colors.green.shade900,
                    fontSize: 13)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDismiss,
            color: isError ? cs.error : Colors.green.shade700,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
