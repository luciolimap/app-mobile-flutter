part of 'work_orders_bloc.dart';

sealed class WorkOrdersEvent extends Equatable {
  const WorkOrdersEvent();

  @override
  List<Object?> get props => [];
}

/// Starts watching the local cache and triggers the first network refresh.
class WorkOrdersStarted extends WorkOrdersEvent {
  const WorkOrdersStarted();
}

class WorkOrdersRefreshRequested extends WorkOrdersEvent {
  const WorkOrdersRefreshRequested();
}

class _WorkOrdersCacheUpdated extends WorkOrdersEvent {
  const _WorkOrdersCacheUpdated(this.items);
  final List<WorkOrder> items;

  @override
  List<Object?> get props => [items];
}
