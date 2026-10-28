import 'dart:convert';
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
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:130.0) Gecko/20100101 Firefox/130.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_6_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15',
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
    'bing.com',
    'msn.com',
    'microsoft.com',
    'duckduckgo.com',
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

  /// Constructs the standard primary search query string as specified:
  /// "[contractors_name_list] contractors in [City_name_list] [State_name_change_when_cities_are_covered] USA"
  static String buildQuery({
    required String contractor,
    required String city,
    required String state,
  }) {
    return '$contractor contractors in $city $state USA';
  }

  /// Decodes Bing's Base64 obfuscated redirect URLs (`...&u=a1<BASE64>...`)
  static String? decodeBingUrl(String href) {
    try {
      final uri = Uri.tryParse(href);
      final uParam = uri?.queryParameters['u'];
      if (uParam != null && uParam.startsWith('a1')) {
        var base64Part = uParam.substring(2);
        while (base64Part.length % 4 != 0) {
          base64Part += '=';
        }
        return utf8.decode(base64.decode(base64Part));
      }
    } catch (_) {}
    return null;
  }

  /// Exhaustive Multi-Page Deep Search Engine:
  /// Paginates through all result pages (page 1, 2, 3... 20+) across query variations
  /// until at least [minLinksTarget] (default 300+) unique contractor websites are harvested.
  /// Filters out all Google apps and search engine internal links.
  static Future<List<SearchResultLink>> searchWebExhaustive({
    required String contractor,
    required String city,
    required String state,
    int minLinksTarget = 300,
    bool filterDirectories = true,
    void Function(int linksFound, int pagesScanned, String activeQuery)? onProgress,
  }) async {
    final List<SearchResultLink> results = [];
    final Set<String> seenDomains = {};
    int totalPagesScanned = 0;

    // Sub-query variations to guarantee 300+ unique results from all pagination depths
    final queryVariations = [
      '$contractor contractors in $city $state USA',
      '$contractor companies in $city $state USA',
      'best $contractor in $city $state',
      'local $contractor services $city $state',
      'licensed $contractor in $city $state USA',
      '$contractor repair and installation $city $state',
      '$contractor business $city $state contact email',
      'commercial and residential $contractor $city $state',
      'top rated $contractor $city $state USA',
    ];

    final client = http.Client();

    for (var query in queryVariations) {
      if (results.length >= minLinksTarget) break;

      final userAgent = _userAgents[DateTime.now().millisecond % _userAgents.length];

      // Paginate through 20 pages per query (first = 1, 21, 41, 61, 81 ... 401)
      for (int page = 0; page < 20; page++) {
        if (results.length >= minLinksTarget) break;

        final first = (page * 20) + 1;
        final url = Uri.parse(
          'https://www.bing.com/search?q=${Uri.encodeComponent(query)}&first=$first&FORM=PERE$page',
        );

        try {
          final res = await client.get(
            url,
            headers: {
              'User-Agent': userAgent,
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              'Accept-Language': 'en-US,en;q=0.9',
            },
          ).timeout(const Duration(seconds: 8));

          if (res.statusCode == 200) {
            final doc = html_parser.parse(res.body);
            final anchors = doc.querySelectorAll('li.b_algo h2 a, li.b_algo a[href]');
            int pageAdded = 0;

            for (var a in anchors) {
              final rawHref = a.attributes['href'] ?? '';
              final title = a.text.trim();
              final decodedUrl = decodeBingUrl(rawHref) ?? rawHref;

              if (decodedUrl.startsWith('http')) {
                final uri = Uri.tryParse(decodedUrl);
                if (uri == null) continue;

                final host = uri.host.toLowerCase().replaceAll(RegExp(r'^www\.'), '');
                if (host.isEmpty) continue;

                // STRICT FILTER: Exclude Google apps and search engine domains
                if (_isDomainBlocked(host, _searchEngineAndAppDomains)) continue;

                // FILTER: Exclude directory aggregators if enabled
                if (filterDirectories && _isDomainBlocked(host, _directoryAggregatorDomains)) continue;

                // Deduplicate by domain
                if (!seenDomains.contains(host)) {
                  seenDomains.add(host);
                  results.add(SearchResultLink(
                    title: title.isEmpty ? host : title,
                    url: decodedUrl,
                    domain: host,
                  ));
                  pageAdded++;
                }
              }
            }

            totalPagesScanned++;
            onProgress?.call(results.length, totalPagesScanned, query);

            if (pageAdded == 0 && page > 3) {
              // Reached end of results for this specific variation
              break;
            }

            // Polite jitter between page requests
            await Future.delayed(const Duration(milliseconds: 150));
          } else {
            break;
          }
        } catch (_) {
          break;
        }
      }

      // Also supplement with DuckDuckGo for additional organic diversity
      if (results.length < minLinksTarget) {
        try {
          final ddgUrl = Uri.parse('https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(query)}');
          final ddgRes = await client.get(
            ddgUrl,
            headers: {
              'User-Agent': userAgent,
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              'Accept-Language': 'en-US,en;q=0.9',
            },
          ).timeout(const Duration(seconds: 8));

          if (ddgRes.statusCode == 200) {
            final doc = html_parser.parse(ddgRes.body);
            final ddgAnchors = doc.querySelectorAll('a.result__url, a.result__a, div.result__body a');

            for (var a in ddgAnchors) {
              var href = a.attributes['href'] ?? '';
              final title = a.text.trim();

              if (href.contains('uddg=')) {
                final uri = Uri.tryParse(href.startsWith('http') ? href : 'https://duckduckgo.com$href');
                final target = uri?.queryParameters['uddg'];
                if (target != null && target.isNotEmpty) {
                  href = target;
                }
              }

              if (href.startsWith('http')) {
                final uri = Uri.tryParse(href);
                if (uri == null) continue;

                final host = uri.host.toLowerCase().replaceAll(RegExp(r'^www\.'), '');
                if (host.isEmpty) continue;

                if (_isDomainBlocked(host, _searchEngineAndAppDomains)) continue;
                if (filterDirectories && _isDomainBlocked(host, _directoryAggregatorDomains)) continue;

                if (!seenDomains.contains(host)) {
                  seenDomains.add(host);
                  results.add(SearchResultLink(
                    title: title.isEmpty ? host : title,
                    url: href,
                    domain: host,
                  ));
                }
              }
            }
            totalPagesScanned++;
            onProgress?.call(results.length, totalPagesScanned, query);
          }
        } catch (_) {}
      }
    }

    client.close();
    return results;
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
