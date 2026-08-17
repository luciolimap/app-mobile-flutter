import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/database/app_database.dart';
import '../../sync/sync_service.dart';

part 'history_event.dart';
part 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc({
    required AppDatabase database,
    required SyncService syncService,
  })  : _database = database,
        _syncService = syncService,
        super(const HistoryState()) {
    on<HistoryStarted>(_onStarted);
    on<HistoryFilterChanged>(_onFilterChanged);
    on<HistorySyncNowPressed>(_onSyncNowPressed);
    on<HistoryRetryPressed>(_onRetryPressed);
    on<_HistoryItemsUpdated>(_onItemsUpdated);
  }

  final AppDatabase _database;
  final SyncService _syncService;
  StreamSubscription<List<InspectionRow>>? _subscription;

  Future<void> _onStarted(HistoryStarted event, Emitter<HistoryState> emit) async {
    await _subscription?.cancel();
    _subscription = _database.watchAllInspections().listen(
          (items) => add(_HistoryItemsUpdated(items)),
        );
  }

  void _onItemsUpdated(_HistoryItemsUpdated event, Emitter<HistoryState> emit) {
    emit(state.copyWith(allItems: event.items));
  }

  void _onFilterChanged(HistoryFilterChanged event, Emitter<HistoryState> emit) {
    if (event.status == null) {
      emit(state.copyWith(clearFilter: true));
    } else {
      emit(state.copyWith(filter: event.status));
    }
  }

  Future<void> _onSyncNowPressed(
    HistorySyncNowPressed event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(isSyncing: true));
    await _syncService.syncAll();
    emit(state.copyWith(isSyncing: false));
  }

  Future<void> _onRetryPressed(
    HistoryRetryPressed event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(isSyncing: true));
    await _syncService.retry(event.localId);
    emit(state.copyWith(isSyncing: false));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
