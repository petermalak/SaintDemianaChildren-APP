import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/locale/app_language.dart';
import '../../../../core/session/session_context.dart';
import '../../../../core/utils/role_helper.dart';
import '../../../../core/services/interface/i_api_service.dart';
import '../../../../core/widgets/country_phone_field.dart';
import '../../../../core/widgets/profile_field.dart';
import '../../../../core/widgets/profile_image_picker.dart';
import '../../../authentication/model/user_model.dart';
import '../../../authentication/view/screen/change_password_screen.dart';
import '../../repository/i_profile_repository.dart';
import '../../viewmodel/profile_cubit.dart';
import '../../../program/repository/i_program_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fathersPhoneController = TextEditingController();
  final _mothersPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressLocationLinkController = TextEditingController();
  final _fatherOfConfessionController = TextEditingController();
  DateTime? _selectedBirthdate;
  String? _selectedImagePath;
  List<int>? _imageBytes;
  String? _imageName;
  bool _isEditing = false;
  String? _serviceProgramId;
  List<Map<String, String>> _serviceFields = const [];
  final Map<String, TextEditingController> _extraControllers = {};
  UserModel get user => sl<IProfileRepository>().user!;
  @override
  void initState() {
    super.initState();
    _initializeFields();
    _loadServiceFields();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameEnController.dispose();
    for (final input in _extraControllers.values) {
      input.dispose();
    }
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
    _nameController.text = user.name!;
    _nameEnController.text = user.nameEn ?? '';
    _emailController.text = user.email!;
    _phoneController.text = user.phoneNumber!;
    _fathersPhoneController.text = user.fathersPhoneNumber ?? '';
    _mothersPhoneController.text = user.mothersPhoneNumber ?? '';
    _addressController.text = user.address ?? '';
    _addressLocationLinkController.text = user.addressLocationLink ?? '';
    _fatherOfConfessionController.text = user.fatherOfConfession ?? '';
    _selectedBirthdate = user.birthdate;
    _selectedImagePath = user.profileImage;
    _imageBytes = null;
    _imageName = null;
  }

  @override
  Widget build(BuildContext context) {
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
                        if (user.theaterProfile != null) ...[
                          const SizedBox(height: AppSpacing.xl),
                          _buildTheaterSection(),
                        ],
                        if (_serviceFields.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xl),
                          _buildServiceFields(),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        _buildSecuritySection(),
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
          (!_isEditing)
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () {
                        AppLanguage.instance.toggle();
                        setState(() {});
                      },
                      child: Text(
                        AppLanguage.instance.english ? 'عربي' : 'EN',
                        style: const TextStyle(color: AppColors.accentWhite, fontWeight: FontWeight.bold),
                      ),
                    ),
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
                        tooltip: AppLanguage.instance.t('تعديل الملف الشخصي', 'Edit profile'),
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
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

          ProfileField(
            label: AppLanguage.instance.t('الاسم بالإنجليزي', 'English name'),
            value: _nameEnController.text,
            isEditable: _isEditing,
            controller: _nameEnController,
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
                    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
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
            enabled: _isEditing, // Always enabled to show country dropdown
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
            enabled: _isEditing, // Always enabled to show country dropdown
            icon: Icons.phone,
          ),

          // Mother's phone field - optional
          CountryPhoneField(
            controller: _mothersPhoneController,
            label: 'رقم هاتف الأم (اختياري)',
            enabled: _isEditing, // Always enabled to show country dropdown
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

          // ID field - always read-only
          ProfileField(
            label: 'رقم العضوية',
            value: user.id.toString(),
            isEditable: false,
            isRequired: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTheaterSection() {
    final profile = user.theaterProfile!;
    final participated = profile.participatedBefore == null
        ? null
        : (profile.participatedBefore! ? 'نعم' : 'لا');

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
            'خدمة المسرح',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ProfileField(
            label: 'القسم',
            value: profile.departmentLabel,
            isEditable: false,
            isRequired: false,
          ),
          if (profile.stage != null && profile.stage!.isNotEmpty)
            ProfileField(
              label: 'المرحلة',
              value: profile.stage!,
              isEditable: false,
              isRequired: false,
            ),
          if (profile.priority1 != null && profile.priority1!.isNotEmpty)
            ProfileField(
              label: 'الأولوية الأولى',
              value: profile.priority1!,
              isEditable: false,
              isRequired: false,
            ),
          if (profile.priority2 != null && profile.priority2!.isNotEmpty)
            ProfileField(
              label: 'الأولوية التانية',
              value: profile.priority2!,
              isEditable: false,
              isRequired: false,
            ),
          if (participated != null)
            ProfileField(
              label: 'اشترك في مسرحيات قبل كده',
              value: participated,
              isEditable: false,
              isRequired: false,
            ),
          if (profile.previousResponsibility != null &&
              profile.previousResponsibility!.isNotEmpty)
            ProfileField(
              label: 'المسؤولية السابقة',
              value: profile.previousResponsibility!,
              isEditable: false,
              isRequired: false,
            ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    if (_isEditing) return const SizedBox.shrink();

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
            'الأمان',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        color: AppColors.accentWhite,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تغيير كلمة المرور',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'قم بتحديث كلمة المرور للحفاظ على أمان حسابك',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (!_isEditing) return const SizedBox.shrink();
    return BlocProvider(
      create: (context) => ProfileCubit(sl<IProfileRepository>()),
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileSuccess) {
            setState(() {
              _isEditing = false;
              _initializeFields();
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('تم تحديث الملف الشخصي بنجاح'),
            ));
          } else if (state is ProfileFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('فشل في تحديث الملف الشخصي: ${state.errorMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelEdit,
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
                child: OutlinedButton(
                  onPressed: state is ProfileLoading ? null : () => _saveProfile(context),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    side: const BorderSide(color: AppColors.primaryMaroon),
                    backgroundColor: AppColors.primaryMaroon,
                  ),
                  child: Text(
                    AppLanguage.instance.t('حفظ', 'Save'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBirthdateField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
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
          const Text(
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
                    borderSide:
                        const BorderSide(color: AppColors.primaryMaroon),
                  ),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!RegExp(r'^https?://').hasMatch(value)) {
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

  void _onImageChanged(String? imagePath, List<int>? bytes, String? name) {
    setState(() {
      _selectedImagePath = imagePath;
      _imageBytes = bytes;
      _imageName = name;
    });
  }

  Future<void> _saveProfile(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    var image = _selectedImagePath;
    if (_imageBytes != null && _imageBytes!.isNotEmpty) {
      try {
        final uploaded = await sl<IApiService>().postMultipart(
          path: 'users/me/profile-image',
          filePath: kIsWeb ? null : image,
          fileBytes: _imageBytes,
          fileName: _imageName ?? 'profile.jpg',
          contentType: 'image/jpeg',
        );
        final data = uploaded.data;
        final url = data is Map ? data['imageUrl']?.toString() : null;
        if (url != null && url.isNotEmpty) image = url;
        _imageBytes = null;
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLanguage.instance.t('الصورة ما اترفعتش', 'The photo was not uploaded'))),
        );
        return;
      }
    }
    if (!context.mounted) return;
    final updated = user.copyWith(
      name: _nameController.text.trim(),
      nameEn: _nameEnController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      fathersPhoneNumber: _fathersPhoneController.text.trim(),
      mothersPhoneNumber: _mothersPhoneController.text.trim(),
      address: _addressController.text.trim(),
      addressLocationLink: _addressLocationLinkController.text.trim(),
      fatherOfConfession: _fatherOfConfessionController.text.trim(),
      birthdate: _selectedBirthdate,
      profileImage: image,
    );
    context.read<ProfileCubit>().updateProfile(updated, clearImage: image == null);
    final programId = _serviceProgramId;
    if (programId != null && _serviceFields.isNotEmpty) {
      await sl<IProgramRepository>().saveProfileFields(programId, {
        for (final field in _serviceFields)
          field['keyName']!: _extraControllers[field['keyName']]?.text.trim() ?? '',
      });
    }
  }

  Future<void> _loadServiceFields() async {
    final program = RoleHelper.programFor(user, SessionContext.instance.current);
    if (program == null) return;
    final result = await sl<IProgramRepository>().summary(program.id);
    if (!mounted) return;
    result.fold((_) {}, (data) {
      final rows = data['profileFields'];
      final values = data['profileValues'];
      final fields = <Map<String, String>>[];
      if (rows is List) {
        for (final row in rows.whereType<Map>()) {
          final key = row['keyName']?.toString() ?? '';
          if (key.isEmpty) continue;
          fields.add({'keyName': key, 'label': (row['label'] ?? key).toString()});
        }
      }
      setState(() {
        _serviceProgramId = program.id;
        _serviceFields = fields;
        for (final field in fields) {
          final key = field['keyName']!;
          final current = values is Map ? values[key]?.toString() ?? '' : '';
          _extraControllers.putIfAbsent(key, TextEditingController.new).text = current;
        }
      });
    });
  }

  Widget _buildServiceFields() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLanguage.instance.t('بيانات الخدمة', 'Service details'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final field in _serviceFields)
            ProfileField(
              label: field['label'] ?? '',
              value: _extraControllers[field['keyName']]?.text ?? '',
              isEditable: _isEditing,
              controller: _extraControllers[field['keyName']],
            ),
        ],
      ),
    );
  }
}
