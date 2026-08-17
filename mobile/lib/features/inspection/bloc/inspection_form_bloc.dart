import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/location_service.dart';
import '../../sync/sync_service.dart';
import '../data/form_schema.dart';
import '../data/form_schema_repository.dart';
import '../data/inspection_repository.dart';

part 'inspection_form_event.dart';
part 'inspection_form_state.dart';

class InspectionFormBloc extends Bloc<InspectionFormEvent, InspectionFormState> {
  InspectionFormBloc({
    required this.workOrderId,
    required this.workOrderLatitude,
    required this.workOrderLongitude,
    required InspectionRepository repository,
    required SyncService syncService,
    this.existingDraft,
    FormSchemaRepository? schemaRepository,
    LocationService? locationService,
    ImagePicker? imagePicker,
  })  : _repository = repository,
        _syncService = syncService,
        _schemaRepository = schemaRepository,
        _locationService = locationService ?? LocationService(),
        _imagePicker = imagePicker ?? ImagePicker(),
        super(existingDraft == null
            ? const InspectionFormState()
            : InspectionFormState(
                observation: existingDraft.observation,
                condition: existingDraft.condition,
                photoPath: (existingDraft.photoPath?.isEmpty ?? true)
                    ? null
                    : existingDraft.photoPath,
                latitude: existingDraft.latitude == 0 && existingDraft.longitude == 0
                    ? null
                    : existingDraft.latitude,
                longitude: existingDraft.latitude == 0 && existingDraft.longitude == 0
                    ? null
                    : existingDraft.longitude,
              )) {
    on<InspectionObservationChanged>((event, emit) =>
        emit(state.copyWith(observation: event.value, clearError: true)));
    on<InspectionConditionChanged>(
        (event, emit) => emit(state.copyWith(condition: event.value)));
    on<InspectionPhotoRequested>(_onPhotoRequested);
    on<InspectionLocationRequested>(_onLocationRequested);
    on<InspectionSchemaRequested>(_onSchemaRequested);
    on<InspectionSaveDraftPressed>(_onSaveDraftPressed);
    on<InspectionCompletePressed>(_onCompletePressed);
  }

  final String workOrderId;
  final double workOrderLatitude;
  final double workOrderLongitude;
  final InspectionRow? existingDraft;
  final InspectionRepository _repository;
  final SyncService _syncService;
  final FormSchemaRepository? _schemaRepository;
  final LocationService _locationService;
  final ImagePicker _imagePicker;

  Future<void> _onSchemaRequested(
    InspectionSchemaRequested event,
    Emitter<InspectionFormState> emit,
  ) async {
    final repository = _schemaRepository;
    if (repository == null) return;
    final schema = await repository.fetch(workOrderId);
    if (schema != null) {
      emit(state.copyWith(schema: schema));
    }
  }

  Future<void> _onPhotoRequested(
    InspectionPhotoRequested event,
    Emitter<InspectionFormState> emit,
  ) async {
    emit(state.copyWith(isPickingPhoto: true, clearError: true));
    try {
      final picked = await _imagePicker.pickImage(
        source: event.source,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (picked == null) {
        emit(state.copyWith(isPickingPhoto: false));
        return;
      }
      final path = await _repository.persistPhoto(picked);
      emit(state.copyWith(isPickingPhoto: false, photoPath: path));
    } catch (_) {
      emit(state.copyWith(
        isPickingPhoto: false,
        errorMessage: 'Não foi possível capturar a foto.',
      ));
    }
  }

  Future<void> _onLocationRequested(
    InspectionLocationRequested event,
    Emitter<InspectionFormState> emit,
  ) async {
    emit(state.copyWith(isCapturingLocation: true, clearError: true));
    try {
      final position = await _locationService.getCurrentLocation();
      final distance = Geolocator.distanceBetween(
        workOrderLatitude,
        workOrderLongitude,
        position.latitude,
        position.longitude,
      );
      emit(state.copyWith(
        isCapturingLocation: false,
        latitude: position.latitude,
        longitude: position.longitude,
        distanceFromWorkOrderMeters: distance,
      ));
    } on LocationServiceException catch (e) {
      emit(state.copyWith(isCapturingLocation: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(
        isCapturingLocation: false,
        errorMessage: 'Não foi possível obter a localização.',
      ));
    }
  }

  Future<void> _onSaveDraftPressed(
    InspectionSaveDraftPressed event,
    Emitter<InspectionFormState> emit,
  ) async {
    if (state.observation.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Escreva ao menos uma observação.'));
      return;
    }
    emit(state.copyWith(isSaving: true, clearError: true));
    await _repository.saveInspection(
      workOrderId: workOrderId,
      observation: state.observation.trim(),
      condition: state.condition,
      photoPath: state.photoPath ?? '',
      latitude: state.latitude ?? 0,
      longitude: state.longitude ?? 0,
      capturedAt: DateTime.now(),
      asDraft: true,
      existing: existingDraft,
    );
    emit(state.copyWith(
      isSaving: false,
      saveResult: InspectionSaveResult.draftSaved,
    ));
  }

  Future<void> _onCompletePressed(
    InspectionCompletePressed event,
    Emitter<InspectionFormState> emit,
  ) async {
    if (state.observation.trim().length < state.minObservationLength) {
      emit(state.copyWith(
        errorMessage:
            'A observação precisa ter ao menos ${state.minObservationLength} caracteres.',
      ));
      return;
    }
    if (!state.hasPhoto) {
      emit(state.copyWith(errorMessage: 'Anexe uma foto da evidência.'));
      return;
    }
    if (!state.hasLocation) {
      emit(state.copyWith(errorMessage: 'Capture a localização da inspeção.'));
      return;
    }

    emit(state.copyWith(isSaving: true, clearError: true));
    await _repository.saveInspection(
      workOrderId: workOrderId,
      observation: state.observation.trim(),
      condition: state.condition,
      photoPath: state.photoPath!,
      latitude: state.latitude!,
      longitude: state.longitude!,
      capturedAt: DateTime.now(),
      asDraft: false,
      existing: existingDraft,
    );
    emit(state.copyWith(
      isSaving: false,
      saveResult: InspectionSaveResult.completed,
    ));
    // Fire-and-forget: try to sync immediately if there's connectivity;
    // if offline, it stays "pending" and the automatic sync (on
    // reconnect) or manual sync in the history screen will pick it up.
    unawaited(_syncService.syncAll());
  }
}
