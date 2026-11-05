import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/model/aftekad_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/repository/i_aftekad_repository.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/viewmodel/add_aftekad/add_aftekad_cubit.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/services/data_refresh_cubit.dart';
import '../../../../../core/utils/date_helper.dart';
import '../../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../../core/widgets/custom_text_field.dart';
import '../../../../profile/repository/i_profile_repository.dart';

class AddAftekadDialog extends StatefulWidget {
  const AddAftekadDialog({super.key, required this.user});
  final AftekadModel user;
  @override
  State<AddAftekadDialog> createState() => _AddAftekadDialogState();
}

class _AddAftekadDialogState extends State<AddAftekadDialog> {
  final TextEditingController _outcomeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  AftekadType? _selectedType;
  DateTime _selectedDate = DateTime.now();
  DateTime? _submittedDate; // Store the date that was submitted

  @override
  void dispose() {
    _outcomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;
    final sizing = ResponsiveDialogUtils.buildSizing(
      mediaSize,
      minWidth: 420,
      maxWidth: 1180,
      compactHeightFactor: 0.62,
      regularHeightFactor: 0.76,
    );
    final typography = ResponsiveDialogTypography.resolve(mediaSize);
    final textTheme = Theme.of(context).textTheme;

    return BlocProvider(
      create: (context) => AddAftekadCubit(sl<IAftekadRepository>()),
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: sizing.toConstraints(lockWidth: true),
          child: SizedBox(
            width: sizing.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people,
                        color: AppColors.accentWhite,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'افتقاد ${widget.user.makhdoum?.name}',
                        style: ResponsiveDialogTypography.merge(
                          textTheme.titleLarge,
                          typography.headline,
                          color: AppColors.accentWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.accentWhite,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTypeSelector(),
                          const SizedBox(height: 12),
                          _buildDateSelector(),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _outcomeController,
                            labelText: 'ملاحظات',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                  child: BlocConsumer<AddAftekadCubit, AddAftekadState>(
                    listener: (context, state) {
                      if (state is AddAftekadSuccess) {
                        print(
                          '✅ [AddAftekadDialog] Success! Closing dialog and triggering refresh...',
                        );

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تسجيل الافتقاد بنجاح'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );

                        Future.delayed(const Duration(milliseconds: 300), () {
                          // Determine the Friday date for the submitted date
                          final submittedDate = _submittedDate ?? _selectedDate;
                          final fridayDate = DateHelper.getFridayDateStringForDate(submittedDate);
                          print(
                            '🔄 [AddAftekadDialog] Triggering DataRefreshCubit NOW for Friday: $fridayDate (submitted date: ${DateHelper.formatDateToString(submittedDate)})',
                          );
                          sl<DataRefreshCubit>().refreshMultiple({
                            RefreshType.eftekad,
                            RefreshType.stats,
                          }, fridayDate: fridayDate);
                        });
                      } else if (state is AddAftekadFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.errorMessage),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is AddAftekadLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'إلغاء',
                                style: ResponsiveDialogTypography.merge(
                                  textTheme.titleMedium,
                                  typography.button,
                                  color: AppColors.primaryMaroon,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _handleAddAftekad(context),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: AppColors.accentWhite,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'تسجيل الافتقاد',
                                style: ResponsiveDialogTypography.merge(
                                  textTheme.titleMedium,
                                  typography.button,
                                  color: AppColors.accentWhite,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddAftekad(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    // Check if type is selected
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار طريقة الافتقاد'),
        ),
      );
      return;
    }

    // Check if user ID is available
    if (widget.user.makhdoum?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: معرف المخدوم غير متوفر'),
        ),
      );
      return;
    }

    // Check if current user (khadem) is available
    final currentUser = sl<IProfileRepository>().user;
    if (currentUser == null || currentUser.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: معرف الخادم غير متوفر'),
        ),
      );
      return;
    }

    // Store the date being submitted
    _submittedDate = _selectedDate;
    
    context.read<AddAftekadCubit>().addAftekad(
          type: _selectedType!,
          date: _selectedDate,
          classId: widget.user.classId!,
          outcome: _outcomeController.text.trim(),
          makhdoumId: widget.user.makhdoum!.id!,
          khademId: currentUser.id!,
        );
  }

  Widget _buildTypeSelector() {
    final typography = ResponsiveDialogTypography.resolve(
      MediaQuery.of(context).size,
    );
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "اختار طريقة الافتقاد",
          style: ResponsiveDialogTypography.merge(
            textTheme.titleMedium,
            typography.title,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<AftekadType>(
          value: _selectedType,
          style: ResponsiveDialogTypography.merge(
            textTheme.bodyMedium,
            typography.body,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryMaroon, width: 2),
            ),
          ),
          items: AftekadType.values.map((event) {
            return DropdownMenuItem(
              value: event,
              child: Text(
                _getAftekadTypeArabicName(event),
                style: ResponsiveDialogTypography.merge(
                  textTheme.bodyMedium,
                  typography.body,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedType = value),
          validator: (value) {
            if (value == null) {
              return 'يرجى اختيار الطريقة';
            }
            return null;
          },
        ),
      ],
    );
  }

  String _getAftekadTypeArabicName(AftekadType type) {
    switch (type) {
      case AftekadType.phone_call:
        return 'اتصال هاتفي';
      case AftekadType.whatsapp_message:
        return 'رسالة واتساب';
      case AftekadType.home_visit:
        return 'زيارة منزلية';
    }
  }

  Widget _buildDateSelector() {
    final typography = ResponsiveDialogTypography.resolve(
      MediaQuery.of(context).size,
    );
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تاريخ الحضور',
          style: ResponsiveDialogTypography.merge(
            textTheme.titleMedium,
            typography.title,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentWhite,
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: AppColors.primaryMaroon),
                const SizedBox(width: 12),
                Text(
                  _formatDate(_selectedDate),
                  style: ResponsiveDialogTypography.merge(
                    textTheme.bodyMedium,
                    typography.subtitle,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }
}
