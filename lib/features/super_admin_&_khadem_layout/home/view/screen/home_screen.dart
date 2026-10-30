import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/home/model/stats_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/home/viewmodel/stats_cubit.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/view/widget/add_user_dialog.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/view/widget/request_member_dialog.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/model/class_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/repository/i_class_repository.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/session/session_context.dart';
import '../../../attendance_qr/constants.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/services/data_refresh_cubit.dart';
import '../../../../../core/widgets/app_shell.dart';
import '../../repository/i_home_repository.dart';

class HomeScreen extends StatefulWidget {
  final Animation<double> cardAnimation;
  final ScrollController? scrollController;

  const HomeScreen({
    super.key,
    required this.cardAnimation,
    this.scrollController,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _currentUser;
  String? _selectedClassId;
  bool _isLoadingClasses = false;
  List<ClassModel> _availableClasses = const [];
  late StatsCubit _statsCubit;

  @override
  void initState() {
    super.initState();
    _currentUser = sl<IProfileRepository>().user;
    _selectedClassId = SessionContext.instance.current?.classId;
    _statsCubit = StatsCubit(sl<IHomeRepository>(), sl<DataRefreshCubit>())
      ..fetchStats(classId: _selectedClassId);
    SessionContext.instance.addListener(_onSessionClass);
    _loadClassesIfNeeded();
  }

  void _onSessionClass() {
    if (!mounted) return;
    final classId = SessionContext.instance.current?.classId;
    if (classId == _selectedClassId) return;
    setState(() => _selectedClassId = classId);
    _statsCubit.fetchStats(classId: classId);
  }

  @override
  void dispose() {
    SessionContext.instance.removeListener(_onSessionClass);
    _statsCubit.close();
    super.dispose();
  }

  Future<void> _loadClassesIfNeeded() async {
    final user = _currentUser;
    if (user == null) return;
    final isSuperAdmin = SessionContext.isSuperAdminContext(user);
    final isKhadem = SessionContext.isKhademContext(user);

    if (!isKhadem && !isSuperAdmin) return;

    setState(() {
      _isLoadingClasses = true;
    });

    final classRepository = sl<IClassRepository>();
    final result = isSuperAdmin
        ? await classRepository.loadClasses()
        : await classRepository.loadMyClasses();

    result.fold(
      (error) {
        print('⚠️ [HomeScreen] Failed to load classes: $error');
        if (!mounted) return;
        setState(() {
          _availableClasses = const [];
        });
      },
      (classes) {
        if (!mounted) return;
        final scoped = classesForContext(
          user: user,
          role: UserRole.khadem,
          classes: classes,
          idOf: (item) => item.id,
        );
        final previousClassId = _selectedClassId;
        setState(() {
          _availableClasses = scoped;
          final sessionId = SessionContext.instance.current?.classId;
          if (sessionId != null && scoped.any((c) => c.id == sessionId)) {
            _selectedClassId = sessionId;
          } else if (_selectedClassId != null &&
              !scoped.any((c) => c.id == _selectedClassId)) {
            _selectedClassId = null;
          }
        });
        if (_selectedClassId != previousClassId) {
          _statsCubit.fetchStats(classId: _selectedClassId);
        }
      },
    );

    if (!mounted) return;
    setState(() {
      _isLoadingClasses = false;
    });
  }

  bool get _shouldShowClassFilter {
    final user = _currentUser;
    if (user == null) return false;
    if (SessionContext.isSuperAdminContext(user)) {
      return _availableClasses.isNotEmpty;
    }
    if (SessionContext.isKhademContext(user)) {
      return _availableClasses.length > 1;
    }
    return false;
  }

  Widget _buildClassFilter() {
    if (_isLoadingClasses) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LinearProgressIndicator(),
      );
    }

    if (!_shouldShowClassFilter) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<String?>(
        value: _selectedClassId,
        decoration: const InputDecoration(
          labelText: 'اختر فصل',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('كل الفصول'),
          ),
          ..._availableClasses.map(
            (classModel) => DropdownMenuItem<String?>(
              value: classModel.id,
              child: Text(classModel.name),
            ),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _selectedClassId = value;
          });
          _statsCubit.fetchStats(classId: value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildWelcomeSection(),
          const SizedBox(height: 16),
          _buildClassFilter(),
          const SizedBox(height: 8),
          BlocProvider.value(
              value: _statsCubit,
              child: BlocBuilder<StatsCubit, StatsState>(
                  builder: (context, state) {
                if (state is StatsLoading) {
                  return const SizedBox(
                      height: 250,
                      child: Center(child: CircularProgressIndicator()));
                } else if (state is StatsFailure) {
                  return SizedBox(
                      height: 250,
                      child: Center(
                          child: Text(state.errorMessage,
                              style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold))));
                } else if (state is StatsSuccess) {
                  return _buildStatsGrid(state.stats);
                }
                return const SizedBox.shrink();
              })),
          const SizedBox(height: 24),
          _buildQuickActions(context),
          if (canViewPopeAthanasiusData(_currentUser)) ...[
            const SizedBox(height: 16),
            _buildPopeSection(context),
          ],
        ]));
  }

  Widget _buildWelcomeSection() {
    return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primaryMaroon
                      .withValues(alpha: 0.3.clamp(0.0, 1.0)),
                  blurRadius: 15,
                  offset: const Offset(0, 5))
            ]),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.accentWhite
                      .withValues(alpha: 0.2.clamp(0.0, 1.0)),
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.waving_hand,
                  color: AppColors.accentWhite, size: 32)),
          const SizedBox(width: 20),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                    'مرحباً ${firstNameOf(_currentUser?.name, fallback: 'الخادم')}',
                    style: const TextStyle(
                        color: AppColors.accentWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('إدارة الأعضاء والحضور في مكان واحد',
                    style: TextStyle(
                        color: AppColors.accentWhite
                            .withValues(alpha: 0.9.clamp(0.0, 1.0)),
                        fontSize: 14))
              ]))
        ]));
  }

  void _openSection(int tab, {String? morePage}) {
    try {
      context.read<KhademSectionNav>().open(tab, morePage: morePage);
    } catch (_) {
      try {
        context.read<void Function(int)>().call(tab);
      } catch (error) {
        debugPrint('Could not open section: $error');
      }
    }
  }

  Widget _buildStatsGrid(StatsModel stats) {
    final isKhadem = SessionContext.isKhademContext(_currentUser);
    final absent = stats.lastFridayTotalMembers - stats.lastFridayAttendedCount;
    final attendanceTypes = _orderedCounts(stats.attendanceByType, const [
      'mass',
      'generalMeeting',
      'specialMeeting',
      'praise',
    ]);
    final eftekadTypes = _orderedCounts(stats.eftekadByType, const [
      'phone_call',
      'whatsapp_message',
      'home_visit',
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(_formatFriday(stats.lastFridayDate)),
        const SizedBox(height: 10),
        _progressCard(
          title: 'الحضور',
          done: stats.lastFridayAttendedCount,
          total: stats.lastFridayTotalMembers,
          detail: absent > 0 ? '$absent غابوا' : 'مفيش غياب',
          icon: Icons.event_available_rounded,
          color: AppColors.primaryBrown,
          onTap: () => _openSection(2),
        ),
        const SizedBox(height: 10),
        _progressCard(
          title: 'الافتقاد',
          done: stats.lastFridayEftekadCompleted,
          total: stats.lastFridayEftekadTotal,
          detail: 'آخر جمعة',
          icon: Icons.phone_in_talk_rounded,
          color: AppColors.accentGold,
          onTap: () => _openSection(3, morePage: 'eftekad'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: isKhadem ? 'المخدومين' : 'الأعضاء',
                value: '${stats.totalUsers}',
                subtitle: stats.totalClasses > 0
                    ? '${stats.totalClasses} فصل'
                    : null,
                icon: Icons.people_rounded,
                color: AppColors.primaryMaroon,
                onTap: () => _openSection(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                title: 'سجلات الحضور',
                value: '${stats.totalAttendances}',
                subtitle: '30 يوم: ${stats.recentAttendances}',
                icon: Icons.fact_check_rounded,
                color: AppColors.primaryBrown,
                onTap: () => _openSection(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionTitle('الحضور حسب النوع'),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.35,
          children: [
            for (final item in attendanceTypes)
              _metricChip(
                label: _attendanceTypeLabel(item.key),
                value: '${item.value}',
                icon: _attendanceTypeIcon(item.key),
                color: AppColors.primaryBrown,
                onTap: () => _openSection(2),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionTitle('الافتقاد'),
        const SizedBox(height: 10),
        _eftekadCard(stats, eftekadTypes),
      ],
    );
  }

  Widget _progressCard({
    required String title,
    required num done,
    required num total,
    required String detail,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final percent = _percent(done, total);
    return Material(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '$done/$total',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$percent%',
                    style: TextStyle(fontWeight: FontWeight.w700, color: color),
                  ),
                  Icon(Icons.chevron_left, color: AppColors.textSecondary, size: 18),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _ratio(done, total),
                  minHeight: 8,
                  backgroundColor: color.withValues(alpha: 0.12),
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eftekadCard(StatsModel stats, List<MapEntry<String, num>> types) {
    final statuses = stats.eftekadByStatus.entries.toList();
    return Material(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openSection(3, morePage: 'eftekad'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone_in_talk_rounded,
                      color: AppColors.accentGold, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'كل الافتقاد',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${stats.totalEftekads}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGold,
                      fontSize: 18,
                    ),
                  ),
                  Icon(Icons.chevron_left, color: AppColors.textSecondary, size: 18),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'آخر 30 يوم: ${stats.recentEftekads}',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 0; i < types.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${types[i].value}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentGold,
                            ),
                          ),
                          Text(
                            _eftekadTypeLabel(types[i].key),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (statuses.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final status in statuses)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_eftekadStatusLabel(status.key)} ${status.value}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _ratio(num done, num total) {
    if (total <= 0) return 0;
    final value = done / total;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value.toDouble();
  }

  int _percent(num done, num total) {
    if (total <= 0) return 0;
    return ((_ratio(done, total)) * 100).round();
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String? subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  List<MapEntry<String, num>> _orderedCounts(
    Map<String, num> counts,
    List<String> order,
  ) {
    final items = <MapEntry<String, num>>[];
    for (final key in order) {
      items.add(MapEntry(key, counts[key] ?? 0));
    }
    for (final entry in counts.entries) {
      if (!order.contains(entry.key)) items.add(entry);
    }
    return items;
  }

  String _formatFriday(String? iso) {
    if (iso == null || iso.length < 10) return 'آخر جمعة';
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    final parts = iso.split('-');
    final month = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 1;
    final day = int.tryParse(parts.length > 2 ? parts[2] : '') ?? 1;
    final name = months[(month - 1).clamp(0, 11)];
    return 'جمعة $day $name';
  }

  String _attendanceTypeLabel(String type) {
    switch (type) {
      case 'mass':
        return 'قداس';
      case 'generalMeeting':
        return 'اجتماع عام';
      case 'specialMeeting':
        return 'اجتماع خاص';
      case 'praise':
        return 'تسبحة';
      default:
        return type;
    }
  }

  IconData _attendanceTypeIcon(String type) {
    switch (type) {
      case 'mass':
        return Icons.church_rounded;
      case 'praise':
        return Icons.music_note_rounded;
      default:
        return Icons.groups_rounded;
    }
  }

  String _eftekadTypeLabel(String type) {
    switch (type) {
      case 'phone_call':
        return 'مكالمات';
      case 'whatsapp_message':
        return 'واتساب';
      case 'home_visit':
        return 'زيارات منزلية';
      default:
        return type;
    }
  }

  String _eftekadStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'تم الافتقاد';
      case 'no_answer':
        return 'لم يرد';
      case 'busy':
        return 'مشغول';
      case 'postponed':
        return 'مؤجل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('الإجراءات السريعة',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
            child: _buildQuickActionCard(
          title: 'إضافة عضو',
          icon: Icons.person_add,
          color: AppColors.primaryMaroon,
          onTap: () async {
            await showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  final user = sl<IProfileRepository>().user;
                  if (user?.role == UserRole.khadem) {
                    return RequestMemberDialog(onSuccess: () {});
                  }
                  return AddUserDialog(
                    onSuccess: () {
                      // Members screen will auto-refresh
                    },
                  );
                });
          },
        )),
        const SizedBox(width: 16),
        Expanded(
            child: _buildQuickActionCard(
          title: 'تسجيل حضور',
          icon: Icons.event_available,
          color: AppColors.primaryBrown,
          onTap: () => _openSection(2),
        ))
      ])
    ]);
  }

  Widget _buildPopeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'البابا أثناسيوس',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        _popeLink(context, Icons.menu_book, 'منهج الدراسة', '/pope-agenda'),
        _popeLink(context, Icons.qr_code_2, 'حضور الفرقة الثانية', '/pope-level-two'),
        _popeLink(context, Icons.fact_check, 'سجل الفرقة الأولى', '/pope-level-one-marks'),
      ],
    );
  }

  Widget _popeLink(BuildContext context, IconData icon, String title, String path) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(path),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryMaroon),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                Icon(Icons.chevron_left, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
      {required String title,
      required IconData icon,
      required Color color,
      VoidCallback? onTap}) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: color.withValues(alpha: 0.2.clamp(0.0, 1.0)),
                    width: 1),
                boxShadow: [
                  BoxShadow(
                      color:
                          Colors.black.withValues(alpha: 0.05.clamp(0.0, 1.0)),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ]),
            child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color:
                                  color.withValues(alpha: 0.1.clamp(0.0, 1.0)),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(icon, color: color, size: 22)),
                      const SizedBox(height: 8),
                      Text(title,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis)
                    ])));
  }
}

class KhademSectionNav {
  final void Function(int tab, {String? morePage}) open;

  KhademSectionNav(this.open);
}
