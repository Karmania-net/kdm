/// Format byte count for display (e.g. 96.3 MB).
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var i = 0;
  var n = bytes.toDouble();
  while (n >= 1024 && i < units.length - 1) {
    n /= 1024;
    i++;
  }
  if (i == 0) return '$bytes B';
  return '${n.toStringAsFixed(n >= 100 || n == n.roundToDouble() ? 0 : 1)} ${units[i]}';
}

/// Format speed for display (e.g. 11.2 MB/s).
String formatSpeed(int bytesPerSecond) {
  return '${formatBytes(bytesPerSecond)}/s';
}
