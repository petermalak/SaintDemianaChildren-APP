import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../model/feed_model.dart';

class FeedCard extends StatelessWidget {
  const FeedCard({super.key, required this.feed});
  final FeedModel feed;

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return difference.inMinutes <= 1
            ? 'الآن'
            : 'منذ ${difference.inMinutes} دقيقة';
      }
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return DateFormat('dd/MM/yyyy', 'ar').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    print(feed.imageUrl);
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      color: AppColors.backgroundCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (feed.date != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMaroon.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.primaryMaroon,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _formatDate(feed.date),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primaryMaroon,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                if (feed.date != null) const SizedBox(height: AppSpacing.sm),
                if (feed.title != null && feed.title!.isNotEmpty)
                  Text(
                    feed.title!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (feed.title != null &&
                    feed.title!.isNotEmpty &&
                    feed.description != null &&
                    feed.description!.isNotEmpty)
                  const SizedBox(height: AppSpacing.sm),
                if (feed.description != null && feed.description!.isNotEmpty)
                  _ExpandedText(
                    text: feed.description!,
                  ),
              ],
            ),
          ),
          if (feed.imageUrl != null && feed.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppSpacing.radiusLg),
                bottomRight: Radius.circular(AppSpacing.radiusLg),
              ),
              child: Image.network(
                feed.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: AppColors.borderLight,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryMaroon,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: AppColors.borderLight,
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: AppColors.primaryMaroon.withValues(alpha: 0.7),
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(
            height: 10,
          )
        ],
      ),
    );
  }
}

class _ExpandedText extends StatefulWidget {
  final String text;

  const _ExpandedText({
    required this.text,
  });

  @override
  _ExpandedTextState createState() => _ExpandedTextState();
}

class _ExpandedTextState extends State<_ExpandedText> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryMaroon.withValues(alpha: 0.7),
                height: 1.4,
              ),
          maxLines: _isDescriptionExpanded ? null : 2,
          overflow: _isDescriptionExpanded
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
        ),
        if (widget.text.length > 100)
          GestureDetector(
            onTap: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                _isDescriptionExpanded ? 'عرض أقل' : 'عرض المزيد',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryMaroon,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}
