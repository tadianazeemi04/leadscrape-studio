class ScraperConfig {
  String searchEngine; // 'deep_search', 'bing', 'duckduckgo'
  double delayBetweenRequestsSeconds;
  int minLinksTarget; // Target at least 300+ unique web links per search
  int concurrency; // Number of parallel website crawlers (e.g. 6-12)
  bool filterDirectories;
  bool checkFacebook;
  String? outputFolderPath;

  ScraperConfig({
    this.searchEngine = 'deep_search', // Exhaustive multi-page harvester
    this.delayBetweenRequestsSeconds = 0.3,
    this.minLinksTarget = 300, // At least 300 links per search
    this.concurrency = 8,
    this.filterDirectories = true,
    this.checkFacebook = true,
    this.outputFolderPath,
  });

  ScraperConfig copyWith({
    String? searchEngine,
    double? delayBetweenRequestsSeconds,
    int? minLinksTarget,
    int? concurrency,
    bool? filterDirectories,
    bool? checkFacebook,
    String? outputFolderPath,
  }) {
    return ScraperConfig(
      searchEngine: searchEngine ?? this.searchEngine,
      delayBetweenRequestsSeconds:
          delayBetweenRequestsSeconds ?? this.delayBetweenRequestsSeconds,
      minLinksTarget: minLinksTarget ?? this.minLinksTarget,
      concurrency: concurrency ?? this.concurrency,
      filterDirectories: filterDirectories ?? this.filterDirectories,
      checkFacebook: checkFacebook ?? this.checkFacebook,
      outputFolderPath: outputFolderPath ?? this.outputFolderPath,
    );
  }
}
