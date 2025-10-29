import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/authentication/model/user_model.dart';
import '../constants/app_colors.dart';
import 'country_phone_field.dart';

class InfoForm extends StatefulWidget {
  InfoForm({
    super.key,
    this.isEditing = true,
    required this.user,
    required this.selectedImagePath,
  });

  final UserModel user;
  String? selectedImagePath;
  final bool isEditing;

  @override
  State<InfoForm> createState() => InfoFormState();
}

class InfoFormState extends State<InfoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _fatherPhoneController;
  late final TextEditingController _motherPhoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _addressLinkController;
  late final TextEditingController _fatherOfConfessionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _fatherPhoneController =
        TextEditingController(text: widget.user.fathersPhoneNumber);
    _motherPhoneController =
        TextEditingController(text: widget.user.mothersPhoneNumber);
    _addressController = TextEditingController(text: widget.user.address);
    _addressLinkController =
        TextEditingController(text: widget.user.addressLocationLink);
    _fatherOfConfessionController =
        TextEditingController(text: widget.user.fatherOfConfession );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _fatherPhoneController.dispose();
    _motherPhoneController.dispose();
    _addressController.dispose();
    _addressLinkController.dispose();

    _fatherOfConfessionController.dispose();

    super.dispose();
  }

  // Method to collect form data into the user model
  bool saveFormToModel() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.user.name = _nameController.text;
      widget.user.phoneNumber = _phoneController.text;
      if(_fatherPhoneController.text.length>7)widget.user.fathersPhoneNumber = _fatherPhoneController.text;
      if(_motherPhoneController.text.length>7)widget.user.mothersPhoneNumber = _motherPhoneController.text;
      if(_addressController.text.isNotEmpty)widget.user.address = _addressController.text;
      if(_addressLinkController.text.isNotEmpty)widget.user.addressLocationLink = _addressLinkController.text;
      if(_fatherOfConfessionController.text.isNotEmpty)widget.user.fatherOfConfession = _fatherOfConfessionController.text;
      // Add more fields if needed
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'الاسم',
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال الاسم';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CountryPhoneField(
            enabled: widget.isEditing,
            controller: _phoneController,
            label: 'رقم الهاتف',
            icon: Icons.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال رقم الهاتف';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CountryPhoneField(
            enabled: widget.isEditing,
            controller: _fatherPhoneController,
            label: 'رقم هاتف الأب (اختياري)',
            icon: Icons.phone,
          ),
          const SizedBox(height: 16),
          CountryPhoneField(
            enabled: widget.isEditing,
            controller: _motherPhoneController,
            label: 'رقم هاتف الأم (اختياري)',
            icon: Icons.phone,
          ),
          const SizedBox(height: 16),
          _buildBirthdateSelector(),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _addressController,
            label: 'العنوان (اختياري)',
            icon: Icons.location_on,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _addressLinkController,
                  label: 'رابط موقع العنوان (اختياري)',
                  icon: Icons.link,
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (!RegExp(r'^https?://').hasMatch(value)) {
                        return 'يجب أن يبد الرابط بـ http:// أو https://';
                      }
                    }
                    return null;
                  },
                ),
              ),
              if (widget.isEditing) ...[
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
              ]
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _fatherOfConfessionController,
            label: 'أب الاعتراف (اختياري)',
            icon: Icons.person,
          ),
          const SizedBox(height: 16),
          widget.isEditing ? _buildImageSelector() : const SizedBox.shrink(),
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
        _addressLinkController.text = locationLink;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم الحصول على موقعك بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
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

  Widget _buildImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'صورة الملف الشخصي (اختياري)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: Text(widget.selectedImagePath != null
                    ? 'تغيير الصورة'
                    : 'اختيار صورة'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (widget.selectedImagePath != null) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => widget.selectedImagePath = null),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.accentWhite,
                    size: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (widget.selectedImagePath != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(widget.selectedImagePath!),
              height: 80,
              width: 80,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBirthdateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تاريخ الميلاد (اختياري)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: widget.isEditing ? _selectBirthdate : null,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: AppColors.primaryMaroon),
                const SizedBox(width: 12),
                Text(
                  widget.user.birthdate != null
                      ? '${widget.user.birthdate!.day}/${widget.user.birthdate!.month}/${widget.user.birthdate!.year}'
                      : 'اختيار تاريخ الميلاد',
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.user.birthdate != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.right,
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectBirthdate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.user.birthdate ??
          DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        widget.user.birthdate = date;
      });
    }
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool? isEditing,
    bool obscureText = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      enabled: isEditing ?? widget.isEditing,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryMaroon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primaryMaroon, width: 2),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        widget.selectedImagePath = pickedFile.path;
      });
    }
  }
}
