import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/core/widgets/custom_text_field.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/viewmodel/add_member/add_member_cubit.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../../core/widgets/info_form.dart';
import '../../../../authentication/model/user_model.dart';
import '../../repository/i_members_repository.dart';

class AddUserDialog extends StatefulWidget {
  final UserModel? user;
  final VoidCallback onSuccess;
  const AddUserDialog({
    super.key,
    this.user,
    required this.onSuccess,
  });

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();

  final _infoFormKey = GlobalKey<InfoFormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  UserRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user?.role;
    _emailController.text = widget.user?.email ?? "";
  }

  @override
  Widget build(BuildContext context) {
    String? selectedImagePath;

    bool isUpdate = widget.user != null;
    final currentUser = widget.user ?? UserModel();
    final mediaSize = MediaQuery.of(context).size;
    final sizing = ResponsiveDialogUtils.buildSizing(
      mediaSize,
      minWidth: 440,
      maxWidth: 1280,
      compactHeightFactor: 0.62,
      regularHeightFactor: 0.78,
    );
    final typography = ResponsiveDialogTypography.resolve(mediaSize);
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: sizing.toConstraints(lockWidth: true),
        child: SizedBox(
          width: sizing.width,
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
                      isUpdate
                          ? 'تعديل ملف ${currentUser.name}'
                          : 'إضافة عضو جديد',
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
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        InfoForm(
                          key: _infoFormKey, // Add this key
                          user: currentUser,
                          selectedImagePath: selectedImagePath,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _emailController,
                          labelText: "الايميل",
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى إدخال الايميل';
                            }
                            return null;
                          },
                        ),
                        if (!isUpdate) ...[
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _passwordController,
                            labelText: 'الرقم السري',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'يرجى إدخال الرقم السري';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildRoleSelector()
                        ]
                      ],
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
                        widget.onSuccess();
                        Navigator.pop(context);
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
                              onPressed: () {
                                final addMemberCubit =
                                    context.read<AddMemberCubit>();
                                if (_infoFormKey.currentState
                                        ?.saveFormToModel() ??
                                    false) {
                                  currentUser.password =
                                      _passwordController.text;
                                  currentUser.email = _emailController.text;
                                  currentUser.role = _selectedRole;

                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    if (isUpdate) {
                                      addMemberCubit
                                          .updateMemberProfile(currentUser);
                                    } else {
                                      addMemberCubit.addMember(currentUser);
                                    }
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryMaroon,
                                foregroundColor: AppColors.accentWhite,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                isUpdate ? 'حفظ التغييرات' : 'إضافة العضو',
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    final typography = ResponsiveDialogTypography.resolve(
      MediaQuery.of(context).size,
    );
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<UserRole>(
        value: _selectedRole,
        style: ResponsiveDialogTypography.merge(
          textTheme.bodyMedium,
          typography.body,
          color: AppColors.textPrimary,
        ),
        decoration: const InputDecoration(
          labelText: 'الدور',
          border: InputBorder.none,
          icon: Icon(Icons.person_outline, color: AppColors.primaryMaroon),
        ),
        items: UserRole.values.map((UserRole role) {
          return DropdownMenuItem<UserRole>(
            value: role,
            child: Text(
              _getRoleDisplayName(role),
              style: ResponsiveDialogTypography.merge(
                textTheme.bodyMedium,
                typography.body,
                color: AppColors.textPrimary,
              ),
            ),
          );
        }).toList(),
        onChanged: (UserRole? newValue) {
          setState(() {
            _selectedRole = newValue;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'يرجى اختيار الدور';
          }
          return null;
        },
      ),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.khadem:
        return 'خادم';
      case UserRole.makhdoum:
        return 'مخدوم';
      case UserRole.superAdmin:
        return 'مدير عام';
    }
  }
}
