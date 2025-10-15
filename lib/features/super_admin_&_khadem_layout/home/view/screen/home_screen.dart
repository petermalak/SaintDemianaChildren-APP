import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/home/model/stats_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/home/viewmodel/stats_cubit.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/repository/i_members_repository.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/view/widget/add_user_dialog.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/viewmodel/get_members/get_members_cubit.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../repository/i_home_repository.dart';

class HomeScreen extends StatelessWidget {
  final Animation<double> cardAnimation;

  const HomeScreen({super.key, required this.cardAnimation});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildWelcomeSection(),
          const SizedBox(height: 24),
          BlocProvider(
              create: (context) =>
              StatsCubit(sl<IHomeRepository>())
                ..fetchStats(),
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
                    const Text('مرحباً بك في لوحة التحكم',
                        style: TextStyle(
                            color: AppColors.accentWhite,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('إدارة فعالة للأعضاء والحضور',
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
          childAspectRatio: 1.8,
          children: [
            _buildStatCard('إجمالي الأعضاء', stats.totalUsers.toString(),
                Icons.people, AppColors.primaryMaroon),
            _buildStatCard('نسبة الحضور', stats.attendanceRate.toString(),
                Icons.person, AppColors.primaryBrown),
            _buildStatCard(
                'نسبة الافتقاد',
                stats.eftekadCompletionRate.toString(),
                Icons.admin_panel_settings,
                AppColors.accentGold),
            _buildStatCard('عدد الفصول', stats.totalClasses.toString(),
                Icons.trending_up, AppColors.success)
          ])
    ]);
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      Color color) {
    return AnimatedBuilder(
        animation: cardAnimation,
        builder: (context, child) {
          return Transform.scale(
              scale: cardAnimation.value,
              child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.05.clamp(0.0, 1.0)),
                            blurRadius: 10,
                            offset: const Offset(0, 2))
                      ]),
                  child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                    color: color.withValues(
                                        alpha: 0.1.clamp(0.0, 1.0)),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Icon(icon, color: color, size: 16)),
                            const SizedBox(height: 8),
                            Flexible(
                                child: Text(value,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: color),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                            const SizedBox(height: 4),
                            Flexible(
                                child: Text(title,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.start))
                          ]))));
        });
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
              onTap: () => context.read<void Function(int)>().call(2),
            ))
      ])
    ]);
  }

  Widget _buildQuickActionCard({required String title,
    required IconData icon,
    required Color color,
    VoidCallback? onTap}) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.all(20),
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
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color:
                              color.withValues(alpha: 0.1.clamp(0.0, 1.0)),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(icon, color: color, size: 20)),
                      const SizedBox(height: 8),
                      Text(title,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis)
                    ]))));
  }
}
