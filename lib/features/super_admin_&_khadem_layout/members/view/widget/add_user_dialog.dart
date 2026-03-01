import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/core/widgets/custom_text_field.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/viewmodel/add_member/add_member_cubit.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../../core/utils/role_helper.dart';
import '../../../../../core/widgets/info_form.dart';
import '../../../../../core/widgets/class_export_selection_dialog.dart';
import '../../../../authentication/model/user_model.dart';
import '../../../../profile/repository/i_profile_repository.dart';
import '../../repository/i_members_repository.dart';
import 'pope_athanasius_form.dart';

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
  List<String> _selectedClassIds = [];
  PopeAthanasiusFormData? _popeAthanasiusData;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user?.role;
    _emailController.text = widget.user?.email ?? "";

    // If khadem creating makhdoum, auto-select their classes
    if (widget.user == null) {
      _initializeClassSelection();
    }
  }

  void _initializeClassSelection() async {
    final currentUser = sl<IProfileRepository>().user;
    if (currentUser != null &&
        RoleHelper.hasRole(currentUser, UserRole.khadem) &&
        _selectedRole == UserRole.makhdoum) {
      final khademClasses = RoleHelper.getKhademClasses(currentUser);
      if (khademClasses.length == 1) {
        // Auto-select single class
        setState(() {
          _selectedClassIds = [khademClasses.first.classId];
        });
      } else if (khademClasses.length > 1) {
        // Pre-select all classes by default
        setState(() {
          _selectedClassIds = khademClasses.map((c) => c.classId).toList();
        });
      }
    }
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
                          _buildRoleSelector(),
                          if (_shouldShowClassSelection()) ...[
                            const SizedBox(height: 16),
                            _buildClassSelection(),
                          ],
                          if (_shouldShowPopeAthanasiusForm()) ...[
                            const SizedBox(height: 16),
                            PopeAthanasiusForm(
                              initialData: _popeAthanasiusData,
                              onDataChanged: (data) {
                                setState(() {
                                  _popeAthanasiusData = data;
                                });
                              },
                            ),
                          ],
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

                                  // Ensure khadem creator can relate new makhdoum to their classes
                                  final creator = sl<IProfileRepository>().user;
                                  final isKhademCreator = creator != null &&
                                      RoleHelper.hasRole(
                                          creator, UserRole.khadem);

                                  List<String> effectiveClassIds = [];

                                  // Primary path: explicit class selection UI
                                  if (_shouldShowClassSelection()) {
                                    if (_selectedClassIds.isNotEmpty) {
                                      effectiveClassIds =
                                          List<String>.from(_selectedClassIds);
                                    } else if (isKhademCreator &&
                                        _selectedRole == UserRole.makhdoum) {
                                      // Fallback: if nothing was selected, default to all khadem classes
                                      final khademClasses =
                                          RoleHelper.getKhademClasses(creator);
                                      effectiveClassIds = khademClasses
                                          .map((c) => c.classId)
                                          .toList();
                                    }
                                  } else if (isKhademCreator &&
                                      _selectedRole == UserRole.makhdoum) {
                                    // Safety fallback: even if the selector is hidden for some reason,
                                    // still relate the new makhdoum to all classes where creator is khadem.
                                    final khademClasses =
                                        RoleHelper.getKhademClasses(creator);
                                    effectiveClassIds = khademClasses
                                        .map((c) => c.classId)
                                        .toList();
                                  }

                                  if (effectiveClassIds.isNotEmpty) {
                                    currentUser.classIds = effectiveClassIds;
                                  }

                                  // Set Pope Athanasius data if applicable
                                  if (_shouldShowPopeAthanasiusForm() &&
                                      _popeAthanasiusData != null) {
                                    currentUser.isPopeAthnasius = true;
                                    // Store classPhase separately as it needs to be sent separately to backend
                                    final additionalData =
                                        _popeAthanasiusData!.toAdditionalData();
                                    currentUser.popeAthnasiusMeetingData =
                                        PopeAthnasiusMeetingData(
                                      additionalData: additionalData,
                                    );
                                    // Store classPhase in a temporary field that will be extracted in toJson
                                    if (_popeAthanasiusData!.classPhase !=
                                        null) {
                                      // Add classPhase to additionalData temporarily - backend will extract it
                                      additionalData['classPhase'] =
                                          _popeAthanasiusData!.classPhase;
                                    }
                                  }

                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    // Validate class selection for khadem creating makhdoum
                                    if (_shouldShowClassSelection() &&
                                        _selectedClassIds.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'يرجى اختيار فصل واحد على الأقل'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                      return;
                                    }

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
            // Re-initialize class selection when role changes
            if (newValue == UserRole.makhdoum) {
              _initializeClassSelection();
            } else {
              _selectedClassIds.clear();
              _popeAthanasiusData = null;
            }
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

  bool _shouldShowClassSelection() {
    if (widget.user != null) return false; // Don't show for updates

    final currentUser = sl<IProfileRepository>().user;
    return currentUser != null &&
        RoleHelper.hasRole(currentUser, UserRole.khadem) &&
        _selectedRole == UserRole.makhdoum;
  }

  bool _shouldShowPopeAthanasiusForm() {
    if (widget.user != null) return false; // Don't show for updates

    final currentUser = sl<IProfileRepository>().user;
    if (currentUser == null || _selectedRole != UserRole.makhdoum) {
      return false;
    }

    // Check if khadem is assigned to Pope Athanasius classes
    final khademClasses = RoleHelper.getKhademClasses(currentUser);
    return khademClasses.any((classInfo) {
      final className = classInfo.className ?? '';
      final classDescription = classInfo.classDescription ?? '';
      return className.toLowerCase().contains('pope') ||
          className.toLowerCase().contains('athanasius') ||
          className.toLowerCase().contains('أثناسيوس') ||
          className.toLowerCase().contains('بابا') ||
          classDescription.toLowerCase().contains('pope') ||
          classDescription.toLowerCase().contains('athanasius') ||
          classDescription.toLowerCase().contains('أثناسيوس') ||
          classDescription.toLowerCase().contains('بابا');
    });
  }

  Widget _buildClassSelection() {
    final currentUser = sl<IProfileRepository>().user;
    if (currentUser == null) return const SizedBox.shrink();

    final khademClasses = RoleHelper.getKhademClasses(currentUser);
    if (khademClasses.isEmpty) return const SizedBox.shrink();

    if (khademClasses.length == 1) {
      // Single class - show as read-only
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryMaroon.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryMaroon.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.class_, color: AppColors.primaryMaroon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سيتم إضافة المخدوم إلى الفصل:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    khademClasses.first.className ??
                        khademClasses.first.classId,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryMaroon,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Multiple classes - show selection button
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () async {
          final selectedIds = await showDialog<List<String>>(
            context: context,
            builder: (context) => ClassExportSelectionDialog(
              availableClasses: khademClasses
                  .map((c) => ClassOption(
                        id: c.classId,
                        name: c.className ?? c.classId,
                      ))
                  .toList(),
              title: 'اختر الفصول لإضافة المخدوم',
              allowMultiple: true,
            ),
          );

          if (selectedIds != null) {
            setState(() {
              _selectedClassIds = selectedIds;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.class_, color: AppColors.primaryMaroon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'اختر الفصول',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_selectedClassIds.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _selectedClassIds.length == khademClasses.length
                            ? 'جميع الفصول (${_selectedClassIds.length})'
                            : '${_selectedClassIds.length} من ${khademClasses.length} فصل',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
