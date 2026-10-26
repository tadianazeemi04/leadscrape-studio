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
  String _currentState = '';
  String _currentCity = '';

  // Progress metrics
  bool _isHarvestingLinks = false;
  int _currentSitesTotal = 0;
  int _currentSitesVisited = 0;
  int _completedContractorQueries = 0;
  int _websitesVisitedTotal = 0;

  // Storage
  final List<LogEntry> _logs = [];
  final List<EmailRecord> _allDiscoveredRecords = [];
  final List<String> _savedFiles = [];

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
  String get currentContractor => _currentContractor;
  String get currentState => _currentState;
  String get currentCity => _currentCity;

  bool get isHarvestingLinks => _isHarvestingLinks;
  int get currentSitesTotal => _currentSitesTotal;
  int get currentSitesVisited => _currentSitesVisited;
  int get completedContractorQueries => _completedContractorQueries;
  int get websitesVisited => _websitesVisitedTotal;
  int get totalEmailsFound => _allDiscoveredRecords.map((r) => r.email).toSet().length;

  List<LogEntry> get logs => List.unmodifiable(_logs);
  List<EmailRecord> get allDiscoveredRecords => List.unmodifiable(_allDiscoveredRecords);
  List<String> get savedFiles => List.unmodifiable(_savedFiles);

  int get totalContractorQueries {
    int totalCities = 0;
    for (var cities in _task.statesAndCities.values) {
      totalCities += cities.length;
    }
    return _task.contractorTypes.length * totalCities;
  }

  /// Progress fraction for the active query's website crawl (0.0 to 1.0)
  double get currentCrawlProgress {
    if (_currentSitesTotal <= 0) return 0.0;
    return (_currentSitesVisited / _currentSitesTotal).clamp(0.0, 1.0);
  }

  /// Progress fraction across the entire queue of queries (0.0 to 1.0)
  double get overallProgress {
    if (totalContractorQueries <= 0) return 0.0;
    return (_completedContractorQueries / totalContractorQueries).clamp(0.0, 1.0);
  }

  void updateConfig(ScraperConfig newConfig) {
    _config = newConfig;
    notifyListeners();
  }

  void updateContractors(List<String> list) {
    _task.contractorTypes = list;
    notifyListeners();
  }

  void updateStatesAndCities(Map<String, List<String>> map) {
    _task.statesAndCities = map;
    notifyListeners();
  }

  void _log(String message, LogType type) {
    final entry = LogEntry(message: message, type: type);
    _logs.add(entry);
    if (_logs.length > 3000) {
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
    _completedContractorQueries = 0;
    _websitesVisitedTotal = 0;
    _currentSitesTotal = 0;
    _currentSitesVisited = 0;
    notifyListeners();
  }

  /// Start the full automated extraction workflow adhering to:
  /// For City -> For each Contractor in that city -> Exhaustively harvest all web links (300-1000s) ->
  /// Discard Google apps -> Crawl all links -> Move to next contractor of same city -> Move to next city!
  Future<void> startScraping() async {
    if (_status == ScrapeStatus.running) return;

    if (_task.contractorTypes.isEmpty) {
      _log('Please provide at least one contractor type.', LogType.error);
      return;
    }
    if (_task.statesAndCities.isEmpty) {
      _log('Please provide at least one state and city.', LogType.error);
      return;
    }

    _status = ScrapeStatus.running;
    _completedContractorQueries = 0;
    _websitesVisitedTotal = 0;
    notifyListeners();

    _log('=== LEAD EXTRACTION PIPELINE STARTED ===', LogType.info);
    _log('Total queries in queue: $totalContractorQueries', LogType.info);
    _log('Links limit: ${_config.maxLinksPerSearch == 0 ? "Exhaustive / All available (300-1000+)" : "${_config.maxLinksPerSearch} max"}', LogType.info);
    _log('Concurrency workers: ${_config.concurrency}', LogType.info);

    try {
      // Loop: State -> City -> Contractor in same City -> Repeat
      for (var stateEntry in _task.statesAndCities.entries) {
        if (_status == ScrapeStatus.stopped) break;

        final state = stateEntry.key;
        final cities = stateEntry.value;

        for (var city in cities) {
          if (_status == ScrapeStatus.stopped) break;

          _currentState = state;
          _currentCity = city;
          _log('=====================================================', LogType.info);
          _log('Entering Location: $city, $state (${_task.contractorTypes.length} contractor categories to crawl)', LogType.info);
          _log('=====================================================', LogType.info);

          for (var contractor in _task.contractorTypes) {
            // Check pause/stop
            while (_status == ScrapeStatus.paused) {
              await Future.delayed(const Duration(milliseconds: 400));
            }
            if (_status == ScrapeStatus.stopped) break;

            _currentContractor = contractor;
            _isHarvestingLinks = true;
            _currentSitesTotal = 0;
            _currentSitesVisited = 0;
            notifyListeners();

            // 1. Construct exact search query
            final query = SearchService.buildQuery(
              contractor: contractor,
              city: city,
              state: state,
            );

            _log('>>> SEARCHING: "$query"', LogType.search);

            // 2. Multi-page exhaustive search to extract ALL web links (300s, 500s, 1000s)
            final searchLinks = await SearchService.searchWeb(
              query: query,
              engine: _config.searchEngine,
              filterDirectories: _config.filterDirectories,
              maxResults: _config.maxLinksPerSearch, // 0 = Unlimited
              onProgress: (linksFound, pages) {
                _currentSitesTotal = linksFound;
                _log('Harvesting search results: $linksFound links discovered across $pages pages...', LogType.info);
                notifyListeners();
              },
            );

            _isHarvestingLinks = false;
            _currentSitesTotal = searchLinks.length;
            _currentSitesVisited = 0;
            notifyListeners();

            _log('Search complete: Found ${searchLinks.length} contractor websites to check (excluding all Google apps)', LogType.success);

            final List<EmailRecord> cityContractorRecords = [];

            // 3. Crawl ALL extracted web links using high-speed concurrent pool
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

                      if (!cityContractorRecords.contains(record)) {
                        cityContractorRecords.add(record);
                        _allDiscoveredRecords.add(record);
                        _log('[$completedIndex/$total] FOUND EMAIL: $email [$source] (${link.domain})', LogType.emailFound);
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

            // 4. Save results for this contractor in this city
            if (cityContractorRecords.isNotEmpty) {
              final saved = await FileService.saveCityContractorResult(
                contractor: contractor,
                city: city,
                state: state,
                records: cityContractorRecords,
                customBaseDir: _config.outputFolderPath,
              );
              _savedFiles.add(saved.path);
              _log('>>> SAVED BATCH FILE: ${saved.path} (${cityContractorRecords.length} unique emails)', LogType.success);
            } else {
              _log('Completed $contractor in $city, $state (0 emails found)', LogType.warning);
            }

            _completedContractorQueries++;
            notifyListeners();

            _log('Done with $contractor in $city. Moving to next contractor in the same city...', LogType.info);
            // Continues immediately to the NEXT CONTRACTOR in the SAME CITY!
          }

          _log('All contractors completed for city: $city, $state. Moving to next city...', LogType.success);
        }
      }

      if (_status != ScrapeStatus.stopped) {
        _status = ScrapeStatus.completed;
        _log('=== ALL EXTRACTION JOBS COMPLETED SUCCESSFULLY ===', LogType.success);
      }
    } catch (e, stack) {
      _status = ScrapeStatus.stopped;
      _log('Critical error during execution: $e', LogType.error);
      debugPrint('$e\n$stack');
    } finally {
      notifyListeners();
    }
  }

  void pauseScraping() {
    if (_status == ScrapeStatus.running) {
      _status = ScrapeStatus.paused;
      _log('Process paused by user.', LogType.warning);
      notifyListeners();
    }
  }

  void resumeScraping() {
    if (_status == ScrapeStatus.paused) {
      _status = ScrapeStatus.running;
      _log('Process resumed.', LogType.info);
      notifyListeners();
    }
  }

  void stopScraping() {
    _status = ScrapeStatus.stopped;
    _log('Process stopped by user.', LogType.warning);
    notifyListeners();
  }
}
