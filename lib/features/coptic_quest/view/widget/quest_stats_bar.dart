import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../coptic_quest_strings.dart';
import '../../model/level_progress.dart';
import '../../theme/coptic_quest_colors.dart';

class QuestStatsBar extends StatelessWidget {
  final UserCopticQuestProgress progress;
  final String lang;
  final VoidCallback? onLeaderboardTap;

  const QuestStatsBar({
    super.key,
    required this.progress,
    required this.lang,
    this.onLeaderboardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: CopticQuestColors.cardDecoration(),
      child: Row(
        children: [
          _StatChip(
            emoji: '⭐',
            value: '${progress.totalStars()}',
            label: CopticQuestStrings.get('stars', lang),
            color: CopticQuestColors.accentGold,
          ),
          const SizedBox(width: 10),
          _StatChip(
            emoji: '⚡',
            value: '${progress.totalXp}',
            label: CopticQuestStrings.get('xp', lang),
            color: CopticQuestColors.funOrange,
          ),
          const SizedBox(width: 10),
          _StatChip(
            emoji: '🔥',
            value: '${progress.streakDays}',
            label: CopticQuestStrings.get('streak', lang),
            color: CopticQuestColors.funPink,
          ),
          if (onLeaderboardTap != null) ...[
            const Spacer(),
            Material(
              color: CopticQuestColors.funGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: onLeaderboardTap,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 4),
                      Text(
                        CopticQuestStrings.get('leaderboard', lang),
                        style: const TextStyle(
                          color: CopticQuestColors.funGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.15, end: 0, curve: Curves.easeOutCubic);
  }
}

class _StatChip extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: CopticQuestColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
