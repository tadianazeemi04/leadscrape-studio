import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/log_entry.dart';
import '../../state/scraper_controller.dart';

class LogTerminal extends StatefulWidget {
  final ScraperController controller;

  const LogTerminal({super.key, required this.controller});

  @override
  State<LogTerminal> createState() => _LogTerminalState();
}

class _LogTerminalState extends State<LogTerminal> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void didUpdateWidget(covariant LogTerminal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_autoScroll && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _copyAllLogs() {
    final buffer = StringBuffer();
    for (var log in widget.controller.logs) {
      buffer.writeln('${log.timeFormatted} ${log.prefix} ${log.message}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard!')),
    );
  }

  Color _getColorForLogType(LogType type) {
    switch (type) {
      case LogType.search:
        return const Color(0xFF64D2FF); // Cyan
      case LogType.visit:
        return const Color(0xFF0A84FF); // Blue
      case LogType.emailFound:
        return const Color(0xFF30D158); // Bright Green
      case LogType.facebook:
        return const Color(0xFFFF9F0A); // Orange
      case LogType.success:
        return const Color(0xFF32D74B); // Emerald
      case LogType.warning:
        return const Color(0xFFFFD60A); // Yellow
      case LogType.error:
        return const Color(0xFFFF453A); // Red
      case LogType.info:
        return const Color(0xFF8E8E93); // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = widget.controller.logs;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF18181A),
      ),
      child: Column(
        children: [
          // Terminal Top Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF222225),
              border: Border(
                bottom: BorderSide(color: Color(0xFF2C2C2E)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Live Console',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _autoScroll = !_autoScroll),
                  child: Row(
                    children: [
                      Icon(
                        _autoScroll ? Icons.check_box : Icons.check_box_outline_blank,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Auto-scroll',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Copy all logs',
                  icon: const Icon(Icons.copy, color: Colors.white70, size: 14),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: logs.isEmpty ? null : _copyAllLogs,
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Clear terminal',
                  icon: const Icon(Icons.clear_all, color: Colors.white70, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: logs.isEmpty ? null : widget.controller.clearLogs,
                ),
              ],
            ),
          ),

          // Terminal Output List
          Expanded(
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs yet. Click "START SCRAPING" to begin.\n\nWorkflow:\n1. Search "[contractor] contractors in [city] [state] USA"\n2. Scroll & filter web links (discard Google apps)\n3. Visit contractor websites and grab emails\n4. Inspect Facebook business pages for email\n5. Save batch files per contractor per state',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontFamily: 'Courier',
                        height: 1.5,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final color = _getColorForLogType(log.type);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: SelectableText.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12,
                              height: 1.3,
                            ),
                            children: [
                              TextSpan(
                                text: '${log.timeFormatted} ',
                                style: const TextStyle(color: Color(0xFF636366)),
                              ),
                              TextSpan(
                                text: '${log.prefix} ',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: log.message,
                                style: const TextStyle(color: Color(0xFFF2F2F7)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
