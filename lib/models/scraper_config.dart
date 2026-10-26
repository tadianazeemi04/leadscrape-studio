class ScraperConfig {
  String searchEngine; // 'duckduckgo', 'google', 'bing'
  double delayBetweenRequestsSeconds;
  int maxLinksPerSearch; // 0 = Unlimited / All results (hundreds/thousands)
  int concurrency; // Number of parallel website crawlers (e.g. 5-10)
  bool filterDirectories;
  bool checkFacebook;
  String? outputFolderPath;

  ScraperConfig({
    this.searchEngine = 'duckduckgo',
    this.delayBetweenRequestsSeconds = 0.5,
    this.maxLinksPerSearch = 0, // 0 = Unlimited / all search results
    this.concurrency = 6,
    this.filterDirectories = true,
    this.checkFacebook = true,
    this.outputFolderPath,
  });

  ScraperConfig copyWith({
    String? searchEngine,
    double? delayBetweenRequestsSeconds,
    int? maxLinksPerSearch,
    int? concurrency,
    bool? filterDirectories,
    bool? checkFacebook,
    String? outputFolderPath,
  }) {
    return ScraperConfig(
      searchEngine: searchEngine ?? this.searchEngine,
      delayBetweenRequestsSeconds:
          delayBetweenRequestsSeconds ?? this.delayBetweenRequestsSeconds,
      maxLinksPerSearch: maxLinksPerSearch ?? this.maxLinksPerSearch,
      concurrency: concurrency ?? this.concurrency,
      filterDirectories: filterDirectories ?? this.filterDirectories,
      checkFacebook: checkFacebook ?? this.checkFacebook,
      outputFolderPath: outputFolderPath ?? this.outputFolderPath,
    );
  }
}
