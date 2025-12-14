import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:saint_demiana_children/core/di/service_locator.dart';
import 'package:saint_demiana_children/core/services/interface/i_update_service.dart';
import 'package:saint_demiana_children/core/widgets/update_dialog.dart';

/// Widget that checks for app updates and shows update dialogs
/// Wrap your app with this widget to enable automatic update checking
class UpdateChecker extends StatefulWidget {
  final Widget child;
  final bool checkOnInit;
  final Duration checkInterval;

  const UpdateChecker({
    super.key,
    required this.child,
    this.checkOnInit = true,
    this.checkInterval = const Duration(hours: 1),
  });

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  final IUpdateService _updateService = sl<IUpdateService>();
  bool _isChecking = false;
  bool _hasShownUpdate = false;

  @override
  void initState() {
    super.initState();
    if (widget.checkOnInit && !kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForUpdates();
      });
    }
  }

  Future<void> _checkForUpdates() async {
    if (_isChecking || _hasShownUpdate || kIsWeb) return;

    setState(() {
      _isChecking = true;
    });

    try {
      final result = await _updateService.checkForUpdate();

      result.fold(
        (error) {
          if (kDebugMode) {
            print('⚠️ [UpdateChecker] Update check failed: $error');
          }
        },
        (updateInfo) {
          if (updateInfo.isUpdateAvailable && mounted) {
            _hasShownUpdate = true;
            _showUpdateDialog(updateInfo);
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UpdateChecker] Error checking updates: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  void _showUpdateDialog(UpdateInfo updateInfo) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: !updateInfo.isForceUpdate,
      builder: (context) => UpdateDialog(
        updateInfo: updateInfo,
        isForceUpdate: updateInfo.isForceUpdate,
        onUpdate: () => _handleUpdate(updateInfo),
        onCancel: updateInfo.isForceUpdate
            ? null
            : () {
                Navigator.of(context).pop();
              },
      ),
    );
  }

  Future<void> _handleUpdate(UpdateInfo updateInfo) async {
    if (!mounted) return;

    // Close the update dialog
    Navigator.of(context).pop();

    // Show download dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UpdateDownloadDialog(),
    );

    // Download and apply update
    final result = await _updateService.downloadUpdate();

    if (!mounted) return;

    // Close download dialog
    Navigator.of(context).pop();

    result.fold(
      (error) {
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('خطأ في التحديث'),
            content: Text('فشل تحميل التحديث: $error'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      },
      (_) {
        // Update downloaded successfully
        // The app will restart automatically with the new patch
        if (kDebugMode) {
          print('✅ [UpdateChecker] Update downloaded successfully');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

