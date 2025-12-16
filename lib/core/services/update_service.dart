import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:saint_demiana_children/core/services/shorebird_code_push_stub.dart'
    if (dart.library.io) 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:saint_demiana_children/core/services/interface/i_update_service.dart';
import 'package:saint_demiana_children/core/services/logging_service.dart';

/// Service for handling app updates via Shorebird OTA updates
/// Only available on mobile platforms (Android/iOS)
class UpdateService implements IUpdateService {
  static final UpdateService _instance = UpdateService._internal();
  
  factory UpdateService() => _instance;
  
  UpdateService._internal();

  ShorebirdCodePush get _shorebirdCodePush => _createShorebirdInstance();
  static const String _tag = 'UpdateService';
  
  LoggingService get _logger => LoggingService.instance;

  ShorebirdCodePush _createShorebirdInstance() {
    return ShorebirdCodePush();
  }

  @override
  Future<Either<String, UpdateInfo>> checkForUpdate() async {
    if (kIsWeb) {
      const errorMessage = 'OTA updates are not supported on web platform';
      _logger.warning(errorMessage, tag: _tag);
      return const Left(errorMessage);
    }

    try {
      _logger.debug('Checking for updates...', tag: _tag);
      
      // Check if there's a new patch available
      final isUpdateAvailable = await _shorebirdCodePush.isNewPatchAvailableForDownload();
      
      if (kDebugMode) {
        print('📦 [UpdateService] Update available: $isUpdateAvailable');
      }

      if (!isUpdateAvailable) {
        _logger.debug('No updates available', tag: _tag);
        return Right(const UpdateInfo(
          isUpdateAvailable: false,
          isForceUpdate: false,
        ));
      }

      // Get current patch number
      final currentPatchNumber = await getCurrentPatchNumber();
      
      // Get the latest patch info
      final patchInfo = await _shorebirdCodePush.currentPatchNumber();
      
      // Determine if this is a force update
      // You can customize this logic based on your requirements
      // For now, we'll check if patch number difference is significant
      final isForceUpdate = await isForceUpdateRequired();

      _logger.info(
        'Update available: patch=$patchInfo, force=$isForceUpdate',
        tag: _tag,
      );

      return Right(UpdateInfo(
        isUpdateAvailable: true,
        isForceUpdate: isForceUpdate,
        patchNumber: patchInfo,
        updateVersion: await getCurrentVersion(),
      ));
    } catch (e) {
      final errorMessage = 'Error checking for updates: ${e.toString()}';
      _logger.error(
        'Failed to check for updates',
        tag: _tag,
        error: e,
      );
      return Left(errorMessage);
    }
  }

  @override
  Future<Either<String, bool>> downloadUpdate() async {
    if (kIsWeb) {
      const errorMessage = 'OTA updates are not supported on web platform';
      return const Left(errorMessage);
    }

    try {
      _logger.info('Downloading update...', tag: _tag);
      
      await _shorebirdCodePush.downloadUpdateIfAvailable();
      
      _logger.info('Update downloaded successfully', tag: _tag);
      return const Right(true);
    } catch (e) {
      final errorMessage = 'Error downloading update: ${e.toString()}';
      _logger.error(
        'Failed to download update',
        tag: _tag,
        error: e,
      );
      return Left(errorMessage);
    }
  }

  @override
  Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      _logger.error(
        'Error getting current version',
        tag: _tag,
        error: e,
      );
      return 'Unknown';
    }
  }

  @override
  Future<int?> getCurrentPatchNumber() async {
    if (kIsWeb) return null;
    
    try {
      final patchNumber = await _shorebirdCodePush.currentPatchNumber();
      return patchNumber;
    } catch (e) {
      _logger.error(
        'Error getting current patch number',
        tag: _tag,
        error: e,
      );
      return null;
    }
  }

  @override
  Future<bool> isForceUpdateRequired() async {
    if (kIsWeb) return false;
    
    try {
      // Check if there's a new patch available
      final isUpdateAvailable = await _shorebirdCodePush.isNewPatchAvailableForDownload();
      
      if (!isUpdateAvailable) {
        return false;
      }

      // You can customize this logic:
      // 1. Check backend API for force update flag
      // 2. Check patch metadata from Shorebird
      // 3. Compare patch numbers to determine if critical
      
      // For now, we'll use a simple heuristic:
      // If update is available and patch number is significantly higher, it's a force update
      final currentPatch = await getCurrentPatchNumber();
      
      // Example: If patch number difference is > 5, consider it force update
      // You can adjust this logic based on your needs
      // Or integrate with your backend API to get force update flag
      
      // For now, return false (optional update)
      // You can change this to true if you want all updates to be forced
      // Or implement backend API check here
      
      return false; // Change this based on your requirements
    } catch (e) {
      _logger.error(
        'Error checking force update requirement',
        tag: _tag,
        error: e,
      );
      return false;
    }
  }

  /// Checks for updates and downloads if available
  /// Returns UpdateInfo with update status
  Future<Either<String, UpdateInfo>> checkAndDownloadUpdate() async {
    final checkResult = await checkForUpdate();
    
    return checkResult.fold(
      (error) => Left(error),
      (updateInfo) async {
        if (!updateInfo.isUpdateAvailable) {
          return Right(updateInfo);
        }

        final downloadResult = await downloadUpdate();
        return downloadResult.fold(
          (error) => Left(error),
          (_) => Right(updateInfo),
        );
      },
    );
  }
}

