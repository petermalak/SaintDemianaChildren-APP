import 'package:flutter_test/flutter_test.dart';
import 'package:saint_demiana_children/features/coptic_quest/core/quest_scoring.dart';
import 'package:saint_demiana_children/features/coptic_quest/model/lesson_model.dart';
import 'package:saint_demiana_children/features/coptic_quest/model/level_progress.dart';
import 'package:saint_demiana_children/features/coptic_quest/model/localized_text.dart';

void main() {
  group('LessonRewards', () {
    test('starsForScore returns correct star count', () {
      const rewards = LessonRewards(starThresholds: [0.5, 0.75, 1.0]);
      expect(rewards.starsForScore(0.4), 0);
      expect(rewards.starsForScore(0.5), 1);
      expect(rewards.starsForScore(0.8), 2);
      expect(rewards.starsForScore(1.0), 3);
    });
  });

  group('QuestScoring', () {
    test('xp increases with stars and combo', () {
      final base = QuestScoring.xpForLevel(
        stars: 1,
        quizScore: 0.5,
        maxCombo: 1,
        practiceBonus: false,
      );
      final boosted = QuestScoring.xpForLevel(
        stars: 3,
        quizScore: 1.0,
        maxCombo: 4,
        practiceBonus: true,
      );
      expect(boosted, greaterThan(base));
    });
  });

  group('UserCopticQuestProgress persistence', () {
    test('fromJson handles Hive dynamic maps', () {
      final progress = UserCopticQuestProgress.fromJson({
        'userId': 'u1',
        'paths': {
          'bible': {
            'bible_001': {
              'levelId': 'bible_001',
              'stars': 2,
              'completed': true,
              'bestQuizScore': 0.8,
            },
          },
        },
        'totalXp': 100,
      });
      expect(progress.totalXp, 100);
      expect(progress.levelProgress('bible', 'bible_001').stars, 2);
    });
  });

  group('UserCopticQuestProgress streak', () {
    test('streak increments on consecutive days', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yKey =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      final progress = UserCopticQuestProgress(
        userId: 'u1',
        streakDays: 3,
        lastPlayDate: yKey,
      );
      final updated = progress.withStreakUpdate(DateTime.now());
      expect(updated.streakDays, 4);
    });
  });

  group('UserCopticQuestProgress', () {
    test('first level is always unlocked', () {
      const progress = UserCopticQuestProgress(userId: 'u1');
      expect(
        progress.isLevelUnlocked('bible', 'bible_001', ['bible_001', 'bible_002']),
        true,
      );
    });

    test('second level locked until first completed', () {
      final progress = UserCopticQuestProgress(
        userId: 'u1',
        paths: {
          'bible': {
            'bible_001': const LevelProgress(
              levelId: 'bible_001',
              completed: false,
            ),
          },
        },
      );
      expect(
        progress.isLevelUnlocked('bible', 'bible_002', ['bible_001', 'bible_002']),
        false,
      );
    });

    test('second level unlocks after first completed', () {
      final progress = UserCopticQuestProgress(
        userId: 'u1',
        paths: {
          'bible': {
            'bible_001': const LevelProgress(
              levelId: 'bible_001',
              completed: true,
              stars: 2,
            ),
          },
        },
      );
      expect(
        progress.isLevelUnlocked('bible', 'bible_002', ['bible_001', 'bible_002']),
        true,
      );
    });
  });

  group('LocalizedText', () {
    test('forLang falls back correctly', () {
      const text = LocalizedText(en: 'Hello', ar: 'مرحبا');
      expect(text.forLang('en'), 'Hello');
      expect(text.forLang('ar'), 'مرحبا');
    });
  });
}
