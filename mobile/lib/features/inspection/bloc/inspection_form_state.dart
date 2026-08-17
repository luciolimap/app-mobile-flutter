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

  bool get hasLocation => latitude != null && longitude != null;
  bool get hasPhoto => photoPath != null;

  static const geofenceRadiusMeters = 200;

  bool get isFarFromWorkOrder =>
      distanceFromWorkOrderMeters != null &&
      distanceFromWorkOrderMeters! > geofenceRadiusMeters;

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
      ];
}
