import 'package:flutter/material.dart';

import '../../coptic_quest_strings.dart';
import '../../theme/coptic_quest_colors.dart';
import '../../viewmodel/lesson_cubit/lesson_cubit.dart';

class LessonPhaseBar extends StatelessWidget {
  final LessonPhase current;
  final String lang;

  const LessonPhaseBar({
    super.key,
    required this.current,
    required this.lang,
  });

  static const _phases = LessonPhase.values;
  static const _phaseEmojis = ['👋', '📖', '🎮', '❓', '🏆'];

  String _label(LessonPhase phase) {
    switch (phase) {
      case LessonPhase.hook:
        return CopticQuestStrings.get('hookTitle', lang);
      case LessonPhase.teach:
        return CopticQuestStrings.get('teachTitle', lang);
      case LessonPhase.practice:
        return CopticQuestStrings.get('practiceTitle', lang);
      case LessonPhase.check:
        return CopticQuestStrings.get('checkTitle', lang);
      case LessonPhase.reward:
        return CopticQuestStrings.get('rewardTitle', lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _phases.indexOf(current);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: List.generate(_phases.length, (i) {
              final done = i < currentIndex;
              final active = i == currentIndex;
              return Expanded(
                child: Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: done || active
                                ? CopticQuestColors.funGreen
                                : Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: active ? 36 : 28,
                      height: active ? 36 : 28,
                      decoration: BoxDecoration(
                        color: done
                            ? CopticQuestColors.funGreen
                            : active
                                ? CopticQuestColors.funOrange
                                : Colors.white.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: CopticQuestColors.funOrange
                                      .withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          _phaseEmojis[i],
                          style: TextStyle(fontSize: active ? 16 : 13),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            _label(current),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}
