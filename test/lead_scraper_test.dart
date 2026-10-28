import 'package:flutter_test/flutter_test.dart';
import 'package:juniauto/services/email_extractor.dart';
import 'package:juniauto/services/file_service.dart';
import 'package:juniauto/services/search_service.dart';
import 'package:juniauto/models/contractor_task.dart';
import 'package:juniauto/models/email_record.dart';

void main() {
  group('EmailExtractor Tests', () {
    test('extracts valid emails from raw text and ignores false positives', () {
      const htmlSample = '''
        <html>
          <body>
            <h1>Contact Austin Roofing Pros</h1>
            <p>Email us at: support@austinroofing.com or sales@austinroofing.org</p>
            <a href="mailto:info@austinroofing.com?subject=Inquiry">Email us</a>
            <img src="logo@2x.png" />
            <script src="sentry@1.0.0.js"></script>
            <p>Fake emails: test@example.com, user@domain.com, placeholder@test.com</p>
          </body>
        </html>
      ''';

      final emails = EmailExtractor.extractEmails(htmlSample);

      expect(emails.contains('support@austinroofing.com'), isTrue);
      expect(emails.contains('sales@austinroofing.org'), isTrue);
      expect(emails.contains('info@austinroofing.com'), isTrue);

      // Verify false positives are eliminated
      expect(emails.contains('logo@2x.png'), isFalse);
      expect(emails.contains('sentry@1.0.0.js'), isFalse);
      expect(emails.contains('test@example.com'), isFalse);
      expect(emails.contains('user@domain.com'), isFalse);
    });
  });

  group('SearchService Tests', () {
    test('builds query strictly adhering to specified pattern', () {
      final query = SearchService.buildQuery(
        contractor: 'Roofing',
        city: 'Austin',
        state: 'Texas',
      );

      expect(query, equals('Roofing contractors in Austin Texas USA'));
    });

    test('decodes Bing Base64 redirect URLs accurately', () {
      // "a1" followed by base64 for "https://example-roofing.com/contact"
      // base64("https://example-roofing.com/contact") = "aHR0cHM6Ly9leGFtcGxlLXJvb2ZpbmcuY29tL2NvbnRhY3Q"
      const bingUrl = 'https://www.bing.com/ck/a?!&&p=123&u=a1aHR0cHM6Ly9leGFtcGxlLXJvb2ZpbmcuY29tL2NvbnRhY3Q&ntb=1';
      final decoded = SearchService.decodeBingUrl(bingUrl);
      expect(decoded, equals('https://example-roofing.com/contact'));
    });
  });

  group('FileService Parsing Tests', () {
    test('parses contractors from multiline and comma-separated string', () {
      const text = '''
        Roofing, Plumbing
        HVAC
        # Comment line
        Electrician
        Painting, Solar
      ''';

      final list = FileService.parseContractors(text);
      expect(list, containsAll(['Roofing', 'Plumbing', 'HVAC', 'Electrician', 'Painting', 'Solar']));
    });

    test('parses cities list from multiline and comma-separated text', () {
      const text = '''
        Austin, Dallas
        Houston
        # Note
        San Antonio
      ''';

      final list = FileService.parseCities(text);
      expect(list, containsAll(['Austin', 'Dallas', 'Houston', 'San Antonio']));
    });

    test('parses states and cities from line format', () {
      const text = '''
        Texas: Houston, Austin, Dallas
        Florida: Miami, Orlando
      ''';

      final map = FileService.parseStatesAndCities(text);
      expect(map.containsKey('Texas'), isTrue);
      expect(map['Texas'], equals(['Houston', 'Austin', 'Dallas']));
      expect(map.containsKey('Florida'), isTrue);
      expect(map['Florida'], equals(['Miami', 'Orlando']));
    });
  });

  group('ContractorTask Model Tests', () {
    test('calculates total queries accurately based on active cities and contractors', () {
      final task = ContractorTask(
        manualState: 'Texas',
        activeCities: ['Austin', 'Dallas', 'Houston', 'San Antonio', 'Fort Worth'],
        contractorTypes: ['Roofing', 'Plumbing'],
        statesAndCities: {},
      );

      // 2 contractors * 5 cities = 10 queries
      expect(task.totalQueries, equals(10));
    });
  });

  group('EmailRecord Equality & Deduplication', () {
    test('deduplicates identical email for same contractor and state', () {
      final r1 = EmailRecord(
        email: 'info@roofing.com',
        contractorType: 'Roofing',
        city: 'Austin',
        state: 'Texas',
        websiteUrl: 'https://roofing.com',
        source: 'Website',
      );

      final r2 = EmailRecord(
        email: 'INFO@roofing.com', // Case insensitive
        contractorType: 'Roofing',
        city: 'Dallas',
        state: 'Texas',
        websiteUrl: 'https://roofing.com/dallas',
        source: 'Contact Page',
      );

      final set = <EmailRecord>{r1, r2};
      expect(set.length, equals(1));
    });
  });
}
