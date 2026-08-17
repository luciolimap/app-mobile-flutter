import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../bloc/history_bloc.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  static const _filters = <String?, String>{
    null: 'Todos',
    InspectionStatus.draft: 'Rascunho',
    InspectionStatus.pending: 'Pendente',
    InspectionStatus.synced: 'Sincronizada',
    InspectionStatus.failed: 'Falhou',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        final bloc = context.read<HistoryBloc>();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.entries.map((entry) {
                          final selected = state.filter == entry.key;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(entry.value),
                              selected: selected,
                              onSelected: (_) => bloc.add(
                                HistoryFilterChanged(entry.key),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sincronizar agora',
                    icon: state.isSyncing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    onPressed: state.isSyncing
                        ? null
                        : () => bloc.add(const HistorySyncNowPressed()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.filteredItems.isEmpty
                  ? const Center(child: Text('Nenhuma inspeção neste filtro.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: state.filteredItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = state.filteredItems[index];
                        return _InspectionCard(item: item);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _InspectionCard extends StatelessWidget {
  const _InspectionCard({required this.item});

  final InspectionRow item;

  (Color, IconData, String) _statusVisual() {
    switch (item.status) {
      case InspectionStatus.draft:
        return (Colors.grey, Icons.edit_note, 'Rascunho');
      case InspectionStatus.pending:
        return (Colors.orange, Icons.hourglass_top, 'Pendente');
      case InspectionStatus.synced:
        return (Colors.green, Icons.check_circle, 'Sincronizada');
      case InspectionStatus.failed:
        return (Colors.red, Icons.error, 'Falhou');
      default:
        return (Colors.grey, Icons.help_outline, item.status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = _statusVisual();
    final formattedDate =
        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item.createdAt).toLocal());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(formattedDate, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text('OS: ${item.workOrderId}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              item.observation,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.status == InspectionStatus.failed && item.errorMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                item.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            if (item.status == InspectionStatus.failed) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Tentar novamente'),
                  onPressed: () => context
                      .read<HistoryBloc>()
                      .add(HistoryRetryPressed(item.localId)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
