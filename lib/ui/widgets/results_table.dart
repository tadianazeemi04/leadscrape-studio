import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/email_record.dart';
import '../../services/file_service.dart';
import '../../state/scraper_controller.dart';

class ResultsTable extends StatefulWidget {
  final ScraperController controller;

  const ResultsTable({super.key, required this.controller});

  @override
  State<ResultsTable> createState() => _ResultsTableState();
}

class _ResultsTableState extends State<ResultsTable> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchFilter = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchFilter.dispose();
    super.dispose();
  }

  void _copyAllEmailsToClipboard() {
    final emails = widget.controller.allDiscoveredRecords
        .map((r) => r.email)
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

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final records = c.allDiscoveredRecords;
    final uniqueEmails = records.map((r) => r.email).toSet().toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        children: [
          // Top Controls Bar
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
                            const Icon(Icons.table_chart, size: 16),
                            const SizedBox(width: 6),
                            Text('Detailed Grid (${records.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.folder_zip, size: 16),
                            const SizedBox(width: 6),
                            Text('Saved Files (${c.savedFiles.length})'),
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

                // Tab 2: Detailed Table View
                _buildDetailedTableView(records),

                // Tab 3: Saved Files
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
              'No batch files saved yet.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              'When a contractor list item finishes searching all cities in a state,\nits file will appear here automatically.',
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

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.description, color: Colors.orange),
            title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(filePath, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () => FileService.openFile(filePath),
                  icon: const Icon(Icons.edit_document, size: 14),
                  label: const Text('Open in Notepad', style: TextStyle(fontSize: 11)),
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
