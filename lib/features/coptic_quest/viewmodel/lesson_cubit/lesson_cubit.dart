import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../profile/repository/i_profile_repository.dart';
import '../../../scoring/repository/i_scoring_repository.dart';
import '../../core/quest_scoring.dart';
import '../../model/lesson_model.dart';
import '../../repository/i_coptic_quest_repository.dart';

enum LessonPhase { hook, teach, practice, check, reward }

abstract class LessonState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LessonInitial extends LessonState {}

class LessonLoading extends LessonState {}

class LessonActive extends LessonState {
  final LessonModel lesson;
  final String tier;
  final String lessonLanguage;
  final LessonPhase phase;
  final int slideIndex;
  final int quizIndex;
  final int correctAnswers;
  final int currentCombo;
  final int maxCombo;
  final double? finalQuizScore;
  final int? earnedStars;
  final int? xpEarned;
  final int? classPointsEarned;
  final bool isNewStarRecord;
  final bool isNewTimeRecord;
  final bool practiceBonus;
  final bool practiceComplete;

  LessonActive({
    required this.lesson,
    required this.tier,
    required this.lessonLanguage,
    required this.phase,
    this.slideIndex = 0,
    this.quizIndex = 0,
    this.correctAnswers = 0,
    this.currentCombo = 0,
    this.maxCombo = 0,
    this.finalQuizScore,
    this.earnedStars,
    this.xpEarned,
    this.classPointsEarned,
    this.isNewStarRecord = false,
    this.isNewTimeRecord = false,
    this.practiceBonus = false,
    this.practiceComplete = false,
  });

  TierContent get tierContent => lesson.tierContent(tier);

  int get totalSlides => tierContent.slides.length;
  int get totalQuestions => lesson.quiz.length;

  LessonActive copyWith({
    LessonPhase? phase,
    int? slideIndex,
    int? quizIndex,
    int? correctAnswers,
    int? currentCombo,
    int? maxCombo,
    double? finalQuizScore,
    int? earnedStars,
    int? xpEarned,
    int? classPointsEarned,
    bool? isNewStarRecord,
    bool? isNewTimeRecord,
    bool? practiceBonus,
    bool? practiceComplete,
  }) {
    return LessonActive(
      lesson: lesson,
      tier: tier,
      lessonLanguage: lessonLanguage,
      phase: phase ?? this.phase,
      slideIndex: slideIndex ?? this.slideIndex,
      quizIndex: quizIndex ?? this.quizIndex,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      currentCombo: currentCombo ?? this.currentCombo,
      maxCombo: maxCombo ?? this.maxCombo,
      finalQuizScore: finalQuizScore ?? this.finalQuizScore,
      earnedStars: earnedStars ?? this.earnedStars,
      xpEarned: xpEarned ?? this.xpEarned,
      classPointsEarned: classPointsEarned ?? this.classPointsEarned,
      isNewStarRecord: isNewStarRecord ?? this.isNewStarRecord,
      isNewTimeRecord: isNewTimeRecord ?? this.isNewTimeRecord,
      practiceBonus: practiceBonus ?? this.practiceBonus,
      practiceComplete: practiceComplete ?? this.practiceComplete,
    );
  }

  @override
  List<Object?> get props => [
        lesson,
        tier,
        lessonLanguage,
        phase,
        slideIndex,
        quizIndex,
        correctAnswers,
        currentCombo,
        maxCombo,
        finalQuizScore,
        earnedStars,
        xpEarned,
        classPointsEarned,
        isNewStarRecord,
        isNewTimeRecord,
        practiceBonus,
        practiceComplete,
      ];
}

class LessonError extends LessonState {
  final String message;
  LessonError(this.message);
  @override
  List<Object?> get props => [message];
}

class LessonCubit extends Cubit<LessonState> {
  final ICopticQuestRepository _repository;
  final IScoringRepository? _scoringRepository;
  final IProfileRepository? _profileRepository;
  final String pathId;
  final String levelId;

  DateTime? _lessonStart;

  LessonCubit(
    this._repository,
    this.pathId,
    this.levelId, {
    IScoringRepository? scoringRepository,
    IProfileRepository? profileRepository,
  })  : _scoringRepository = scoringRepository,
        _profileRepository = profileRepository,
        super(LessonInitial());

  Future<void> load() async {
    emit(LessonLoading());
    try {
      final lesson = await _repository.getLesson(pathId, levelId);
      final tier = await _repository.getTier();
      final lang = await _repository.getLessonLanguage();
      _lessonStart = DateTime.now();
      emit(LessonActive(
        lesson: lesson,
        tier: tier,
        lessonLanguage: lang,
        phase: LessonPhase.hook,
      ));
    } catch (e) {
      emit(LessonError(e.toString()));
    }
  }

  void finishTeach() {
    final s = state;
    if (s is! LessonActive) return;
    emit(s.copyWith(phase: LessonPhase.practice, practiceComplete: false));
  }

  void advanceFromHook() {
    final s = state;
    if (s is! LessonActive) return;
    emit(s.copyWith(phase: LessonPhase.teach, slideIndex: 0));
  }

  void nextSlide() {
    final s = state;
    if (s is! LessonActive) return;
    if (s.slideIndex < s.totalSlides - 1) {
      emit(s.copyWith(slideIndex: s.slideIndex + 1));
    } else {
      emit(s.copyWith(phase: LessonPhase.practice, practiceComplete: false));
    }
  }

  void completePractice({bool fastComplete = true}) {
    final s = state;
    if (s is! LessonActive) return;
    emit(s.copyWith(
      phase: LessonPhase.check,
      quizIndex: 0,
      correctAnswers: 0,
      currentCombo: 0,
      maxCombo: 0,
      practiceBonus: fastComplete,
      practiceComplete: true,
    ));
  }

  void answerQuiz(bool correct) {
    final s = state;
    if (s is! LessonActive) return;

    final combo = correct ? s.currentCombo + 1 : 0;
    final maxCombo = combo > s.maxCombo ? combo : s.maxCombo;
    final newCorrect = s.correctAnswers + (correct ? 1 : 0);

    if (s.quizIndex < s.totalQuestions - 1) {
      emit(s.copyWith(
        quizIndex: s.quizIndex + 1,
        correctAnswers: newCorrect,
        currentCombo: combo,
        maxCombo: maxCombo,
      ));
    } else {
      _finishLesson(s, newCorrect, maxCombo);
    }
  }

  Future<void> _finishLesson(
    LessonActive s,
    int newCorrect,
    int maxCombo,
  ) async {
    final score = s.totalQuestions > 0 ? newCorrect / s.totalQuestions : 1.0;
    final stars = s.lesson.rewards.starsForScore(score);
    final xp = QuestScoring.xpForLevel(
      stars: stars,
      quizScore: score,
      maxCombo: maxCombo,
      practiceBonus: s.practiceBonus,
    );
    final classPoints = QuestScoring.classPointsForStars(stars);

    final progress = await _repository.getProgress();
    final existing = progress.levelProgress(pathId, levelId);
    final isNewStarRecord = stars > existing.stars;

    int? completionMs;
    bool isNewTimeRecord = false;
    if (_lessonStart != null) {
      completionMs = DateTime.now().difference(_lessonStart!).inMilliseconds;
      if (existing.bestTimeMs == null || completionMs < existing.bestTimeMs!) {
        isNewTimeRecord = true;
      }
    }

    emit(s.copyWith(
      correctAnswers: newCorrect,
      finalQuizScore: score,
      earnedStars: stars,
      xpEarned: xp,
      classPointsEarned: classPoints,
      isNewStarRecord: isNewStarRecord,
      isNewTimeRecord: isNewTimeRecord,
      maxCombo: maxCombo,
      phase: LessonPhase.reward,
    ));

    await _repository.saveLevelResult(
      pathId: pathId,
      levelId: levelId,
      stars: stars,
      quizScore: score,
      xpEarned: xp,
      completionTimeMs: completionMs,
    );

    await _awardClassPoints(classPoints, stars);
  }

  Future<void> _awardClassPoints(int points, int stars) async {
    final scoring = _scoringRepository;
    final profile = _profileRepository;
    if (scoring == null || profile == null) return;

    final user = profile.user;
    final userId = user?.id;
    final classId = user?.classId;
    if (userId == null || classId == null || classId.isEmpty) return;

    await scoring.addPoints(
      userId,
      classId,
      points,
      'coptic_quest:$levelId:${stars}stars',
    );
  }

  void markPracticeComplete() {
    final s = state;
    if (s is! LessonActive) return;
    emit(s.copyWith(practiceComplete: true));
  }
}
