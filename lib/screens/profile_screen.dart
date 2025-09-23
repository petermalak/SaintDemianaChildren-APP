import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/spacing.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile_field.dart';
import '../widgets/profile_image_picker.dart';
import '../widgets/loading_button.dart';
import '../widgets/country_phone_field.dart';

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
  final _fathersPhoneController = TextEditingController();
  final _mothersPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressLocationLinkController = TextEditingController();
  final _fatherOfConfessionController = TextEditingController();
  DateTime? _selectedBirthdate;

  String? _selectedImagePath;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('ProfileScreen initialized - isCurrentUser: ${widget.isCurrentUser}');
    _initializeFields();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _fathersPhoneController.dispose();
    _mothersPhoneController.dispose();
    _addressController.dispose();
    _addressLocationLinkController.dispose();
    _fatherOfConfessionController.dispose();
    super.dispose();
  }

  void _initializeFields() {
    final user = widget.user;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber;
      _fathersPhoneController.text = user.fathersPhoneNumber ?? '';
      _mothersPhoneController.text = user.mothersPhoneNumber ?? '';
      _addressController.text = user.address ?? '';
      _addressLocationLinkController.text = user.addressLocationLink ?? '';
      _fatherOfConfessionController.text = user.fatherOfConfession ?? '';
      _selectedBirthdate = user.birthdate;
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
          else if (widget.isCurrentUser)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: _startEdit,
                icon: const Icon(
                  Icons.edit,
                  color: AppColors.accentWhite,
                  size: 24,
                ),
                tooltip: 'تعديل الملف الشخصي',
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
            validator: _isEditing && !isMakhdoum
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'البريد الإلكتروني مطلوب';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'البريد الإلكتروني غير صحيح';
                    }
                    return null;
                  }
                : null,
          ),

          // Phone field - always editable
          CountryPhoneField(
            controller: _phoneController,
            label: 'رقم الهاتف',
            enabled: true, // Always enabled to show country dropdown
            icon: Icons.phone,
            validator: _isEditing
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'رقم الهاتف مطلوب';
                    }
                    return null;
                  }
                : null,
          ),

          // Father's phone field - optional
          CountryPhoneField(
            controller: _fathersPhoneController,
            label: 'رقم هاتف الأب (اختياري)',
            enabled: true, // Always enabled to show country dropdown
            icon: Icons.phone,
          ),

          // Mother's phone field - optional
          CountryPhoneField(
            controller: _mothersPhoneController,
            label: 'رقم هاتف الأم (اختياري)',
            enabled: true, // Always enabled to show country dropdown
            icon: Icons.phone,
          ),

          // Birthdate field - optional
          _buildBirthdateField(),

          // Address field - optional
          ProfileField(
            label: 'العنوان',
            value: _addressController.text,
            isEditable: _isEditing,
            isRequired: false,
            controller: _addressController,
            maxLines: 3,
          ),

          // Address location link field - optional with auto-location
          _buildLocationField(),

          // Father of confession field - optional
          ProfileField(
            label: 'أب الاعتراف',
            value: _fatherOfConfessionController.text,
            isEditable: _isEditing,
            isRequired: false,
            controller: _fatherOfConfessionController,
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

  Widget _buildBirthdateField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تاريخ الميلاد',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _isEditing ? _selectBirthdate : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: _isEditing
                    ? AppColors.backgroundCard
                    : AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: _isEditing
                        ? AppColors.primaryMaroon
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedBirthdate != null
                        ? '${_selectedBirthdate!.day}/${_selectedBirthdate!.month}/${_selectedBirthdate!.year}'
                        : 'لم يتم تحديد تاريخ الميلاد',
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedBirthdate != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (_isEditing) ...[
                    const Spacer(),
                    Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectBirthdate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ??
          DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedBirthdate = date;
      });
    }
  }

  Widget _buildLocationField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'رابط موقع العنوان',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isEditing
                        ? AppColors.backgroundCard
                        : AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    _addressLocationLinkController.text.isNotEmpty
                        ? _addressLocationLinkController.text
                        : 'لم يتم تحديد رابط الموقع',
                    style: TextStyle(
                      fontSize: 14,
                      color: _addressLocationLinkController.text.isNotEmpty
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.location_on, size: 18),
                  label: const Text('موقعي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMaroon,
                    foregroundColor: AppColors.accentWhite,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_isEditing)
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: TextFormField(
                controller: _addressLocationLinkController,
                decoration: InputDecoration(
                  hintText: 'أو أدخل رابط الموقع يدوياً',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryMaroon),
                  ),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!RegExp(r'^https?:\/\/').hasMatch(value)) {
                      return 'يجب أن يبدأ الرابط بـ http:// أو https://';
                    }
                  }
                  return null;
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('تم رفض إذن الموقع');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError(
            'تم رفض إذن الموقع نهائياً. يرجى تفعيله من الإعدادات');
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Create Google Maps link
      final locationLink =
          'https://www.google.com/maps?q=${position.latitude},${position.longitude}';

      // Close loading dialog
      Navigator.of(context).pop();

      // Update the text field
      setState(() {
        _addressLocationLinkController.text = locationLink;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم الحصول على موقعك بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog if it's open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      _showLocationError('فشل في الحصول على الموقع: ${e.toString()}');
    }
  }

  void _showLocationError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطأ في الموقع'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.khadem:
        return 'خادم';
      case UserRole.makhdoum:
        return 'مخدوم';
      case UserRole.admin:
        return 'مدير';
      case UserRole.superAdmin:
        return 'مدير عام';
    }
  }

  void _startEdit() {
    print('Edit button pressed! Starting edit mode...');
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
        'phoneNumber': _phoneController.text.trim(),
        'fathersPhoneNumber': _fathersPhoneController.text.trim().isEmpty
            ? null
            : _fathersPhoneController.text.trim(),
        'mothersPhoneNumber': _mothersPhoneController.text.trim().isEmpty
            ? null
            : _mothersPhoneController.text.trim(),
        'birthdate': _selectedBirthdate
            ?.toIso8601String()
            .split('T')[0], // Format as YYYY-MM-DD
        'address': _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        'addressLocationLink':
            _addressLocationLinkController.text.trim().isEmpty
                ? null
                : _addressLocationLinkController.text.trim(),
        'fatherOfConfession': _fatherOfConfessionController.text.trim().isEmpty
            ? null
            : _fatherOfConfessionController.text.trim(),
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
