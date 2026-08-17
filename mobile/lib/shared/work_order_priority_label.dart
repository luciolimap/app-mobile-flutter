/// Portuguese label for a work order's `priority` field, shared between
/// the work orders list and the work order detail screen.
String workOrderPriorityLabel(String priority) {
  switch (priority) {
    case 'high':
      return 'ALTA';
    case 'medium':
      return 'MÉDIA';
    case 'low':
      return 'BAIXA';
    default:
      return priority.toUpperCase();
  }
}
