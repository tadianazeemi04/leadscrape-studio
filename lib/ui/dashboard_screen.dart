import 'package:flutter/material.dart';
import '../state/scraper_controller.dart';
import 'widgets/config_panel.dart';
import 'widgets/progress_header.dart';
import 'widgets/log_terminal.dart';
import 'widgets/results_table.dart';

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
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.travel_explore,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LeadScrape Studio',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              IconButton(
                tooltip: 'Clear All Session Data',
                icon: const Icon(Icons.refresh),
                onPressed: _controller.status == ScrapeStatus.running
                    ? null
                    : () {
                        _controller.clearResults();
                        _controller.clearLogs();
                      },
              ),
              const SizedBox(width: 8),
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

                    // Main Content Split: Results (Notepad & Grid) + Live Terminal Log
                    Expanded(
                      child: Row(
                        children: [
                          // Left half of right column: Extracted Emails (Notepad & Grid)
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
