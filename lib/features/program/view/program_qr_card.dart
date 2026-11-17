import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../repository/i_program_repository.dart';

class ProgramQrCard extends StatefulWidget {
  final String programId;
  final IProgramRepository programs;
  final String? initialToken;

  const ProgramQrCard({
    super.key,
    required this.programId,
    required this.programs,
    this.initialToken,
  });

  @override
  State<ProgramQrCard> createState() => _ProgramQrCardState();
}

class _ProgramQrCardState extends State<ProgramQrCard> {
  String? _token;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _token = _usable(widget.initialToken);
    _loading = _token == null;
    _refresh();
  }

  @override
  void didUpdateWidget(covariant ProgramQrCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.programId != widget.programId) {
      _token = _usable(widget.initialToken);
      _refresh();
    }
  }

  String? _usable(String? token) {
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length != 2) return token;
    try {
      final body = utf8.decode(base64Url.decode(base64Url.normalize(parts[0])));
      final payload = jsonDecode(body);
      final exp = payload is Map ? payload['exp'] : null;
      if (exp is num && DateTime.now().millisecondsSinceEpoch > exp) return null;
    } catch (_) {
      return token;
    }
    return token;
  }

  Future<void> _refresh() async {
    final result = await widget.programs.freshQr(widget.programId);
    if (!mounted) return;
    result.fold((_) {
      setState(() => _loading = false);
    }, (data) {
      final next = data is Map ? _usable(data['token']?.toString()) : null;
      setState(() {
        if (next != null) _token = next;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final token = _token;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('رمز الحضور', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          if (token != null)
            QrImageView(
              data: token,
              size: 220,
              backgroundColor: Colors.white,
            )
          else if (_loading)
            const Text('الرمز بيتجهز')
          else
            const Text(
              'الرمز هيظهر أول ما تفتح الصفحة والنت موجود. بعد كده يفضل ظاهر من غير نت.',
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 8),
          const Text('أظهره لخادم الفصل عشان يسجل حضورك', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
