import 'package:flutter/material.dart';

/// Arabic is the church default. English flips the direction and the screens that use [t].
class AppLanguage extends ChangeNotifier {
  AppLanguage._();

  static final AppLanguage instance = AppLanguage._();

  Locale locale = const Locale('ar', 'EG');

  bool get english => locale.languageCode == 'en';

  TextDirection get direction => english ? TextDirection.ltr : TextDirection.rtl;

  void toggle() {
    locale = english ? const Locale('ar', 'EG') : const Locale('en');
    notifyListeners();
  }

  String t(String arabic, String englishText) => english ? englishText : arabic;
}
