import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photocafe_windows/features/flipbook/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/settings/domain/data/models/flipbook_archive_entry.dart';

final flipbookArchiveProvider =
    AsyncNotifierProvider<FlipbookArchiveNotifier, List<FlipbookArchiveEntry>>(
      FlipbookArchiveNotifier.new,
    );

class FlipbookArchiveNotifier
    extends AsyncNotifier<List<FlipbookArchiveEntry>> {
  @override
  Future<List<FlipbookArchiveEntry>> build() async {
    final entries = await _loadIndex();
    final cleaned = await _cleanupOldEntries(entries);
    return cleaned;
  }

  Future<Directory> _getArchiveDir() async {
    final appSupport = await getApplicationSupportDirectory();
    final archiveDir = Directory(p.join(appSupport.path, 'flipbook_archives'));
    if (!await archiveDir.exists()) {
      await archiveDir.create(recursive: true);
    }
    return archiveDir;
  }

  Future<File> _getIndexFile() async {
    final dir = await _getArchiveDir();
    return File(p.join(dir.path, 'index.json'));
  }

  Future<List<FlipbookArchiveEntry>> _loadIndex() async {
    final indexFile = await _getIndexFile();
    if (!await indexFile.exists()) {
      return [];
    }
    final content = await indexFile.readAsString();
    if (content.trim().isEmpty) {
      return [];
    }
    final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
    return jsonList
        .map((e) => FlipbookArchiveEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveIndex(List<FlipbookArchiveEntry> entries) async {
    final indexFile = await _getIndexFile();
    final jsonList = entries.map((e) => e.toJson()).toList();
    await indexFile.writeAsString(jsonEncode(jsonList));
  }

  Future<List<FlipbookArchiveEntry>> _cleanupOldEntries(
    List<FlipbookArchiveEntry> entries,
  ) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final toKeep = <FlipbookArchiveEntry>[];
    final toRemove = <FlipbookArchiveEntry>[];

    for (final entry in entries) {
      if (entry.createdAt.isBefore(cutoff)) {
        toRemove.add(entry);
      } else {
        toKeep.add(entry);
      }
    }

    for (final entry in toRemove) {
      final file = File(entry.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    if (toRemove.isNotEmpty) {
      await _saveIndex(toKeep);
    }

    return toKeep;
  }

  Future<void> saveArchive(
    Uint8List pdfBytes,
    FlipbookFrameDefinition frame,
  ) async {
    final dir = await _getArchiveDir();
    final timestamp = DateTime.now();
    final fileName = 'flipbook_${timestamp.millisecondsSinceEpoch}.pdf';
    final filePath = p.join(dir.path, fileName);

    await File(filePath).writeAsBytes(pdfBytes);

    final entry = FlipbookArchiveEntry(
      filePath: filePath,
      createdAt: timestamp,
      frameName: frame.name,
      frameId: frame.id,
    );

    final current = state.value ?? [];
    final updated = [entry, ...current];
    await _saveIndex(updated);
    state = AsyncData(updated);
  }

  Future<void> deleteArchive(FlipbookArchiveEntry entry) async {
    final file = File(entry.filePath);
    if (await file.exists()) {
      await file.delete();
    }

    final current = state.value ?? [];
    final updated = current.where((e) => e.filePath != entry.filePath).toList();
    await _saveIndex(updated);
    state = AsyncData(updated);
  }

  Future<Uint8List> getArchivePdfBytes(FlipbookArchiveEntry entry) async {
    final file = File(entry.filePath);
    return file.readAsBytes();
  }
}
