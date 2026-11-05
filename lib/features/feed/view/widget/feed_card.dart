import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../model/feed_model.dart';

class FeedCard extends StatelessWidget {
  const FeedCard({
    super.key,
    required this.feed,
    this.isKhadem = false,
    this.onDelete,
    this.onEdit,
  });

  final FeedModel feed;
  final bool isKhadem;
  final Function(String)? onDelete;
  final Function(FeedModel)? onEdit;

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
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  IconData _getTypeIcon() {
    switch (feed.type) {
      case 'announcement':
        return Icons.campaign_rounded;
      case 'reminder':
        return Icons.event_rounded;
      case 'post':
        return Icons.article_rounded;
      case 'link':
        return Icons.link_rounded;
      default:
        return Icons.feed_rounded;
    }
  }

  Color _getTypeColor() {
    switch (feed.type) {
      case 'announcement':
        return const Color(0xFF1877F2); // Facebook blue
      case 'reminder':
        return const Color(0xFFFF9800); // Orange
      case 'post':
        return AppColors.primaryMaroon;
      case 'link':
        return const Color(0xFF4CAF50); // Green
      default:
        return AppColors.primaryMaroon;
    }
  }

  String _getTypeLabel() {
    switch (feed.type) {
      case 'announcement':
        return 'إعلان';
      case 'reminder':
        return 'تذكير';
      case 'post':
        return 'منشور';
      case 'link':
        return 'رابط';
      default:
        return '';
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with author, type badge, and actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                // Author avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryMaroon.withOpacity(0.1),
                  backgroundImage: feed.author?.profileImage != null
                      ? CachedNetworkImageProvider(
                          ApiEndpoints.fullUrlForPath(
                              feed.author!.profileImage!))
                      : null,
                  child: feed.author?.profileImage == null
                      ? Text(
                          feed.author?.name?.substring(0, 1).toUpperCase() ??
                              'خ',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryMaroon,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Author info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              feed.author?.name ?? 'خادم',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (feed.createdAt != null)
                            Text(
                              _formatDate(feed.createdAt),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                            ),
                          if (feed.feedClass != null) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                            Flexible(
                              child: Text(
                                feed.feedClass!.name ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          // Type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getTypeIcon(),
                                  size: 10,
                                  color: typeColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getTypeLabel(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: typeColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions menu (for khadem only)
                if (isKhadem)
                  PopupMenuButton(
                    icon: Icon(Icons.more_horiz_rounded,
                        size: 24, color: Colors.grey[600]),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    offset: const Offset(0, 40),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        onTap: () {
                          if (onEdit != null) {
                            onEdit!(feed);
                          }
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 12),
                            Text('تعديل'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          if (onDelete != null && feed.id != null) {
                            Future.delayed(const Duration(milliseconds: 100),
                                () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: const Text('تأكيد الحذف',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  content: const Text(
                                      'هل أنت متأكد من حذف هذا الإعلان؟'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text('إلغاء',
                                          style: TextStyle(
                                              color: Colors.grey[700])),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        onDelete!(feed.id!);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('حذف'),
                                    ),
                                  ],
                                ),
                              );
                            });
                          }
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('حذف', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Title and Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                if (feed.title != null && feed.title!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      feed.title!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            height: 1.4,
                            color: Colors.grey[900],
                          ),
                    ),
                  ),

                // Content
                if (feed.content != null && feed.content!.isNotEmpty)
                  _ExpandedText(text: feed.content!),
              ],
            ),
          ),

          // Event date card (for reminders) - Modern design
          if (feed.type == 'reminder' && feed.eventDate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange.withOpacity(0.08),
                      Colors.orange.withOpacity(0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.event_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'موعد الحدث',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            DateFormat('dd/MM/yyyy').format(feed.eventDate!),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.orange[900],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Link card (for link type) - Modern clickable design
          if (feed.type == 'link' && feed.link != null && feed.link!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _launchUrl(feed.link!),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green.withOpacity(0.08),
                          Colors.green.withOpacity(0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.link_rounded,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'رابط خارجي',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                feed.link!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.green[900],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 20,
                          color: Colors.green[700],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),
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
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey[800],
          height: 1.5,
          fontSize: 14,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: textStyle,
          maxLines: _isExpanded ? null : 4,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (widget.text.length > 150 || widget.text.split('\n').length > 4)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _isExpanded ? 'عرض أقل' : 'عرض المزيد',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primaryMaroon,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}
