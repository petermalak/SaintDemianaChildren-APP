class CopticQuestStrings {
  static String get(String key, String lang) {
    final entry = _strings[key];
    if (entry == null) return key;
    return lang == 'en' ? entry.en : entry.ar;
  }

  static const Map<String, _StringPair> _strings = {
    'appTitle': _StringPair('Coptic Quest', 'رحلة الإيمان'),
    'back': _StringPair('Back', 'رجوع'),
    'settings': _StringPair('Settings', 'الإعدادات'),
    'continue': _StringPair('Continue', 'متابعة'),
    'start': _StringPair('Start', 'ابدأ'),
    'next': _StringPair('Next', 'التالي'),
    'finish': _StringPair('Finish', 'إنهاء'),
    'tryAgain': _StringPair('Try Again', 'حاول مرة أخرى'),
    'comingSoon': _StringPair('Coming Soon', 'قريباً'),
    'tier': _StringPair('Difficulty', 'المستوى'),
    'lessonLanguage': _StringPair('Lesson Language', 'لغة الدرس'),
    'tier1': _StringPair('Young Explorers (6–8)', 'المستكشفون الصغار (٦–٨)'),
    'tier2': _StringPair('Growing Learners (9–10)', 'المتعلمون الناشئون (٩–١٠)'),
    'tier3': _StringPair('Faith Scholars (11–12)', 'علماء الإيمان (١١–١٢)'),
    'pathBible': _StringPair('Bible & Saints', 'الكتاب المقدس والقديسين'),
    'pathLetters': _StringPair('Coptic Letters', 'الحروف القبطية'),
    'pathPrayers': _StringPair('Prayers & Creed', 'الصلوات والإيمان'),
    'pathBibleDesc':
        _StringPair('Stories from the Bible and lives of saints', 'قصص من الكتاب المقدس وحياة القديسين'),
    'pathLettersDesc':
        _StringPair('Learn the Coptic alphabet', 'تعلّم الحروف القبطية'),
    'pathPrayersDesc':
        _StringPair('Learn prayers and the Creed', 'تعلّم الصلوات والإيمان'),
    'locked': _StringPair('Locked', 'مقفل'),
    'stars': _StringPair('Stars', 'نجوم'),
    'hookTitle': _StringPair('Get Ready!', 'استعد!'),
    'teachTitle': _StringPair('Story Time', 'وقت القصة'),
    'practiceTitle': _StringPair('Practice', 'تدريب'),
    'checkTitle': _StringPair('Quick Check', 'اختبار سريع'),
    'rewardTitle': _StringPair('Well Done!', 'أحسنت!'),
    'playCardTitle': _StringPair('Coptic Quest', 'رحلة الإيمان'),
    'playCardSubtitle': _StringPair(
      'Learn faith through fun levels',
      'تعلّم الإيمان عبر مستويات ممتعة',
    ),
    'matchPairs': _StringPair('Match the pairs!', 'طابق الأزواج!'),
    'sequence': _StringPair('Put events in order!', 'رتّب الأحداث بالترتيب!'),
    'quizProgress': _StringPair('Question', 'سؤال'),
    'correct': _StringPair('Correct!', 'صحيح!'),
    'wrong': _StringPair('Not quite — try again!', 'ليس تماماً — حاول مرة أخرى!'),
    'levelComplete': _StringPair('Level Complete!', 'أكملت المستوى!'),
    'english': _StringPair('English', 'إنجليزي'),
    'arabic': _StringPair('Arabic', 'عربي'),
    'hubWelcome': _StringPair(
      'Pick a path and start your faith adventure! 🌟',
      'اختر مساراً وابدأ مغامرة إيمانك! 🌟',
    ),
    'hubHeroTitle': _StringPair('Ready for Adventure?', 'مستعد للمغامرة؟'),
    'hubHeroSubtitle': _StringPair(
      'Learn Bible stories through fun games!',
      'تعلّم قصص الكتاب المقدس بألعاب ممتعة!',
    ),
    'pickPath': _StringPair('Choose your path', 'اختر مسارك'),
    'pathProgress': _StringPair(
      '{done} of {total} levels complete',
      'أكملت {done} من {total} مستويات',
    ),
    'dragHint': _StringPair(
      'Drag items to put them in order',
      'اسحب العناصر لترتيبها',
    ),
    'xp': _StringPair('XP', 'نقاط'),
    'streak': _StringPair('Streak', 'سلسلة'),
    'leaderboard': _StringPair('Rank', 'الترتيب'),
    'leaderboardHint': _StringPair(
      'Class points from quests & attendance',
      'نقاط الفصل من الرحلة والحضور',
    ),
    'leaderboardEmpty': _StringPair('No scores yet', 'لا توجد نقاط بعد'),
    'yourRank': _StringPair('You', 'أنت'),
    'noClass': _StringPair('Join a class to compete', 'انضم لفصل للمنافسة'),
    'classPoints': _StringPair('class pts', 'نقاط الفصل'),
    'newRecord': _StringPair('New best!', 'رقم قياسي!'),
    'fastestTime': _StringPair('Fastest time!', 'أسرع وقت!'),
    'combo': _StringPair('Combo', 'تركيبة'),
  };
}

class _StringPair {
  final String en;
  final String ar;
  const _StringPair(this.en, this.ar);
}
