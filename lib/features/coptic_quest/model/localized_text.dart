import 'package:equatable/equatable.dart';

class LocalizedText extends Equatable {
  final String en;
  final String ar;
  final String? cop;
  final String? copTranslit;

  const LocalizedText({
    required this.en,
    required this.ar,
    this.cop,
    this.copTranslit,
  });

  factory LocalizedText.fromJson(Map<String, dynamic> json) {
    return LocalizedText(
      en: json['en'] as String? ?? '',
      ar: json['ar'] as String? ?? '',
      cop: json['cop'] as String?,
      copTranslit: json['cop_translit'] as String?,
    );
  }

  String forLang(String lang) {
    switch (lang) {
      case 'ar':
        return ar.isNotEmpty ? ar : en;
      case 'cop':
        return cop ?? en;
      default:
        return en.isNotEmpty ? en : ar;
    }
  }

  bool get isRtl => false;

  Map<String, dynamic> toJson() => {
        'en': en,
        'ar': ar,
        if (cop != null) 'cop': cop,
        if (copTranslit != null) 'cop_translit': copTranslit,
      };

  @override
  List<Object?> get props => [en, ar, cop, copTranslit];
}
