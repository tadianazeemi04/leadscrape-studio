import 'package:html/dom.dart' as dom;

class EmailExtractor {
  // RFC 5322 compliant regex for detecting email addresses
  static final RegExp _emailRegExp = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
    caseSensitive: false,
  );

  static final Set<String> _invalidExtensions = {
    'png',
    'jpg',
    'jpeg',
    'gif',
    'svg',
    'webp',
    'bmp',
    'ico',
    'css',
    'js',
    'woff',
    'woff2',
    'ttf',
    'otf',
    'mp4',
    'webm',
    'pdf',
    'zip',
  };

  static final Set<String> _ignoredDomains = {
    'sentry.io',
    'wixpress.com',
    'example.com',
    'test.com',
    'domain.com',
    'email.com',
    'yourdomain.com',
    'sitename.com',
    'mysite.com',
    'bootstrap.com',
    'google.com',
    'gstatic.com',
    'facebook.com',
    'twitter.com',
    'instagram.com',
    'linkedin.com',
    'apple.com',
    'cloudflare.com',
    'gravatar.com',
  };

  /// Extracts clean, valid emails from raw HTML string or document
  static Set<String> extractEmails(String htmlContent, [dom.Document? document]) {
    final Set<String> results = {};

    // 1. Mailto links parsing (high confidence)
    if (document != null) {
      final mailtoLinks = document.querySelectorAll('a[href^="mailto:"]');
      for (var element in mailtoLinks) {
        final href = element.attributes['href'] ?? '';
        final cleanEmail = _cleanMailto(href);
        if (isValidEmail(cleanEmail)) {
          results.add(cleanEmail.toLowerCase());
        }
      }
    }

    // 2. Regex scan across full text / HTML content
    final matches = _emailRegExp.allMatches(htmlContent);
    for (var match in matches) {
      final candidate = match.group(0)?.trim() ?? '';
      if (isValidEmail(candidate)) {
        results.add(candidate.toLowerCase());
      }
    }

    return results;
  }

  static String _cleanMailto(String href) {
    var email = href.replaceFirst(RegExp(r'^mailto:', caseSensitive: false), '').trim();
    // Remove query params like ?subject=...
    if (email.contains('?')) {
      email = email.split('?').first;
    }
    return email.trim();
  }

  static bool isValidEmail(String email) {
    if (email.isEmpty || email.length > 100 || !email.contains('@')) {
      return false;
    }

    // Avoid trailing dots or special characters
    email = email.replaceAll(RegExp(r'[.,;:]+$'), '');

    final parts = email.split('@');
    if (parts.length != 2) return false;

    final user = parts[0];
    final domain = parts[1].toLowerCase();

    if (user.isEmpty || domain.isEmpty) return false;

    // Check extension
    final domainParts = domain.split('.');
    if (domainParts.length < 2) return false;

    final ext = domainParts.last.toLowerCase();
    if (_invalidExtensions.contains(ext)) return false;

    // Check ignored domains
    for (var ignored in _ignoredDomains) {
      if (domain == ignored || domain.endsWith('.$ignored')) {
        return false;
      }
    }

    // Avoid placeholder emails
    if (user.contains('placeholder') ||
        user.contains('sample') ||
        user == 'yourname' ||
        user == 'username' ||
        user == 'user') {
      return false;
    }

    return true;
  }
}
