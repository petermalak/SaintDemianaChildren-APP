import 'package:flutter/material.dart';
import '../../model/scoring_models.dart';

class TierProgressWidget extends StatelessWidget {
  final UserScoreModel userScore;
  final ScoringTierModel currentTier;

  const TierProgressWidget({
    Key? key,
    required this.userScore,
    required this.currentTier,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = userScore.tierProgress;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'التقدم في المرحلة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (progress != null)
                  Text(
                    '${progress.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (progress != null) ...[
              LinearProgressIndicator(
                value: progress.percentage / 100,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _parseColor(currentTier.color),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الحالي: ${userScore.totalPoints}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (progress.max != null)
                    Text(
                      'التالي: ${progress.max}',
                      style: const TextStyle(fontSize: 14),
                    ),
                ],
              ),
              if (progress.pointsToNext > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'تحتاج ${progress.pointsToNext} نقطة للمرحلة التالية',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ] else
              const Text(
                'أنت في أعلى مرحلة!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null) return Colors.blue;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}
