import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saint_demiana_children/core/constants/api_endpoints.dart';
import 'package:saint_demiana_children/core/constants/app_colors.dart';
import 'package:saint_demiana_children/core/di/service_locator.dart';
import 'package:saint_demiana_children/features/shop/model/shop_gift_model.dart';
import 'package:saint_demiana_children/features/shop/repository/i_shop_repository.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/model/class_model.dart';

class AddEditGiftDialog extends StatefulWidget {
  final String classId;
  final List<ClassModel>? classes;
  final ShopGiftModel? gift;
  final VoidCallback onSaved;

  const AddEditGiftDialog({
    super.key,
    required this.classId,
    this.classes,
    this.gift,
    required this.onSaved,
  });

  @override
  State<AddEditGiftDialog> createState() => _AddEditGiftDialogState();
}

class _AddEditGiftDialogState extends State<AddEditGiftDialog> {
  final _shopRepo = sl<IShopRepository>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isVisible = true;
  bool _saving = false;
  bool _uploadingImage = false;

  /// Single class for edit mode or when only one class is selected in add mode.
  late String _selectedClassId;

  /// For add mode with multiple classes: which classes to assign the gift to.
  late Set<String> _selectedClassIds;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.gift?.classId ?? widget.classId;
    _selectedClassIds = {widget.classId};
    if (widget.gift != null) {
      _titleController.text = widget.gift!.title;
      _descriptionController.text = widget.gift!.description ?? '';
      _priceController.text = widget.gift!.price.toString();
      _imageUrlController.text = widget.gift!.imageUrl ?? '';
      _isVisible = widget.gift!.isVisible;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  String get _fullImageUrl {
    final url = _imageUrlController.text.trim();
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    final base = ApiEndpoints.baseUrl.replaceFirst(RegExp(r'/$'), '');
    return base + (url.startsWith('/') ? url : '/$url');
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('المعرض'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('الكاميرا'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final xFile = await picker.pickImage(
        source: source, maxWidth: 1200, imageQuality: 85);
    if (xFile == null || !mounted) return;
    setState(() => _uploadingImage = true);
    final result = await _shopRepo.uploadGiftImage(xFile);
    if (!mounted) return;
    setState(() => _uploadingImage = false);
    result.fold(
      (msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      ),
      (imageUrl) {
        _imageUrlController.text = imageUrl;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم رفع الصورة'),
              backgroundColor: AppColors.success),
        );
      },
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل عنوان الهدية')),
      );
      return;
    }
    final price = int.tryParse(_priceController.text.trim());
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل سعراً صحيحاً (عدد صحيح غير سالب)')),
      );
      return;
    }
    setState(() => _saving = true);
    if (widget.gift != null) {
      final result = await _shopRepo.updateGift(
        widget.gift!.id,
        title: title,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        price: price,
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        isVisible: _isVisible,
        classId:
            _selectedClassId != widget.gift!.classId ? _selectedClassId : null,
      );
      result.fold(
        (msg) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: AppColors.error),
          );
        },
        (_) {
          setState(() => _saving = false);
          Navigator.of(context).pop();
          widget.onSaved();
        },
      );
    } else {
      if (widget.classes != null &&
          widget.classes!.length > 1 &&
          _selectedClassIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('اختر فصلاً واحداً على الأقل'),
              backgroundColor: AppColors.error),
        );
        return;
      }
      final classIds = _selectedClassIds.isNotEmpty
          ? _selectedClassIds.toList()
          : [_selectedClassId];
      final description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();
      final imageUrl = _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim();
      String? firstError;
      for (final classId in classIds) {
        final result = await _shopRepo.createGift(
          classId,
          title: title,
          description: description,
          price: price,
          imageUrl: imageUrl,
          isVisible: _isVisible,
        );
        result.fold(
          (msg) => firstError ??= msg,
          (_) {},
        );
      }
      if (!mounted) return;
      setState(() => _saving = false);
      if (firstError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(firstError!), backgroundColor: AppColors.error),
        );
      } else {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.gift != null;
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'تعديل الهدية' : 'إضافة هدية',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (widget.classes != null && widget.classes!.isNotEmpty) ...[
              Text(
                isEdit
                    ? 'الفصل الذي تظهر فيه الهدية'
                    : (widget.classes!.length > 1
                        ? 'الفصول التي تظهر فيها الهدية (اختر واحداً أو أكثر)'
                        : 'الفصل الذي تظهر فيه الهدية'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              if (isEdit)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedClassId,
                      isExpanded: true,
                      hint: const Text('اختر الفصل'),
                      items: widget.classes!
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: (id) {
                        if (id != null) setState(() => _selectedClassId = id);
                      },
                    ),
                  ),
                )
              else if (widget.classes!.length > 1)
                ...widget.classes!.map((c) {
                  final selected = _selectedClassIds.contains(c.id);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedClassIds.add(c.id);
                        } else {
                          _selectedClassIds.remove(c.id);
                        }
                      });
                    },
                    title: Text(c.name),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  );
                })
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    widget.classes!.first.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'العنوان',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'الوصف (اختياري)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'السعر (نقاط)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            const Text('صورة الهدية',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (_fullImageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _fullImageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                ),
              ),
              const SizedBox(height: 6),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed:
                      _uploadingImage || _saving ? null : _pickAndUploadImage,
                  icon: _uploadingImage
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload),
                  label: Text(_uploadingImage ? 'جاري الرفع...' : 'رفع صورة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMaroon,
                  ),
                ),
                if (_imageUrlController.text.trim().isNotEmpty)
                  TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () {
                            _imageUrlController.clear();
                            setState(() {});
                          },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('إزالة الصورة'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'رابط الصورة (اختياري أو ارفع أعلاه)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('ظاهر للمخدومين'),
                const SizedBox(width: 12),
                Switch(
                  value: _isVisible,
                  onChanged: (v) => setState(() => _isVisible = v),
                  activeTrackColor:
                      AppColors.primaryMaroon.withValues(alpha: 0.5),
                  activeThumbColor: AppColors.primaryMaroon,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMaroon,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEdit ? 'حفظ' : 'إضافة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      color: AppColors.backgroundCard,
      child: Icon(Icons.broken_image_outlined,
          size: 48, color: AppColors.textSecondary),
    );
  }
}
