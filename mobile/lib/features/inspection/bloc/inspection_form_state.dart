part of 'inspection_form_bloc.dart';

enum InspectionSaveResult { none, draftSaved, completed }

class InspectionFormState extends Equatable {
  const InspectionFormState({
    this.observation = '',
    this.condition,
    this.photoPath,
    this.latitude,
    this.longitude,
    this.isPickingPhoto = false,
    this.isCapturingLocation = false,
    this.isSaving = false,
    this.errorMessage,
    this.saveResult = InspectionSaveResult.none,
    this.distanceFromWorkOrderMeters,
    this.schema,
  });

  final String observation;
  final String? condition;
  final String? photoPath;
  final double? latitude;
  final double? longitude;
  final bool isPickingPhoto;
  final bool isCapturingLocation;
  final bool isSaving;
  final String? errorMessage;
  final InspectionSaveResult saveResult;
  final double? distanceFromWorkOrderMeters;

  /// Dynamic field definitions fetched from `GET
  /// /work-orders/:id/form-schema` (opcional scope). Null until it loads
  /// (or if the fetch failed, e.g. offline) — the form always renders a
  /// sensible default in that case, this never gates the form.
  final InspectionFormSchema? schema;

  bool get hasLocation => latitude != null && longitude != null;
  bool get hasPhoto => photoPath != null;

  static const geofenceRadiusMeters = 200;
  static const _defaultConditionOptions = ['bom', 'regular', 'ruim', 'crítico'];

  bool get isFarFromWorkOrder =>
      distanceFromWorkOrderMeters != null &&
      distanceFromWorkOrderMeters! > geofenceRadiusMeters;

  int get minObservationLength => schema?.fieldFor('observation')?.minLength ?? 10;

  List<String> get conditionOptions =>
      schema?.fieldFor('condition')?.options ?? _defaultConditionOptions;

  InspectionFormState copyWith({
    String? observation,
    String? condition,
    String? photoPath,
    double? latitude,
    double? longitude,
    bool? isPickingPhoto,
    bool? isCapturingLocation,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    InspectionSaveResult? saveResult,
    double? distanceFromWorkOrderMeters,
    InspectionFormSchema? schema,
  }) {
    return InspectionFormState(
      observation: observation ?? this.observation,
      condition: condition ?? this.condition,
      photoPath: photoPath ?? this.photoPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPickingPhoto: isPickingPhoto ?? this.isPickingPhoto,
      isCapturingLocation: isCapturingLocation ?? this.isCapturingLocation,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      saveResult: saveResult ?? this.saveResult,
      distanceFromWorkOrderMeters:
          distanceFromWorkOrderMeters ?? this.distanceFromWorkOrderMeters,
      schema: schema ?? this.schema,
    );
  }

  @override
  List<Object?> get props => [
        observation,
        condition,
        photoPath,
        latitude,
        longitude,
        isPickingPhoto,
        isCapturingLocation,
        isSaving,
        errorMessage,
        saveResult,
        distanceFromWorkOrderMeters,
        schema,
      ];
}
