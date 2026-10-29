import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../authentication/model/user_model.dart';
import '../../viewmodel/qr_attendance_cubit.dart';
import '../../viewmodel/qr_attendance_state.dart';
import '../widget/scanned_member_tile.dart';

/// QR attendance for Pope Athanasius الفرقة الثانية (khadem / super admin).
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
      child: _QrAttendanceBody(classId: classId),
    );
  }
}

class _QrAttendanceBody extends StatefulWidget {
  const _QrAttendanceBody({required this.classId});

  final String classId;

  @override
  State<_QrAttendanceBody> createState() => _QrAttendanceBodyState();
}

class _QrAttendanceBodyState extends State<_QrAttendanceBody>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  late final AnimationController _flashController;

  String? _lastBarcode;
  DateTime _lastBarcodeAt = DateTime.fromMillisecondsSinceEpoch(0);
  String? _flashName;

  /// Level 2 focus: bible + doctrine first.
  static const List<List<String>> _eventOptions = [
    ['generalMeeting', 'كتاب المقدس'],
    ['specialMeeting', 'عقيدة'],
    ['mass', 'قداس'],
    ['praise', 'تسبحة'],
  ];

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Load the reader from this app so scanning works offline, without a CDN.
      MobileScannerPlatform.instance.setBarcodeLibraryScriptUrl('zxing.min.js');
    }
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: kIsWeb ? CameraFacing.front : CameraFacing.back,
      formats: const [BarcodeFormat.qrCode],
    );
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _flashController.dispose();
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

  Future<void> _showManualAddDialog(QrAttendanceReady ready) async {
    final options = ready.rosterById.values
        .where((m) =>
            m.popeAthnasiusMeetingData?.studyLevel == 2 ||
            m.classes.any((info) =>
                info.classId == widget.classId &&
                info.membershipRole == 'khadem' &&
                info.isActive != false))
        .toList()
      ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));

    await _scannerController.stop();
    if (!mounted) return;
    final selectedId = await showDialog<String>(
      context: context,
      builder: (ctx) => _ManualAddMemberDialog(options: options),
    );
    if (!mounted) return;
    await _scannerController.start();
    if (!mounted) return;
    if (selectedId != null) {
      context.read<QrAttendanceCubit>().tryAddManualId(selectedId);
    }
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String _eventLabel(String? key) {
    for (final o in _eventOptions) {
      if (o[0] == key) return o[1];
    }
    return 'حضور';
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  void _playSuccess(String name) {
    HapticFeedback.mediumImpact();
    setState(() => _flashName = name);
    _flashController.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() => _flashName = null);
      context.read<QrAttendanceCubit>().clearLastSuccess();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QrAttendanceCubit, QrAttendanceState>(
      listenWhen: (prev, curr) {
        if (curr is QrAttendanceSubmitSuccess) return true;
        if (curr is! QrAttendanceReady) return false;
        final prevReady = prev is QrAttendanceReady ? prev : null;
        return curr.feedback != null ||
            (curr.successTick != (prevReady?.successTick ?? 0) &&
                curr.lastSuccessName != null);
      },
      listener: (context, state) {
        if (state is QrAttendanceReady) {
          if (state.lastSuccessName != null &&
              state.successTick > 0 &&
              !state.feedbackIsError) {
            _playSuccess(state.lastSuccessName!);
          }
          if (state.feedback != null) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.feedback!),
                backgroundColor:
                    state.feedbackIsError ? AppColors.error : AppColors.success,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.read<QrAttendanceCubit>().clearFeedback();
          }
        }
        if (state is QrAttendanceSubmitSuccess) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.backgroundSecondary,
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تسجيل حضور QR', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                Text('الفرقة الثانية · بطاقات البابا أثناسيوس', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400)),
              ],
            ),
            backgroundColor: AppColors.primaryMaroon,
            foregroundColor: AppColors.accentWhite,
            actions: [
              IconButton(
                tooltip: 'سجل اليوم',
                onPressed: () {
                  final current = context.read<QrAttendanceCubit>().state;
                  final date = current is QrAttendanceReady ? current.selectedDate : DateTime.now();
                  final month = date.month.toString().padLeft(2, '0');
                  final day = date.day.toString().padLeft(2, '0');
                  context.push('/pope-level-two?date=${date.year}-$month-$day');
                },
                icon: const Icon(Icons.fact_check_outlined),
              ),
            ],
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
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textPrimary)),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => context.read<QrAttendanceCubit>().loadRoster(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primaryMaroon),
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
        // Pinned camera — does not scroll away while check-in continues
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildEventChips(ready, cubit),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: ready.isSubmitting ? null : () => _pickDate(ready),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppColors.primaryMaroon, size: 18),
                            const SizedBox(width: 8),
                            Text(_formatDate(ready.selectedDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(ready.shouldAddScore ? 'نقاط ✓' : 'بدون نقاط'),
                    selected: ready.shouldAddScore,
                    onSelected: ready.isSubmitting ? null : cubit.setShouldAddScore,
                    selectedColor: AppColors.primaryMaroon.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primaryMaroon,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.28,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                        errorBuilder: (context, error) => _cameraError(error),
                        overlayBuilder: (context, constraints) => _scanOverlay(),
                      ),
                      if (!kIsWeb)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Row(
                            children: [
                              IconButton.filledTonal(
                                onPressed: () => _scannerController.toggleTorch(),
                                icon: ValueListenableBuilder(
                                  valueListenable: _scannerController,
                                  builder: (context, mobileState, _) => Icon(
                                    mobileState.torchState == TorchState.on
                                        ? Icons.flash_on
                                        : Icons.flash_off,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton.filledTonal(
                                onPressed: () => _scannerController.switchCamera(),
                                icon: const Icon(Icons.cameraswitch),
                              ),
                            ],
                          ),
                        ),
                      if (_flashName != null)
                        FadeTransition(
                          opacity: Tween(begin: 1.0, end: 0.0).animate(
                            CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
                          ),
                          child: ColoredBox(
                            color: AppColors.success.withValues(alpha: 0.55),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white, size: 44),
                                    const SizedBox(height: 8),
                                    Text(
                                      _flashName!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'وجّه الكاميرا لبطاقة الفرقة الثانية · ${_eventLabel(ready.selectedEvent)}',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: ready.isSubmitting || ready.scannedMembers.isEmpty
                          ? null
                          : () => cubit.removeLastScan(),
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('إزالة الأخير'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: ready.isSubmitting ? null : () => _showManualAddDialog(ready),
                      icon: const Icon(Icons.person_search, size: 18),
                      label: const Text('بحث وإضافة'),
                    ),
                  ),
                ],
              ),
              if (ready.scannedMembers.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'الممسوحون (${ready.scannedMembers.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: ready.isSubmitting ? null : () => cubit.clearAllScans(),
                      child: const Text('مسح الكل'),
                    ),
                  ],
                ),
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
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final m = ready.scannedMembers[ready.scannedMembers.length - 1 - index];
                      return ScannedMemberTile(
                        member: m,
                        index: ready.scannedMembers.length - 1 - index,
                        onRemove: () {
                          if (m.id != null) cubit.removeMember(m.id!);
                        },
                      );
                    },
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(Icons.qr_code_2, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      Text(
                        'ابدأ بمسح بطاقة من الفرقة الثانية',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
            ],
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentWhite),
                    )
                  : const Icon(Icons.send),
              label: Text(
                ready.isSubmitting
                    ? 'جاري الإرسال...'
                    : 'تسجيل ${_eventLabel(ready.selectedEvent)} (${ready.scannedMembers.length})',
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

  Widget _buildEventChips(QrAttendanceReady ready, QrAttendanceCubit cubit) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _eventOptions.map((o) {
          final selected = ready.selectedEvent == o[0];
          final isPrimary = o[0] == 'generalMeeting' || o[0] == 'specialMeeting';
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(
                o[1],
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? AppColors.accentWhite : AppColors.textPrimary,
                ),
              ),
              selected: selected,
              onSelected: ready.isSubmitting
                  ? null
                  : (_) => cubit.setSelectedEvent(o[0]),
              selectedColor: AppColors.primaryMaroon,
              backgroundColor: isPrimary
                  ? AppColors.primaryCream
                  : AppColors.backgroundCard,
              side: BorderSide(
                color: selected ? AppColors.primaryMaroon : AppColors.borderMedium,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _scanOverlay() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2.5),
          ),
        ),
      ),
    );
  }

  String _cameraMessage(MobileScannerException error) {
    final raw = error.errorDetails?.message ?? '';
    final permissionDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied ||
            raw.contains('NotAllowed');
    if (permissionDenied) {
      return 'يلزم السماح بالكاميرا لمسح بطاقات الحضور';
    }
    if (error.errorCode == MobileScannerErrorCode.unsupported ||
        raw.contains('NotFound') ||
        raw.contains('NotSupported')) {
      return 'لم يتم العثور على كاميرا في هذا الجهاز';
    }
    if (raw.contains('Could not load')) {
      return 'تعذر تحميل قارئ الباركود. أغلق التطبيق وافتحه من سطح المكتب مرة أخرى.';
    }
    return 'تعذّر فتح الكاميرا';
  }

  Widget _cameraError(MobileScannerException error) {
    final permissionDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied ||
            (error.errorDetails?.message ?? '').contains('NotAllowed');
    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                permissionDenied ? Icons.no_photography : Icons.error_outline,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                _cameraMessage(error),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (permissionDenied)
                FilledButton(
                  onPressed: _openAppSettings,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primaryMaroon),
                  child: const Text('فتح الإعدادات'),
                )
              else
                FilledButton(
                  onPressed: () => _scannerController.start(),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primaryMaroon),
                  child: const Text('إعادة المحاولة'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Owns its [TextEditingController] so it is disposed only after the route is gone.
class _ManualAddMemberDialog extends StatefulWidget {
  const _ManualAddMemberDialog({required this.options});

  final List<UserModel> options;

  @override
  State<_ManualAddMemberDialog> createState() => _ManualAddMemberDialogState();
}

class _ManualAddMemberDialogState extends State<_ManualAddMemberDialog> {
  late final TextEditingController _controller;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needle = _controller.text.trim();
    final filtered = needle.isEmpty
        ? widget.options.take(40).toList()
        : widget.options
            .where((m) =>
                (m.name ?? '').contains(needle) ||
                (m.phoneNumber ?? '').contains(needle) ||
                (m.id ?? '').contains(needle))
            .take(40)
            .toList();

    final maxListHeight =
        (MediaQuery.sizeOf(context).height * 0.4).clamp(160.0, 280.0);

    return AlertDialog(
      title: const Text('إضافة يدوية'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'ابحث بالاسم أو الهاتف',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: maxListHeight,
              child: filtered.isEmpty
                  ? const Center(child: Text('لا نتائج من الفرقة الثانية'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final m = filtered[i];
                        final selected = _selectedId == m.id;
                        return ListTile(
                          selected: selected,
                          title: Text(m.name ?? '—'),
                          subtitle: Text(m.phoneNumber ?? ''),
                          onTap: () => setState(() => _selectedId = m.id),
                          trailing: selected
                              ? const Icon(Icons.check_circle, color: AppColors.success)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _selectedId == null
              ? null
              : () => Navigator.pop(context, _selectedId),
          child: const Text('إضافة'),
        ),
      ],
    );
  }
}
