import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Sync status of a locally stored inspection.
class InspectionStatus {
  static const draft = 'draft';
  static const pending = 'pending';
  static const synced = 'synced';
  static const failed = 'failed';
}

@DataClassName('WorkOrderCacheRow')
class WorkOrderCache extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get address => text()();
  TextColumn get priority => text()();
  TextColumn get status => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get scheduledAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('InspectionRow')
class Inspections extends Table {
  IntColumn get localId => integer().autoIncrement()();
  TextColumn get clientId => text().unique()();
  TextColumn get workOrderId => text()();
  TextColumn get observation => text()();
  TextColumn get condition => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get capturedAt => text()();
  TextColumn get status => text()();
  TextColumn get errorMessage => text().nullable()();
  TextColumn get serverId => text().nullable()();
  TextColumn get syncedAt => text().nullable()();
  TextColumn get createdAt => text()();
}

@DriftDatabase(tables: [WorkOrderCache, Inspections])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  // --- Work orders cache ---

  Future<void> replaceWorkOrders(List<WorkOrderCacheRow> rows) async {
    await transaction(() async {
      await delete(workOrderCache).go();
      await batch((b) => b.insertAll(workOrderCache, rows));
    });
  }

  Stream<List<WorkOrderCacheRow>> watchWorkOrders() =>
      select(workOrderCache).watch();

  // --- Inspections / sync queue ---

  Future<int> insertInspection(InspectionsCompanion entry) =>
      into(inspections).insert(entry);

  Future<bool> updateInspection(InspectionRow row) =>
      update(inspections).replace(row);

  Stream<List<InspectionRow>> watchAllInspections() {
    final query = select(inspections)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch();
  }

  Future<List<InspectionRow>> pendingOrFailedInspections() {
    final query = select(inspections)
      ..where((t) =>
          t.status.equals(InspectionStatus.pending) |
          t.status.equals(InspectionStatus.failed));
    return query.get();
  }

  Future<InspectionRow?> findByClientId(String clientId) {
    final query = select(inspections)
      ..where((t) => t.clientId.equals(clientId));
    return query.getSingleOrNull();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'orbytis_field_inspection.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
