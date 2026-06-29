import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../profile/repository/i_profile_repository.dart';
import '../model/lesson_model.dart';
import '../model/level_progress.dart';
import '../model/path_model.dart';
import 'i_coptic_quest_repository.dart';
import 'lesson_content_loader.dart';

class CopticQuestRepository implements ICopticQuestRepository {
  static const String progressBoxName = 'coptic_quest_progress';
  static const String tierKey = 'cq_tier';
  static const String lessonLangKey = 'cq_lesson_lang';

  final LessonContentLoader _loader;
  final IProfileRepository _profileRepository;

  CopticQuestRepository(this._loader, this._profileRepository);

  String? get _userId => _profileRepository.user?.id;

  Future<Box> _openBox() async {
    if (!Hive.isBoxOpen(progressBoxName)) {
      return Hive.openBox(progressBoxName);
    }
    return Hive.box(progressBoxName);
  }

  @override
  Future<CopticQuestManifest> getManifest() => _loader.loadManifest();

  @override
  Future<LessonModel> getLesson(String pathId, String levelId) async {
    final manifest = await getManifest();
    return _loader.loadLessonById(manifest, pathId, levelId);
  }

  @override
  Future<UserCopticQuestProgress> getProgress() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      return UserCopticQuestProgress.empty('');
    }
    final box = await _openBox();
    final raw = box.get(userId);
    if (raw == null) {
      final prefs = await SharedPreferences.getInstance();
      return UserCopticQuestProgress(
        userId: userId,
        tier: prefs.getString(tierKey) ?? 'T1',
        lessonLanguage: prefs.getString(lessonLangKey) ?? 'ar',
      );
    }
    final progress = UserCopticQuestProgress.fromJson(
      Map<String, dynamic>.from(raw as Map),
    );
    final prefs = await SharedPreferences.getInstance();
    return progress.copyWith(
      tier: prefs.getString(tierKey) ?? progress.tier,
      lessonLanguage: prefs.getString(lessonLangKey) ?? progress.lessonLanguage,
    );
  }

  Future<void> _saveProgress(UserCopticQuestProgress progress) async {
    final box = await _openBox();
    await box.put(progress.userId, progress.toJson());
  }

  @override
  Future<void> saveLevelResult({
    required String pathId,
    required String levelId,
    required int stars,
    required double quizScore,
    required int xpEarned,
    int? completionTimeMs,
  }) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;

    final now = DateTime.now();
    var progress = await getProgress();
    progress = progress.withStreakUpdate(now);

    final pathProgress =
        Map<String, LevelProgress>.from(progress.paths[pathId] ?? {});
    final existing = pathProgress[levelId] ?? LevelProgress(levelId: levelId);

    int? bestTime = existing.bestTimeMs;
    if (completionTimeMs != null) {
      if (bestTime == null || completionTimeMs < bestTime) {
        bestTime = completionTimeMs;
      }
    }

    final updated = existing.copyWith(
      stars: stars > existing.stars ? stars : existing.stars,
      completed: true,
      bestQuizScore:
          quizScore > existing.bestQuizScore ? quizScore : existing.bestQuizScore,
      attempts: existing.attempts + 1,
      bestTimeMs: bestTime,
    );
    pathProgress[levelId] = updated;

    final allPaths = Map<String, Map<String, LevelProgress>>.from(progress.paths);
    allPaths[pathId] = pathProgress;

    await _saveProgress(progress.copyWith(
      paths: allPaths,
      lastPlayedAt: now,
      totalXp: progress.totalXp + xpEarned,
    ));
  }

  @override
  Future<void> setTier(String tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tierKey, tier);
    final userId = _userId;
    if (userId != null && userId.isNotEmpty) {
      final progress = await getProgress();
      await _saveProgress(progress.copyWith(tier: tier));
    }
  }

  @override
  Future<void> setLessonLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lessonLangKey, lang);
    final userId = _userId;
    if (userId != null && userId.isNotEmpty) {
      final progress = await getProgress();
      await _saveProgress(progress.copyWith(lessonLanguage: lang));
    }
  }

  @override
  Future<String> getTier() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tierKey) ?? 'T1';
  }

  @override
  Future<String> getLessonLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(lessonLangKey) ?? 'ar';
  }

  @override
  bool isLevelUnlocked(
    String pathId,
    String levelId,
    List<String> orderedIds,
  ) {
    final userId = _userId;
    if (userId == null) return levelId == orderedIds.firstOrNull;
    // Sync check — caller should use getProgress for accurate state
    return true;
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
