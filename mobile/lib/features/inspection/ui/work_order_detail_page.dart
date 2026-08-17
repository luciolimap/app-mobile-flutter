import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(workOrder.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.place_outlined, label: 'Endereço', value: workOrder.address),
          _InfoRow(
            icon: Icons.priority_high,
            label: 'Prioridade',
            value: workOrder.priority.toUpperCase(),
          ),
          _InfoRow(icon: Icons.flag_outlined, label: 'Status', value: workOrder.status),
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
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InspectionFormPage(
                  workOrderId: workOrder.id,
                  workOrderTitle: workOrder.title,
                  workOrderLatitude: workOrder.latitude,
                  workOrderLongitude: workOrder.longitude,
                ),
              ),
            ),
          ),
        ],
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
