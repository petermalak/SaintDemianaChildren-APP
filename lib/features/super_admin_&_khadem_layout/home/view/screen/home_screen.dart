import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/home/model/stats_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/home/viewmodel/stats_cubit.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/view/widget/add_user_dialog.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/model/class_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/repository/i_class_repository.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';

import '../../../../../core/constants/app_colors.dart';
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
    _statsCubit = StatsCubit(sl<IHomeRepository>(), sl<DataRefreshCubit>())
      ..fetchStats(classId: _selectedClassId);
    _loadClassesIfNeeded();
  }

  @override
  void dispose() {
    _statsCubit.close();
    super.dispose();
  }

  Future<void> _loadClassesIfNeeded() async {
    final user = _currentUser;
    if (user == null) return;
    final userRole = user.role;
    final isKhadem = userRole == UserRole.khadem;
    final isSuperAdmin = userRole == UserRole.superAdmin;

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
        setState(() {
          _availableClasses = classes;
          if (_selectedClassId != null &&
              !_availableClasses.any((c) => c.id == _selectedClassId)) {
            _selectedClassId = null;
          }
        });
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
    if (user.role == UserRole.superAdmin) {
      return _availableClasses.isNotEmpty;
    }
    if (user.role == UserRole.khadem) {
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
          _buildQuickActions(context)
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

  Widget _buildStatsGrid(StatsModel stats) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('الإحصائيات',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary)),
      const SizedBox(height: 16),
      GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.85,
          children: [
            _buildStatCard('إجمالي الأعضاء', stats.totalUsers.toString(),
                Icons.people, AppColors.primaryMaroon),
            _buildStatCard(
                'حضور آخر جمعة',
                '${stats.lastFridayAttendedCount}/${stats.lastFridayTotalMembers}',
                Icons.event_available,
                AppColors.primaryBrown),
            _buildStatCard(
                'افتقاد آخر جمعة',
                '${stats.lastFridayEftekadCompleted}/${stats.lastFridayEftekadTotal}',
                Icons.phone_in_talk,
                AppColors.accentGold),
            _buildStatCard('عدد الفصول', stats.totalClasses.toString(),
                Icons.class_, AppColors.success)
          ])
    ]);
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return AnimatedBuilder(
      animation: widget.cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.cardAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.2.clamp(0.0, 1.0)),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.08.clamp(0.0, 1.0)),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
            ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12.clamp(0.0, 1.0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                value,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          ),
        );
      },
    );
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
          onTap: () {
            print('📋 Quick action: Navigate to Attendance tab'); // Debug
            try {
              context
                  .read<void Function(int)>()
                  .call(3); // Tab 3 is AttendanceScreen
            } catch (e) {
              print('❌ Error switching tab: $e'); // Debug
            }
          },
        ))
      ])
    ]);
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
