const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "13 Nov 2026" in local time.
String formatDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}

/// "2h 05m", "12m", "45s".
String formatDuration(Duration value) {
  if (value.inHours > 0) {
    return '${value.inHours}h ${(value.inMinutes % 60).toString().padLeft(2, '0')}m';
  }
  if (value.inMinutes > 0) return '${value.inMinutes}m';
  return '${value.inSeconds}s';
}
