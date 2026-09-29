import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../model/scoring_models.dart';
import '../../viewmodel/class_scores_cache.dart';

/// A widget that displays a user's score as a badge
/// Shows points and tier with appropriate styling
///
/// Scores come from [ClassScoresCache], which loads the whole class at once, so a
/// long member list costs one request instead of one per member.
class ScoreBadgeWidget extends StatefulWidget {
  final String userId;
  final String classId;
  final bool compact;

  const ScoreBadgeWidget({
    super.key,
    required this.userId,
    required this.classId,
    this.compact = true,
  });

  @override
  State<ScoreBadgeWidget> createState() => _ScoreBadgeWidgetState();
}

class _ScoreBadgeWidgetState extends State<ScoreBadgeWidget> {
  late final ClassScoresCache _cache = sl<ClassScoresCache>();

  @override
  void initState() {
    super.initState();
    _cache.addListener(_onCacheChanged);
    _cache.ensureLoaded(widget.classId);
  }

  @override
  void didUpdateWidget(ScoreBadgeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      _cache.ensureLoaded(widget.classId);
    }
  }

  @override
  void dispose() {
    _cache.removeListener(_onCacheChanged);
    super.dispose();
  }

  void _onCacheChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_cache.isLoaded(widget.classId)) {
      if (_cache.hasFailed(widget.classId)) return const SizedBox.shrink();
      return const _BadgePlaceholder();
    }

    final entry = _cache.entryFor(widget.classId, widget.userId);
    // Members with no points yet are absent from the leaderboard.
    final points = entry?.totalPoints ?? 0;
    final tier = entry?.tier;
    final rank = entry?.rank;
    final tierColor =
        tier != null ? _parseColor(tier.color) : AppColors.accentGold;

    return widget.compact
        ? _buildCompactBadge(points, tierColor)
        : _buildFullBadge(points, tier, rank, tierColor);
  }

  Widget _buildCompactBadge(int points, Color tierColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: tierColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tierColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events,
            size: 12,
            color: tierColor,
          ),
          const SizedBox(width: 3),
          Text(
            '$points',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: tierColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBadge(
    int points,
    ScoringTierModel? tier,
    int? rank,
    Color tierColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tierColor.withValues(alpha: 0.2),
            tierColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tierColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events,
                size: 20,
                color: tierColor,
              ),
              const SizedBox(width: 8),
              Text(
                '$points',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: tierColor,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'نقطة',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          if (tier != null) ...[
            const SizedBox(height: 4),
            Text(
              tier.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tierColor,
              ),
            ),
          ],
          if (rank != null) ...[
            const SizedBox(height: 2),
            Text(
              'الترتيب #$rank',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null) return AppColors.accentGold;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.accentGold;
    }
  }
}

/// Neutral shape while the class scores load, so rows do not change height.
class _BadgePlaceholder extends StatelessWidget {
  const _BadgePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
