import 'package:equatable/equatable.dart';

import '../../../core/database/app_database.dart';

class WorkOrder extends Equatable {
  const WorkOrder({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.address,
    required this.priority,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.scheduledAt,
    required this.updatedAt,
    this.notes,
  });

  factory WorkOrder.fromJson(Map<String, dynamic> json) => WorkOrder(
        id: json['id'] as String,
        code: json['code'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        address: json['address'] as String,
        priority: json['priority'] as String,
        status: json['status'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        scheduledAt: json['scheduledAt'] as String,
        updatedAt: json['updatedAt'] as String,
        notes: json['notes'] as String?,
      );

  factory WorkOrder.fromCache(WorkOrderCacheRow row) => WorkOrder(
        id: row.id,
        code: row.code,
        title: row.title,
        description: row.description,
        address: row.address,
        priority: row.priority,
        status: row.status,
        latitude: row.latitude,
        longitude: row.longitude,
        scheduledAt: row.scheduledAt,
        updatedAt: row.updatedAt,
        notes: row.notes,
      );

  final String id;
  final String code;
  final String title;
  final String description;
  final String address;
  final String priority;
  final String status;
  final double latitude;
  final double longitude;
  final String scheduledAt;
  final String updatedAt;
  final String? notes;

  WorkOrderCacheRow toCacheRow() => WorkOrderCacheRow(
        id: id,
        code: code,
        title: title,
        description: description,
        address: address,
        priority: priority,
        status: status,
        latitude: latitude,
        longitude: longitude,
        scheduledAt: scheduledAt,
        updatedAt: updatedAt,
        notes: notes,
      );

  @override
  List<Object?> get props => [id, code, title, status, updatedAt];
}
