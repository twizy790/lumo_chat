String twoDigits(int value) => value.toString().padLeft(2, '0');

String formatShortTime(DateTime dateTime) {
  return '${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}';
}

String formatShortDate(DateTime dateTime) {
  return '${twoDigits(dateTime.day)}.${twoDigits(dateTime.month)}.${dateTime.year}';
}

String formatDateTimeCompact(DateTime dateTime) {
  return '${formatShortDate(dateTime)} ${formatShortTime(dateTime)}';
}

String timeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.inMinutes < 1) return 'только что';
  if (diff.inHours < 1) return '${diff.inMinutes} мин';
  if (diff.inDays < 1) return '${diff.inHours} ч';
  if (diff.inDays < 7) return '${diff.inDays} дн';
  return formatShortDate(dateTime);
}
