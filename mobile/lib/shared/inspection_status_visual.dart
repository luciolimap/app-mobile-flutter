import 'package:flutter/material.dart';

import '../core/database/app_database.dart';

/// Shared color/icon/label mapping for an inspection's sync status,
/// used by both the history list and the work order detail screen.
(Color, IconData, String) inspectionStatusVisual(String status) {
  switch (status) {
    case InspectionStatus.draft:
      return (Colors.grey, Icons.edit_note, 'Rascunho');
    case InspectionStatus.pending:
      return (Colors.orange, Icons.hourglass_top, 'Pendente');
    case InspectionStatus.synced:
      return (Colors.green, Icons.check_circle, 'Sincronizada');
    case InspectionStatus.failed:
      return (Colors.red, Icons.error, 'Falhou');
    default:
      return (Colors.grey, Icons.help_outline, status);
  }
}
