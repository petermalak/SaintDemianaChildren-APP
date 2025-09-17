import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  static ImageCacheService get instance => _instance;

  final CacheManager _cacheManager = CacheManager(
    Config(
      'profile_images',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: 'profile_images'),
      fileService: HttpFileService(),
    ),
  );

  /// Get cached image file or download if not cached
  Future<File?> getCachedImage(String imageUrl) async {
    if (imageUrl.isEmpty) return null;
    
    try {
      final file = await _cacheManager.getSingleFile(imageUrl);
      return file.existsSync() ? file : null;
    } catch (e) {
      return null;
    }
  }

  /// Download and cache image
  Future<File?> downloadAndCacheImage(String imageUrl) async {
    if (imageUrl.isEmpty) return null;
    
    try {
      final file = await _cacheManager.getSingleFile(imageUrl);
      return file.existsSync() ? file : null;
    } catch (e) {
      return null;
    }
  }

  /// Clear specific image from cache
  Future<void> clearImageCache(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    
    try {
      await _cacheManager.removeFile(imageUrl);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Clear all cached images
  Future<void> clearAllCache() async {
    try {
      await _cacheManager.emptyCache();
    } catch (e) {
      // Ignore errors
    }
  }

  /// Get image with cache busting
  Future<File?> getImageWithCacheBusting(String imageUrl) async {
    if (imageUrl.isEmpty) return null;
    
    // Add timestamp to force refresh
    final cacheBustedUrl = '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    
    // Clear old cache first
    await clearImageCache(imageUrl);
    
    // Download new image
    return await downloadAndCacheImage(cacheBustedUrl);
  }

  /// Preload image into cache
  Future<void> preloadImage(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    
    try {
      await _cacheManager.getSingleFile(imageUrl);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Clear all profile image caches (useful when user logs out or changes)
  Future<void> clearAllProfileImages() async {
    try {
      await _cacheManager.emptyCache();
    } catch (e) {
      // Ignore errors
    }
  }
}

/// Custom Image widget that handles caching and refresh
class CachedProfileImage extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BoxFit? fit;
  final bool enableCacheBusting;

  const CachedProfileImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.fit,
    this.enableCacheBusting = false,
  });

  @override
  State<CachedProfileImage> createState() => _CachedProfileImageState();
}

class _CachedProfileImageState extends State<CachedProfileImage> {
  File? _cachedFile;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedProfileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      // Clear cache for old URL if it exists
      if (oldWidget.imageUrl != null && oldWidget.imageUrl!.isNotEmpty) {
        ImageCacheService.instance.clearImageCache(oldWidget.imageUrl!);
      }
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      File? imageFile;
      
      if (widget.enableCacheBusting) {
        imageFile = await ImageCacheService.instance.getImageWithCacheBusting(widget.imageUrl!);
      } else {
        imageFile = await ImageCacheService.instance.getCachedImage(widget.imageUrl!);
      }

      if (mounted) {
        setState(() {
          _cachedFile = imageFile;
          _isLoading = false;
          _hasError = imageFile == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.placeholder ?? const CircularProgressIndicator(),
      );
    }

    if (_hasError || _cachedFile == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.errorWidget ?? const Icon(Icons.person),
      );
    }

    return Image.file(
      _cachedFile!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit ?? BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: widget.errorWidget ?? const Icon(Icons.person),
        );
      },
    );
  }

  /// Refresh the image (useful after profile image updates)
  Future<void> refreshImage() async {
    if (widget.imageUrl != null) {
      await ImageCacheService.instance.clearImageCache(widget.imageUrl!);
      await _loadImage();
    }
  }

  /// Force refresh the image with cache busting
  Future<void> forceRefresh() async {
    if (widget.imageUrl != null) {
      await ImageCacheService.instance.clearImageCache(widget.imageUrl!);
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      await _loadImage();
    }
  }
}
