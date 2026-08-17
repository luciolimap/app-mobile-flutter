import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/api/api_exception.dart';
import '../data/work_order.dart';
import '../data/work_orders_repository.dart';

part 'work_orders_event.dart';
part 'work_orders_state.dart';

class WorkOrdersBloc extends Bloc<WorkOrdersEvent, WorkOrdersState> {
  WorkOrdersBloc({required WorkOrdersRepository repository})
      : _repository = repository,
        super(const WorkOrdersState()) {
    on<WorkOrdersStarted>(_onStarted);
    on<WorkOrdersRefreshRequested>(_onRefreshRequested);
    on<_WorkOrdersCacheUpdated>(_onCacheUpdated);
  }

  final WorkOrdersRepository _repository;
  StreamSubscription<List<WorkOrder>>? _cacheSubscription;

  Future<void> _onStarted(
    WorkOrdersStarted event,
    Emitter<WorkOrdersState> emit,
  ) async {
    await _cacheSubscription?.cancel();
    _cacheSubscription = _repository.watchCached().listen(
          (items) => add(_WorkOrdersCacheUpdated(items)),
        );
    await _refresh(emit, isPullToRefresh: false);
  }

  Future<void> _onRefreshRequested(
    WorkOrdersRefreshRequested event,
    Emitter<WorkOrdersState> emit,
  ) async {
    await _refresh(emit, isPullToRefresh: true);
  }

  void _onCacheUpdated(
    _WorkOrdersCacheUpdated event,
    Emitter<WorkOrdersState> emit,
  ) {
    emit(state.copyWith(
      status: WorkOrdersStatus.success,
      items: event.items,
    ));
  }

  Future<void> _refresh(
    Emitter<WorkOrdersState> emit, {
    required bool isPullToRefresh,
  }) async {
    emit(state.copyWith(isRefreshing: true));
    try {
      await _repository.refresh();
      // Cache stream will emit the fresh items; just clear error/loading here.
      emit(state.copyWith(
        status: WorkOrdersStatus.success,
        isRefreshing: false,
        errorMessage: null,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: state.items.isEmpty ? WorkOrdersStatus.failure : WorkOrdersStatus.success,
        isRefreshing: false,
        errorMessage: e.message,
      ));
    }
  }

  @override
  Future<void> close() {
    _cacheSubscription?.cancel();
    return super.close();
  }
}
