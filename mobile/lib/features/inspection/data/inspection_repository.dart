import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';

class InspectionRepository {
  InspectionRepository({required AppDatabase database}) : _database = database;

  final AppDatabase _database;
  static const _uuid = Uuid();

  /// Copies the picked photo into permanent app storage so it survives
  /// beyond the OS-managed temp/cache directory used by image_picker.
  Future<String> persistPhoto(XFile file) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docsDir.path, 'inspection_photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final ext = p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path);
    final destPath = p.join(photosDir.path, '${_uuid.v4()}$ext');
    await File(file.path).copy(destPath);
    return destPath;
  }

  Future<void> saveInspection({
    required String workOrderId,
    required String observation,
    String? condition,
    required String photoPath,
    required double latitude,
    required double longitude,
    required DateTime capturedAt,
    required bool asDraft,
  }) async {
    await _database.insertInspection(InspectionsCompanion.insert(
      clientId: _uuid.v4(),
      workOrderId: workOrderId,
      observation: observation,
      condition: Value(condition),
      photoPath: Value(photoPath),
      latitude: latitude,
      longitude: longitude,
      capturedAt: capturedAt.toIso8601String(),
      status: asDraft ? InspectionStatus.draft : InspectionStatus.pending,
      createdAt: DateTime.now().toIso8601String(),
    ));
  }
}
