import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/contractor_task.dart';
import '../models/email_record.dart';
import '../models/log_entry.dart';
import '../models/scraper_config.dart';
import '../services/search_service.dart';
import '../services/website_crawler.dart';
import '../services/file_service.dart';

enum ScrapeStatus {
  idle,
  running,
  paused,
  stopped,
  completed,
}

class ScraperController extends ChangeNotifier {
  ScrapeStatus _status = ScrapeStatus.idle;
  ScraperConfig _config = ScraperConfig();
  final ContractorTask _task = ContractorTask.defaultData();

  // Active targets
  String _currentContractor = '';
  String _currentCity = '';

  // Progress tracking
  bool _isHarvestingLinks = false;
  String _activeHarvestQuery = '';
  int _currentSitesTotal = 0;
  int _currentSitesVisited = 0;
  int _completedQueriesCount = 0;
  int _websitesVisitedTotal = 0;

  // Single Master Output Batch Files
  MasterBatchFiles? _activeMasterBatch;
  final List<String> _savedFiles = [];

  // Storage
  final List<LogEntry> _logs = [];
  final List<EmailRecord> _allDiscoveredRecords = [];

  ScraperController() {
    _initDefaultPath();
  }

  Future<void> _initDefaultPath() async {
    try {
      final dir = await FileService.getDefaultOutputDirectory();
      _config.outputFolderPath = dir.path;
      notifyListeners();
    } catch (_) {}
  }

  // Getters
  ScrapeStatus get status => _status;
  ScraperConfig get config => _config;
  ContractorTask get task => _task;
  String get manualState => _task.manualState;
  String get currentState => _task.manualState;
  List<String> get activeCities => List.unmodifiable(_task.activeCities);
  List<String> get contractorTypes => List.unmodifiable(_task.contractorTypes);

  String get currentContractor => _currentContractor;
  String get currentCity => _currentCity;
  String get activeHarvestQuery => _activeHarvestQuery;

  bool get isHarvestingLinks => _isHarvestingLinks;
  int get currentSitesTotal => _currentSitesTotal;
  int get currentSitesVisited => _currentSitesVisited;
  int get completedQueriesCount => _completedQueriesCount;
  int get completedContractorQueries => _completedQueriesCount;
  int get websitesVisited => _websitesVisitedTotal;
  int get totalEmailsFound => _allDiscoveredRecords.map((r) => r.email.toLowerCase().trim()).toSet().length;

  int get totalContractorQueries => totalQueriesInSession;

  String? get masterTxtPath => _activeMasterBatch?.txtFile.path;
  String? get masterCsvPath => _activeMasterBatch?.csvFile.path;
  List<String> get savedFiles => List.unmodifiable(_savedFiles);

  List<LogEntry> get logs => List.unmodifiable(_logs);
  List<EmailRecord> get allDiscoveredRecords => List.unmodifiable(_allDiscoveredRecords);

  int get totalQueriesInSession {
    return _task.contractorTypes.length * _task.activeCities.length;
  }

  double get currentCrawlProgress {
    if (_currentSitesTotal <= 0) return 0.0;
    return (_currentSitesVisited / _currentSitesTotal).clamp(0.0, 1.0);
  }

  double get overallProgress {
    if (totalQueriesInSession <= 0) return 0.0;
    return (_completedQueriesCount / totalQueriesInSession).clamp(0.0, 1.0);
  }

  // State Management Updates
  void updateManualState(String newState) {
    _task.manualState = newState.trim();
    notifyListeners();
  }

  void addCity(String city) {
    final clean = city.trim();
    if (clean.isNotEmpty && !_task.activeCities.contains(clean)) {
      _task.activeCities.add(clean);
      notifyListeners();
    }
  }

  void removeCity(String city) {
    _task.activeCities.remove(city);
    notifyListeners();
  }

  void setCities(List<String> cities) {
    _task.activeCities = cities.where((c) => c.trim().isNotEmpty).toList();
    notifyListeners();
  }

  void addContractor(String contractor) {
    final clean = contractor.trim();
    if (clean.isNotEmpty && !_task.contractorTypes.contains(clean)) {
      _task.contractorTypes.add(clean);
      notifyListeners();
    }
  }

  void removeContractor(String contractor) {
    _task.contractorTypes.remove(contractor);
    notifyListeners();
  }

  void setContractors(List<String> contractors) {
    _task.contractorTypes = contractors.where((c) => c.trim().isNotEmpty).toList();
    notifyListeners();
  }

  void updateConfig(ScraperConfig newConfig) {
    _config = newConfig;
    notifyListeners();
  }

  void _log(String message, LogType type) {
    final entry = LogEntry(message: message, type: type);
    _logs.add(entry);
    if (_logs.length > 3500) {
      _logs.removeRange(0, 500);
    }
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  void clearResults() {
    _allDiscoveredRecords.clear();
    _savedFiles.clear();
    _completedQueriesCount = 0;
    _websitesVisitedTotal = 0;
    _currentSitesTotal = 0;
    _currentSitesVisited = 0;
    _activeMasterBatch = null;
    notifyListeners();
  }

  /// Start the full automated extraction workflow:
  /// Creates ONE master TXT and CSV for the session.
  /// For City -> For each Contractor in same city -> Harvest all pages (300+ links) ->
  /// Crawl all links -> Append to single master files -> Move to next contractor -> Move to next city!
  Future<void> startScraping() async {
    if (_status == ScrapeStatus.running) return;

    if (_task.manualState.trim().isEmpty) {
      _log('Please enter a State name (e.g. Texas, Florida).', LogType.error);
      return;
    }
    if (_task.activeCities.isEmpty) {
      _log('Please add at least one city in the Cities list.', LogType.error);
      return;
    }
    if (_task.contractorTypes.isEmpty) {
      _log('Please provide at least one contractor type.', LogType.error);
      return;
    }

    _status = ScrapeStatus.running;
    _completedQueriesCount = 0;
    _websitesVisitedTotal = 0;
    notifyListeners();

    // 1. Initialize Single Master Output Files for this started batch
    final state = _task.manualState.trim();
    _activeMasterBatch = await FileService.initMasterBatchSession(
      state: state,
      customBaseDir: _config.outputFolderPath,
    );
    if (!_savedFiles.contains(_activeMasterBatch!.txtFile.path)) {
      _savedFiles.add(_activeMasterBatch!.txtFile.path);
      _savedFiles.add(_activeMasterBatch!.csvFile.path);
    }

    _log('=== BATCH EXTRACTION PIPELINE INITIALIZED ===', LogType.info);
    _log('State: $state | Cities: ${_task.activeCities.length} | Contractors: ${_task.contractorTypes.length}', LogType.info);
    _log('Total searches to execute: $totalQueriesInSession', LogType.info);
    _log('Target links per search: Minimum ${_config.minLinksTarget}+ unique websites across all search pages', LogType.info);
    _log('Master Output TXT: ${_activeMasterBatch!.txtFile.path}', LogType.success);
    _log('Master Output CSV: ${_activeMasterBatch!.csvFile.path}', LogType.success);

    try {
      // Loop: City -> Contractor in same City -> All Pages -> Crawl -> Next Contractor -> Next City
      for (var city in _task.activeCities) {
        if (_status == ScrapeStatus.stopped) break;

        _currentCity = city;
        _log('-----------------------------------------------------', LogType.info);
        _log('>>> CURRENT LOCATION: $city, $state', LogType.info);
        _log('-----------------------------------------------------', LogType.info);

        for (var contractor in _task.contractorTypes) {
          while (_status == ScrapeStatus.paused) {
            await Future.delayed(const Duration(milliseconds: 400));
          }
          if (_status == ScrapeStatus.stopped) break;

          _currentContractor = contractor;
          _isHarvestingLinks = true;
          _currentSitesTotal = 0;
          _currentSitesVisited = 0;
          _activeHarvestQuery = SearchService.buildQuery(contractor: contractor, city: city, state: state);
          notifyListeners();

          _log('Starting Deep Search: "$_activeHarvestQuery"', LogType.search);

          // 2. Multi-page exhaustive search to extract ALL web links (at least 300+ links across pages 1 to N)
          final searchLinks = await SearchService.searchWebExhaustive(
            contractor: contractor,
            city: city,
            state: state,
            minLinksTarget: _config.minLinksTarget,
            filterDirectories: _config.filterDirectories,
            onProgress: (linksFound, pagesScanned, activeQ) {
              _currentSitesTotal = linksFound;
              _log('Paginating search results (Page $pagesScanned): $linksFound organic links extracted...', LogType.info);
              notifyListeners();
            },
          );

          _isHarvestingLinks = false;
          _currentSitesTotal = searchLinks.length;
          _currentSitesVisited = 0;
          notifyListeners();

          _log('Search complete! Extracted ${searchLinks.length} websites across all pages (Google apps filtered)', LogType.success);

          final List<EmailRecord> batchDiscoveredRecords = [];

          // 3. Crawl EVERY SINGLE ONE of the extracted web links using concurrent worker pool
          if (searchLinks.isNotEmpty) {
            await WebsiteCrawler.crawlWebsitesPool(
              links: searchLinks,
              concurrency: _config.concurrency,
              checkFacebook: _config.checkFacebook,
              delaySeconds: _config.delayBetweenRequestsSeconds,
              shouldStop: () => _status == ScrapeStatus.stopped,
              isPaused: () => _status == ScrapeStatus.paused,
              onSiteDone: (link, crawlResult, completedIndex, total) async {
                _currentSitesVisited = completedIndex;
                _websitesVisitedTotal++;

                if (crawlResult.emails.isNotEmpty) {
                  for (var email in crawlResult.emails) {
                    final source = crawlResult.emailSources[email] ?? 'Website';
                    final record = EmailRecord(
                      email: email,
                      contractorType: contractor,
                      city: city,
                      state: state,
                      websiteUrl: link.url,
                      facebookUrl: crawlResult.facebookUrl,
                      source: source,
                    );

                    if (!batchDiscoveredRecords.contains(record)) {
                      batchDiscoveredRecords.add(record);
                      _allDiscoveredRecords.add(record);

                      // Append immediately to the Single Master TXT and CSV
                      await FileService.appendToMasterBatch(
                        masterBatch: _activeMasterBatch!,
                        newRecords: [record],
                      );

                      _log('[$completedIndex/$total] EXTRACTED EMAIL: $email [$source] (${link.domain})', LogType.emailFound);
                    }
                  }
                }

                if (crawlResult.facebookUrl != null && crawlResult.facebookUrl!.isNotEmpty) {
                  _log('[$completedIndex/$total] Facebook Page: ${crawlResult.facebookUrl}', LogType.facebook);
                }

                notifyListeners();
              },
            );
          }

          _completedQueriesCount++;
          notifyListeners();

          _log('Completed $contractor in $city ($searchLinks links visited, ${batchDiscoveredRecords.length} emails added to master file).', LogType.success);
          _log('Advancing to next contractor in the same city: $city...', LogType.info);
          // Immediately moves to the NEXT contractor in the SAME city!
        }

        _log('All contractor searches completed for $city! Moving to next city...', LogType.success);
      }

      if (_status != ScrapeStatus.stopped) {
        _status = ScrapeStatus.completed;
        _log('=================================================================', LogType.success);
        _log('BATCH COMPLETED! All unique emails saved in: ${_activeMasterBatch?.txtFile.path}', LogType.success);
        _log('Website visit report saved in: ${_activeMasterBatch?.csvFile.path}', LogType.success);
        _log('=================================================================', LogType.success);
      }
    } catch (e, stack) {
      _status = ScrapeStatus.stopped;
      _log('Critical error: $e', LogType.error);
      debugPrint('$e\n$stack');
    } finally {
      notifyListeners();
    }
  }

  void pauseScraping() {
    if (_status == ScrapeStatus.running) {
      _status = ScrapeStatus.paused;
      _log('Scraping paused.', LogType.warning);
      notifyListeners();
    }
  }

  void resumeScraping() {
    if (_status == ScrapeStatus.paused) {
      _status = ScrapeStatus.running;
      _log('Scraping resumed.', LogType.info);
      notifyListeners();
    }
  }

  void stopScraping() {
    _status = ScrapeStatus.stopped;
    _log('Scraping stopped.', LogType.warning);
    notifyListeners();
  }
}
