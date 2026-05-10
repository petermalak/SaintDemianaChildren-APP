import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../viewmodel/qr_attendance_cubit.dart';
import '../../viewmodel/qr_attendance_state.dart';
import '../widget/scanned_member_tile.dart';

/// QR attendance for Pope Athanasius class (khadem flow).
class QrAttendanceScreen extends StatelessWidget {
  const QrAttendanceScreen({
    super.key,
    required this.classId,
    this.className,
  });

  final String classId;
  final String? className;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QrAttendanceCubit(
        sl(),
        sl(),
        classId,
      )..loadRoster(),
      child: const _QrAttendanceBody(),
    );
  }
}

class _QrAttendanceBody extends StatefulWidget {
  const _QrAttendanceBody();

  @override
  State<_QrAttendanceBody> createState() => _QrAttendanceBodyState();
}

class _QrAttendanceBodyState extends State<_QrAttendanceBody> {
  late final MobileScannerController _scannerController;

  String? _lastBarcode;
  DateTime _lastBarcodeAt = DateTime.fromMillisecondsSinceEpoch(0);

  static const List<List<String>> _eventOptions = [
    ['praise', 'تسبحة'],
    ['mass', 'قداس'],
    ['generalMeeting', 'اجتماع عام'],
    ['specialMeeting', 'اجتماع خاص'],
  ];

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!mounted) return;
    final cubit = context.read<QrAttendanceCubit>();
    final st = cubit.state;
    if (st is! QrAttendanceReady || st.isSubmitting) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    final now = DateTime.now();
    final trimmed = raw.trim();
    if (trimmed == _lastBarcode &&
        now.difference(_lastBarcodeAt) < const Duration(seconds: 2)) {
      return;
    }
    _lastBarcode = trimmed;
    _lastBarcodeAt = now;

    if (!mounted) return;
    cubit.tryAddScan(trimmed);
  }

  Future<void> _pickDate(QrAttendanceReady ready) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: ready.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && mounted) {
      context.read<QrAttendanceCubit>().setSelectedDate(picked);
    }
  }

  Future<void> _showManualAddDialog() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة يدوية'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'معرف المستخدم (UUID)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        context.read<QrAttendanceCubit>().tryAddManualId(text);
      }
    }
    controller.dispose();
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QrAttendanceCubit, QrAttendanceState>(
      listenWhen: (prev, curr) =>
          (curr is QrAttendanceReady && curr.feedback != null) ||
          curr is QrAttendanceSubmitSuccess,
      listener: (context, state) {
        if (state is QrAttendanceReady && state.feedback != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.feedback!),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 2),
            ),
          );
          context.read<QrAttendanceCubit>().clearFeedback();
        }
        if (state is QrAttendanceSubmitSuccess) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.backgroundSecondary,
          appBar: AppBar(
            title: const Text('تسجيل حضور بالـ QR'),
            backgroundColor: AppColors.primaryMaroon,
            foregroundColor: AppColors.accentWhite,
          ),
          body: switch (state) {
            QrAttendanceLoadingRoster() => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryMaroon),
              ),
            QrAttendanceRosterError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () =>
                            context.read<QrAttendanceCubit>().loadRoster(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryMaroon,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            QrAttendanceReady() => _buildReadyContent(context, state),
            QrAttendanceSubmitSuccess() => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryMaroon),
              ),
          },
        );
      },
    );
  }

  Widget _buildReadyContent(BuildContext context, QrAttendanceReady ready) {
    final cubit = context.read<QrAttendanceCubit>();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 0,
                  color: AppColors.backgroundCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تفاصيل الحضور',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: ready.selectedEvent,
                          decoration: const InputDecoration(
                            labelText: 'نوع الاجتماع',
                            border: OutlineInputBorder(),
                          ),
                          items: _eventOptions
                              .map(
                                (o) => DropdownMenuItem(
                                  value: o[0],
                                  child: Text(o[1]),
                                ),
                              )
                              .toList(),
                          onChanged: ready.isSubmitting
                              ? null
                              : (v) => cubit.setSelectedEvent(v),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: ready.isSubmitting
                              ? null
                              : () => _pickDate(ready),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'التاريخ',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: AppColors.primaryMaroon, size: 20),
                                const SizedBox(width: 8),
                                Text(_formatDate(ready.selectedDate)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('احتساب نقاط الحضور'),
                          value: ready.shouldAddScore,
                          onChanged: ready.isSubmitting
                              ? null
                              : cubit.setShouldAddScore,
                          activeTrackColor:
                              AppColors.primaryMaroon.withValues(alpha: 0.45),
                          activeThumbColor: AppColors.primaryMaroon,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: _onDetect,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Row(
                            children: [
                              IconButton.filledTonal(
                                onPressed: () =>
                                    _scannerController.toggleTorch(),
                                icon: ValueListenableBuilder<MobileScannerState>(
                                  valueListenable: _scannerController,
                                  builder: (context, mobileState, child) {
                                    return Icon(
                                      mobileState.torchState == TorchState.on
                                          ? Icons.flash_on
                                          : Icons.flash_off,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton.filledTonal(
                                onPressed: () =>
                                    _scannerController.switchCamera(),
                                icon: const Icon(Icons.cameraswitch),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: ready.isSubmitting ||
                                ready.scannedMembers.isEmpty
                            ? null
                            : () => cubit.removeLastScan(),
                        icon: const Icon(Icons.undo),
                        label: const Text('إزالة الأخير'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: ready.isSubmitting
                            ? null
                            : () => cubit.clearAllScans(),
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: const Text('مسح الكل'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        ready.isSubmitting ? null : _showManualAddDialog,
                    icon: const Icon(Icons.keyboard),
                    label: const Text('إضافة يدوية'),
                  ),
                ),
                if (ready.scannedMembers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'الممسوحون (${ready.scannedMembers.length})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.borderLight),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ready.scannedMembers.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final m = ready.scannedMembers[index];
                        return ScannedMemberTile(
                          member: m,
                          onRemove: () {
                            if (m.id != null) {
                              cubit.removeMember(m.id!);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton.icon(
              onPressed: ready.isSubmitting || ready.scannedMembers.isEmpty
                  ? null
                  : () => cubit.submit(),
              icon: ready.isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentWhite,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                ready.isSubmitting
                    ? 'جاري الإرسال...'
                    : 'تسجيل الحضور (${ready.scannedMembers.length})',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryMaroon,
                foregroundColor: AppColors.accentWhite,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
