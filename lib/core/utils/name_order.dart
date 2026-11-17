import '../locale/app_language.dart';

/// Puts Arabic names together, then English names, each group in order.
String shownName(Object? name, Object? nameEn, {String fallback = 'بدون اسم'}) {
  final arabic = (name ?? '').toString().trim();
  final english = (nameEn ?? '').toString().trim();
  if (AppLanguage.instance.english && english.isNotEmpty) return english;
  if (arabic.isNotEmpty) return arabic;
  if (english.isNotEmpty) return english;
  return fallback;
}

int compareDisplayNames(String left, String right) {
  final a = _nameKey(left);
  final b = _nameKey(right);
  final aArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(a);
  final bArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(b);
  if (aArabic != bArabic) return aArabic ? -1 : 1;
  return a.compareTo(b);
}

bool nameMatches(String label, String query) {
  final needle = _nameKey(query);
  if (needle.isEmpty) return true;
  return _nameKey(label).contains(needle);
}

String _nameKey(String value) {
  var text = value.split('·').first.trim().toLowerCase();
  text = text.replaceAll(RegExp(r'[\u064B-\u0652]'), '');
  return text
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه');
}
