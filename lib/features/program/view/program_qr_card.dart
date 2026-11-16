import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../repository/i_program_repository.dart';

class ProgramQrCard extends StatefulWidget {
  final String programId;
  final IProgramRepository programs;
  final String? initialToken;
  final int expiresIn;

  const ProgramQrCard({
    super.key,
    required this.programId,
    required this.programs,
    this.initialToken,
    this.expiresIn = 45,
  });

  @override
  State<ProgramQrCard> createState() => _ProgramQrCardState();
}

class _ProgramQrCardState extends State<ProgramQrCard> {
  Timer? _timer;
  String? _token;
  int _seconds = 45;

  @override
  void initState() {
    super.initState();
    _token = widget.initialToken;
    _seconds = widget.expiresIn.clamp(30, 60).toInt();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant ProgramQrCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.programId != widget.programId) {
      _token = widget.initialToken;
      _refresh();
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: _seconds), (_) => _refresh());
  }

  Future<void> _refresh() async {
    final result = await widget.programs.freshQr(widget.programId);
    if (!mounted) return;
    result.fold((_) {}, (data) {
      if (data is! Map || data['token'] == null) return;
      final seconds = int.tryParse('${data['expiresIn']}') ?? _seconds;
      setState(() {
        _token = data['token'].toString();
        _seconds = seconds.clamp(30, 60).toInt();
      });
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
          if (token == null)
            const Text('الرمز بيتجهز')
          else
            QrImageView(
              data: token,
              size: 180,
              backgroundColor: Colors.white,
            ),
          const SizedBox(height: 8),
          Text('بيتجدد كل $_seconds ثانية', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
