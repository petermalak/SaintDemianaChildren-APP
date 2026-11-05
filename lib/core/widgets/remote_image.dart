import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/api_endpoints.dart';
import '../constants/app_colors.dart';

/// Image from the server, cached on the device so it is not downloaded again on
/// every scroll and still shows when there is no connection.
class RemoteImage extends StatelessWidget {
  final String? path;
  final double size;
  final double borderRadius;
  final IconData fallbackIcon;
  final BoxFit fit;

  const RemoteImage({
    super.key,
    required this.path,
    required this.size,
    this.borderRadius = 8,
    this.fallbackIcon = Icons.image_outlined,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) return _fallback();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: ApiEndpoints.fullUrlForPath(path!),
        width: size,
        height: size,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, __) => Container(
          width: size,
          height: size,
          color: AppColors.textSecondary.withValues(alpha: 0.08),
        ),
        errorWidget: (_, __, ___) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(fallbackIcon, size: size * 0.5, color: AppColors.textSecondary),
    );
  }
}
