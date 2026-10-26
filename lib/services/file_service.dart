import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:csv/csv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/email_record.dart';

class FileService {
  /// Gets the default directory for saving output files: Documents/LeadScrape_Outputs/
  static Future<Directory> getDefaultOutputDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final outDir = Directory(p.join(docsDir.path, 'LeadScrape_Outputs'));
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }
    return outDir;
  }

  /// Parses contractors list from a TXT or CSV string
  static List<String> parseContractors(String content) {
    final List<String> contractors = [];
    final lines = const LineSplitter().convert(content);

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      if (trimmed.contains(',')) {
        final items = trimmed.split(',');
        for (var item in items) {
          final clean = item.trim();
          if (clean.isNotEmpty && !contractors.contains(clean)) {
            contractors.add(clean);
          }
        }
      } else {
        if (!contractors.contains(trimmed)) {
          contractors.add(trimmed);
        }
      }
    }
    return contractors;
  }

  /// Parses States and Cities from JSON or CSV / TXT format
  static Map<String, List<String>> parseStatesAndCities(String content) {
    final Map<String, List<String>> result = {};

    try {
      final decoded = jsonDecode(content);
      if (decoded is Map) {
        for (var entry in decoded.entries) {
          final state = entry.key.toString().trim();
          final val = entry.value;
          final List<String> cities = [];

          if (val is List) {
            for (var item in val) {
              final c = item.toString().trim();
              if (c.isNotEmpty) cities.add(c);
            }
          }
          if (state.isNotEmpty && cities.isNotEmpty) {
            result[state] = cities;
          }
        }
        if (result.isNotEmpty) return result;
      }
    } catch (_) {}

    final lines = const LineSplitter().convert(content);
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      if (trimmed.contains(':')) {
        final parts = trimmed.split(':');
        final state = parts[0].trim();
        final citiesStr = parts[1].trim();
        final cities = citiesStr
            .split(',')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toList();

        if (state.isNotEmpty && cities.isNotEmpty) {
          result.putIfAbsent(state, () => []).addAll(cities);
        }
      } else if (trimmed.contains(',')) {
        final parts = trimmed.split(',');
        if (parts.length >= 2) {
          final state = parts[0].trim();
          final city = parts[1].trim();
          if (state.isNotEmpty && city.isNotEmpty) {
            result.putIfAbsent(state, () => []);
            if (!result[state]!.contains(city)) {
              result[state]!.add(city);
            }
          }
        }
      }
    }

    return result;
  }

  /// Saves extracted emails for a specific Contractor in a specific City:
  /// baseDir / [State] / [Contractor]_[City]_[State]_emails.txt
  static Future<File> saveCityContractorResult({
    required String contractor,
    required String city,
    required String state,
    required List<EmailRecord> records,
    String? customBaseDir,
  }) async {
    final baseDir = customBaseDir != null && customBaseDir.isNotEmpty
        ? Directory(customBaseDir)
        : await getDefaultOutputDirectory();

    final cleanState = state.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '').trim();
    final cleanCity = city.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '').trim();
    final cleanContractor =
        contractor.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '').trim();

    final stateFolder = Directory(p.join(baseDir.path, cleanState));
    if (!await stateFolder.exists()) {
      await stateFolder.create(recursive: true);
    }

    // 1. Plain Text Notepad file (One email per line)
    final txtFileName = '${cleanContractor}_${cleanCity}_${cleanState}_emails.txt';
    final txtFile = File(p.join(stateFolder.path, txtFileName));

    final uniqueEmails = records.map((r) => r.email).toSet().toList();
    final txtBuffer = StringBuffer();
    for (var email in uniqueEmails) {
      txtBuffer.writeln(email);
    }
    await txtFile.writeAsString(txtBuffer.toString());

    // 2. Detailed CSV with website and Facebook links
    final csvFileName = '${cleanContractor}_${cleanCity}_${cleanState}_emails.csv';
    final csvFile = File(p.join(stateFolder.path, csvFileName));

    final List<List<dynamic>> csvRows = [
      ['Email', 'Contractor Type', 'City', 'State', 'Website URL', 'Facebook URL', 'Source', 'Date Discovered'],
    ];

    for (var record in records) {
      csvRows.add([
        record.email,
        record.contractorType,
        record.city,
        record.state,
        record.websiteUrl,
        record.facebookUrl ?? '',
        record.source,
        record.discoveredAt.toIso8601String(),
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvRows);
    await csvFile.writeAsString(csvString);

    return txtFile;
  }

  /// Saves the extracted emails for a specific Contractor searched across all cities in one State.
  static Future<File> saveBatchResult({
    required String contractor,
    required String state,
    required List<EmailRecord> records,
    String? customBaseDir,
  }) async {
    final baseDir = customBaseDir != null && customBaseDir.isNotEmpty
        ? Directory(customBaseDir)
        : await getDefaultOutputDirectory();

    final cleanState = state.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '').trim();
    final cleanContractor =
        contractor.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '').trim();

    final stateFolder = Directory(p.join(baseDir.path, cleanState));
    if (!await stateFolder.exists()) {
      await stateFolder.create(recursive: true);
    }

    final txtFileName = '${cleanContractor}_${cleanState}_emails.txt';
    final txtFile = File(p.join(stateFolder.path, txtFileName));

    final uniqueEmails = records.map((r) => r.email).toSet().toList();
    final txtBuffer = StringBuffer();
    for (var email in uniqueEmails) {
      txtBuffer.writeln(email);
    }
    await txtFile.writeAsString(txtBuffer.toString());

    final csvFileName = '${cleanContractor}_${cleanState}_emails.csv';
    final csvFile = File(p.join(stateFolder.path, csvFileName));

    final List<List<dynamic>> csvRows = [
      ['Email', 'Contractor Type', 'City', 'State', 'Website URL', 'Facebook URL', 'Source', 'Date Discovered'],
    ];

    for (var record in records) {
      csvRows.add([
        record.email,
        record.contractorType,
        record.city,
        record.state,
        record.websiteUrl,
        record.facebookUrl ?? '',
        record.source,
        record.discoveredAt.toIso8601String(),
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvRows);
    await csvFile.writeAsString(csvString);

    return txtFile;
  }

  /// Opens the output folder in Finder (macOS) or File Explorer (Windows/Linux)
  static Future<void> openFolder(String folderPath) async {
    final uri = Uri.directory(folderPath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (Platform.isMacOS) {
        await Process.run('open', [folderPath]);
      } else if (Platform.isWindows) {
        await Process.run('explorer.exe', [folderPath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [folderPath]);
      }
    }
  }

  /// Opens a specific file in the system default text editor / notepad
  static Future<void> openFile(String filePath) async {
    final uri = Uri.file(filePath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (Platform.isMacOS) {
        await Process.run('open', [filePath]);
      } else if (Platform.isWindows) {
        await Process.run('notepad.exe', [filePath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [filePath]);
      }
    }
  }
}
