import 'package:flutter/material.dart';
import '../../state/scraper_controller.dart';

class ProgressHeader extends StatelessWidget {
  final ScraperController controller;

  const ProgressHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final theme = Theme.of(context);

    Color statusColor;
    String statusText;
    switch (c.status) {
      case ScrapeStatus.running:
        statusColor = Colors.green;
        statusText = 'RUNNING';
        break;
      case ScrapeStatus.paused:
        statusColor = Colors.amber.shade800;
        statusText = 'PAUSED';
        break;
      case ScrapeStatus.completed:
        statusColor = Colors.teal;
        statusText = 'COMPLETED';
        break;
      case ScrapeStatus.stopped:
        statusColor = Colors.red.shade700;
        statusText = 'STOPPED';
        break;
      case ScrapeStatus.idle:
        statusColor = Colors.grey.shade600;
        statusText = 'IDLE';
    }

    final isCrawling = c.status == ScrapeStatus.running || c.status == ScrapeStatus.paused;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Status badge, active city/contractor, and stat pills
          Row(
            children: [
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Active Target summary
              Expanded(
                child: isCrawling
                    ? Text(
                        'Target: ${c.currentContractor} contractors in ${c.currentCity}, ${c.currentState}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        'Ready. Click "START SCRAPING" to begin multi-page harvesting.',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Stat Pills
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildStatPill(
                icon: Icons.mark_email_read,
                color: Colors.green,
                label: 'Emails Extracted',
                value: '${c.totalEmailsFound}',
              ),
              _buildStatPill(
                icon: Icons.language,
                color: Colors.blue,
                label: 'Websites Visited',
                value: '${c.websitesVisited}',
              ),
              _buildStatPill(
                icon: Icons.alt_route,
                color: Colors.deepPurple,
                label: 'Queries Done',
                value: '${c.completedContractorQueries} / ${c.totalContractorQueries}',
              ),
              _buildStatPill(
                icon: Icons.description,
                color: Colors.orange,
                label: 'Batches Saved',
                value: '${c.savedFiles.length}',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // PROGRESS BAR 1: Current City & Contractor Website Crawl Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    c.isHarvestingLinks
                        ? '1. Harvesting search result links: ${c.currentSitesTotal} links found so far...'
                        : isCrawling
                            ? '1. Current Batch Crawl: ${c.currentSitesVisited} of ${c.currentSitesTotal} websites checked'
                            : '1. Current Batch Progress',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    c.isHarvestingLinks
                        ? 'Paginating search engine...'
                        : '${(c.currentCrawlProgress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: c.isHarvestingLinks ? Colors.blue : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: c.isHarvestingLinks
                    ? const LinearProgressIndicator(minHeight: 6)
                    : LinearProgressIndicator(
                        value: c.currentCrawlProgress,
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                      ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // PROGRESS BAR 2: Overall Queue Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '2. Overall Queue Progress (${c.completedContractorQueries} of ${c.totalContractorQueries} contractor queries)',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    '${(c.overallProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: c.overallProgress,
                  minHeight: 5,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
