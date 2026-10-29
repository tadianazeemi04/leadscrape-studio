import 'package:flutter/material.dart';
import 'webreven_logo.dart';

void showAboutWebRevenDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final isDark = theme.brightness == Brightness.dark;

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.colorScheme.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1412) : const Color(0xFFE8F5E9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const WebRevenLogo(size: 46),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'WebReven',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E676).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF00E676).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: const Text(
                                  'v2.0 PRO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00E676),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Automated Contractor & City Email Harvester — System Guide',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Section 1: Overview
                    _buildSectionCard(
                      context,
                      icon: Icons.rocket_launch,
                      iconColor: const Color(0xFF00E676),
                      title: '1. How WebReven Works (The Pipeline)',
                      content: [
                        _buildStep(
                          number: '1',
                          title: 'Target Formulation',
                          description:
                              'Constructs structured search queries formatted as: "[Contractor] contractors in [City] [State] USA".',
                        ),
                        _buildStep(
                          number: '2',
                          title: 'Multi-Page Pagination (300+ Links per Search)',
                          description:
                              'Traverses pages 1 through 20+ of search results, extracting all organic website destinations while strictly filtering out search engine and Google apps (maps, play, youtube).',
                        ),
                        _buildStep(
                          number: '3',
                          title: 'Deep Concurrent Web Crawling',
                          description:
                              'Visits homepages, Contact & About subpages, mailto links, and linked Facebook business page bios to harvest direct business emails.',
                        ),
                        _buildStep(
                          number: '4',
                          title: 'Single-File Real-Time Appending',
                          description:
                              'Newly discovered emails and audit records are appended immediately to a single master TXT and CSV file on disk. No data is lost if you pause or close the app.',
                        ),
                        _buildStep(
                          number: '5',
                          title: 'Automated Sequential Queue',
                          description:
                              'Crawls all contractor categories for City 1, then automatically advances to City 2, City 3, and so on until the entire state queue is finished.',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Section 2: Batch Management: Resume vs Start New
                    _buildSectionCard(
                      context,
                      icon: Icons.history_toggle_off,
                      iconColor: Colors.amber,
                      title: '2. "Resume Batch" vs "Start New Batch"',
                      content: [
                        _buildFeatureRow(
                          icon: Icons.replay,
                          iconColor: const Color(0xFF00E676),
                          title: 'Resume Previous Batch (No Duplicate Files)',
                          description:
                              'When you pause or restart the app, click "Resume Batch". WebReven reconnects to your existing TXT and CSV files, pre-loads existing emails, skips searches that already completed, and adds all new data into the same files without creating new files.',
                        ),
                        _buildFeatureRow(
                          icon: Icons.add_circle_outline,
                          iconColor: Colors.blue,
                          title: 'Start New Batch',
                          description:
                              'Initializes fresh master output files for a new state or campaign while preserving your previous batches in the Batch History tab.',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Section 3: Central Tabs
                    _buildSectionCard(
                      context,
                      icon: Icons.tab,
                      iconColor: Colors.purpleAccent,
                      title: '3. Center Workspace Tabs Explained',
                      content: [
                        _buildFeatureRow(
                          icon: Icons.edit_note,
                          iconColor: Colors.teal,
                          title: 'Notepad View (X)',
                          description:
                              'Displays all extracted emails formatted one per line in clean monospace font. Use "Copy Emails" to copy all unique emails to your clipboard in one click.',
                        ),
                        _buildFeatureRow(
                          icon: Icons.location_city,
                          iconColor: Colors.blue,
                          title: 'Cities Queue (N)',
                          description:
                              'Displays all cities queued for the active state with search counts. You can add new cities or remove cities at any time.',
                        ),
                        _buildFeatureRow(
                          icon: Icons.engineering,
                          iconColor: Colors.orange,
                          title: 'Contractors List (M)',
                          description:
                              'Displays all contractor categories being searched in each city. Add or remove contractor niches on the fly.',
                        ),
                        _buildFeatureRow(
                          icon: Icons.table_chart,
                          iconColor: Colors.indigo,
                          title: 'Visited Websites (K)',
                          description:
                              'Detailed table showing every website crawled, contractor type, city, state, discovery source, and direct links to open the website or Facebook page.',
                        ),
                        _buildFeatureRow(
                          icon: Icons.history_edu,
                          iconColor: const Color(0xFF00E676),
                          title: 'Batch History (B)',
                          description:
                              'Browse all past and active batch sessions. View progress percentages, total emails collected, and click "Resume Batch" or open master files directly in Notepad/Excel.',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Section 4: Settings & Configuration
                    _buildSectionCard(
                      context,
                      icon: Icons.tune,
                      iconColor: Colors.blueAccent,
                      title: '4. Settings & Crawl Options Reference',
                      content: [
                        _buildFeatureRow(
                          icon: Icons.location_on,
                          iconColor: Colors.redAccent,
                          title: 'Manual State Input',
                          description: 'Type the target state name (e.g. Texas, California, Florida).',
                        ),
                        _buildFeatureRow(
                          icon: Icons.filter_alt,
                          iconColor: Colors.amber,
                          title: 'Minimum Target Links per Search',
                          description:
                              'Choose 300+ links (Standard), 500+ (Deep Exhaustive), or 150+ (Fast mode). The scraper will traverse as many search result pages as needed to reach your target.',
                        ),
                        _buildFeatureRow(
                          icon: Icons.speed,
                          iconColor: Colors.green,
                          title: 'Crawl Speed (Concurrency)',
                          description:
                              'Adjust parallel workers (1 to 16 workers) to match your machine and internet bandwidth.',
                        ),
                        _buildFeatureRow(
                          icon: Icons.domain_disabled,
                          iconColor: Colors.grey,
                          title: 'Filter Aggregators (Yelp, BBB)',
                          description:
                              'Automatically excludes aggregator and directory websites so only direct contractor businesses are harvested.',
                        ),
                        _buildFeatureRow(
                          icon: Icons.facebook,
                          iconColor: Colors.blue,
                          title: 'Extract Facebook Page Emails',
                          description:
                              'When contractor websites link to their official Facebook business pages, WebReven inspects the public bio to harvest direct contact emails.',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Section 5: Master Files & Windows SmartScreen
                    _buildSectionCard(
                      context,
                      icon: Icons.folder,
                      iconColor: Colors.orange,
                      title: '5. Master Output Files & Client Tips',
                      content: [
                        _buildFeatureRow(
                          icon: Icons.description,
                          iconColor: Colors.orange,
                          title: 'Master TXT File ([State]_Batch_[Date]_Emails.txt)',
                          description:
                              'Contains all unique emails extracted, one per line. Perfect for import into email senders and marketing tools.',
                        ),
                        _buildFeatureRow(
                          icon: Icons.table_view,
                          iconColor: Colors.green,
                          title: 'Master CSV File ([State]_Batch_[Date]_Visited_Websites.csv)',
                          description:
                              'Full audit log with columns: Email, Contractor Type, City, State, Website URL, Facebook URL, Source, and Date Discovered.',
                        ),
                        _buildFeatureRow(
                          icon: Icons.security,
                          iconColor: Colors.blueGrey,
                          title: 'Windows SmartScreen Notice ("Windows protected your PC")',
                          description:
                              'When clients download newly compiled .exe installers, Microsoft Defender displays a prompt. Simply instruct them to click "More info" and then "Run anyway" to install or launch.',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1412) : const Color(0xFFF1F5F3),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  border: Border(
                    top: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'WebReven — Built for High-Volume Lead Generation',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Got It', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildSectionCard(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String title,
  required List<Widget> content,
}) {
  final theme = Theme.of(context);

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: theme.dividerColor.withValues(alpha: 0.15),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...content,
      ],
    ),
  );
}

Widget _buildStep({
  required String number,
  required String title,
  required String description,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF00E676).withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00E676), width: 1),
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00E676),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 12, height: 1.35, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildFeatureRow({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String description,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 12, height: 1.35, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
