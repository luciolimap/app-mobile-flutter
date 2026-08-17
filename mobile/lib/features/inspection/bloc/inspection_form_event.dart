part of 'inspection_form_bloc.dart';

sealed class InspectionFormEvent extends Equatable {
  const InspectionFormEvent();

  @override
  List<Object?> get props => [];
}

class InspectionObservationChanged extends InspectionFormEvent {
  const InspectionObservationChanged(this.value);
  final String value;

  @override
  List<Object?> get props => [value];
}

class InspectionConditionChanged extends InspectionFormEvent {
  const InspectionConditionChanged(this.value);
  final String? value;

  @override
  List<Object?> get props => [value];
}

class InspectionPhotoRequested extends InspectionFormEvent {
  const InspectionPhotoRequested(this.source);
  final ImageSource source;

  @override
  List<Object?> get props => [source];
}

class InspectionLocationRequested extends InspectionFormEvent {
  const InspectionLocationRequested();
}

/// Fetches the dynamic form schema for this work order (opcional scope).
/// Never gates the form: on failure (e.g. offline) [InspectionFormState]
/// simply keeps its default fields.
class InspectionSchemaRequested extends InspectionFormEvent {
  const InspectionSchemaRequested();
}

class InspectionSaveDraftPressed extends InspectionFormEvent {
  const InspectionSaveDraftPressed();
}

class InspectionCompletePressed extends InspectionFormEvent {
  const InspectionCompletePressed();
}
