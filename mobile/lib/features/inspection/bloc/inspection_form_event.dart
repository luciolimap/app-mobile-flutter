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

class InspectionSaveDraftPressed extends InspectionFormEvent {
  const InspectionSaveDraftPressed();
}

class InspectionCompletePressed extends InspectionFormEvent {
  const InspectionCompletePressed();
}
