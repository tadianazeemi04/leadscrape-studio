import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/batch_session.dart';
import '../../models/email_record.dart';
import '../../services/file_service.dart';
import '../../state/scraper_controller.dart';
import 'confirmation_dialog.dart';

class ResultsTable extends StatefulWidget {
  final ScraperController controller;

  const ResultsTable({super.key, required this.controller});

  @override
  State<ResultsTable> createState() => _ResultsTableState();
}

class _ResultsTableState extends State<ResultsTable> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _cityInputController = TextEditingController();
  final TextEditingController _contractorInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cityInputController.dispose();
    _contractorInputController.dispose();
    super.dispose();
  }

  void _copyAllEmailsToClipboard() {
    final emails = widget.controller.allDiscoveredRecords
        .map((r) => r.email.toLowerCase().trim())
        .toSet()
        .toList();

    if (emails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No emails to copy yet!')),
      );
      return;
    }

    final text = emails.join('\n');
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${emails.length} unique emails to clipboard!'),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  void _addCity() {
    final text = _cityInputController.text.trim();
    if (text.isNotEmpty) {
      widget.controller.addCity(text);
      _cityInputController.clear();
    }
  }

  void _addContractor() {
    final text = _contractorInputController.text.trim();
    if (text.isNotEmpty) {
      widget.controller.addContractor(text);
      _contractorInputController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final records = c.allDiscoveredRecords;
    final uniqueEmails = records.map((r) => r.email.toLowerCase().trim()).toSet().toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        children: [
          // Top Controls Bar with Tabs & Summary Badges
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      // 1. Notepad View
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.edit_note, size: 16),
                            const SizedBox(width: 6),
                            Text('Notepad View (${uniqueEmails.length})'),
                          ],
                        ),
                      ),
                      // 2. Cities Queue
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.location_city, size: 16),
                            const SizedBox(width: 6),
                            Text('Cities (${c.activeCities.length})'),
                          ],
                        ),
                      ),
                      // 3. Contractors List
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.engineering, size: 16),
                            const SizedBox(width: 6),
                            Text('Contractors (${c.contractorTypes.length})'),
                          ],
                        ),
                      ),
                      // 4. Visited Websites
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.table_chart, size: 16),
                            const SizedBox(width: 6),
                            Text('Visited Websites (${records.length})'),
                          ],
                        ),
                      ),
                      // 5. Batch History & Resume
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.history_edu, size: 16),
                            const SizedBox(width: 6),
                            Text('Batch History (${c.allBatchSessions.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: uniqueEmails.isEmpty ? null : _copyAllEmailsToClipboard,
                  icon: const Icon(Icons.copy, size: 15),
                  label: const Text(
                    'Copy Emails',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Notepad View (One email per line, selectable text)
                _buildNotepadView(uniqueEmails),

                // Tab 2: Cities Queue (Editable on the right!)
                _buildCitiesQueueView(c),

                // Tab 3: Contractors List (Editable on the right!)
                _buildContractorsQueueView(c),

                // Tab 4: Detailed Visited Websites Table View
                _buildDetailedTableView(records),

                // Tab 5: Saved Previous Batches & Resume
                _buildBatchHistoryView(c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotepadView(List<String> uniqueEmails) {
    if (uniqueEmails.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mark_email_unread_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No emails extracted yet.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              'Extracted emails will appear here formatted as a clean notepad list.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final plainText = uniqueEmails.join('\n');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Total Unique Emails: ${uniqueEmails.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              const Text('Select all or use "Copy All Emails"', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
              ),
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                plainText,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitiesQueueView(ScraperController c) {
    final isRunning = c.status == ScrapeStatus.running;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Active State: ${c.manualState.isEmpty ? "None" : c.manualState} (${c.activeCities.length} Cities)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Text(
                '${c.contractorTypes.length} contractor categories per city',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cityInputController,
                  enabled: !isRunning,
                  decoration: const InputDecoration(
                    hintText: 'Add another city to queue (e.g. San Antonio)...',
                    prefixIcon: Icon(Icons.add_location_alt, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addCity(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: isRunning ? null : _addCity,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add City'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: c.activeCities.isEmpty
                ? const Center(child: Text('No cities added yet. Add cities above.'))
                : ListView.separated(
                    itemCount: c.activeCities.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final city = c.activeCities[index];
                      final isCurrent = c.currentCity == city && isRunning;

                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: isCurrent ? Colors.green : Theme.of(context).colorScheme.primaryContainer,
                          child: Text('${index + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(
                          '$city, ${c.manualState}',
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                            color: isCurrent ? Colors.green.shade800 : null,
                          ),
                        ),
                        subtitle: isCurrent
                            ? Text('Currently crawling: ${c.currentContractor}...', style: const TextStyle(fontSize: 11, color: Colors.green))
                            : Text('${c.contractorTypes.length} searches will run here', style: const TextStyle(fontSize: 11)),
                        trailing: isRunning
                            ? null
                            : IconButton(
                                tooltip: 'Remove $city',
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await confirmAction(
                                    context,
                                    title: 'Remove City?',
                                    message: 'Are you sure you want to remove "$city" from the search queue?',
                                    confirmLabel: 'Remove City',
                                    confirmColor: Colors.red.shade700,
                                    icon: Icons.delete_outline,
                                    iconColor: Colors.red,
                                  );
                                  if (confirm) {
                                    c.removeCity(city);
                                  }
                                },
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractorsQueueView(ScraperController c) {
    final isRunning = c.status == ScrapeStatus.running;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.engineering, color: Theme.of(context).colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Contractor Categories (${c.contractorTypes.length} types)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Text(
                'Will be searched in all ${c.activeCities.length} cities',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _contractorInputController,
                  enabled: !isRunning,
                  decoration: const InputDecoration(
                    hintText: 'Add category e.g. Electrician, Landscaping, HVAC...',
                    prefixIcon: Icon(Icons.add_business, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addContractor(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: isRunning ? null : _addContractor,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Contractor'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: c.contractorTypes.isEmpty
                ? const Center(child: Text('No contractor categories added yet. Add categories above.'))
                : ListView.separated(
                    itemCount: c.contractorTypes.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final contractor = c.contractorTypes[index];
                      final isCurrent = c.currentContractor == contractor && isRunning;

                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: isCurrent ? Colors.green : Theme.of(context).colorScheme.primaryContainer,
                          child: Text('${index + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(
                          contractor,
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                            color: isCurrent ? Colors.green.shade800 : null,
                          ),
                        ),
                        subtitle: isCurrent
                            ? Text('Currently crawling in ${c.currentCity}...', style: const TextStyle(fontSize: 11, color: Colors.green))
                            : Text('Searches in ${c.activeCities.length} cities (${c.config.minLinksTarget}+ links each)', style: const TextStyle(fontSize: 11)),
                        trailing: isRunning
                            ? null
                            : IconButton(
                                tooltip: 'Remove $contractor',
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await confirmAction(
                                    context,
                                    title: 'Remove Contractor Category?',
                                    message: 'Are you sure you want to remove "$contractor" from the list?',
                                    confirmLabel: 'Remove Category',
                                    confirmColor: Colors.red.shade700,
                                    icon: Icons.delete_outline,
                                    iconColor: Colors.red,
                                  );
                                  if (confirm) {
                                    c.removeContractor(contractor);
                                  }
                                },
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedTableView(List<EmailRecord> records) {
    if (records.isEmpty) {
      return const Center(
        child: Text('No detailed records yet.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: records.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final record = records[index];

        return ListTile(
          dense: true,
          leading: const Icon(Icons.email_outlined, color: Colors.green),
          title: SelectableText(
            record.email,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          subtitle: Row(
            children: [
              Text(
                '${record.contractorType} • ${record.city}, ${record.state}',
                style: const TextStyle(fontSize: 11),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  record.source,
                  style: const TextStyle(fontSize: 10, color: Colors.blue),
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (record.facebookUrl != null && record.facebookUrl!.isNotEmpty)
                IconButton(
                  tooltip: 'Open Facebook Page',
                  icon: const Icon(Icons.facebook, color: Colors.blue, size: 18),
                  onPressed: () => launchUrl(Uri.parse(record.facebookUrl!)),
                ),
              IconButton(
                tooltip: 'Open Website',
                icon: const Icon(Icons.language, size: 18),
                onPressed: () => launchUrl(Uri.parse(record.websiteUrl)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBatchHistoryView(ScraperController c) {
    if (c.allBatchSessions.isEmpty && c.savedFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_toggle_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No previous batch sessions saved yet.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              'When you start or pause a batch, all progress and data are saved here.\nYou can resume any previous batch at any time!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final isRunning = c.status == ScrapeStatus.running;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: c.allBatchSessions.length,
      itemBuilder: (context, index) {
        final BatchSession session = c.allBatchSessions[index];
        final isCurrent = c.currentBatchSession?.id == session.id;
        final isCompleted = session.isCompleted || session.completedQueries >= session.totalQueries;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: isCurrent
                  ? const Color(0xFF00E676)
                  : Theme.of(context).dividerColor.withValues(alpha: 0.2),
              width: isCurrent ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isCompleted
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.amber.withValues(alpha: 0.15),
                      child: Icon(
                        isCompleted ? Icons.check_circle_outline : Icons.pause_circle_outline,
                        color: isCompleted ? Colors.green : Colors.amber.shade800,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${session.state} Harvesting Batch',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isCompleted ? Colors.green : Colors.amber).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isCompleted ? 'COMPLETED' : 'PAUSED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted ? Colors.green : Colors.amber.shade800,
                                  ),
                                ),
                              ),
                              if (isCurrent) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00E676),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Started: ${session.createdAt.month}/${session.createdAt.day}/${session.createdAt.year} • Updated: ${session.updatedAt.hour}:${session.updatedAt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${session.cities.length} Cities • ${session.contractors.length} Categories',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      '${session.completedQueries} of ${session.totalQueries} Searches (${(session.progressRatio * 100).toInt()}%) • ${session.emailsCount} Emails Saved',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: session.progressRatio,
                    minHeight: 5,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? Colors.green : const Color(0xFF00E676),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Resume Button (if not completed and not already actively running)
                    if (!isCompleted && !isRunning)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00E676),
                            foregroundColor: Colors.black,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          icon: const Icon(Icons.play_arrow, size: 15),
                          label: const Text('Resume Batch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final confirm = await confirmAction(
                              context,
                              title: 'Resume Previous Batch?',
                              message:
                                  'Resume batch for "${session.state}"?\n\n'
                                  '• ${session.completedQueries} searches already completed will be skipped.\n'
                                  '• All new emails will be added directly into the existing file:\n${session.masterTxtPath}\n\n'
                                  'No new files will be created.',
                              confirmLabel: 'Resume Batch',
                              confirmColor: const Color(0xFF00E676),
                              icon: Icons.history,
                              iconColor: const Color(0xFF00E676),
                            );
                            if (confirm) {
                              c.resumeBatch(session);
                            }
                          },
                        ),
                      ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.description, size: 14, color: Colors.orange),
                      label: const Text('Open TXT', style: TextStyle(fontSize: 11)),
                      onPressed: () => FileService.openFile(session.masterTxtPath),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.table_view, size: 14, color: Colors.green),
                      label: const Text('Open CSV', style: TextStyle(fontSize: 11)),
                      onPressed: () => FileService.openFile(session.masterCsvPath),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Reveal in Folder',
                      icon: const Icon(Icons.folder_open, size: 18),
                      onPressed: () {
                        final parentDir = session.masterTxtPath.substring(0, session.masterTxtPath.lastIndexOf(RegExp(r'[/\\]')));
                        FileService.openFolder(parentDir);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
