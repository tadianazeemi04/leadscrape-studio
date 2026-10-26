import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class SearchResultLink {
  final String title;
  final String url;
  final String domain;

  SearchResultLink({
    required this.title,
    required this.url,
    required this.domain,
  });
}

class SearchService {
  static const List<String> _userAgents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:125.0) Gecko/20100101 Firefox/125.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_4_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4.1 Safari/605.1.15',
  ];

  /// Comprehensive blocklist of Google apps, search engines, and internal services
  static final Set<String> _searchEngineAndAppDomains = {
    'google.com',
    'google.co',
    'google.ca',
    'google.co.uk',
    'google.com.au',
    'google.de',
    'google.fr',
    'google.es',
    'google.it',
    'google.nl',
    'gstatic.com',
    'googleapis.com',
    'googleusercontent.com',
    'youtube.com',
    'youtu.be',
    'maps.google.com',
    'play.google.com',
    'policies.google.com',
    'support.google.com',
    'accounts.google.com',
    'news.google.com',
    'mail.google.com',
    'drive.google.com',
    'docs.google.com',
    'photos.google.com',
    'calendar.google.com',
    'duckduckgo.com',
    'bing.com',
    'msn.com',
    'microsoft.com',
    'yahoo.com',
    'w3.org',
    'schema.org',
    'cloudflare.com',
  };

  static final Set<String> _directoryAggregatorDomains = {
    'yelp.com',
    'yellowpages.com',
    'angieslist.com',
    'angi.com',
    'bbb.org',
    'thumbtack.com',
    'homeadvisor.com',
    'houzz.com',
    'wikipedia.org',
    'mapquest.com',
    'superpages.com',
    'chamberofcommerce.com',
    'manta.com',
    'linkedin.com',
    'instagram.com',
    'twitter.com',
    'x.com',
    'tiktok.com',
    'pinterest.com',
  };

  /// Constructs the standard search query string as specified:
  /// "[contractors_name_list] contractors in [City_name_list] [State_name_change_when_cities_are_covered] USA"
  static String buildQuery({
    required String contractor,
    required String city,
    required String state,
  }) {
    return '$contractor contractors in $city $state USA';
  }

  /// Exhaustively searches the web across multiple paginated result pages
  /// to harvest ALL available contractor website links (hundreds or thousands),
  /// while strictly excluding Google apps and internal services.
  static Future<List<SearchResultLink>> searchWeb({
    required String query,
    String engine = 'duckduckgo',
    bool filterDirectories = true,
    int maxResults = 0, // 0 means Unlimited / All available
    void Function(int linksFound, int pagesScanned)? onProgress,
  }) async {
    final List<SearchResultLink> results = [];
    final Set<String> seenDomains = {};
    int pagesScanned = 0;

    final userAgent = _userAgents[DateTime.now().millisecond % _userAgents.length];

    // 1. Primary Engine Multi-Page Harvesting
    if (engine == 'google') {
      await _harvestGooglePages(
        query: query,
        userAgent: userAgent,
        results: results,
        seenDomains: seenDomains,
        filterDirectories: filterDirectories,
        maxResults: maxResults,
        onPageDone: (links, pages) {
          pagesScanned = pages;
          onProgress?.call(links, pagesScanned);
        },
      );
    } else if (engine == 'bing') {
      await _harvestBingPages(
        query: query,
        userAgent: userAgent,
        results: results,
        seenDomains: seenDomains,
        filterDirectories: filterDirectories,
        maxResults: maxResults,
        onPageDone: (links, pages) {
          pagesScanned = pages;
          onProgress?.call(links, pagesScanned);
        },
      );
    } else {
      // Default / Recommended: DuckDuckGo multi-page pagination
      await _harvestDuckDuckGoPages(
        query: query,
        userAgent: userAgent,
        results: results,
        seenDomains: seenDomains,
        filterDirectories: filterDirectories,
        maxResults: maxResults,
        onPageDone: (links, pages) {
          pagesScanned = pages;
          onProgress?.call(links, pagesScanned);
        },
      );
    }

    // 2. Supplementary Harvesting: If maxResults == 0 (unlimited) or user wants 300+
    // query secondary engines to maximize volume into hundreds/thousands of unique links
    if ((maxResults == 0 || results.length < maxResults) && results.length < 500) {
      if (engine != 'bing') {
        await _harvestBingPages(
          query: query,
          userAgent: userAgent,
          results: results,
          seenDomains: seenDomains,
          filterDirectories: filterDirectories,
          maxResults: maxResults,
          onPageDone: (links, pages) {
            onProgress?.call(links, pagesScanned + pages);
          },
        );
      }
      if (engine != 'duckduckgo' && (maxResults == 0 || results.length < maxResults)) {
        await _harvestDuckDuckGoPages(
          query: query,
          userAgent: userAgent,
          results: results,
          seenDomains: seenDomains,
          filterDirectories: filterDirectories,
          maxResults: maxResults,
          onPageDone: (links, pages) {
            onProgress?.call(links, pagesScanned + pages);
          },
        );
      }
    }

    return results;
  }

  /// Paginate Google search (start = 0, 100, 200, 300, 400...)
  static Future<void> _harvestGooglePages({
    required String query,
    required String userAgent,
    required List<SearchResultLink> results,
    required Set<String> seenDomains,
    required bool filterDirectories,
    required int maxResults,
    required void Function(int linksFound, int pagesScanned) onPageDone,
  }) async {
    final client = http.Client();
    int page = 0;
    const maxGooglePages = 10; // Up to ~500-1000 results

    while (page < maxGooglePages) {
      if (maxResults > 0 && results.length >= maxResults) break;

      final start = page * 100;
      final url = Uri.parse(
          'https://www.google.com/search?q=${Uri.encodeComponent(query)}&num=100&start=$start&hl=en');

      try {
        final response = await client.get(
          url,
          headers: {
            'User-Agent': userAgent,
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
          },
        ).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final doc = html_parser.parse(response.body);
          final rawLinks = _extractGoogleLinks(doc);
          final added = _filterAndAdd(
            rawLinks,
            results,
            seenDomains,
            filterDirectories,
            maxResults,
          );

          page++;
          onPageDone(results.length, page);

          // If this page yielded no new links, Google has reached the end of results
          if (added == 0) break;

          // Short delay between search engine pages
          await Future.delayed(const Duration(milliseconds: 600));
        } else {
          break;
        }
      } catch (_) {
        break;
      }
    }
    client.close();
  }

  /// Paginate Bing search (first = 1, 51, 101, 151, 201...)
  static Future<void> _harvestBingPages({
    required String query,
    required String userAgent,
    required List<SearchResultLink> results,
    required Set<String> seenDomains,
    required bool filterDirectories,
    required int maxResults,
    required void Function(int linksFound, int pagesScanned) onPageDone,
  }) async {
    final client = http.Client();
    int page = 0;
    const maxBingPages = 15; // Up to ~750 links

    while (page < maxBingPages) {
      if (maxResults > 0 && results.length >= maxResults) break;

      final first = (page * 50) + 1;
      final url = Uri.parse(
          'https://www.bing.com/search?q=${Uri.encodeComponent(query)}&first=$first&count=50');

      try {
        final response = await client.get(
          url,
          headers: {
            'User-Agent': userAgent,
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final doc = html_parser.parse(response.body);
          final rawLinks = _extractBingLinks(doc);
          final added = _filterAndAdd(
            rawLinks,
            results,
            seenDomains,
            filterDirectories,
            maxResults,
          );

          page++;
          onPageDone(results.length, page);

          if (added == 0) break;
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          break;
        }
      } catch (_) {
        break;
      }
    }
    client.close();
  }

  /// Paginate DuckDuckGo HTML search
  static Future<void> _harvestDuckDuckGoPages({
    required String query,
    required String userAgent,
    required List<SearchResultLink> results,
    required Set<String> seenDomains,
    required bool filterDirectories,
    required int maxResults,
    required void Function(int linksFound, int pagesScanned) onPageDone,
  }) async {
    final client = http.Client();
    int page = 0;
    const maxDDGPages = 10;

    while (page < maxDDGPages) {
      if (maxResults > 0 && results.length >= maxResults) break;

      final s = page * 30;
      final url = Uri.parse(
          'https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(query)}&s=$s');

      try {
        final response = await client.get(
          url,
          headers: {
            'User-Agent': userAgent,
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final doc = html_parser.parse(response.body);
          final rawLinks = _extractDuckDuckGoLinks(doc);
          final added = _filterAndAdd(
            rawLinks,
            results,
            seenDomains,
            filterDirectories,
            maxResults,
          );

          page++;
          onPageDone(results.length, page);

          if (added == 0) break;
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          break;
        }
      } catch (_) {
        break;
      }
    }
    client.close();
  }

  static List<Map<String, String>> _extractGoogleLinks(dynamic doc) {
    final List<Map<String, String>> links = [];
    final anchors = doc.querySelectorAll('a[href]');

    for (var a in anchors) {
      var href = a.attributes['href'] ?? '';
      final title = a.text.trim();

      // Unwrap Google redirect (/url?q=...)
      if (href.startsWith('/url?') || href.contains('url?q=')) {
        final uri = Uri.tryParse(href.startsWith('http') ? href : 'https://www.google.com$href');
        final target = uri?.queryParameters['q'];
        if (target != null && target.isNotEmpty) {
          href = target;
        }
      }

      if (href.startsWith('http')) {
        links.add({'title': title, 'url': href});
      }
    }
    return links;
  }

  static List<Map<String, String>> _extractBingLinks(dynamic doc) {
    final List<Map<String, String>> links = [];
    final items = doc.querySelectorAll('li.b_algo h2 a, a[href]');

    for (var a in items) {
      final href = a.attributes['href'] ?? '';
      final title = a.text.trim();
      if (href.startsWith('http')) {
        links.add({'title': title, 'url': href});
      }
    }
    return links;
  }

  static List<Map<String, String>> _extractDuckDuckGoLinks(dynamic doc) {
    final List<Map<String, String>> links = [];
    final anchors = doc.querySelectorAll('a.result__url, a.result__a, div.result__body a, a[href]');

    for (var a in anchors) {
      var rawHref = a.attributes['href'] ?? '';
      final title = a.text.trim();

      if (rawHref.contains('uddg=')) {
        final uri = Uri.tryParse(rawHref.startsWith('http') ? rawHref : 'https://duckduckgo.com$rawHref');
        final target = uri?.queryParameters['uddg'];
        if (target != null && target.isNotEmpty) {
          rawHref = target;
        }
      }

      if (rawHref.startsWith('http')) {
        links.add({'title': title, 'url': rawHref});
      }
    }
    return links;
  }

  static int _filterAndAdd(
    List<Map<String, String>> rawLinks,
    List<SearchResultLink> targetList,
    Set<String> seenDomains,
    bool filterDirectories,
    int maxResults,
  ) {
    int addedCount = 0;

    for (var item in rawLinks) {
      if (maxResults > 0 && targetList.length >= maxResults) break;

      final url = item['url'] ?? '';
      final title = item['title'] ?? '';

      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        continue;
      }

      final host = uri.host.toLowerCase().replaceAll(RegExp(r'^www\.'), '');
      if (host.isEmpty) continue;

      // STRICT GOOGLE APP & SEARCH ENGINE FILTER
      if (_isDomainBlocked(host, _searchEngineAndAppDomains)) {
        continue;
      }

      // Filter Aggregators/Directories if configured
      if (filterDirectories && _isDomainBlocked(host, _directoryAggregatorDomains)) {
        continue;
      }

      // Deduplicate by root domain so we only crawl one URL per contractor
      if (seenDomains.contains(host)) {
        continue;
      }

      seenDomains.add(host);
      targetList.add(SearchResultLink(
        title: title.isEmpty ? host : title,
        url: url,
        domain: host,
      ));
      addedCount++;
    }

    return addedCount;
  }

  static bool _isDomainBlocked(String host, Set<String> blocklist) {
    for (var blocked in blocklist) {
      if (host == blocked || host.endsWith('.$blocked')) {
        return true;
      }
    }
    return false;
  }
}
