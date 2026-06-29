/// XP, combo, and class-point rules for Coptic Quest.
class QuestScoring {
  static const int baseXp = 30;
  static const int xpPerStar = 40;
  static const int perfectQuizBonus = 30;
  static const int practiceBonusXp = 15;
  static const int xpPerComboStep = 8;

  static int xpForLevel({
    required int stars,
    required double quizScore,
    required int maxCombo,
    required bool practiceBonus,
  }) {
    var xp = baseXp + stars * xpPerStar;
    if (quizScore >= 1.0) xp += perfectQuizBonus;
    if (practiceBonus) xp += practiceBonusXp;
    if (maxCombo >= 2) xp += (maxCombo - 1) * xpPerComboStep;
    return xp;
  }

  static int classPointsForStars(int stars) {
    if (stars <= 0) return 5;
    return stars * 15;
  }

  static String comboLabel(int combo, String lang) {
    if (combo < 2) return '';
    if (combo >= 5) return lang == 'en' ? '🔥 Amazing combo!' : '🔥 تركيبة رائعة!';
    if (combo >= 3) return lang == 'en' ? '⚡ Great combo!' : '⚡ تركيبة ممتازة!';
    return lang == 'en' ? '✨ Combo!' : '✨ تركيبة!';
  }
}
