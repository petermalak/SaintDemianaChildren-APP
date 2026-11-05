import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/model/class_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/viewmodel/add_classes/add_class_cubit.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/di/service_locator.dart';
import '../../../../../../core/utils/responsive_dialog_utils.dart';
import '../../repository/i_class_repository.dart';

class AddClassDialog extends StatefulWidget {
  const AddClassDialog({super.key, this.classModel, this.onSuccess});
  final ClassModel? classModel;
  final VoidCallback? onSuccess;

  @override
  State<AddClassDialog> createState() => _AddClassDialogState();
}

class _AddClassDialogState extends State<AddClassDialog> {
  late bool _hasShop;

  @override
  void initState() {
    super.initState();
    _hasShop = widget.classModel?.hasShop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: widget.classModel?.name);
    final locationController =
        TextEditingController(text: widget.classModel?.location);
    final isUpdate = widget.classModel != null;
    final mediaSize = MediaQuery.of(context).size;
    final sizing = ResponsiveDialogUtils.buildSizing(
      mediaSize,
      minWidth: 360,
      maxWidth: 820,
      compactHeightFactor: 0.48,
      regularHeightFactor: 0.62,
    );
    final typography = ResponsiveDialogTypography.resolve(mediaSize);
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: sizing.toConstraints(lockWidth: true),
        child: SizedBox(
          width: sizing.width,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isUpdate ? 'تعديل الفصل' : 'إنشاء فصل جديد',
                  style: ResponsiveDialogTypography.merge(
                    textTheme.titleLarge,
                    typography.headline,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفصل',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'الموقع',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'متجر التايو لهذا الفصل',
                        style: ResponsiveDialogTypography.merge(
                          textTheme.titleMedium,
                          typography.body,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Switch(
                      value: _hasShop,
                      onChanged: (value) => setState(() => _hasShop = value),
                      activeColor: AppColors.primaryMaroon,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                BlocProvider(
                  create: (context) => AddClassCubit(sl<IClassRepository>()),
                  child: BlocConsumer<AddClassCubit, AddClassState>(
                    listener: (context, state) {
                      if (state is AddClassFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.errorMessage)),
                        );
                      } else if (state is AddClassSuccess) {
                        Navigator.pop(context, true);
                        widget.onSuccess?.call();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isUpdate
                                ? 'تم تعديل الفصل بنجاح'
                                : 'تم حفظ الفصل بنجاح'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is AddClassLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
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
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              if (nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('يرجى إدخال اسم الفصل')),
                                );
                                return;
                              }
                              isUpdate
                                  ? await context
                                      .read<AddClassCubit>()
                                      .updateClass(
                                        widget.classModel!.id,
                                        nameController.text.trim(),
                                        locationController.text.trim(),
                                        hasShop: _hasShop,
                                      )
                                  : await context
                                      .read<AddClassCubit>()
                                      .addClass(
                                        nameController.text.trim(),
                                        locationController.text.trim(),
                                        hasShop: _hasShop,
                                      );
                            },
                            child: Text(
                              isUpdate ? 'تعديل' : 'إنشاء',
                              style: ResponsiveDialogTypography.merge(
                                textTheme.titleMedium,
                                typography.button,
                                color: AppColors.accentWhite,
                                fontWeight: FontWeight.w700,
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
}
