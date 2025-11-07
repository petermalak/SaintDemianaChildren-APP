import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/core/constants/app_colors.dart';
import 'package:saint_demiana_children/core/constants/spacing.dart';
import 'package:saint_demiana_children/core/di/service_locator.dart';
import 'package:saint_demiana_children/core/utils/responsive_dialog_utils.dart';
import 'package:saint_demiana_children/features/feed/model/feed_model.dart';
import 'package:saint_demiana_children/features/feed/viewmodel/add_feed/add_feed_cubit.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/model/class_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/repository/i_class_repository.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';

class AddFeedDialog extends StatefulWidget {
  final FeedModel? existingFeed;

  const AddFeedDialog({super.key, this.existingFeed});

  @override
  State<AddFeedDialog> createState() => _AddFeedDialogState();
}

class _AddFeedDialogState extends State<AddFeedDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _linkController = TextEditingController();

  String _selectedType = 'announcement';
  ClassModel? _selectedClass;
  DateTime? _eventDate;
  bool _isLoading = false;
  List<ClassModel> _classes = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();

    if (widget.existingFeed != null) {
      _titleController.text = widget.existingFeed!.title ?? '';
      _contentController.text = widget.existingFeed!.content ?? '';
      _linkController.text = widget.existingFeed!.link ?? '';
      _selectedType = widget.existingFeed!.type ?? 'announcement';
      _eventDate = widget.existingFeed!.eventDate;
    }
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    final classRepo = sl<IClassRepository>();
    final currentUser = sl<IProfileRepository>().user;

    final result = await classRepo.loadClasses();
    result.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل الفصول: $error')),
        );
      },
      (classes) {
        setState(() {
          print('🔍 [AddFeedDialog] Current user role: ${currentUser?.role}');
          print(
              '🔍 [AddFeedDialog] Current user classId: ${currentUser?.classId}');
          print(
              '🔍 [AddFeedDialog] Available classes: ${classes.map((c) => '${c.name} (${c.id})').join(', ')}');

          // Filter classes based on user role
          if (currentUser?.role == UserRole.khadem &&
              currentUser?.classId != null) {
            // Khadem can only see their own class
            _classes = classes.where((c) {
              final match = c.id == currentUser!.classId;
              print(
                  '🔍 [AddFeedDialog] Comparing class ${c.name} (${c.id}) with user classId ${currentUser.classId}: $match');
              return match;
            }).toList();

            print(
                '🔍 [AddFeedDialog] Filtered classes for khadem: ${_classes.map((c) => c.name).join(', ')}');
          } else {
            // Super admin can see all classes
            _classes = classes;
            print(
                '🔍 [AddFeedDialog] Super admin - showing all ${_classes.length} classes');
          }

          if (_classes.isNotEmpty && widget.existingFeed == null) {
            _selectedClass = _classes.first;
          } else if (widget.existingFeed != null && _classes.isNotEmpty) {
            try {
              _selectedClass = _classes.firstWhere(
                (c) => c.id == widget.existingFeed!.classId,
              );
            } catch (e) {
              _selectedClass = _classes.first;
            }
          }
        });
      },
    );
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _eventDate = picked;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = sl<IProfileRepository>().user;

    // Check if khadem has a class assigned
    if (currentUser?.role == UserRole.khadem && currentUser?.classId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('لم يتم تعيين فصل لك. الرجاء التواصل مع الإدارة.')),
      );
      return;
    }

    if (_selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار فصل')),
      );
      return;
    }

    if (_selectedType == 'reminder' && _eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تحديد تاريخ الحدث للتذكير')),
      );
      return;
    }

    if (_selectedType == 'link' && _linkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال الرابط')),
      );
      return;
    }

    if (widget.existingFeed != null) {
      // Update existing feed
      context.read<AddFeedCubit>().updateFeed(
            feedId: widget.existingFeed!.id!,
            type: _selectedType,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            link: _linkController.text.trim().isEmpty
                ? null
                : _linkController.text.trim(),
            eventDate: _eventDate,
          );
    } else {
      // Create new feed
      context.read<AddFeedCubit>().createFeed(
            classId: _selectedClass!.id,
            type: _selectedType,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            link: _linkController.text.trim().isEmpty
                ? null
                : _linkController.text.trim(),
            eventDate: _eventDate,
            isPinned: false, // Always false, no pin option in UI
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;
    final sizing = ResponsiveDialogUtils.buildSizing(
      mediaSize,
      minWidth: 420,
      maxWidth: 1180,
      compactHeightFactor: 0.6,
      regularHeightFactor: 0.82,
    );
    final typography = ResponsiveDialogTypography.resolve(mediaSize);
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<AddFeedCubit, AddFeedState>(
      listener: (context, state) {
        if (state is AddFeedSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.existingFeed != null
                  ? 'تم تحديث الإعلان بنجاح'
                  : 'تم إضافة الإعلان بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else if (state is AddFeedFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: sizing.toConstraints(lockWidth: true),
          child: SizedBox(
            width: sizing.width,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(
                          widget.existingFeed != null ? Icons.edit : Icons.add,
                          color: AppColors.primaryMaroon,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            widget.existingFeed != null
                                ? 'تعديل الإعلان'
                                : 'إضافة إعلان جديد',
                        style: ResponsiveDialogTypography.merge(
                          textTheme.titleLarge,
                          typography.headline,
                          color: AppColors.primaryMaroon,
                          fontWeight: FontWeight.bold,
                        ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Class selector (only for new feeds)
                    if (widget.existingFeed == null)
                      Builder(
                        builder: (context) {
                          final currentUser = sl<IProfileRepository>().user;
                          final isKhadem = currentUser?.role == UserRole.khadem;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الفصل',
                                style: ResponsiveDialogTypography.merge(
                                  textTheme.titleMedium,
                                  typography.title,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : isKhadem
                                      // For Khadem: Show read-only field with their class
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.md,
                                            vertical: AppSpacing.md,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(
                                                AppSpacing.radiusMd),
                                            color: Colors.grey.shade50,
                                          ),
                                          width: double.infinity,
                                          child: Row(
                                            children: [
                                              const Icon(Icons.class_,
                                                  color:
                                                      AppColors.primaryMaroon),
                                              const SizedBox(
                                                  width: AppSpacing.sm),
                                              Expanded(
                                                child: Text(
                                                  _selectedClass?.name ??
                                                      'لم يتم تعيين فصل',
                                        style: ResponsiveDialogTypography.merge(
                                          textTheme.bodyLarge,
                                          typography.subtitle,
                                          color: AppColors.textPrimary,
                                        ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      // For Super Admin: Show dropdown with all classes
                                      : DropdownButtonFormField<ClassModel>(
                                          value: _selectedClass,
                                          style:
                                              ResponsiveDialogTypography.merge(
                                            textTheme.bodyMedium,
                                            typography.body,
                                            color: AppColors.textPrimary,
                                          ),
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppSpacing.radiusMd),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.md,
                                              vertical: AppSpacing.sm,
                                            ),
                                          ),
                                          items: _classes.map((classModel) {
                                            return DropdownMenuItem(
                                              value: classModel,
                                              child: Text(
                                                classModel.name,
                                                style: ResponsiveDialogTypography
                                                    .merge(
                                                  textTheme.bodyMedium,
                                                  typography.body,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedClass = value;
                                            });
                                          },
                                          validator: (value) {
                                            if (value == null) {
                                              return 'الرجاء اختيار فصل';
                                            }
                                            return null;
                                          },
                                        ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                          );
                        },
                      ),

                    // Type selector
                    Text(
                      'نوع الإعلان',
                      style: ResponsiveDialogTypography.merge(
                        textTheme.titleMedium,
                        typography.title,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      style: ResponsiveDialogTypography.merge(
                        textTheme.bodyMedium,
                        typography.body,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      items: const [
                        ['announcement', 'إعلان'],
                        ['reminder', 'تذكير'],
                        ['post', 'منشور'],
                        ['link', 'رابط'],
                      ]
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option.first,
                              child: Text(
                                option.last,
                                style: ResponsiveDialogTypography.merge(
                                  textTheme.bodyMedium,
                                  typography.body,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Title
                    Text(
                      'العنوان',
                      style: ResponsiveDialogTypography.merge(
                        textTheme.titleMedium,
                        typography.title,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'أدخل عنوان الإعلان',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الرجاء إدخال العنوان';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Content
                    Text(
                      'المحتوى',
                      style: ResponsiveDialogTypography.merge(
                        textTheme.titleMedium,
                        typography.title,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _contentController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'أدخل محتوى الإعلان',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الرجاء إدخال المحتوى';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Link (if type is link)
                    if (_selectedType == 'link')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الرابط',
                        style: ResponsiveDialogTypography.merge(
                          textTheme.titleMedium,
                          typography.title,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _linkController,
                            decoration: InputDecoration(
                              hintText: 'https://example.com',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              prefixIcon: const Icon(Icons.link),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),

                    // Event date (if type is reminder)
                    if (_selectedType == 'reminder')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تاريخ الحدث',
                            style: ResponsiveDialogTypography.merge(
                              textTheme.titleMedium,
                              typography.title,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          InkWell(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    _eventDate != null
                                        ? '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}'
                                        : 'اختر تاريخ الحدث',
                                    style: ResponsiveDialogTypography.merge(
                                      textTheme.bodyMedium,
                                      typography.subtitle,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),

                    const SizedBox(height: AppSpacing.md),

                    // Submit button
                    BlocBuilder<AddFeedCubit, AddFeedState>(
                      builder: (context, state) {
                        final isLoading = state is AddFeedLoading;
                        return ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryMaroon,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                  ),
                                )
                              : Text(
                                  widget.existingFeed != null
                                      ? 'تحديث'
                                      : 'إضافة',
                                  style: ResponsiveDialogTypography.merge(
                                    textTheme.titleMedium,
                                    typography.button,
                                    color: AppColors.accentWhite,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
