import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../repository/i_scoring_repository.dart';
import '../../model/scoring_models.dart';

/// A widget that displays a user's score as a badge
/// Shows points and tier with appropriate styling
class ScoreBadgeWidget extends StatefulWidget {
  final String userId;
  final String classId;
  final bool compact;

  const ScoreBadgeWidget({
    Key? key,
    required this.userId,
    required this.classId,
    this.compact = true,
  }) : super(key: key);

  @override
  State<ScoreBadgeWidget> createState() => _ScoreBadgeWidgetState();
}

class _ScoreBadgeWidgetState extends State<ScoreBadgeWidget> {
  UserScoreModel? _userScore;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  @override
  void didUpdateWidget(ScoreBadgeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload score if userId or classId changed
    if (oldWidget.userId != widget.userId ||
        oldWidget.classId != widget.classId) {
      _loadScore();
    }
  }

  Future<void> _loadScore() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await sl<IScoringRepository>().getUserScore(
        widget.userId,
        widget.classId,
      );

      result.fold(
        (error) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          }
        },
        (score) {
          if (mounted) {
            setState(() {
              _userScore = score;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.compact
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const CircularProgressIndicator();
    }

    if (_hasError || _userScore == null) {
      return const SizedBox.shrink();
    }

    if (widget.compact) {
      return _buildCompactBadge();
    } else {
      return _buildFullBadge();
    }
  }

  Widget _buildCompactBadge() {
    final tier = _userScore!.currentTier;
    final tierColor =
        tier != null ? _parseColor(tier.color) : AppColors.accentGold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: tierColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tierColor.withOpacity(0.3)),
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
            '${_userScore!.totalPoints}',
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

  Widget _buildFullBadge() {
    final tier = _userScore!.currentTier;
    final tierColor =
        tier != null ? _parseColor(tier.color) : AppColors.accentGold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tierColor.withOpacity(0.2),
            tierColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tierColor.withOpacity(0.3)),
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
                '${_userScore!.totalPoints}',
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
          if (_userScore!.rank != null) ...[
            const SizedBox(height: 2),
            Text(
              'الترتيب #${_userScore!.rank}',
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
