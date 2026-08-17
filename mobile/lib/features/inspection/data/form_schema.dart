import 'package:equatable/equatable.dart';

class InspectionFormFieldSpec extends Equatable {
  const InspectionFormFieldSpec({
    required this.key,
    required this.type,
    required this.label,
    required this.required,
    this.minLength,
    this.options,
  });

  factory InspectionFormFieldSpec.fromJson(Map<String, dynamic> json) {
    return InspectionFormFieldSpec(
      key: json['key'] as String,
      type: json['type'] as String,
      label: json['label'] as String,
      required: json['required'] as bool? ?? false,
      minLength: json['minLength'] as int?,
      options: (json['options'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  final String key;
  final String type;
  final String label;
  final bool required;
  final int? minLength;
  final List<String>? options;

  @override
  List<Object?> get props => [key, type, label, required, minLength, options];
}

class InspectionFormSchema extends Equatable {
  const InspectionFormSchema({required this.workOrderId, required this.fields});

  factory InspectionFormSchema.fromJson(Map<String, dynamic> json) {
    return InspectionFormSchema(
      workOrderId: json['workOrderId'] as String,
      fields: (json['fields'] as List<dynamic>)
          .map((e) => InspectionFormFieldSpec.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String workOrderId;
  final List<InspectionFormFieldSpec> fields;

  InspectionFormFieldSpec? fieldFor(String key) {
    for (final field in fields) {
      if (field.key == key) return field;
    }
    return null;
  }

  @override
  List<Object?> get props => [workOrderId, fields];
}
