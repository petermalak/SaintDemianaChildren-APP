import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/quest_scoring.dart';
import '../../theme/coptic_quest_colors.dart';
import '../../theme/level_visuals.dart';
import 'confetti_overlay.dart';
import 'guide_character.dart';

class StarReward extends StatefulWidget {
  final int stars;
  final String title;
  final String subtitle;
  final String continueLabel;
  final String? stickerId;
  final int? xpEarned;
  final int? classPointsEarned;
  final int maxCombo;
  final bool isNewStarRecord;
  final bool isNewTimeRecord;
  final String lang;
  final VoidCallback onContinue;

  const StarReward({
    super.key,
    required this.stars,
    required this.title,
    required this.subtitle,
    required this.continueLabel,
    this.stickerId,
    this.xpEarned,
    this.classPointsEarned,
    this.maxCombo = 0,
    this.isNewStarRecord = false,
    this.isNewTimeRecord = false,
    this.lang = 'ar',
    required this.onContinue,
  });

  @override
  State<StarReward> createState() => _StarRewardState();
}

class _StarRewardState extends State<StarReward>
    with TickerProviderStateMixin {
  late final List<AnimationController> _starControllers;

  @override
  void initState() {
    super.initState();
    _starControllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
    });
    _animateStars();
  }

  Future<void> _animateStars() async {
    await Future.delayed(const Duration(milliseconds: 400));
    for (var i = 0; i < widget.stars; i++) {
      if (!mounted) return;
      await Future.delayed(Duration(milliseconds: 280 * i));
      _starControllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _starControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stickerEmoji = LevelVisuals.stickerEmoji(widget.stickerId);

    return Stack(
      children: [
        const Positioned.fill(child: ConfettiOverlay(active: true)),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFFF9F43)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: CopticQuestColors.funOrange.withValues(alpha: 0.5),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        stickerEmoji,
                        style: const TextStyle(fontSize: 56),
                      ),
                    ),
                  ),
                ).animate().shake(hz: 2, duration: 800.ms, delay: 600.ms),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.maxCombo >= 2) ...[
                  const SizedBox(height: 8),
                  Text(
                    QuestScoring.comboLabel(widget.maxCombo, widget.lang),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _RewardBadges(
                  xp: widget.xpEarned,
                  classPoints: widget.classPointsEarned,
                  isNewStar: widget.isNewStarRecord,
                  isNewTime: widget.isNewTimeRecord,
                  lang: widget.lang,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return AnimatedBuilder(
                      animation: _starControllers[i],
                      builder: (context, child) {
                        return Transform.scale(
                          scale: Curves.elasticOut.transform(
                            _starControllers[i].value,
                          ),
                          child: child,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          i < widget.stars ? '⭐' : '☆',
                          style: TextStyle(
                            fontSize: 56,
                            color: i < widget.stars
                                ? CopticQuestColors.accentGold
                                : Colors.white54,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                cqPrimaryButton(
                  label: widget.continueLabel,
                  onPressed: widget.onContinue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RewardBadges extends StatelessWidget {
  final int? xp;
  final int? classPoints;
  final bool isNewStar;
  final bool isNewTime;
  final String lang;

  const _RewardBadges({
    this.xp,
    this.classPoints,
    required this.isNewStar,
    required this.isNewTime,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (xp != null)
          _Badge(
            emoji: '⚡',
            text: '+$xp ${cqStr('xp', lang)}',
            color: CopticQuestColors.funOrange,
          ),
        if (classPoints != null && classPoints! > 0)
          _Badge(
            emoji: '🏫',
            text: '+$classPoints ${cqStr('classPoints', lang)}',
            color: CopticQuestColors.funGreen,
          ),
        if (isNewStar)
          _Badge(
            emoji: '🌟',
            text: cqStr('newRecord', lang),
            color: CopticQuestColors.funPurple,
          ),
        if (isNewTime)
          _Badge(
            emoji: '⏱️',
            text: cqStr('fastestTime', lang),
            color: CopticQuestColors.skyTop,
          ),
      ],
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2);
  }
}

class _Badge extends StatelessWidget {
  final String emoji;
  final String text;
  final Color color;

  const _Badge({
    required this.emoji,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
