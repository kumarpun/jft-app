String formatDuration(int seconds) {
  if (seconds <= 0) return 'No time limit';
  final h = seconds ~/ 3600, m = (seconds % 3600) ~/ 60, s = seconds % 60;
  if (h > 0) return m > 0 ? '${h}h ${m}m' : '${h}h';
  if (m > 0) return s > 0 ? '${m}m ${s}s' : '$m min';
  return '${s}s';
}

String clock(int seconds) {
  final h = seconds ~/ 3600, m = (seconds % 3600) ~/ 60, s = seconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

String timeLeft(int seconds) {
  final d = seconds ~/ 86400, h = (seconds % 86400) ~/ 3600, m = (seconds % 3600) ~/ 60;
  if (d > 0) return '${d}d ${h}h left';
  if (h > 0) return '${h}h ${m}m left';
  return '${m}m left';
}

String formatPrice(double v) => v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(2);

String formatDate(String iso) {
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  const mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${mo[d.month - 1]} ${d.year}';
}
