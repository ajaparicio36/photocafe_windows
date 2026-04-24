import 'package:freezed_annotation/freezed_annotation.dart';

part 'flipbook_archive_entry.freezed.dart';
part 'flipbook_archive_entry.g.dart';

@freezed
sealed class FlipbookArchiveEntry with _$FlipbookArchiveEntry {
  const factory FlipbookArchiveEntry({
    required String filePath,
    required DateTime createdAt,
    required String frameName,
    required String frameId,
  }) = _FlipbookArchiveEntry;

  factory FlipbookArchiveEntry.fromJson(Map<String, dynamic> json) =>
      _$FlipbookArchiveEntryFromJson(json);
}
