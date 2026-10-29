import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cityInputController.dispose();
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
          // Top Controls Bar with Tabs & Master File Actions
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
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.edit_note, size: 16),
                            const SizedBox(width: 6),
                            Text('Notepad View (${uniqueEmails.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.location_city, size: 16),
                            const SizedBox(width: 6),
                            Text('Cities Queue (${c.activeCities.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.table_chart, size: 16),
                            const SizedBox(width: 6),
                            Text('Visited Websites (${records.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.folder, size: 16),
                            const SizedBox(width: 6),
                            Text('Batch Files (${c.savedFiles.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                  ),
                  onPressed: uniqueEmails.isEmpty ? null : _copyAllEmailsToClipboard,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text(
                    'Copy All Emails',
                    style: TextStyle(fontWeight: FontWeight.bold),
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

                // Tab 3: Detailed Visited Websites Table View
                _buildDetailedTableView(records),

                // Tab 4: Saved Files
                _buildSavedFilesView(c),
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
                'Searches per city: ${c.contractorTypes.length} contractor categories',
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

  Widget _buildSavedFilesView(ScraperController c) {
    if (c.savedFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No master batch files created yet.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              'When you start scraping, a single master TXT and CSV will be created here\nand updated in real-time with all discovered emails.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: c.savedFiles.length,
      itemBuilder: (context, index) {
        final filePath = c.savedFiles[index];
        final fileName = filePath.split(RegExp(r'[/\\]')).last;
        final isTxt = fileName.endsWith('.txt');

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              isTxt ? Icons.description : Icons.table_view,
              color: isTxt ? Colors.orange : Colors.green,
            ),
            title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(filePath, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () => FileService.openFile(filePath),
                  icon: const Icon(Icons.launch, size: 14),
                  label: Text(isTxt ? 'Open in Notepad' : 'Open in Excel', style: const TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Reveal in Folder',
                  icon: const Icon(Icons.folder, size: 18),
                  onPressed: () {
                    final parentDir = filePath.substring(0, filePath.lastIndexOf(RegExp(r'[/\\]')));
                    FileService.openFolder(parentDir);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
