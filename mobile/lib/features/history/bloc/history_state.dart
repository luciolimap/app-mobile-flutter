part of 'history_bloc.dart';

class HistoryState extends Equatable {
  const HistoryState({
    this.allItems = const [],
    this.filter,
    this.isSyncing = false,
  });

  final List<InspectionRow> allItems;
  final String? filter;
  final bool isSyncing;

  List<InspectionRow> get filteredItems => filter == null
      ? allItems
      : allItems.where((i) => i.status == filter).toList();

  HistoryState copyWith({
    List<InspectionRow>? allItems,
    String? filter,
    bool clearFilter = false,
    bool? isSyncing,
  }) {
    return HistoryState(
      allItems: allItems ?? this.allItems,
      filter: clearFilter ? null : (filter ?? this.filter),
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  @override
  List<Object?> get props => [allItems, filter, isSyncing];
}
