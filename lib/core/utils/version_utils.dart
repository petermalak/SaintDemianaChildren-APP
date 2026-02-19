/// Returns true if [current] is strictly less than [required].
/// Supports semantic versions like 1.0.4, 1.0.5, 2.0.0.
bool isVersionLessThan(String current, String required) {
  final c = _parseVersion(current);
  final r = _parseVersion(required);
  for (var i = 0; i < 3; i++) {
    final cn = i < c.length ? c[i] : 0;
    final rn = i < r.length ? r[i] : 0;
    if (cn < rn) return true;
    if (cn > rn) return false;
  }
  return false;
}

List<int> _parseVersion(String v) {
  return v
      .split('.')
      .map((e) => int.tryParse(e.trim()) ?? 0)
      .toList();
}
