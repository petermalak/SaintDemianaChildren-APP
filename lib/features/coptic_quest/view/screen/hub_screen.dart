import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../coptic_quest_strings.dart';
import '../../repository/i_coptic_quest_repository.dart';
import '../../theme/coptic_quest_colors.dart';
import '../../viewmodel/coptic_quest_progress_cubit/coptic_quest_progress_cubit.dart';
import '../widget/guide_character.dart';
import '../widget/path_card.dart';
import '../widget/quest_stats_bar.dart';
import 'quest_leaderboard_sheet.dart';
import 'settings_sheet.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CopticQuestProgressCubit(sl<ICopticQuestRepository>())..load(),
      child: BlocBuilder<CopticQuestProgressCubit, CopticQuestProgressState>(
        builder: (context, state) {
          final lang = state is CopticQuestProgressLoaded
              ? state.progress.lessonLanguage
              : 'ar';

          return CopticQuestScaffold(
            title: cqStr('appTitle', lang),
            lang: lang,
            actions: [
              IconButton(
                onPressed: () => showCopticQuestSettings(context, lang),
                icon: const Icon(Icons.settings_outlined),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ],
            body: _buildBody(context, state, lang),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CopticQuestProgressState state,
    String lang,
  ) {
    if (state is CopticQuestProgressLoading ||
        state is CopticQuestProgressInitial) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (state is CopticQuestProgressError) {
      return Center(
        child: Text(
          state.message,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    final loaded = state as CopticQuestProgressLoaded;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _HeroBanner(lang: lang),
        const SizedBox(height: 16),
        QuestStatsBar(
          progress: loaded.progress,
          lang: lang,
          onLeaderboardTap: () => showQuestLeaderboard(context, lang),
        ),
        const SizedBox(height: 20),
        GuideCharacter(
          message: cqStr('hubWelcome', lang),
          lang: lang,
        ),
        const SizedBox(height: 24),
        Text(
          cqStr('pickPath', lang),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
          ),
        ),
        const SizedBox(height: 12),
        ...loaded.manifest.paths.asMap().entries.map((entry) {
          final path = entry.value;
          final index = entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: PathCard(
              title: _pathTitle(path.id, lang),
              description: _pathDesc(path.id, lang),
              pathId: path.id,
              enabled: path.enabled,
              comingSoonLabel: cqStr('comingSoon', lang),
              onTap: () => context.push('/coptic-quest/${path.id}'),
            )
                .animate(delay: (120 * index).ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.15, curve: Curves.easeOutCubic),
          );
        }),
      ],
    );
  }

  String _pathTitle(String pathId, String lang) {
    switch (pathId) {
      case 'letters':
        return CopticQuestStrings.get('pathLetters', lang);
      case 'prayers':
        return CopticQuestStrings.get('pathPrayers', lang);
      default:
        return CopticQuestStrings.get('pathBible', lang);
    }
  }

  String _pathDesc(String pathId, String lang) {
    switch (pathId) {
      case 'letters':
        return CopticQuestStrings.get('pathLettersDesc', lang);
      case 'prayers':
        return CopticQuestStrings.get('pathPrayersDesc', lang);
      default:
        return CopticQuestStrings.get('pathBibleDesc', lang);
    }
  }
}

class _HeroBanner extends StatelessWidget {
  final String lang;

  const _HeroBanner({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFF9F43)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: CopticQuestColors.funOrange.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cqStr('hubHeroTitle', lang),
                  style: const TextStyle(
                    color: CopticQuestColors.textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  cqStr('hubHeroSubtitle', lang),
                  style: TextStyle(
                    color: CopticQuestColors.textDark.withValues(alpha: 0.75),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Text('🎮', style: TextStyle(fontSize: 52)),
        ],
      ),
    );
  }
}
