import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'email_extractor.dart';

class FacebookService {
  static final RegExp _fbRegex = RegExp(
    r'https?:\/\/(?:www\.|m\.|mobile\.)?facebook\.com\/(?:pages\/[^\/]+\/)?([a-zA-Z0-9.\-_]+)\/?',
    caseSensitive: false,
  );

  static final Set<String> _invalidPaths = {
    'sharer',
    'share',
    'plugins',
    'dialog',
    'tr',
    'login',
    'help',
    'policies',
    'privacy',
    'hashtag',
    'events',
  };

  /// Find valid Facebook page URLs in an HTML document
  static String? findFacebookPageUrl(String htmlContent) {
    final matches = _fbRegex.allMatches(htmlContent);
    for (var match in matches) {
      final fullUrl = match.group(0) ?? '';
      final pageSlug = match.group(1)?.toLowerCase() ?? '';

      if (pageSlug.isEmpty || _invalidPaths.contains(pageSlug)) {
        continue;
      }

      // Clean URL
      var cleanUrl = fullUrl;
      if (cleanUrl.contains('?')) {
        cleanUrl = cleanUrl.split('?').first;
      }
      return cleanUrl;
    }
    return null;
  }

  /// Scrape public email from a Facebook business page
  static Future<Set<String>> extractEmailsFromFacebook(String facebookUrl) async {
    final Set<String> emails = {};

    try {
      final uri = Uri.tryParse(facebookUrl);
      if (uri == null) return emails;

      final client = http.Client();
      final response = await client.get(
        uri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body;
        final doc = html_parser.parse(body);

        // Check meta description & og tags
        final metaTags = doc.querySelectorAll('meta');
        for (var meta in metaTags) {
          final content = meta.attributes['content'] ?? '';
          final found = EmailExtractor.extractEmails(content);
          emails.addAll(found);
        }

        // Check full page body
        final bodyEmails = EmailExtractor.extractEmails(body, doc);
        emails.addAll(bodyEmails);
      }
    } catch (_) {
      // Facebook network/scrape errors should be handled silently
    }

    return emails;
  }
}
