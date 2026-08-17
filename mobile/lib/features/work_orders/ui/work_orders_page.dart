import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/work_order_priority_label.dart';
import '../../../shared/work_order_status_label.dart';
import '../../inspection/ui/work_order_detail_page.dart';
import '../bloc/work_orders_bloc.dart';
import '../data/work_order.dart';

class WorkOrdersPage extends StatelessWidget {
  const WorkOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkOrdersBloc, WorkOrdersState>(
      builder: (context, state) {
        if (state.status == WorkOrdersStatus.loading && state.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == WorkOrdersStatus.failure && state.items.isEmpty) {
          return _ErrorView(
            message: state.errorMessage ?? 'Erro ao carregar ordens de serviço.',
            onRetry: () => context
                .read<WorkOrdersBloc>()
                .add(const WorkOrdersRefreshRequested()),
          );
        }

        if (state.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => context
                .read<WorkOrdersBloc>()
                .add(const WorkOrdersRefreshRequested()),
            child: ListView(
              children: const [
                SizedBox(height: 120),
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Center(child: Text('Nenhuma ordem de serviço encontrada.')),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => context
              .read<WorkOrdersBloc>()
              .add(const WorkOrdersRefreshRequested()),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: state.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final workOrder = state.items[index];
              return _WorkOrderCard(workOrder: workOrder);
            },
          ),
        );
      },
    );
  }
}

class _WorkOrderCard extends StatelessWidget {
  const _WorkOrderCard({required this.workOrder});

  final WorkOrder workOrder;

  Color _priorityColor(BuildContext context) {
    switch (workOrder.priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkOrderDetailPage(workOrder: workOrder),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      workOrder.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _priorityColor(context).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      workOrderPriorityLabel(workOrder.priority),
                      style: TextStyle(
                        color: _priorityColor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      workOrder.address,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(workOrderStatusLabel(workOrder.status)),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }
}
