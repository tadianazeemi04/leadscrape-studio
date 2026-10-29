import 'package:flutter/material.dart';
import '../main.dart';
import '../models/batch_session.dart';
import '../services/file_service.dart';
import '../state/scraper_controller.dart';
import 'widgets/about_dialog.dart';
import 'widgets/confirmation_dialog.dart';
import 'widgets/config_panel.dart';
import 'widgets/progress_header.dart';
import 'widgets/log_terminal.dart';
import 'widgets/results_table.dart';
import 'widgets/webreven_logo.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ScraperController _controller;
  bool _startupChecked = false;

  @override
  void initState() {
    super.initState();
    _controller = ScraperController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPreviousPausedBatch();
    });
  }

  void _checkPreviousPausedBatch() {
    if (_startupChecked) return;
    _startupChecked = true;

    if (!mounted) return;

    final pausedBatch = _controller.getLatestPausedBatch();
    if (pausedBatch != null && _controller.status == ScrapeStatus.idle) {
      _showResumeOrNewBatchDialog(pausedBatch);
    }
  }

  Future<void> _showResumeOrNewBatchDialog(BatchSession batch) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00E676).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.history_toggle_off, color: Color(0xFF00E676), size: 36),
        ),
        title: const Text(
          'Resume Previous Batch?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'An unfinished harvesting batch was found for "${batch.state}":',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('State / Target:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('${batch.state} (${batch.cities.length} cities)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Search Progress:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('${batch.completedQueries} of ${batch.totalQueries} done (${(batch.progressRatio * 100).toInt()}%)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Emails Collected:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('${batch.emailsCount} unique emails', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '• "Resume Batch" continues from where it was paused and adds all newly found emails directly into your existing master files without creating new files.\n'
                '• "Start New Batch" leaves this batch saved in history and lets you configure a fresh session.',
                style: TextStyle(fontSize: 12, height: 1.45, color: Colors.grey),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Start New Batch'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Resume Batch', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              _controller.resumeBatch(batch);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmStartNewBatch() async {
    final confirmed = await confirmAction(
      context,
      title: 'Start New Batch?',
      message:
          'This will clear the current in-memory workspace to configure a new batch.\n\nAll your previous batch histories and saved files remain safely stored on disk.',
      confirmLabel: 'New Batch',
      confirmColor: const Color(0xFF00E676),
      icon: Icons.add_circle_outline,
      iconColor: const Color(0xFF00E676),
    );

    if (confirmed) {
      _controller.clearResults();
      _controller.clearLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ready for a new batch session.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    if (appThemeModeNotifier.value == ThemeMode.dark) {
      appThemeModeNotifier.value = ThemeMode.light;
    } else {
      appThemeModeNotifier.value = ThemeMode.dark;
    }
  }

  Future<void> _confirmClearSession() async {
    final confirmed = await confirmAction(
      context,
      title: 'Clear All Session Data?',
      message:
          'This will clear the live logs, visited websites list, and extracted emails from memory on your screen.\n\nYour saved batch files on disk will NOT be deleted.',
      confirmLabel: 'Clear All',
      confirmColor: Colors.red.shade700,
      icon: Icons.cleaning_services_rounded,
      iconColor: Colors.amber,
    );

    if (confirmed) {
      _controller.clearResults();
      _controller.clearLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session data cleared.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 16,
            title: Row(
              children: [
                const WebRevenLogo(size: 34),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WebReven',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.2),
                    ),
                    Text(
                      'Automated Contractor & City Email Harvester',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // 0A. RESUME PREVIOUS BATCH (if a paused batch exists and scraper is not actively running)
              if (_controller.getLatestPausedBatch() != null && _controller.status != ScrapeStatus.running)
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.18),
                      foregroundColor: const Color(0xFF00E676),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.history, size: 15, color: Color(0xFF00E676)),
                    label: const Text('Resume Batch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      final b = _controller.getLatestPausedBatch();
                      if (b != null) {
                        _showResumeOrNewBatchDialog(b);
                      }
                    },
                  ),
                ),

              // 0B. START NEW BATCH
              if (_controller.status != ScrapeStatus.running)
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 14),
                    label: const Text('New Batch', style: TextStyle(fontSize: 11)),
                    onPressed: _confirmStartNewBatch,
                  ),
                ),

              // 1. OPEN BATCH TXT (Relocated to top bar beside clear button)
              if (_controller.masterTxtPath != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.description, size: 15, color: Colors.orange),
                    label: const Text('Open Batch TXT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => FileService.openFile(_controller.masterTxtPath!),
                  ),
                ),

              // 2. OPEN BATCH CSV (Relocated to top bar beside clear button)
              if (_controller.masterCsvPath != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.table_view, size: 15, color: Colors.green),
                    label: const Text('Open Batch CSV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => FileService.openFile(_controller.masterCsvPath!),
                  ),
                ),

              // 3. CLEAR ALL SESSION DATA (With confirmation warning)
              IconButton(
                tooltip: 'Clear All Session Data',
                icon: const Icon(Icons.refresh),
                onPressed: _controller.status == ScrapeStatus.running ? null : _confirmClearSession,
              ),

              const SizedBox(width: 4),

              // 4. LIGHT / DARK MODE TOGGLE BUTTON (Requested on top right)
              ValueListenableBuilder<ThemeMode>(
                valueListenable: appThemeModeNotifier,
                builder: (context, mode, _) {
                  final isDark = mode == ThemeMode.dark;
                  return IconButton(
                    tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                    icon: Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      color: isDark ? Colors.amber : Colors.blueGrey,
                    ),
                    onPressed: _toggleTheme,
                  );
                },
              ),

              const SizedBox(width: 4),

              // 5. ABOUT THIS APP & USER GUIDE ("?")
              IconButton(
                tooltip: 'About WebReven & How It Works (?)',
                icon: const Icon(Icons.help_outline_rounded),
                onPressed: () => showAboutWebRevenDialog(context),
              ),

              const SizedBox(width: 12),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
              ),
            ),
          ),
          body: Row(
            children: [
              // Left Column: Configuration & Task Setup
              ConfigPanel(controller: _controller),

              // Right Column: Progress Header + Results / Logs Split
              Expanded(
                child: Column(
                  children: [
                    // Top Progress & Status Metrics
                    ProgressHeader(controller: _controller),

                    // Main Content Split: Results (Notepad, Cities Queue & Grid) + Live Terminal Log
                    Expanded(
                      child: Row(
                        children: [
                          // Left half of right column: Extracted Emails & Cities Queue
                          Expanded(
                            flex: 6,
                            child: ResultsTable(controller: _controller),
                          ),

                          VerticalDivider(
                            width: 1,
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                          ),

                          // Right half of right column: Live Execution Terminal Log
                          Expanded(
                            flex: 5,
                            child: LogTerminal(controller: _controller),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
