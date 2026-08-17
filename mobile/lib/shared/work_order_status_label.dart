/// Portuguese label for a work order's `status` field, shared between
/// the work orders list and the work order detail screen.
String workOrderStatusLabel(String status) {
  switch (status) {
    case 'open':
      return 'Aberta';
    case 'in_progress':
      return 'Em andamento';
    case 'done':
      return 'Concluída';
    default:
      return status;
  }
}
