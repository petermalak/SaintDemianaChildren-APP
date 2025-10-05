import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';

class Country {
  final String name;
  final String code;
  final String flag;
  final String dialCode;
  final String pattern;

  const Country({
    required this.name,
    required this.code,
    required this.flag,
    required this.dialCode,
    required this.pattern,
  });
}

class CountryPhoneField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool enabled;
  final IconData? icon;
  final int? maxLines;
  final TextInputType? keyboardType;

  const CountryPhoneField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.enabled = true,
    this.icon,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  State<CountryPhoneField> createState() => _CountryPhoneFieldState();
}

class _CountryPhoneFieldState extends State<CountryPhoneField> {
  late Country _selectedCountry;
  final List<Country> _countries = [
    const Country(
      name: 'مصر',
      code: 'EG',
      flag: '🇪🇬',
      dialCode: '+20',
      pattern: r'^(\+20|0)?1[0-9]{9}$',
    ),
    const Country(
      name: 'السعودية',
      code: 'SA',
      flag: '🇸🇦',
      dialCode: '+966',
      pattern: r'^(\+966|0)?5[0-9]{8}$',
    ),
    const Country(
      name: 'الإمارات',
      code: 'AE',
      flag: '🇦🇪',
      dialCode: '+971',
      pattern: r'^(\+971|0)?5[0-9]{8}$',
    ),
    const Country(
      name: 'الكويت',
      code: 'KW',
      flag: '🇰🇼',
      dialCode: '+965',
      pattern: r'^(\+965|0)?[569][0-9]{7}$',
    ),
    const Country(
      name: 'قطر',
      code: 'QA',
      flag: '🇶🇦',
      dialCode: '+974',
      pattern: r'^(\+974|0)?[3-7][0-9]{7}$',
    ),
    const Country(
      name: 'البحرين',
      code: 'BH',
      flag: '🇧🇭',
      dialCode: '+973',
      pattern: r'^(\+973|0)?[3-9][0-9]{7}$',
    ),
    const Country(
      name: 'عُمان',
      code: 'OM',
      flag: '🇴🇲',
      dialCode: '+968',
      pattern: r'^(\+968|0)?[79][0-9]{7}$',
    ),
    const Country(
      name: 'الأردن',
      code: 'JO',
      flag: '🇯🇴',
      dialCode: '+962',
      pattern: r'^(\+962|0)?7[789][0-9]{7}$',
    ),
    const Country(
      name: 'لبنان',
      code: 'LB',
      flag: '🇱🇧',
      dialCode: '+961',
      pattern: r'^(\+961|0)?[3-9][0-9]{7}$',
    ),
    const Country(
      name: 'سوريا',
      code: 'SY',
      flag: '🇸🇾',
      dialCode: '+963',
      pattern: r'^(\+963|0)?9[0-9]{8}$',
    ),
    const Country(
      name: 'العراق',
      code: 'IQ',
      flag: '🇮🇶',
      dialCode: '+964',
      pattern: r'^(\+964|0)?7[0-9]{9}$',
    ),
    const Country(
      name: 'المغرب',
      code: 'MA',
      flag: '🇲🇦',
      dialCode: '+212',
      pattern: r'^(\+212|0)?[67][0-9]{8}$',
    ),
    const Country(
      name: 'الجزائر',
      code: 'DZ',
      flag: '🇩🇿',
      dialCode: '+213',
      pattern: r'^(\+213|0)?[567][0-9]{8}$',
    ),
    const Country(
      name: 'تونس',
      code: 'TN',
      flag: '🇹🇳',
      dialCode: '+216',
      pattern: r'^(\+216|0)?[2-5][0-9]{7}$',
    ),
    const Country(
      name: 'ليبيا',
      code: 'LY',
      flag: '🇱🇾',
      dialCode: '+218',
      pattern: r'^(\+218|0)?9[0-9]{8}$',
    ),
    const Country(
      name: 'السودان',
      code: 'SD',
      flag: '🇸🇩',
      dialCode: '+249',
      pattern: r'^(\+249|0)?9[0-9]{8}$',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCountry = _countries.firstWhere((c) => c.code == 'EG');
    // Set initial phone number with country code if empty
    if (widget.controller.text.isEmpty) {
      widget.controller.text = _selectedCountry.dialCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Country selector
              GestureDetector(
                onTap: widget.enabled ? _showCountryPicker : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.enabled
                        ? AppColors.backgroundCard
                        : AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCountry.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedCountry.dialCode,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.enabled
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (widget.enabled)
                        Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.textSecondary,
                        )
                      else
                        Icon(
                          Icons.lock,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                          size: 16,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Phone number input
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  enabled: widget.enabled,
                  readOnly: !widget.enabled, // Make read-only when disabled
                  keyboardType: widget.keyboardType ?? TextInputType.phone,
                  maxLines: widget.maxLines,
                  inputFormatters: widget.enabled
                      ? [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+\-\s()]')),
                        ]
                      : null,
                  decoration: InputDecoration(
                    prefixIcon: widget.icon != null
                        ? Icon(widget.icon, color: AppColors.primaryMaroon)
                        : null,
                    hintText: 'رقم الهاتف',
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
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: AppColors.borderLight.withValues(alpha: 0.5)),
                    ),
                    filled: true,
                    fillColor: widget.enabled
                        ? AppColors.backgroundCard
                        : AppColors.backgroundSecondary,
                  ),
                  validator: (value) {
                    if (widget.validator != null) {
                      return widget.validator!(value);
                    }

                    return null;
                  },
                  onChanged: (value) {
                    // Auto-format the phone number
                    _formatPhoneNumber(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _formatPhoneNumber(String value) {
    // Remove all non-digit characters except +
    String cleanValue = value.replaceAll(RegExp(r'[^\d+]'), '');

    // If the number doesn't start with the country code, add it
    if (!cleanValue.startsWith(_selectedCountry.dialCode)) {
      if (cleanValue.startsWith('+')) {
        // User is typing a different country code, don't interfere
        return;
      } else {
        // Add the country code
        cleanValue = _selectedCountry.dialCode + cleanValue;
      }
    }

    // Update the controller if the value changed
    if (widget.controller.text != cleanValue) {
      widget.controller.value = widget.controller.value.copyWith(
        text: cleanValue,
        selection: TextSelection.collapsed(offset: cleanValue.length),
      );
    }
  }

  void _showCountryPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'اختر الدولة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _countries.length,
            itemBuilder: (context, index) {
              final country = _countries[index];
              final isSelected = country.code == _selectedCountry.code;

              return ListTile(
                leading: Text(
                  country.flag,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  country.name,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? AppColors.primaryMaroon
                        : AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  country.dialCode,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primaryMaroon
                        : AppColors.textSecondary,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check,
                        color: AppColors.primaryMaroon,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    _selectedCountry = country;
                  });

                  // Update the phone number with new country code
                  final currentNumber = widget.controller.text;
                  final cleanNumber =
                      currentNumber.replaceAll(RegExp(r'[^\d]'), '');

                  // If the current number starts with the old country code, replace it
                  if (currentNumber.startsWith(_selectedCountry.dialCode)) {
                    widget.controller.text = _selectedCountry.dialCode +
                        cleanNumber.substring(_selectedCountry.dialCode.length);
                  } else {
                    widget.controller.text =
                        _selectedCountry.dialCode + cleanNumber;
                  }

                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // Getter for the selected country
  Country get selectedCountry => _selectedCountry;

  // Getter for the full phone number with country code
  String get fullPhoneNumber => widget.controller.text;

  // Method to validate the phone number
  bool isValidPhoneNumber() {
    final value = widget.controller.text;
    if (value.isEmpty) return false;

    final cleanNumber = value.replaceAll(RegExp(r'[\s\-()]'), '');
    return RegExp(_selectedCountry.pattern).hasMatch(cleanNumber);
  }
}
