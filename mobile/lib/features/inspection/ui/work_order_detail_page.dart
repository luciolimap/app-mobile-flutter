import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/inspection_status_visual.dart';
import '../../../shared/work_order_priority_label.dart';
import '../../../shared/work_order_status_label.dart';
import '../../work_orders/data/work_order.dart';
import 'inspection_form_page.dart';

class WorkOrderDetailPage extends StatelessWidget {
  const WorkOrderDetailPage({super.key, required this.workOrder});

  final WorkOrder workOrder;

  String _formatDate(String iso) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(workOrder.code)),
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(workOrder.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.place_outlined, label: 'Endereço', value: workOrder.address),
          _InfoRow(
            icon: Icons.priority_high,
            label: 'Prioridade',
            value: workOrderPriorityLabel(workOrder.priority),
          ),
          _InfoRow(
            icon: Icons.flag_outlined,
            label: 'Status',
            value: workOrderStatusLabel(workOrder.status),
          ),
          _InfoRow(
            icon: Icons.schedule,
            label: 'Agendada para',
            value: _formatDate(workOrder.scheduledAt),
          ),
          const SizedBox(height: 16),
          Text('Descrição', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(workOrder.description),
          if (workOrder.notes != null && workOrder.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Observações da OS', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(workOrder.notes!),
          ],
          const SizedBox(height: 32),
          FilledButton.icon(
            icon: const Icon(Icons.assignment_outlined),
            label: const Text('Nova inspeção'),
            onPressed: () => _openForm(context),
          ),
          const SizedBox(height: 24),
          Text('Inspeções desta OS', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          StreamBuilder<List<InspectionRow>>(
            stream: context.read<AppDatabase>().watchInspectionsForWorkOrder(workOrder.id),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const [];
              if (items.isEmpty) {
                return const Text('Nenhuma inspeção registrada ainda.');
              }
              return Column(
                children: items
                    .map((item) => _LocalInspectionTile(
                          item: item,
                          onContinueDraft: item.status == InspectionStatus.draft
                              ? () => _openForm(context, existingDraft: item)
                              : null,
                        ))
                    .toList(),
              );
            },
          ),
        ],
        ),
      ),
    );
  }

  void _openForm(BuildContext context, {InspectionRow? existingDraft}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InspectionFormPage(
          workOrderId: workOrder.id,
          workOrderTitle: workOrder.title,
          workOrderLatitude: workOrder.latitude,
          workOrderLongitude: workOrder.longitude,
          existingDraft: existingDraft,
        ),
      ),
    );
  }
}

class _LocalInspectionTile extends StatelessWidget {
  const _LocalInspectionTile({required this.item, this.onContinueDraft});

  final InspectionRow item;
  final VoidCallback? onContinueDraft;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = inspectionStatusVisual(item.status);
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        subtitle: Text(
          item.observation.isEmpty ? '(sem observação ainda)' : item.observation,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: onContinueDraft != null
            ? TextButton(
                onPressed: onContinueDraft,
                child: const Text('Continuar'),
              )
            : null,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
