import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'email_extractor.dart';
import 'facebook_service.dart';
import 'search_service.dart';

class CrawlResult {
  final String websiteUrl;
  final Set<String> emails;
  final String? facebookUrl;
  final Map<String, String> emailSources; // email -> 'Homepage', 'Contact Page', 'Facebook'
  final bool success;

  CrawlResult({
    required this.websiteUrl,
    required this.emails,
    this.facebookUrl,
    required this.emailSources,
    this.success = true,
  });
}

class WebsiteCrawler {
  static const List<String> _userAgents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:125.0) Gecko/20100101 Firefox/125.0',
  ];

  /// Crawls the given website: Homepage, Contact Page (if needed), and Facebook
  static Future<CrawlResult> crawlWebsite({
    required String targetUrl,
    bool checkFacebook = true,
    int timeoutSeconds = 8,
  }) async {
    final Set<String> foundEmails = {};
    final Map<String, String> emailSources = {};
    String? facebookUrl;

    final uri = Uri.tryParse(targetUrl);
    if (uri == null || !uri.hasScheme) {
      return CrawlResult(
        websiteUrl: targetUrl,
        emails: foundEmails,
        emailSources: emailSources,
        success: false,
      );
    }

    final client = http.Client();
    final userAgent = _userAgents[DateTime.now().millisecond % _userAgents.length];

    try {
      // 1. Fetch Homepage
      final response = await client.get(
        uri,
        headers: {
          'User-Agent': userAgent,
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final html = response.body;
        final doc = html_parser.parse(html);

        // Extract emails from homepage
        final homeEmails = EmailExtractor.extractEmails(html, doc);
        for (var email in homeEmails) {
          foundEmails.add(email);
          emailSources[email] = 'Website Homepage';
        }

        // Find Facebook link
        if (checkFacebook) {
          facebookUrl = FacebookService.findFacebookPageUrl(html);
        }

        // 2. Discover Contact / About Us page if homepage had no emails
        if (foundEmails.isEmpty) {
          final contactUrls = _findContactLinks(doc, uri);
          for (var contactUri in contactUrls.take(2)) {
            try {
              final contactRes = await client.get(
                contactUri,
                headers: {'User-Agent': userAgent},
              ).timeout(Duration(seconds: timeoutSeconds));

              if (contactRes.statusCode == 200) {
                final contactDoc = html_parser.parse(contactRes.body);
                final contactEmails =
                    EmailExtractor.extractEmails(contactRes.body, contactDoc);

                for (var email in contactEmails) {
                  foundEmails.add(email);
                  emailSources[email] = 'Website Contact Page';
                }

                // Check Facebook link in contact page if not found yet
                if (checkFacebook && facebookUrl == null) {
                  facebookUrl =
                      FacebookService.findFacebookPageUrl(contactRes.body);
                }
              }
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    // 3. Check Facebook if found and enabled
    if (checkFacebook && facebookUrl != null && facebookUrl.isNotEmpty) {
      try {
        final fbEmails = await FacebookService.extractEmailsFromFacebook(facebookUrl);
        for (var email in fbEmails) {
          foundEmails.add(email);
          emailSources.putIfAbsent(email, () => 'Facebook Page');
        }
      } catch (_) {}
    }

    client.close();

    return CrawlResult(
      websiteUrl: targetUrl,
      emails: foundEmails,
      facebookUrl: facebookUrl,
      emailSources: emailSources,
      success: foundEmails.isNotEmpty,
    );
  }

  /// High-speed Concurrent Crawler Pool for scanning hundreds or thousands of links
  static Future<void> crawlWebsitesPool({
    required List<SearchResultLink> links,
    required int concurrency,
    required bool checkFacebook,
    required double delaySeconds,
    required bool Function() shouldStop,
    required bool Function() isPaused,
    required Future<void> Function(SearchResultLink link, CrawlResult result, int completedIndex, int total) onSiteDone,
  }) async {
    int nextIndex = 0;
    int completedCount = 0;
    final total = links.length;

    Future<void> worker() async {
      while (true) {
        if (shouldStop()) break;

        while (isPaused()) {
          await Future.delayed(const Duration(milliseconds: 300));
        }

        if (nextIndex >= total) break;
        final currentIndex = nextIndex++;

        final link = links[currentIndex];
        final result = await crawlWebsite(
          targetUrl: link.url,
          checkFacebook: checkFacebook,
        );

        completedCount++;
        await onSiteDone(link, result, completedCount, total);

        if (delaySeconds > 0) {
          await Future.delayed(Duration(milliseconds: (delaySeconds * 1000).toInt()));
        }
      }
    }

    final workers = List.generate(
      concurrency.clamp(1, 16),
      (_) => worker(),
    );

    await Future.wait(workers);
  }

  static List<Uri> _findContactLinks(dom.Document doc, Uri baseUri) {
    final List<Uri> contactLinks = [];
    final anchors = doc.querySelectorAll('a[href]');

    for (var a in anchors) {
      final href = a.attributes['href']?.trim() ?? '';
      final text = a.text.toLowerCase().trim();

      if (href.isEmpty || href.startsWith('mailto:') || href.startsWith('tel:') || href.startsWith('#')) {
        continue;
      }

      final lowerHref = href.toLowerCase();
      final isContact = lowerHref.contains('contact') ||
          lowerHref.contains('about') ||
          text.contains('contact') ||
          text.contains('about');

      if (isContact) {
        try {
          final resolved = baseUri.resolve(href);
          // Only stay on the same domain
          if (resolved.host == baseUri.host && !contactLinks.contains(resolved)) {
            contactLinks.add(resolved);
          }
        } catch (_) {}
      }
    }

    return contactLinks;
  }
}
