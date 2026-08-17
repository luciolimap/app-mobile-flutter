import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/app_database.dart';
import '../../sync/sync_service.dart';
import '../bloc/inspection_form_bloc.dart';
import '../data/inspection_repository.dart';

class InspectionFormPage extends StatelessWidget {
  const InspectionFormPage({
    super.key,
    required this.workOrderId,
    required this.workOrderTitle,
    required this.workOrderLatitude,
    required this.workOrderLongitude,
    this.existingDraft,
  });

  final String workOrderId;
  final String workOrderTitle;
  final double workOrderLatitude;
  final double workOrderLongitude;
  final InspectionRow? existingDraft;

  static const _conditions = ['bom', 'regular', 'ruim', 'crítico'];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InspectionFormBloc(
        workOrderId: workOrderId,
        workOrderLatitude: workOrderLatitude,
        workOrderLongitude: workOrderLongitude,
        existingDraft: existingDraft,
        repository: context.read<InspectionRepository>(),
        syncService: context.read<SyncService>(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(existingDraft == null
              ? 'Inspeção — $workOrderTitle'
              : 'Continuar rascunho — $workOrderTitle'),
        ),
        body: BlocConsumer<InspectionFormBloc, InspectionFormState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
            if (state.saveResult == InspectionSaveResult.draftSaved) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rascunho salvo localmente.')),
              );
            } else if (state.saveResult == InspectionSaveResult.completed) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Inspeção concluída. Entrará na fila de sincronização.'),
                ),
              );
            }
          },
          builder: (context, state) {
            final bloc = context.read<InspectionFormBloc>();
            return SafeArea(
              child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  initialValue: state.observation,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Observação',
                    hintText: 'Descreva o que foi encontrado (mín. 10 caracteres)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) =>
                      bloc.add(InspectionObservationChanged(value)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: state.condition,
                  decoration: const InputDecoration(
                    labelText: 'Condição do ativo (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  items: _conditions
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) =>
                      bloc.add(InspectionConditionChanged(value)),
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Foto da evidência',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.photoPath != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(state.photoPath!),
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        const Text('Nenhuma foto anexada.'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.camera_alt_outlined),
                              label: const Text('Câmera'),
                              onPressed: state.isPickingPhoto
                                  ? null
                                  : () => bloc.add(const InspectionPhotoRequested(
                                      ImageSource.camera)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Galeria'),
                              onPressed: state.isPickingPhoto
                                  ? null
                                  : () => bloc.add(const InspectionPhotoRequested(
                                      ImageSource.gallery)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Localização',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.hasLocation
                            ? 'Lat: ${state.latitude!.toStringAsFixed(5)}  Lng: ${state.longitude!.toStringAsFixed(5)}'
                            : 'Localização ainda não capturada.',
                      ),
                      if (state.isFarFromWorkOrder) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.orange, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Você está a '
                                '${state.distanceFromWorkOrderMeters!.round()} m '
                                'do ponto da OS (mais de 200 m).',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.my_location),
                        label: Text(state.isCapturingLocation
                            ? 'Obtendo...'
                            : 'Capturar localização atual'),
                        onPressed: state.isCapturingLocation
                            ? null
                            : () => bloc.add(const InspectionLocationRequested()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: state.isSaving
                            ? null
                            : () => bloc.add(const InspectionSaveDraftPressed()),
                        child: const Text('Salvar rascunho'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: state.isSaving
                            ? null
                            : () => bloc.add(const InspectionCompletePressed()),
                        child: state.isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Concluir inspeção'),
                      ),
                    ),
                  ],
                ),
              ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
