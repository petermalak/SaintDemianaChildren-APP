import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/spacing.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile_field.dart';
import '../widgets/profile_image_picker.dart';
import '../widgets/loading_button.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel? user;
  final bool isCurrentUser;

  const ProfileScreen({
    super.key,
    this.user,
    this.isCurrentUser = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String? _selectedImagePath;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initializeFields() {
    final user = widget.user;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
      _selectedImagePath = user.profileImage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('لا توجد بيانات المستخدم'),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildProfileImageSection(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildProfileFieldsSection(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.accentWhite,
            ),
          ),
          const Expanded(
            child: Text(
              'الملف الشخصي',
              style: TextStyle(
                color: AppColors.accentWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (_isEditing)
            TextButton(
              onPressed: _cancelEdit,
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  color: AppColors.accentWhite,
                  fontSize: 16,
                ),
              ),
            )
          else
            IconButton(
              onPressed: _startEdit,
              icon: const Icon(
                Icons.edit,
                color: AppColors.accentWhite,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'صورة الملف الشخصي',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ProfileImagePicker(
            imagePath: _selectedImagePath,
            onImageChanged: _onImageChanged,
            isEditable: _isEditing,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileFieldsSection() {
    final user = widget.user!;
    final isMakhdoum = user.role == UserRole.makhdoum;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'معلومات الملف الشخصي',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Name field - always editable
          ProfileField(
            label: 'الاسم',
            value: _nameController.text,
            isEditable: _isEditing,
            isRequired: true,
            controller: _nameController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'الاسم مطلوب';
              }
              return null;
            },
          ),
          
          // Email field - editable for khadem, read-only for makhdoum
          ProfileField(
            label: 'البريد الإلكتروني',
            value: _emailController.text,
            isEditable: _isEditing && !isMakhdoum,
            isRequired: true,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: _isEditing && !isMakhdoum ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'البريد الإلكتروني مطلوب';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'البريد الإلكتروني غير صحيح';
              }
              return null;
            } : null,
          ),
          
          // Phone field - always editable
          ProfileField(
            label: 'رقم الهاتف',
            value: _phoneController.text,
            isEditable: _isEditing,
            isRequired: false,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: _isEditing ? (value) {
              if (value != null && value.trim().isNotEmpty) {
                if (!RegExp(r'^[0-9+\-\s]+$').hasMatch(value)) {
                  return 'رقم الهاتف غير صحيح';
                }
              }
              return null;
            } : null,
          ),
          
          // Role field - always read-only
          ProfileField(
            label: 'الدور',
            value: _getRoleDisplayName(user.role),
            isEditable: false,
            isRequired: false,
          ),
          
          // ID field - always read-only
          ProfileField(
            label: 'رقم العضوية',
            value: user.id.toString(),
            isEditable: false,
            isRequired: false,
          ),
          
          if (isMakhdoum)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.accentGold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: AppColors.accentGold,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'بعض المعلومات محمية ولا يمكن تعديلها',
                      style: TextStyle(
                        color: AppColors.accentGold,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (!_isEditing) return const SizedBox.shrink();
    
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _cancelEdit,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              side: const BorderSide(color: AppColors.primaryMaroon),
            ),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                color: AppColors.primaryMaroon,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: LoadingButton(
            onPressed: _saveProfile,
            isLoading: _isLoading,
            text: 'حفظ التغييرات',
            loadingText: 'جاري الحفظ...',
          ),
        ),
      ],
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.khadem:
        return 'خادم';
      case UserRole.makhdoum:
        return 'مخدوم';
    }
  }

  void _startEdit() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _initializeFields(); // Reset to original values
    });
  }

  void _onImageChanged(String? imagePath) {
    setState(() {
      _selectedImagePath = imagePath;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Prepare update data
      final updateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        if (_selectedImagePath != null) 'profileImage': _selectedImagePath,
      };

      // Only update email for khadem users
      if (widget.user!.role == UserRole.khadem) {
        updateData['email'] = _emailController.text.trim();
      }

      // Update user profile
      final updatedUser = await authProvider.updateUserProfile(updateData);
      
      if (updatedUser != null) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حفظ التغييرات بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        throw Exception('فشل في حفظ التغييرات');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ التغييرات: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
