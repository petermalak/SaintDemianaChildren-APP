import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/model/aftekad_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/repository/i_aftekad_repository.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/viewmodel/add_aftekad/add_aftekad_cubit.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
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

  @override
  void dispose() {
    _outcomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
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
                    'افتقاد ${widget.user.makhdoumName}',
                    style: const TextStyle(
                      color: AppColors.accentWhite,
                      fontSize: 18,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTypeSelector(),
                      const SizedBox(height: 12),
                      _buildDateSelector(),
                      const SizedBox(height: 16),
                      CustomTextField(
                          controller: _outcomeController, labelText: 'Outcome'),
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
              child: BlocProvider(
                create: (context) => AddAftekadCubit(sl<IAftekadRepository>()),
                child: BlocConsumer<AddAftekadCubit, AddAftekadState>(
                  listener: (context, state) {
                    if (state is AddAftekadSuccess) {
                      widget.user.status = true;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تسجيل الافتقاد بنجاح'),
                        ),
                      );
                    } else if (state is AddAftekadFailure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.errorMessage),
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
                            child: const Text('إلغاء'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleAddAftekad,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: AppColors.accentWhite,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('تسجيل الافتقاد'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddAftekad() async {
    if (!_formKey.currentState!.validate()) return;
    context.read<AddAftekadCubit>().addAftekad(
          type: _selectedType!,
          date: _selectedDate,
          outcome: _outcomeController.text.trim(),
          makhdoumId: widget.user.id!,
          khademId: sl<IProfileRepository>().user!.id!,
        );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "اختار طريقة الافتقاد",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Builder(builder: (context) {
          return DropdownButtonFormField<AftekadType>(
            initialValue: _selectedType,
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
                child: Text(event.name),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedType = value),
            validator: (value) {
              if (value == null) {
                return 'يرجى اختيار الطريقة';
              }
              return null;
            },
          );
        }),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تاريخ الحضور',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Builder(builder: (context) {
          return InkWell(
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
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          );
        }),
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
