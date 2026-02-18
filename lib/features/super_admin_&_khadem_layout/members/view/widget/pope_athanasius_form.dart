import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../../core/widgets/custom_text_field.dart';

class PopeAthanasiusForm extends StatefulWidget {
  final PopeAthanasiusFormData? initialData;
  final Function(PopeAthanasiusFormData) onDataChanged;

  const PopeAthanasiusForm({
    super.key,
    this.initialData,
    required this.onDataChanged,
  });

  @override
  State<PopeAthanasiusForm> createState() => _PopeAthanasiusFormState();
}

class PopeAthanasiusFormData {
  String? registrationDate;
  String? regularChurch;
  String? previousServices;
  String? currentService;
  String? yearsOfService;
  String? profession;
  String? maritalStatus;
  String? meetingEmail;
  bool? interestedBible;
  bool? interestedTheology;
  bool? interestedComparativeTheology;
  bool? interestedApologetics;
  bool? interestedHistory;
  bool? interestedPatristics;
  String? previousCourses;
  String? needToKnow;
  bool? wantExam;
  int? classPhase;

  Map<String, dynamic> toAdditionalData() {
    return {
      'registrationDate': registrationDate,
      'regularChurch': regularChurch,
      'previousServices': previousServices,
      'currentService': currentService,
      'yearsOfService': yearsOfService,
      'profession': profession,
      'maritalStatus': maritalStatus,
      'meetingEmail': meetingEmail,
      'interestedBible': interestedBible,
      'interestedTheology': interestedTheology,
      'interestedComparativeTheology': interestedComparativeTheology,
      'interestedApologetics': interestedApologetics,
      'interestedHistory': interestedHistory,
      'interestedPatristics': interestedPatristics,
      'previousCourses': previousCourses,
      'needToKnow': needToKnow,
      'wantExam': wantExam,
    };
  }
}

class _PopeAthanasiusFormState extends State<PopeAthanasiusForm> {
  late PopeAthanasiusFormData _formData;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _registrationDateController =
      TextEditingController();
  final TextEditingController _regularChurchController =
      TextEditingController();
  final TextEditingController _previousServicesController =
      TextEditingController();
  final TextEditingController _currentServiceController =
      TextEditingController();
  final TextEditingController _yearsOfServiceController =
      TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _maritalStatusController =
      TextEditingController();
  final TextEditingController _meetingEmailController = TextEditingController();
  final TextEditingController _previousCoursesController =
      TextEditingController();
  final TextEditingController _needToKnowController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _formData = widget.initialData ?? PopeAthanasiusFormData();
    _initializeControllers();
  }

  void _initializeControllers() {
    _registrationDateController.text = _formData.registrationDate ?? '';
    _regularChurchController.text = _formData.regularChurch ?? '';
    _previousServicesController.text = _formData.previousServices ?? '';
    _currentServiceController.text = _formData.currentService ?? '';
    _yearsOfServiceController.text = _formData.yearsOfService ?? '';
    _professionController.text = _formData.profession ?? '';
    _maritalStatusController.text = _formData.maritalStatus ?? '';
    _meetingEmailController.text = _formData.meetingEmail ?? '';
    _previousCoursesController.text = _formData.previousCourses ?? '';
    _needToKnowController.text = _formData.needToKnow ?? '';

    // Add listeners to update form data
    _registrationDateController.addListener(_updateFormData);
    _regularChurchController.addListener(_updateFormData);
    _previousServicesController.addListener(_updateFormData);
    _currentServiceController.addListener(_updateFormData);
    _yearsOfServiceController.addListener(_updateFormData);
    _professionController.addListener(_updateFormData);
    _maritalStatusController.addListener(_updateFormData);
    _meetingEmailController.addListener(_updateFormData);
    _previousCoursesController.addListener(_updateFormData);
    _needToKnowController.addListener(_updateFormData);
  }

  void _updateFormData() {
    setState(() {
      _formData.registrationDate =
          _registrationDateController.text.trim().isEmpty
              ? null
              : _registrationDateController.text.trim();
      _formData.regularChurch = _regularChurchController.text.trim().isEmpty
          ? null
          : _regularChurchController.text.trim();
      _formData.previousServices =
          _previousServicesController.text.trim().isEmpty
              ? null
              : _previousServicesController.text.trim();
      _formData.currentService = _currentServiceController.text.trim().isEmpty
          ? null
          : _currentServiceController.text.trim();
      _formData.yearsOfService = _yearsOfServiceController.text.trim().isEmpty
          ? null
          : _yearsOfServiceController.text.trim();
      _formData.profession = _professionController.text.trim().isEmpty
          ? null
          : _professionController.text.trim();
      _formData.maritalStatus = _maritalStatusController.text.trim().isEmpty
          ? null
          : _maritalStatusController.text.trim();
      _formData.meetingEmail = _meetingEmailController.text.trim().isEmpty
          ? null
          : _meetingEmailController.text.trim();
      _formData.previousCourses = _previousCoursesController.text.trim().isEmpty
          ? null
          : _previousCoursesController.text.trim();
      _formData.needToKnow = _needToKnowController.text.trim().isEmpty
          ? null
          : _needToKnowController.text.trim();
    });
    widget.onDataChanged(_formData);
  }

  @override
  void dispose() {
    _registrationDateController.dispose();
    _regularChurchController.dispose();
    _previousServicesController.dispose();
    _currentServiceController.dispose();
    _yearsOfServiceController.dispose();
    _professionController.dispose();
    _maritalStatusController.dispose();
    _meetingEmailController.dispose();
    _previousCoursesController.dispose();
    _needToKnowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typographyScale =
        ResponsiveDialogTypography.resolve(MediaQuery.of(context).size);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryMaroon.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryMaroon.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.church, color: AppColors.primaryMaroon, size: 20),
              const SizedBox(width: 8),
              Text(
                'بيانات لقاء البابا أثناسيوس',
                style: ResponsiveDialogTypography.merge(
                  textTheme.titleMedium,
                  typographyScale.subtitle,
                  color: AppColors.primaryMaroon,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                  controller: _registrationDateController,
                  labelText: 'تاريخ التسجيل (YYYY-MM-DD)',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _regularChurchController,
                  labelText: 'الكنيسه المواظب عليها',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _previousServicesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'خدمات سابقه',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundCard,
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _currentServiceController,
                  labelText: 'الخدمه الحاليه',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _yearsOfServiceController,
                  labelText: 'عدد سنين الخدمه',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _professionController,
                  labelText: 'الوظيفه',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _maritalStatusController,
                  labelText: 'الحاله الاجتماعيه',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _meetingEmailController,
                  labelText: 'الايميل',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildInterestsSection(typographyScale, textTheme),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _previousCoursesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'الدورات السابقة',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundCard,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _needToKnowController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'أريد أن أعرف',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundCard,
                  ),
                ),
                const SizedBox(height: 12),
                _buildClassPhaseSelector(typographyScale, textTheme),
                const SizedBox(height: 12),
                _buildWantExamCheckbox(typographyScale, textTheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(
      DialogTypographyScale typography, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اهتم بدارسه:',
          style: ResponsiveDialogTypography.merge(
            textTheme.bodyMedium,
            typography.body,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildInterestCheckbox(
                'الكتاب المقدس', _formData.interestedBible ?? false, (value) {
              setState(() {
                _formData.interestedBible = value;
              });
              widget.onDataChanged(_formData);
            }),
            _buildInterestCheckbox(
                'العقيده', _formData.interestedTheology ?? false, (value) {
              setState(() {
                _formData.interestedTheology = value;
              });
              widget.onDataChanged(_formData);
            }),
            _buildInterestCheckbox('اللاهوت المقارن',
                _formData.interestedComparativeTheology ?? false, (value) {
              setState(() {
                _formData.interestedComparativeTheology = value;
              });
              widget.onDataChanged(_formData);
            }),
            _buildInterestCheckbox(
                'الدفاعيات', _formData.interestedApologetics ?? false, (value) {
              setState(() {
                _formData.interestedApologetics = value;
              });
              widget.onDataChanged(_formData);
            }),
            _buildInterestCheckbox(
                'التاريخ', _formData.interestedHistory ?? false, (value) {
              setState(() {
                _formData.interestedHistory = value;
              });
              widget.onDataChanged(_formData);
            }),
            _buildInterestCheckbox(
                'ابائيات', _formData.interestedPatristics ?? false, (value) {
              setState(() {
                _formData.interestedPatristics = value;
              });
              widget.onDataChanged(_formData);
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildInterestCheckbox(
      String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: (newValue) => onChanged(newValue ?? false),
          activeColor: AppColors.primaryMaroon,
        ),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildClassPhaseSelector(
      DialogTypographyScale typography, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<int?>(
        value: _formData.classPhase,
        decoration: const InputDecoration(
          labelText: 'مرحلة الفصل',
          border: InputBorder.none,
          icon: Icon(Icons.class_, color: AppColors.primaryMaroon),
        ),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('لا شيء')),
          const DropdownMenuItem<int?>(value: 1, child: Text('المرحلة 1')),
          const DropdownMenuItem<int?>(value: 2, child: Text('المرحلة 2')),
          const DropdownMenuItem<int?>(value: 3, child: Text('المرحلة 3')),
        ],
        onChanged: (value) {
          setState(() {
            _formData.classPhase = value;
          });
          widget.onDataChanged(_formData);
        },
      ),
    );
  }

  Widget _buildWantExamCheckbox(
      DialogTypographyScale typography, TextTheme textTheme) {
    return CheckboxListTile(
      title: const Text('أريد امتحان'),
      value: _formData.wantExam ?? false,
      onChanged: (value) {
        setState(() {
          _formData.wantExam = value;
        });
        widget.onDataChanged(_formData);
      },
      activeColor: AppColors.primaryMaroon,
      contentPadding: EdgeInsets.zero,
    );
  }
}
