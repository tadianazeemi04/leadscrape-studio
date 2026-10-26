import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../state/scraper_controller.dart';
import '../../services/file_service.dart';

class ConfigPanel extends StatefulWidget {
  final ScraperController controller;

  const ConfigPanel({super.key, required this.controller});

  @override
  State<ConfigPanel> createState() => _ConfigPanelState();
}

class _ConfigPanelState extends State<ConfigPanel> {
  final TextEditingController _contractorInputController = TextEditingController();

  Future<void> _uploadContractorsFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'csv'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final parsed = FileService.parseContractors(content);
      if (parsed.isNotEmpty) {
        widget.controller.updateContractors(parsed);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Loaded ${parsed.length} contractor categories!')),
          );
        }
      }
    }
  }

  Future<void> _uploadCitiesFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final parsed = FileService.parseStatesAndCities(content);
      if (parsed.isNotEmpty) {
        widget.controller.updateStatesAndCities(parsed);
        int total = 0;
        for (var c in parsed.values) {
          total += c.length;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Loaded ${parsed.length} states with $total cities!')),
          );
        }
      }
    }
  }

  Future<void> _pickOutputFolder() async {
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      final cfg = widget.controller.config.copyWith(outputFolderPath: selectedDirectory);
      widget.controller.updateConfig(cfg);
    }
  }

  void _addContractor() {
    final text = _contractorInputController.text.trim();
    if (text.isNotEmpty) {
      final current = List<String>.from(widget.controller.task.contractorTypes);
      if (!current.contains(text)) {
        current.add(text);
        widget.controller.updateContractors(current);
        _contractorInputController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final isRunning = c.status == ScrapeStatus.running;
    final isPaused = c.status == ScrapeStatus.paused;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
            ),
          ),
        ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.tune, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Configuration & Tasks',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Settings
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                // 1. Contractors Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '1. Contractors (${c.task.contractorTypes.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: isRunning ? null : _uploadContractorsFile,
                      icon: const Icon(Icons.upload_file, size: 14),
                      label: const Text('Upload', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _contractorInputController,
                        enabled: !isRunning,
                        decoration: const InputDecoration(
                          hintText: 'Add e.g. Roofing, HVAC',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addContractor(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      onPressed: isRunning ? null : _addContractor,
                      icon: const Icon(Icons.add, size: 18),
                      tooltip: 'Add category',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: c.task.contractorTypes.map((type) {
                    return Chip(
                      label: Text(type, style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: isRunning
                          ? null
                          : () {
                              final updated = List<String>.from(c.task.contractorTypes)..remove(type);
                              c.updateContractors(updated);
                            },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),

                const Divider(height: 32),

                // 2. States & Cities Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        '2. States & Cities',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: isRunning ? null : _uploadCitiesFile,
                      icon: const Icon(Icons.upload_file, size: 14),
                      label: const Text('Upload', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: c.task.statesAndCities.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Text(
                          '• ${entry.key}: ${entry.value.length} cities (${entry.value.take(3).join(', ')}${entry.value.length > 3 ? '...' : ''})',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const Divider(height: 32),

                // 3. Engine & Delay Settings
                const Text('3. Search Engine & Options', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: c.config.searchEngine,
                  isExpanded: true,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Search Engine',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'duckduckgo', child: Text('DuckDuckGo (Recommended)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'google', child: Text('Google Search', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'bing', child: Text('Bing Search', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: isRunning
                      ? null
                      : (val) {
                          if (val != null) {
                            c.updateConfig(c.config.copyWith(searchEngine: val));
                          }
                        },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: c.config.maxLinksPerSearch,
                  isExpanded: true,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Link Harvest Depth',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('All Available (300 - 1000+ links)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 100, child: Text('Up to 100 links per query', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 300, child: Text('Up to 300 links per query', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 500, child: Text('Up to 500 links per query', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: isRunning
                      ? null
                      : (val) {
                          if (val != null) {
                            c.updateConfig(c.config.copyWith(maxLinksPerSearch: val));
                          }
                        },
                ),
                const SizedBox(height: 10),
                Text(
                  'Crawl Speed: ${c.config.concurrency} parallel workers',
                  style: const TextStyle(fontSize: 12),
                ),
                Slider(
                  value: c.config.concurrency.toDouble(),
                  min: 1,
                  max: 12,
                  divisions: 11,
                  label: '${c.config.concurrency} workers',
                  onChanged: isRunning
                      ? null
                      : (val) {
                          c.updateConfig(c.config.copyWith(concurrency: val.toInt()));
                        },
                ),
                Text(
                  'Delay: ${c.config.delayBetweenRequestsSeconds.toStringAsFixed(1)}s between sites',
                  style: const TextStyle(fontSize: 12),
                ),
                Slider(
                  value: c.config.delayBetweenRequestsSeconds,
                  min: 0.0,
                  max: 3.0,
                  divisions: 6,
                  label: '${c.config.delayBetweenRequestsSeconds}s',
                  onChanged: isRunning
                      ? null
                      : (val) {
                          c.updateConfig(c.config.copyWith(delayBetweenRequestsSeconds: val));
                        },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Filter Aggregators (Yelp, BBB)', style: TextStyle(fontSize: 13)),
                  value: c.config.filterDirectories,
                  onChanged: isRunning
                      ? null
                      : (val) => c.updateConfig(c.config.copyWith(filterDirectories: val)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Extract Facebook Page Emails', style: TextStyle(fontSize: 13)),
                  value: c.config.checkFacebook,
                  onChanged: isRunning
                      ? null
                      : (val) => c.updateConfig(c.config.copyWith(checkFacebook: val)),
                ),

                const Divider(height: 32),

                // 4. Output Folder
                const Text('4. Output Folder', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  c.config.outputFolderPath ?? 'Default: Documents/LeadScrape_Outputs',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickOutputFolder,
                      icon: const Icon(Icons.folder_open, size: 16),
                      label: const Text('Change Folder', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    if (c.config.outputFolderPath != null)
                      IconButton(
                        tooltip: 'Open in Finder/Explorer',
                        icon: const Icon(Icons.launch, size: 18),
                        onPressed: () => FileService.openFolder(c.config.outputFolderPath!),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Action Controls Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Column(
              children: [
                if (!isRunning && !isPaused)
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: FilledButton.icon(
                      onPressed: c.startScraping,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('START SCRAPING', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (isRunning)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: c.pauseScraping,
                          icon: const Icon(Icons.pause),
                          label: const Text('Pause'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                          onPressed: c.stopScraping,
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop'),
                        ),
                      ),
                    ],
                  ),
                if (isPaused)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
                          onPressed: c.resumeScraping,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Resume'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: c.stopScraping,
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
