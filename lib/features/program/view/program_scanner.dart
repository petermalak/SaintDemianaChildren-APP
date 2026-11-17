import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/app_colors.dart';

Future<String?> showProgramScanner(
  BuildContext context, {
  Future<String> Function(String token)? onCode,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundPrimary,
    builder: (context) => SizedBox(
      height: onCode == null ? 420 : 500,
      child: _ScannerSheet(onCode: onCode),
    ),
  );
}

class _ScannerSheet extends StatefulWidget {
  const _ScannerSheet({this.onCode});

  final Future<String> Function(String token)? onCode;

  @override
  State<_ScannerSheet> createState() => _ScannerSheetState();
}

class _ScannerSheetState extends State<_ScannerSheet> {
  late final MobileScannerController _scanner;
  var _sent = false;
  var _busy = false;
  String? _last;
  DateTime? _lastAt;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _status = widget.onCode == null ? 'وجّه الكاميرا على الرمز' : 'الكاميرا تفضل مفتوحة. امسح الولد اللي بعده على طول.';
    if (kIsWeb) {
      MobileScannerPlatform.instance.setBarcodeLibraryScriptUrl('zxing.min.js');
    }
    _scanner = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_busy || _sent) return;
    final value = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue?.trim();
    if (value == null || value.isEmpty) return;
    final onCode = widget.onCode;
    if (onCode == null) {
      _sent = true;
      Navigator.of(context).pop(value);
      return;
    }
    if (value == _last && _lastAt != null && DateTime.now().difference(_lastAt!) < const Duration(seconds: 8)) return;
    _busy = true;
    _last = value;
    _lastAt = DateTime.now();
    _submit(onCode, value);
  }

  Future<void> _submit(Future<String> Function(String token) onCode, String value) async {
    setState(() => _status = 'بيتسجل...');
    final message = await onCode(value);
    if (!mounted) return;
    setState(() {
      _status = message;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                tooltip: 'إغلاق',
              ),
              const Expanded(
                child: Text('مسح الرمز', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                onPressed: () => _scanner.switchCamera(),
                icon: const Icon(Icons.cameraswitch, color: AppColors.primaryMaroon),
                tooltip: 'تبديل الكاميرا',
              ),
            ],
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MobileScanner(controller: _scanner, onDetect: _onDetect),
            ),
          ),
          const SizedBox(height: 12),
          Text(_status, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
