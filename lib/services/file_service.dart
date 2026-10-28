import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:csv/csv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/email_record.dart';

class MasterBatchFiles {
  final File txtFile;
  final File csvFile;
  final Set<String> recordedEmails;

  MasterBatchFiles({
    required this.txtFile,
    required this.csvFile,
    required this.recordedEmails,
  });
}

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

  /// Initializes a Single Master Batch File pair (TXT & CSV) for the started session
  static Future<MasterBatchFiles> initMasterBatchSession({
    required String state,
    String? customBaseDir,
  }) async {
    final baseDir = customBaseDir != null && customBaseDir.isNotEmpty
        ? Directory(customBaseDir)
        : await getDefaultOutputDirectory();

    final cleanState = state.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '').trim();
    final stateFolder = Directory(p.join(baseDir.path, cleanState));
    if (!await stateFolder.exists()) {
      await stateFolder.create(recursive: true);
    }

    final now = DateTime.now();
    final timeStamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

    // 1. Single Master TXT File (One email per line for email sender tools)
    final txtFileName = '${cleanState}_Batch_${timeStamp}_Emails.txt';
    final txtFile = File(p.join(stateFolder.path, txtFileName));
    if (!await txtFile.exists()) {
      await txtFile.create(recursive: true);
    }

    // 2. Single Master CSV File (All visited website emails, contractor, city, links)
    final csvFileName = '${cleanState}_Batch_${timeStamp}_Visited_Websites.csv';
    final csvFile = File(p.join(stateFolder.path, csvFileName));
    if (!await csvFile.exists()) {
      await csvFile.create(recursive: true);
      // Write header row
      final headerRow = [
        ['Email', 'Contractor Type', 'City', 'State', 'Website URL', 'Facebook URL', 'Source', 'Date Discovered'],
      ];
      final csvHeader = const ListToCsvConverter().convert(headerRow);
      await csvFile.writeAsString('$csvHeader\n');
    }

    return MasterBatchFiles(
      txtFile: txtFile,
      csvFile: csvFile,
      recordedEmails: {},
    );
  }

  /// Appends newly discovered records in real-time to the single master batch files
  static Future<void> appendToMasterBatch({
    required MasterBatchFiles masterBatch,
    required List<EmailRecord> newRecords,
  }) async {
    if (newRecords.isEmpty) return;

    final txtBuffer = StringBuffer();
    final List<List<dynamic>> csvRows = [];

    for (var record in newRecords) {
      final lowerEmail = record.email.toLowerCase().trim();
      if (!masterBatch.recordedEmails.contains(lowerEmail)) {
        masterBatch.recordedEmails.add(lowerEmail);
        txtBuffer.writeln(lowerEmail);

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
    }

    // Append to TXT
    if (txtBuffer.isNotEmpty) {
      await masterBatch.txtFile.writeAsString(txtBuffer.toString(), mode: FileMode.append);
    }

    // Append to CSV
    if (csvRows.isNotEmpty) {
      final csvData = const ListToCsvConverter().convert(csvRows);
      await masterBatch.csvFile.writeAsString('$csvData\n', mode: FileMode.append);
    }
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

  /// Parses cities list from a TXT (one per line or comma-separated)
  static List<String> parseCities(String content) {
    final List<String> cities = [];
    final lines = const LineSplitter().convert(content);

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      if (trimmed.contains(',')) {
        final items = trimmed.split(',');
        for (var item in items) {
          final clean = item.trim();
          if (clean.isNotEmpty && !cities.contains(clean)) {
            cities.add(clean);
          }
        }
      } else {
        if (!cities.contains(trimmed)) {
          cities.add(trimmed);
        }
      }
    }
    return cities;
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
