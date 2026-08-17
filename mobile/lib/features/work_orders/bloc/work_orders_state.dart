part of 'work_orders_bloc.dart';

enum WorkOrdersStatus { loading, success, failure }

class WorkOrdersState extends Equatable {
  const WorkOrdersState({
    this.status = WorkOrdersStatus.loading,
    this.items = const [],
    this.isRefreshing = false,
    this.errorMessage,
  });

  final WorkOrdersStatus status;
  final List<WorkOrder> items;
  final bool isRefreshing;
  final String? errorMessage;

  bool get isEmpty => status == WorkOrdersStatus.success && items.isEmpty;

  WorkOrdersState copyWith({
    WorkOrdersStatus? status,
    List<WorkOrder>? items,
    bool? isRefreshing,
    String? errorMessage,
  }) {
    return WorkOrdersState(
      status: status ?? this.status,
      items: items ?? this.items,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, isRefreshing, errorMessage];
}
