import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/bot_provider.dart';
import '../models/bot_status.dart';
import 'send_screen.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return isWide
              ? _WideLayout()
              : _NarrowLayout();
        },
      ),
    );
  }
}

// ─── Wide (Desktop) layout ───────────────────────────────────────────────────

class _WideLayout extends StatefulWidget {
  @override
  State<_WideLayout> createState() => _WideLayoutState();
}

class _WideLayoutState extends State<_WideLayout> {
  int _selectedIndex = 0;

  void _goToTab(int i) => setState(() => _selectedIndex = i);

  List<Widget> get _pages => [
        _DashboardPage(onNavigate: _goToTab),
        const SendScreen(),
        const LogsScreen(),
        const SettingsScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        // ── Sidebar nav ──────────────────────────────────────────────────
        NavigationRail(
          backgroundColor: cs.surfaceContainerHighest,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _goToTab,
          extended: false,
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: cs.primaryContainer,
              child: Icon(Icons.message_rounded,
                  color: cs.onPrimaryContainer, size: 28),
            ),
          ),
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: Text('Dashboard'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.send_outlined),
              selectedIcon: Icon(Icons.send),
              label: Text('Send'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: Text('Logs'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: Text('Settings'),
            ),
          ],
        ),
        const VerticalDivider(width: 1),
        // ── Page content ─────────────────────────────────────────────────
        Expanded(child: _pages[_selectedIndex]),
      ],
    );
  }
}

// ─── Narrow (Mobile) layout ──────────────────────────────────────────────────

class _NarrowLayout extends StatefulWidget {
  @override
  State<_NarrowLayout> createState() => _NarrowLayoutState();
}

class _NarrowLayoutState extends State<_NarrowLayout> {
  int _selectedIndex = 0;

  void _goToTab(int i) => setState(() => _selectedIndex = i);

  List<Widget> get _pages => [
        _DashboardPage(onNavigate: _goToTab),
        const SendScreen(),
        const LogsScreen(),
        const SettingsScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _goToTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.send_outlined),
            selectedIcon: Icon(Icons.send),
            label: 'Send',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Logs',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ─── Dashboard page ──────────────────────────────────────────────────────────

class _DashboardPage extends StatelessWidget {
  final void Function(int tab) onNavigate;
  const _DashboardPage({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prov = context.watch<BotProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.message_rounded, color: cs.primary),
            const SizedBox(width: 10),
            const Text(
              'WhatsApp Automator',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          _ConnectionBadge(),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: prov.checkConnection,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Status banner ─────────────────────────────────────────────
            _StatusBanner(status: prov.botStatus).animate().fadeIn().slideY(
                  begin: -0.2,
                  duration: 400.ms,
                ),
            const SizedBox(height: 16),

            // ── Stats row ─────────────────────────────────────────────────
            if (prov.botStatus.total > 0) ...[
              _StatsRow(status: prov.botStatus)
                  .animate()
                  .fadeIn(delay: 100.ms)
                  .slideY(begin: 0.2),
              const SizedBox(height: 16),
            ],

            // ── Quick action cards ────────────────────────────────────────
            Text(
              'Quick Actions',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _QuickActionCard(
              icon: Icons.send_rounded,
              title: 'Send Messages',
              subtitle: 'Send bulk messages to contacts from a CSV file',
              color: cs.primaryContainer,
              iconColor: cs.onPrimaryContainer,
              onTap: () => _navigateTo(context, 1),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
            const SizedBox(height: 10),
            _QuickActionCard(
              icon: Icons.attach_file_rounded,
              title: 'Send with Media',
              subtitle: 'Attach copied media (CTRL+C) to each message',
              color: cs.secondaryContainer,
              iconColor: cs.onSecondaryContainer,
              onTap: () => _navigateTo(context, 1, withMedia: true),
            ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
            const SizedBox(height: 10),
            _QuickActionCard(
              icon: Icons.history_rounded,
              title: 'View Logs',
              subtitle: 'See which messages were sent or failed',
              color: cs.tertiaryContainer,
              iconColor: cs.onTertiaryContainer,
              onTap: () => _navigateTo(context, 2),
            ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

            const SizedBox(height: 24),

            // ── How to use ────────────────────────────────────────────────
            _HowToUseCard().animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, int tab, {bool withMedia = false}) {
    if (withMedia) {
      context.read<BotProvider>().setWithMedia(true);
    }
    // Switch the sidebar / bottom-nav tab via the parent callback.
    onNavigate(tab);
  }
}

// ─── Connection badge ─────────────────────────────────────────────────────────

class _ConnectionBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BotProvider>();
    final cs = Theme.of(context).colorScheme;
    if (prov.isConnecting) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: prov.isConnected
            ? Colors.green.withOpacity(0.15)
            : cs.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            prov.isConnected ? Icons.wifi : Icons.wifi_off,
            size: 14,
            color: prov.isConnected ? Colors.green : cs.error,
          ),
          const SizedBox(width: 4),
          Text(
            prov.isConnected ? 'Connected' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: prov.isConnected ? Colors.green : cs.error,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status banner ────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final BotStatus status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color bg;
    Color fg;
    IconData icon;
    String title;

    switch (status.status) {
      case BotRunStatus.running:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        icon = Icons.sync_rounded;
        title = 'Bot is running…';
        break;
      case BotRunStatus.completed:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        icon = Icons.check_circle_rounded;
        title = 'Completed!';
        break;
      case BotRunStatus.error:
        bg = cs.errorContainer;
        fg = cs.onErrorContainer;
        icon = Icons.error_rounded;
        title = 'Error occurred';
        break;
      default:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurface;
        icon = Icons.info_outline_rounded;
        title = 'Ready to send';
    }

    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: fg),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        color: fg, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            if (status.message.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(status.message,
                  style: TextStyle(color: fg.withOpacity(0.8))),
            ],
            if (status.isRunning && status.total > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: status.progressFraction,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${status.progress} / ${status.total} messages sent',
                style: TextStyle(fontSize: 12, color: fg.withOpacity(0.7)),
              ),
            ],
            if (status.isRunning && status.total == 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(minHeight: 8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final BotStatus status;
  const _StatsRow({required this.status});

  @override
  Widget build(BuildContext context) {
    final remaining = status.total - status.progress;
    final pct = (status.progressFraction * 100).round();
    return Row(
      children: [
        Expanded(
            child: _StatCard(
                label: 'Sent', value: '${status.progress}', icon: Icons.check)),
        const SizedBox(width: 10),
        Expanded(
            child: _StatCard(
                label: 'Remaining', value: '$remaining', icon: Icons.hourglass_top)),
        const SizedBox(width: 10),
        Expanded(
            child: _StatCard(
                label: 'Progress', value: '$pct%', icon: Icons.percent)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: cs.primary, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.primary)),
            Text(label,
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Quick action card ────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── How to use card ──────────────────────────────────────────────────────────

class _HowToUseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline_rounded, color: cs.primary),
                const SizedBox(width: 8),
                Text('How to use',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ..._steps.asMap().entries.map(
                  (e) => _StepRow(number: e.key + 1, text: e.value),
                ),
          ],
        ),
      ),
    );
  }

  static const _steps = [
    'Make sure the Python API server is running (run start_server.bat or: python api_server.py)',
    'Go to Settings and verify the server URL (default: http://localhost:5000)',
    'Prepare your contacts CSV file in the data/ folder (format: number,message)',
    'Tap "Send Messages", select your CSV file, and press Start',
    'Scan the WhatsApp Web QR code when the browser opens',
    'Monitor progress from the Dashboard and review results in Logs',
  ];
}

class _StepRow extends StatelessWidget {
  final int number;
  final String text;
  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: cs.primaryContainer,
            child: Text('$number',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.8), height: 1.5)),
          ),
        ],
      ),
    );
  }
}
