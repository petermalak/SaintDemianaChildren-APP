import '../model/lesson_model.dart';
import '../model/level_progress.dart';
import '../model/path_model.dart';

abstract class ICopticQuestRepository {
  Future<CopticQuestManifest> getManifest();
  Future<LessonModel> getLesson(String pathId, String levelId);
  Future<UserCopticQuestProgress> getProgress();
  Future<void> saveLevelResult({
    required String pathId,
    required String levelId,
    required int stars,
    required double quizScore,
    required int xpEarned,
    int? completionTimeMs,
  });
  Future<void> setTier(String tier);
  Future<void> setLessonLanguage(String lang);
  Future<String> getTier();
  Future<String> getLessonLanguage();
  bool isLevelUnlocked(String pathId, String levelId, List<String> orderedIds);
}
