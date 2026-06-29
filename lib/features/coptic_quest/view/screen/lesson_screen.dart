import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../profile/repository/i_profile_repository.dart';
import '../../../scoring/repository/i_scoring_repository.dart';
import '../../repository/i_coptic_quest_repository.dart';
import '../../viewmodel/lesson_cubit/lesson_cubit.dart';
import '../widget/guide_character.dart';
import '../widget/lesson_phase_bar.dart';
import '../widget/minigames/practice_dispatcher.dart';
import '../widget/minigames/quiz_widget.dart';
import '../widget/minigames/story_slideshow.dart';
import '../widget/star_reward.dart';

class LessonScreen extends StatelessWidget {
  final String pathId;
  final String levelId;

  const LessonScreen({
    super.key,
    required this.pathId,
    required this.levelId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LessonCubit(
        sl<ICopticQuestRepository>(),
        pathId,
        levelId,
        scoringRepository: sl<IScoringRepository>(),
        profileRepository: sl<IProfileRepository>(),
      )..load(),
      child: BlocBuilder<LessonCubit, LessonState>(
        builder: (context, state) {
          if (state is LessonLoading || state is LessonInitial) {
            return CopticQuestScaffold(
              title: '',
              lang: 'ar',
              body: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }
          if (state is LessonError) {
            return CopticQuestScaffold(
              title: '',
              lang: 'ar',
              body: Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }

          final active = state as LessonActive;
          final lang = active.lessonLanguage;
          final cubit = context.read<LessonCubit>();

          return CopticQuestScaffold(
            title: active.lesson.title.forLang(lang),
            lang: lang,
            header: LessonPhaseBar(current: active.phase, lang: lang),
            onBack: () {
              if (active.phase == LessonPhase.reward) {
                context.go('/coptic-quest/$pathId');
              } else {
                Navigator.of(context).pop();
              }
            },
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.08, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(active.phase),
                child: _phaseBody(context, active, cubit, lang),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _phaseBody(
    BuildContext context,
    LessonActive active,
    LessonCubit cubit,
    String lang,
  ) {
    switch (active.phase) {
      case LessonPhase.hook:
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: GuideCharacter(
                  message: active.lesson.hook.forLang(lang),
                  lang: lang,
                  excited: true,
                ),
              ),
              cqPrimaryButton(
                label: cqStr('start', lang),
                onPressed: cubit.advanceFromHook,
              ),
            ],
          ),
        );
      case LessonPhase.teach:
        return StorySlideshow(
          slides: active.tierContent.slides,
          lang: lang,
          levelId: levelId,
          nextLabel: cqStr('next', lang),
          finishLabel: cqStr('continue', lang),
          onNext: () {},
          onComplete: cubit.finishTeach,
        );
      case LessonPhase.practice:
        return PracticeMinigameDispatcher(
          config: active.lesson.practice,
          lang: lang,
          matchTitle: cqStr('matchPairs', lang),
          sequenceTitle: cqStr('sequence', lang),
          continueLabel: cqStr('continue', lang),
          wrongLabel: cqStr('wrong', lang),
          onComplete: cubit.completePractice,
        );
      case LessonPhase.check:
        return QuizWidget(
          questions: active.lesson.quiz,
          lang: lang,
          tier: active.tier,
          currentIndex: active.quizIndex,
          currentCombo: active.currentCombo,
          progressLabel: cqStr('quizProgress', lang),
          correctLabel: cqStr('correct', lang),
          wrongLabel: cqStr('wrong', lang),
          onAnswered: cubit.answerQuiz,
        );
      case LessonPhase.reward:
        return StarReward(
          stars: active.earnedStars ?? 0,
          title: cqStr('levelComplete', lang),
          subtitle:
              '${active.correctAnswers}/${active.totalQuestions} ${cqStr('correct', lang)}',
          continueLabel: cqStr('continue', lang),
          stickerId: active.lesson.rewards.stickerId,
          xpEarned: active.xpEarned,
          classPointsEarned: active.classPointsEarned,
          maxCombo: active.maxCombo,
          isNewStarRecord: active.isNewStarRecord,
          isNewTimeRecord: active.isNewTimeRecord,
          lang: lang,
          onContinue: () => context.go('/coptic-quest/$pathId'),
        );
    }
  }
}
