import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/model/class_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/viewmodel/add_classes/add_class_cubit.dart';

import '../../../../../../core/di/service_locator.dart';
import '../../repository/i_class_repository.dart';

class AddClassDialog extends StatelessWidget {
  const AddClassDialog({super.key, this.classModel, this.onSuccess});
  final ClassModel? classModel;
  final VoidCallback? onSuccess;

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: classModel?.name);
    final locationController =
        TextEditingController(text: classModel?.location);
    final isUpdate = classModel != null;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isUpdate ? 'تعديل الفصل' : 'إنشاء فصل جديد',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    onSuccess?.call();
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
                        child: const Text('إلغاء'),
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
                              ? await context.read<AddClassCubit>().updateClass(
                                    classModel!.id,
                                    nameController.text.trim(),
                                    locationController.text.trim(),
                                  )
                              : await context.read<AddClassCubit>().addClass(
                                    nameController.text.trim(),
                                    locationController.text.trim(),
                                  );
                        },
                        child: Text(isUpdate ? 'تعديل' : 'إنشاء'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
