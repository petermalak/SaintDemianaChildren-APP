import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/viewmodel/add_member/add_member_cubit.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/widgets/info_form.dart';
import '../../../../authentication/model/user_model.dart';
import '../../repository/i_members_repository.dart';
import '../../viewmodel/get_members/get_members_cubit.dart';

class AddUserDialog extends StatelessWidget {
  late final UserModel? user;

  AddUserDialog({
    super.key,
    this.user,
  });

  final _formKey = GlobalKey<FormState>();
  final _infoFormKey = GlobalKey<InfoFormState>();

  @override
  Widget build(BuildContext context) {
    String? selectedImagePath;

    bool isUpdate = user != null;
    user ??= UserModel();
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
            // Header
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
                    Icons.edit,
                    color: AppColors.accentWhite,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isUpdate ? 'تعديل ملف ${user!.name}' : 'إضافة عضو جديد',
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
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: InfoForm(
                    key: _infoFormKey, // Add this key
                    user: user!,
                    selectedImagePath: selectedImagePath,
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: BlocProvider(
                create: (context) => AddMemberCubit(sl<IMembersRepository>()),
                child: BlocConsumer<AddMemberCubit, AddMemberState>(
                  listener: (context, state) {
                    if (state is AddMemberSuccess) {
                      Navigator.pop(context);
                      context.read<GetMembersCubit>().refreshMembers();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isUpdate
                              ? 'تم تحديث العضو بنجاح'
                              : 'تم إضافة العضو بنجاح'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    } else if (state is AddMemberFailure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.errorMessage),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is AddMemberLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
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
                            onPressed: () {
                              final addMemberCubit =
                                  context.read<AddMemberCubit>();
                              if (_infoFormKey.currentState
                                      ?.saveFormToModel() ??
                                  false) {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  if (isUpdate) {
                                    addMemberCubit.updateMemberProfile(user!);
                                  } else {
                                    addMemberCubit.addMember(user!);
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryMaroon,
                              foregroundColor: AppColors.accentWhite,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                                isUpdate ? 'حفظ التغييرات' : 'إضافة العضو'),
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
}
