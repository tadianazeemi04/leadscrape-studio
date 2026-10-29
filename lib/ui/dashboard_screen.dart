import 'package:flutter/material.dart';
import '../main.dart';
import '../services/file_service.dart';
import '../state/scraper_controller.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = ScraperController();
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
