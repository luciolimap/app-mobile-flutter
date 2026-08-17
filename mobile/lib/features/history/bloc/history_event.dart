part of 'history_bloc.dart';

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class HistoryStarted extends HistoryEvent {
  const HistoryStarted();
}

class HistoryFilterChanged extends HistoryEvent {
  const HistoryFilterChanged(this.status);
  final String? status;

  @override
  List<Object?> get props => [status];
}

class HistorySyncNowPressed extends HistoryEvent {
  const HistorySyncNowPressed();
}

class HistoryRetryPressed extends HistoryEvent {
  const HistoryRetryPressed(this.localId);
  final int localId;

  @override
  List<Object?> get props => [localId];
}

class _HistoryItemsUpdated extends HistoryEvent {
  const _HistoryItemsUpdated(this.items);
  final List<InspectionRow> items;

  @override
  List<Object?> get props => [items];
}
