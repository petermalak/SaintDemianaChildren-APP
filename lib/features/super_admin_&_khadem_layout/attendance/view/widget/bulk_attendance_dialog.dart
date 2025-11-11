import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/services/data_refresh_cubit.dart';
import '../../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../authentication/model/user_model.dart';
import '../../../members/repository/i_members_repository.dart';
import '../../repository/i_attendance_repository.dart';
import '../../viewmodel/add_attendance/add_attendance_cubit.dart';

class BulkAttendanceDialog extends StatelessWidget {
  const BulkAttendanceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddAttendanceCubit(sl<IAttendanceRepository>()),
      child: const _BulkAttendanceDialogContent(),
    );
  }
}

class _BulkAttendanceDialogContent extends StatefulWidget {
  const _BulkAttendanceDialogContent();

  @override
  State<_BulkAttendanceDialogContent> createState() =>
      _BulkAttendanceDialogContentState();
}

class _BulkAttendanceDialogContentState
    extends State<_BulkAttendanceDialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  String? _selectedEvent;
  DateTime _selectedDate = DateTime.now();
  List<UserModel> _selectedMembers = [];
  List<UserModel> _allMembers = [];
  List<UserModel> _filteredMembers = [];
  bool _selectAll = false;
  bool _isLoadingMembers = true;
  _BulkDialogStep _currentStep = _BulkDialogStep.details;
  bool _shouldAddScore = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _searchController.addListener(_filterMembers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadMembers() {
    final membersRepo = sl<IMembersRepository>();
    setState(() {
      // Sort members alphabetically by name
      _allMembers = List.from(membersRepo.members)
        ..sort((a, b) {
          final nameA = a.name?.trim() ?? '';
          final nameB = b.name?.trim() ?? '';
          return nameA.compareTo(nameB);
        });
      _filteredMembers = _allMembers;
      _isLoadingMembers = false;
    });
  }

  void _filterMembers() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredMembers = _allMembers;
      } else {
        _filteredMembers = _allMembers.where((member) {
          final name = member.name?.toLowerCase() ?? '';
          final email = member.email?.toLowerCase() ?? '';
          return name.contains(query) || email.contains(query);
        }).toList();
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        // Select all filtered members
        for (var member in _filteredMembers) {
          if (!_selectedMembers.contains(member)) {
            _selectedMembers.add(member);
          }
        }
      } else {
        // Deselect all filtered members
        _selectedMembers.removeWhere((m) => _filteredMembers.contains(m));
      }
    });
  }

  void _toggleMember(UserModel member) {
    setState(() {
      if (_selectedMembers.contains(member)) {
        _selectedMembers.remove(member);
        _selectAll = false;
      } else {
        _selectedMembers.add(member);
        if (_selectedMembers.length == _allMembers.length) {
          _selectAll = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;
    final sizing = ResponsiveDialogUtils.buildSizing(
      mediaSize,
      minWidth: 480,
      maxWidth: 1320,
      compactHeightFactor: 0.58,
      regularHeightFactor: 0.74,
    );
    final isWideLayout = sizing.width >= 900;
    final sidePanelWidth =
        (sizing.width * 0.34).clamp(260.0, sizing.width < 1100 ? 360.0 : 420.0);

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
              _buildHeader(context),
              Flexible(
                child: Form(
                  key: _formKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _buildResponsiveContent(
                      key: ValueKey(_currentStep),
                      isWideLayout: isWideLayout,
                      sidePanelWidth: sidePanelWidth,
                      mediaSize: mediaSize,
                    ),
                  ),
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveContent({
    Key? key,
    required bool isWideLayout,
    required double sidePanelWidth,
    required Size mediaSize,
  }) {
    final isMembersStep = _currentStep == _BulkDialogStep.members;

    if (!isMembersStep) {
      return SingleChildScrollView(
        key: key,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepIndicator(),
            const SizedBox(height: 16),
            _buildEventSelector(),
            const SizedBox(height: 20),
            _buildDateSelector(),
            const SizedBox(height: 20),
            _buildScoreToggle(),
            const SizedBox(height: 20),
            _buildSelectionSummary(),
          ],
        ),
      );
    }

    if (!isWideLayout) {
      return LayoutBuilder(
        key: key,
        builder: (context, constraints) {
          final maxHeight = (mediaSize.height * 0.7).clamp(480.0, 620.0);

          return Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepIndicator(),
                const SizedBox(height: 8),
                _buildCompactSelectionSummary(),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    physics: const BouncingScrollPhysics(),
                    child: _buildMembersSelection(
                      maxListHeight:
                          (mediaSize.height * 0.55).clamp(320.0, 460.0),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    if (isWideLayout) {
      return Padding(
        key: key,
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: sidePanelWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepIndicator(),
                  const SizedBox(height: 16),
                  _buildEventSelector(),
                  const SizedBox(height: 16),
                  _buildDateSelector(),
                  const SizedBox(height: 16),
                  _buildScoreToggle(),
                  const SizedBox(height: 20),
                  _buildSelectionSummary(
                    showEventDetails: true,
                    maxHeight: mediaSize.height / 5,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildMembersSelection(
                maxListHeight: (mediaSize.height * 0.6).clamp(360.0, 520.0),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStepIndicator() {
    final isDetails = _currentStep == _BulkDialogStep.details;

    return Row(
      children: [
        _StepChip(
          index: 1,
          label: 'تفاصيل الحضور',
          isActive: isDetails,
        ),
        _StepDivider(isActive: !isDetails),
        _StepChip(
          index: 2,
          label: 'اختيار الأعضاء',
          isActive: !isDetails,
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final typography = ResponsiveDialogTypography.resolve(
      MediaQuery.of(context).size,
    );
    final textTheme = Theme.of(context).textTheme;

    return Container(
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
            Icons.group_add,
            color: AppColors.accentWhite,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'تسجيل حضور جماعي',
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
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSelector() {
    final typography = ResponsiveDialogTypography.resolve(
      MediaQuery.of(context).size,
    );
    final textTheme = Theme.of(context).textTheme;
    const eventOptions = [
      ['praise', 'تسبحة'],
      ['mass', 'قداس'],
      ['generalMeeting', 'اجتماع عام'],
      ['specialMeeting', 'اجتماع خاص'],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "نوع الاجتماع",
          style: ResponsiveDialogTypography.merge(
            textTheme.titleMedium,
            typography.title,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedEvent,
          style: ResponsiveDialogTypography.merge(
            textTheme.bodyMedium,
            typography.body,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryMaroon, width: 2),
            ),
            filled: true,
            fillColor: AppColors.accentWhite,
          ),
          items: eventOptions
              .map(
                (option) => DropdownMenuItem(
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
          onChanged: (value) => setState(() => _selectedEvent = value),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى اختيار نوع الاجتماع';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final typography = ResponsiveDialogTypography.resolve(
      MediaQuery.of(context).size,
    );
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التاريخ',
          style: ResponsiveDialogTypography.merge(
            textTheme.titleMedium,
            typography.title,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentWhite,
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: AppColors.primaryMaroon),
                const SizedBox(width: 12),
                Text(
                  _formatDate(_selectedDate),
                  style: ResponsiveDialogTypography.merge(
                    textTheme.bodyMedium,
                    typography.subtitle,
                    color: AppColors.textPrimary,
                  ),
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

  Widget _buildSelectionSummary({
    bool showEventDetails = false,
    double? maxHeight,
  }) {
    final typography = ResponsiveDialogTypography.resolve(
      MediaQuery.of(context).size,
    );
    final textTheme = Theme.of(context).textTheme;
    final selectedCount = _selectedMembers.length;
    final totalCount = _allMembers.length;
    final eventLabel = _selectedEvent != null
        ? _eventDisplayName(_selectedEvent!)
        : 'لم يتم اختيار الاجتماع';
    final dateLabel = _formatDate(_selectedDate);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showEventDetails) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryMaroon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.event, size: 16, color: AppColors.primaryMaroon),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  eventLabel,
                  style: ResponsiveDialogTypography.merge(
                    textTheme.bodyMedium,
                    typography.body,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryMaroon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.calendar_today,
                    size: 16, color: AppColors.primaryMaroon),
              ),
              const SizedBox(width: 10),
              Text(
                dateLabel,
                style: ResponsiveDialogTypography.merge(
                  textTheme.bodyMedium,
                  typography.body,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryMaroon,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.people, size: 18, color: AppColors.accentWhite),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$selectedCount عضو محدد',
                    style: ResponsiveDialogTypography.merge(
                      textTheme.titleMedium,
                      typography.subtitle,
                      color: AppColors.primaryMaroon,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (totalCount > 0)
                    Text(
                      'من أصل $totalCount عضو متاح',
                      style: ResponsiveDialogTypography.merge(
                        textTheme.bodySmall,
                        typography.label,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.accentWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryMaroon.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _shouldAddScore ? Icons.star : Icons.star_border,
                color: _shouldAddScore
                    ? AppColors.primaryMaroon
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _shouldAddScore
                      ? 'سيتم احتساب نقاط الحضور للخدام'
                      : 'لن يتم احتساب نقاط الحضور لهذه الجلسة',
                  style: ResponsiveDialogTypography.merge(
                    textTheme.bodyMedium,
                    typography.body,
                    color: AppColors.textPrimary,
                    fontWeight:
                        _shouldAddScore ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final container = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryMaroon.withValues(alpha: 0.06),
            AppColors.primaryMaroon.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryMaroon.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: content,
    );

    if (maxHeight != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: container,
        ),
      );
    }

    return container;
  }

  Widget _buildCompactSelectionSummary() {
    final typography = ResponsiveDialogTypography.resolve(
      MediaQuery.of(context).size,
    );
    final textTheme = Theme.of(context).textTheme;
    final selectedCount = _selectedMembers.length;
    final eventLabel = _selectedEvent != null
        ? _eventDisplayName(_selectedEvent!)
        : 'لم يتم اختيار الاجتماع';
    final dateLabel = _formatDate(_selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryMaroon.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primaryMaroon.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.primaryMaroon),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$eventLabel • $dateLabel',
              style: ResponsiveDialogTypography.merge(
                textTheme.bodySmall,
                typography.label,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _shouldAddScore
                  ? AppColors.primaryMaroon
                  : AppColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _shouldAddScore ? Icons.star : Icons.star_border,
                  size: 12,
                  color: AppColors.accentWhite,
                ),
                const SizedBox(width: 4),
                Text(
                  _shouldAddScore ? 'النقاط مفعلة' : 'بدون نقاط',
                  style: ResponsiveDialogTypography.merge(
                    textTheme.labelSmall,
                    typography.label * 0.85,
                    color: AppColors.accentWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryMaroon,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle,
                    size: 12, color: AppColors.accentWhite),
                const SizedBox(width: 4),
                Text(
                  '$selectedCount',
                  style: ResponsiveDialogTypography.merge(
                    textTheme.labelSmall,
                    typography.label * 0.9,
                    color: AppColors.accentWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _eventDisplayName(String eventKey) {
    switch (eventKey) {
      case 'praise':
        return 'تسبحة';
      case 'mass':
        return 'قداس';
      case 'generalMeeting':
        return 'اجتماع عام';
      case 'specialMeeting':
        return 'اجتماع خاص';
      default:
        return eventKey;
    }
  }

  Widget _buildMembersSelection({double? maxListHeight}) {
    final typography = ResponsiveDialogTypography.resolve(
      MediaQuery.of(context).size,
    );
    final textTheme = Theme.of(context).textTheme;
    final listMaxHeight = maxListHeight ?? 320.0;

    if (_isLoadingMembers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "اختر الأعضاء (${_selectedMembers.length}/${_allMembers.length})",
              style: ResponsiveDialogTypography.merge(
                textTheme.titleMedium,
                typography.title,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_filteredMembers.isNotEmpty)
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryMaroon,
                  textStyle: ResponsiveDialogTypography.merge(
                    textTheme.bodyMedium,
                    typography.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: _toggleSelectAll,
                icon: Icon(
                  _selectAll ? Icons.check_box : Icons.check_box_outline_blank,
                  color: AppColors.primaryMaroon,
                ),
                label: Text(
                  _selectAll ? 'إلغاء المعروض' : 'اختيار المعروض',
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Search bar
        TextField(
          controller: _searchController,
          style: ResponsiveDialogTypography.merge(
            textTheme.bodyMedium,
            typography.body,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'ابحث عن عضو...',
            hintStyle: ResponsiveDialogTypography.merge(
              textTheme.bodyMedium,
              typography.body,
              color: AppColors.textSecondary,
            ),
            prefixIcon:
                const Icon(Icons.search, color: AppColors.primaryMaroon),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryMaroon, width: 2),
            ),
            filled: true,
            fillColor: AppColors.accentWhite,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),

        if (_allMembers.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'لا يوجد أعضاء',
                style: ResponsiveDialogTypography.merge(
                  textTheme.bodyMedium,
                  typography.body,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else if (_filteredMembers.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off,
                      size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 8),
                  Text(
                    'لا توجد نتائج للبحث',
                    style: ResponsiveDialogTypography.merge(
                      textTheme.bodyMedium,
                      typography.body,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            constraints: BoxConstraints(maxHeight: listMaxHeight),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _filteredMembers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final member = _filteredMembers[index];
                final isSelected = _selectedMembers.contains(member);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) => _toggleMember(member),
                  visualDensity: VisualDensity.compact,
                  contentPadding:
                      const EdgeInsetsDirectional.only(start: 16, end: 8),
                  title: Text(
                    member.name ?? 'Unknown',
                    style: ResponsiveDialogTypography.merge(
                      textTheme.titleSmall,
                      typography.body,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: member.email != null
                      ? Text(
                          member.email!,
                          style: ResponsiveDialogTypography.merge(
                            textTheme.bodySmall,
                            typography.label,
                            color: AppColors.textSecondary,
                          ),
                        )
                      : null,
                  activeColor: AppColors.primaryMaroon,
                  controlAffinity: ListTileControlAffinity.trailing,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final typography = ResponsiveDialogTypography.resolve(
      MediaQuery.of(context).size,
    );
    final textTheme = Theme.of(context).textTheme;
    final isDetailsStep = _currentStep == _BulkDialogStep.details;
    final canProceed = (_selectedEvent != null);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: BlocConsumer<AddAttendanceCubit, AddAttendanceState>(
        listener: (context, state) {
          print('🟢 [Bulk Dialog] State: ${state.runtimeType}'); // Debug
          if (state is AddAttendanceSuccess) {
            print(
                '✅ [Bulk Dialog] Success! Triggering data refresh...'); // Debug

            // Trigger automatic refresh of attendance, stats, and eftekad
            sl<DataRefreshCubit>().refreshMultiple({
              RefreshType.attendance,
              RefreshType.stats,
              RefreshType.eftekad,
            });

            Navigator.pop(context, true); // Return true to trigger refresh
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('تم تسجيل حضور ${_selectedMembers.length} عضو بنجاح'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is AddAttendanceFailure) {
            print('❌ [Bulk Dialog] Error: ${state.errorMessage}'); // Debug
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AddAttendanceLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (isDetailsStep) {
                      Navigator.pop(context);
                    } else {
                      setState(() {
                        _currentStep = _BulkDialogStep.details;
                      });
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primaryMaroon),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isDetailsStep ? 'إلغاء' : 'رجوع',
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
                  onPressed: isDetailsStep
                      ? (canProceed
                          ? () {
                              setState(() {
                                _currentStep = _BulkDialogStep.members;
                              });
                            }
                          : null)
                      : _handleAddAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMaroon,
                    foregroundColor: AppColors.accentWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isDetailsStep ? 'التالي' : 'تسجيل الحضور',
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
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _handleAddAttendance() async {
    print('🟢 [Dialog] Add Attendance button clicked!'); // Debug

    if (!_formKey.currentState!.validate()) {
      print('⚠️ [Dialog] Form validation failed'); // Debug
      return;
    }

    if (_selectedMembers.isEmpty) {
      print('⚠️ [Dialog] No members selected'); // Debug
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار عضو واحد على الأقل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    print('🟢 [Dialog] Calling cubit with:'); // Debug
    print('  - Members: ${_selectedMembers.length}'); // Debug
    print('  - Event: $_selectedEvent'); // Debug
    print('  - Date: $_selectedDate'); // Debug

    context.read<AddAttendanceCubit>().bulkAddAttendance(
          members: _selectedMembers,
          event: _selectedEvent!,
          date: _selectedDate,
          addScore: _shouldAddScore,
        );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildScoreToggle() {
    final textTheme = Theme.of(context).textTheme;
    final typography = ResponsiveDialogTypography.resolve(
      MediaQuery.of(context).size,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryMaroon.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'احتساب نقاط الحضور',
                  style: ResponsiveDialogTypography.merge(
                    textTheme.titleMedium,
                    typography.title,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'يمكنك إيقاف هذا الخيار إذا لم ترغب في إضافة نقاط للحضور لهذا الاجتماع.',
                  style: ResponsiveDialogTypography.merge(
                    textTheme.bodySmall,
                    typography.label,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: _shouldAddScore,
            activeColor: AppColors.primaryMaroon,
            onChanged: (value) {
              setState(() => _shouldAddScore = value);
            },
          ),
        ],
      ),
    );
  }
}

enum _BulkDialogStep {
  details,
  members,
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.index,
    required this.label,
    required this.isActive,
  });

  final int index;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final typography =
        ResponsiveDialogTypography.resolve(MediaQuery.of(context).size);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryMaroon.withValues(alpha: 0.12)
            : AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive
              ? AppColors.primaryMaroon
              : AppColors.borderLight.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isActive
                ? AppColors.primaryMaroon
                : AppColors.borderLight.withValues(alpha: 0.7),
            child: Text(
              '$index',
              style: const TextStyle(
                color: AppColors.accentWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: ResponsiveDialogTypography.merge(
              textTheme.labelLarge,
              typography.label,
              color:
                  isActive ? AppColors.primaryMaroon : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDivider extends StatelessWidget {
  const _StepDivider({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        height: 2,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryMaroon.withValues(alpha: 0.4)
              : AppColors.borderLight.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
