import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../repository/i_coptic_quest_repository.dart';
import '../../theme/coptic_quest_colors.dart';
import '../../theme/level_visuals.dart';
import '../../viewmodel/coptic_quest_progress_cubit/coptic_quest_progress_cubit.dart';
import '../widget/guide_character.dart';
import '../widget/level_node.dart';

class PathMapScreen extends StatelessWidget {
  final String pathId;

  const PathMapScreen({super.key, required this.pathId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CopticQuestProgressCubit(sl<ICopticQuestRepository>())..load(),
      child: BlocBuilder<CopticQuestProgressCubit, CopticQuestProgressState>(
        builder: (context, state) {
          final lang = state is CopticQuestProgressLoaded
              ? state.progress.lessonLanguage
              : 'ar';

          if (state is CopticQuestProgressLoading ||
              state is CopticQuestProgressInitial) {
            return CopticQuestScaffold(
              title: '',
              lang: lang,
              body: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }
          if (state is CopticQuestProgressError) {
            return CopticQuestScaffold(
              title: '',
              lang: lang,
              body: Center(
                child: Text(state.message, style: const TextStyle(color: Colors.white)),
              ),
            );
          }

          final loaded = state as CopticQuestProgressLoaded;
          final path = loaded.manifest.pathById(pathId);
          if (path == null) {
            return CopticQuestScaffold(
              title: '',
              lang: lang,
              body: const Center(
                child: Text('Path not found', style: TextStyle(color: Colors.white)),
              ),
            );
          }

          final sortedLevels = [...path.levels]..sort((a, b) => a.order.compareTo(b.order));
          final completedCount = sortedLevels
              .where((l) => loaded.levelProgress(pathId, l.id).completed)
              .length;

          return CopticQuestScaffold(
            title: path.title.forLang(lang),
            lang: lang,
            body: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              children: [
                _PathProgressHeader(
                  lang: lang,
                  completed: completedCount,
                  total: sortedLevels.length,
                  pathEmoji: LevelVisuals.pathEmoji(pathId),
                ),
                const SizedBox(height: 16),
                ...List.generate(sortedLevels.length, (index) {
                  final level = sortedLevels[index];
                  final progress = loaded.levelProgress(pathId, level.id);
                  final unlocked = loaded.isUnlocked(pathId, level.id);
                  final prevCompleted = index > 0
                      ? loaded
                          .levelProgress(pathId, sortedLevels[index - 1].id)
                          .completed
                      : true;

                  return Column(
                    children: [
                      if (index > 0)
                        PathTrail(completed: prevCompleted),
                      Align(
                        alignment: index.isEven
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: LevelNode(
                          levelId: level.id,
                          title: level.title?.forLang(lang) ??
                              '${lang == 'en' ? 'Level' : 'مستوى'} ${level.order}',
                          stars: progress.stars,
                          unlocked: unlocked,
                          completed: progress.completed,
                          lockedLabel: cqStr('locked', lang),
                          onTap: () => context.push(
                            '/coptic-quest/$pathId/${level.id}',
                          ),
                        )
                            .animate(delay: (100 * index).ms)
                            .fadeIn()
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              curve: Curves.elasticOut,
                            ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PathProgressHeader extends StatelessWidget {
  final String lang;
  final int completed;
  final int total;
  final String pathEmoji;

  const _PathProgressHeader({
    required this.lang,
    required this.completed,
    required this.total,
    required this.pathEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: CopticQuestColors.cardDecoration(),
      child: Row(
        children: [
          Text(pathEmoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cqStr('pathProgress', lang)
                      .replaceAll('{done}', '$completed')
                      .replaceAll('{total}', '$total'),
                  style: const TextStyle(
                    color: CopticQuestColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: CopticQuestColors.skyBottom,
                    color: CopticQuestColors.funGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
