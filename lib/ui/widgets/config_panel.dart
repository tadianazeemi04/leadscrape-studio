import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../state/scraper_controller.dart';
import '../../services/file_service.dart';
import 'confirmation_dialog.dart';

class ConfigPanel extends StatefulWidget {
  final ScraperController controller;

  const ConfigPanel({super.key, required this.controller});

  @override
  State<ConfigPanel> createState() => _ConfigPanelState();
}

class _ConfigPanelState extends State<ConfigPanel> {
  late TextEditingController _stateInputController;
  final TextEditingController _cityInputController = TextEditingController();
  final TextEditingController _contractorInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _stateInputController = TextEditingController(text: widget.controller.manualState);
  }

  @override
  void dispose() {
    _stateInputController.dispose();
    _cityInputController.dispose();
    _contractorInputController.dispose();
    super.dispose();
  }

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
        widget.controller.setContractors(parsed);
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
      allowedExtensions: ['txt', 'csv', 'json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final parsed = FileService.parseCities(content);
      if (parsed.isNotEmpty) {
        widget.controller.setCities(parsed);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Loaded ${parsed.length} cities!')),
          );
        }
      }
    }
  }

  void _openBulkCityEditorDialog() {
    final textController = TextEditingController(
      text: widget.controller.activeCities.join('\n'),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit_location_alt, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Edit Cities for ${widget.controller.manualState}'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter or paste cities below (one per line):',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                maxLines: 12,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Houston\nDallas\nAustin\nSan Antonio\nFort Worth',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final lines = textController.text
                  .split('\n')
                  .map((c) => c.trim())
                  .where((c) => c.isNotEmpty)
                  .toList();
              widget.controller.setCities(lines);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Updated to ${lines.length} cities!')),
              );
            },
            child: const Text('Save Cities'),
          ),
        ],
      ),
    );
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
      widget.controller.addContractor(text);
      _contractorInputController.clear();
    }
  }

  void _addCity() {
    final text = _cityInputController.text.trim();
    if (text.isNotEmpty) {
      widget.controller.addCity(text);
      _cityInputController.clear();
    }
  }

  Future<void> _handleStartScraping() async {
    final c = widget.controller;
    if (c.activeCities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one city first.')),
      );
      return;
    }
    if (c.contractorTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one contractor category first.')),
      );
      return;
    }

    final totalQueries = c.activeCities.length * c.contractorTypes.length;
    final confirmed = await confirmAction(
      context,
      title: 'Start WebReven Harvester?',
      message:
          'State: ${c.manualState.isEmpty ? "All" : c.manualState}\n'
          'Active Cities: ${c.activeCities.length}\n'
          'Contractor Categories: ${c.contractorTypes.length}\n'
          'Total Searches: $totalQueries\n'
          'Target: ${c.config.minLinksTarget}+ links per query\n\n'
          'WebReven will traverse pages 1 through N, extract all emails, and stream them in real-time into a single master TXT and CSV file.\n\n'
          'Are you ready to proceed?',
      confirmLabel: 'Start Scraping',
      confirmColor: const Color(0xFF0D9488),
      icon: Icons.rocket_launch_rounded,
      iconColor: const Color(0xFF0D9488),
    );

    if (confirmed) {
      c.startScraping();
    }
  }

  Future<void> _handleStopScraping() async {
    final confirmed = await confirmAction(
      context,
      title: 'Stop Scraping Session?',
      message:
          'Are you sure you want to stop the automated scraper?\n\n'
          'Discovered links and emails up to this point are already safely saved on disk in your master batch files.',
      confirmLabel: 'Stop Scraping',
      confirmColor: Colors.red.shade700,
      icon: Icons.stop_circle_outlined,
      iconColor: Colors.red,
    );

    if (confirmed) {
      widget.controller.stopScraping();
    }
  }

  Future<void> _handlePauseScraping() async {
    final confirmed = await confirmAction(
      context,
      title: 'Pause Harvesting?',
      message:
          'Scraping will pause after active web crawlers finish.\n\nYou can resume scraping at any time without losing progress.',
      confirmLabel: 'Pause',
      confirmColor: Colors.amber.shade800,
      icon: Icons.pause_circle_outline,
      iconColor: Colors.amber,
    );

    if (confirmed) {
      widget.controller.pauseScraping();
    }
  }

  Future<void> _confirmRemoveCity(String city) async {
    final confirmed = await confirmAction(
      context,
      title: 'Remove City?',
      message: 'Are you sure you want to remove "$city" from the queue?',
      confirmLabel: 'Remove City',
      confirmColor: Colors.red.shade700,
      icon: Icons.delete_outline,
      iconColor: Colors.red,
    );

    if (confirmed) {
      widget.controller.removeCity(city);
    }
  }

  Future<void> _confirmRemoveContractor(String type) async {
    final confirmed = await confirmAction(
      context,
      title: 'Remove Contractor Category?',
      message: 'Are you sure you want to remove "$type" from the search list?',
      confirmLabel: 'Remove Category',
      confirmColor: Colors.red.shade700,
      icon: Icons.delete_outline,
      iconColor: Colors.red,
    );

    if (confirmed) {
      widget.controller.removeContractor(type);
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
        width: 340,
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
                      'Search Configuration',
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
                  // 1. MANUAL STATE NAME INPUT (Requested explicitly)
                  const Text('1. State Name (Manual Input)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _stateInputController,
                    enabled: !isRunning,
                    decoration: const InputDecoration(
                      labelText: 'State (e.g. Texas, Florida, California)',
                      prefixIcon: Icon(Icons.location_on, size: 18),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => c.updateManualState(val),
                  ),

                  const Divider(height: 28),

                  // 2. EDITABLE CITIES LIST (Requested explicitly)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '2. Cities in State (${c.activeCities.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit / Paste All Cities',
                        icon: const Icon(Icons.edit_note, size: 20, color: Colors.blue),
                        onPressed: isRunning ? null : _openBulkCityEditorDialog,
                      ),
                      IconButton(
                        tooltip: 'Upload Cities File',
                        icon: const Icon(Icons.upload_file, size: 20),
                        onPressed: isRunning ? null : _uploadCitiesFile,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityInputController,
                          enabled: !isRunning,
                          decoration: const InputDecoration(
                            hintText: 'Add city e.g. Austin',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _addCity(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filledTonal(
                        onPressed: isRunning ? null : _addCity,
                        icon: const Icon(Icons.add, size: 18),
                        tooltip: 'Add City',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 130),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: c.activeCities.map((city) {
                          return Chip(
                            label: Text(city, style: const TextStyle(fontSize: 11)),
                            deleteIcon: const Icon(Icons.close, size: 12),
                            onDeleted: isRunning ? null : () => _confirmRemoveCity(city),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const Divider(height: 28),

                  // 3. CONTRACTORS LIST
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '3. Contractors (${c.contractorTypes.length})',
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
                  const SizedBox(height: 4),
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
                    children: c.contractorTypes.map((type) {
                      return Chip(
                        label: Text(type, style: const TextStyle(fontSize: 11)),
                        deleteIcon: const Icon(Icons.close, size: 12),
                        onDeleted: isRunning ? null : () => _confirmRemoveContractor(type),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      );
                    }).toList(),
                  ),

                  const Divider(height: 28),

                  // 4. HARVESTING & CRAWL OPTIONS
                  const Text('4. Multi-Page Harvesting Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: c.config.minLinksTarget,
                    isExpanded: true,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'Minimum Target Links per Search',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 300, child: Text('300+ links (All Pages 1 to N)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 500, child: Text('500+ links (Deep Exhaustive)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 150, child: Text('150+ links (Fast mode)', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: isRunning
                        ? null
                        : (val) {
                            if (val != null) {
                              c.updateConfig(c.config.copyWith(minLinksTarget: val));
                            }
                          },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crawl Speed: ${c.config.concurrency} parallel workers',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Slider(
                    value: c.config.concurrency.toDouble(),
                    min: 1,
                    max: 16,
                    divisions: 15,
                    label: '${c.config.concurrency} workers',
                    onChanged: isRunning
                        ? null
                        : (val) {
                            c.updateConfig(c.config.copyWith(concurrency: val.toInt()));
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

                  const Divider(height: 28),

                  // 5. OUTPUT FOLDER
                  const Text('5. Master Output Folder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    c.config.outputFolderPath ?? 'Default: Documents/WebReven_Outputs',
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
                        onPressed: _handleStartScraping,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('START SCRAPING', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (isRunning)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _handlePauseScraping,
                            icon: const Icon(Icons.pause),
                            label: const Text('Pause'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                            onPressed: _handleStopScraping,
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
                            onPressed: _handleStopScraping,
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
