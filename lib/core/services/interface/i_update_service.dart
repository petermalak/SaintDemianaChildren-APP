import 'package:dartz/dartz.dart';

/// Update information model
class UpdateInfo {
  final bool isUpdateAvailable;
  final bool isForceUpdate;
  final String? updateVersion;
  final String? releaseNotes;
  final int? patchNumber;

  const UpdateInfo({
    required this.isUpdateAvailable,
    required this.isForceUpdate,
    this.updateVersion,
    this.releaseNotes,
    this.patchNumber,
  });
}

/// Interface for app update service
/// Handles OTA updates via Shorebird and force update checks
abstract class IUpdateService {
  /// Checks if an update is available
  /// Returns Right(UpdateInfo) if check successful, Left(error) if failed
  Future<Either<String, UpdateInfo>> checkForUpdate();

  /// Downloads and applies the available update
  /// Returns Right(true) if successful, Left(error) if failed
  Future<Either<String, bool>> downloadUpdate();

  /// Gets the current app version
  Future<String> getCurrentVersion();

  /// Gets the current patch number (Shorebird patch version)
  Future<int?> getCurrentPatchNumber();

  /// Checks if update is mandatory (force update)
  /// This can be configured via backend API or Shorebird metadata
  Future<bool> isForceUpdateRequired();
}
