import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../authentication/model/user_model.dart';
import '../../../../profile/repository/i_profile_repository.dart';
import '../../../../coptic_quest/coptic_quest_strings.dart';
import '../../../attendance/repository/i_attendance_repository.dart';
import '../../../attendance/viewmodel/attendance_cubit.dart';

class HomeScreen extends StatelessWidget {
  final ScrollController? scrollController;

  const HomeScreen({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final UserModel user = sl<IProfileRepository>().user!;
    return BlocProvider(
      create: (context) =>
          AttendanceCubit(sl<IAttendanceRepository>())..fetchAttendance(),
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(user),
            const SizedBox(height: 20),
            _buildCopticQuestCard(context),
            const SizedBox(height: 20),
            _buildProfileSection(user),
            const SizedBox(height: 20),
            _buildAttendanceStatsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                AppColors.primaryMaroon.withValues(alpha: 0.3.clamp(0.0, 1.0)),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  AppColors.accentWhite.withValues(alpha: 0.2.clamp(0.0, 1.0)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.waving_hand,
              color: AppColors.accentWhite,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مرحباً بك في لوحة التحكم',
                  style: TextStyle(
                    color: AppColors.accentWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${user?.name ?? 'المخدوم العزيز'}، مرحباً بك في منصة إدارة الكنيسة',
                  style: TextStyle(
                    color: AppColors.accentWhite
                        .withValues(alpha: 0.9.clamp(0.0, 1.0)),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopticQuestCard(BuildContext context) {
    return Material(
      color: const Color(0xFF3B2E32),
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: () => context.push('/coptic-quest'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: AppColors.accentGold,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CopticQuestStrings.get('playCardTitle', 'ar'),
                      style: const TextStyle(
                        color: Color(0xFFB4ADB3),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CopticQuestStrings.get('playCardSubtitle', 'ar'),
                      style: TextStyle(
                        color: const Color(0xFF6F6471),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.play_circle_fill,
                color: AppColors.accentGold,
                size: 36,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05.clamp(0.0, 1.0)),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryMaroon
                      .withValues(alpha: 0.1.clamp(0.0, 1.0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primaryMaroon,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'معلوماتي الشخصية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.person, 'الاسم', user.name ?? 'غير محدد'),
          const SizedBox(height: 12),
          _buildInfoRow(
              Icons.email, 'البريد الإلكتروني', user.email ?? 'غير محدد'),
          if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, 'رقم الهاتف', user.phoneNumber!),
          ],
          if (user.address != null && user.address!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, 'العنوان', user.address!),
          ],
          if (user.fatherOfConfession != null &&
              user.fatherOfConfession!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
                Icons.person_outline, 'أب الاعتراف', user.fatherOfConfession!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05.clamp(0.0, 1.0)),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryMaroon
                      .withValues(alpha: 0.1.clamp(0.0, 1.0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_note,
                  color: AppColors.primaryMaroon,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'إحصائيات الحضور',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BlocBuilder<AttendanceCubit, AttendanceState>(
            builder: (context, state) {
              if (state is AttendanceLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryMaroon,
                    ),
                  ),
                );
              } else if (state is AttendanceSuccess) {
                final records = state.attendanceModel.attendanceRecords ?? [];
                final massCount = records.where((r) => r.type == 'mass').length;
                final specialMeetingCount =
                    records.where((r) => r.type == 'specialMeeting').length;
                final generalMeetingCount =
                    records.where((r) => r.type == 'generalMeeting').length;
                final praiseCount =
                    records.where((r) => r.type == 'praise').length;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            Icons.church,
                            'قداس',
                            massCount.toString(),
                            AppColors.primaryMaroon,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            Icons.star,
                            'اجتماع خاص',
                            specialMeetingCount.toString(),
                            AppColors.accentGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            Icons.people,
                            'اجتماع عام',
                            generalMeetingCount.toString(),
                            AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            Icons.music_note,
                            'تسبحة',
                            praiseCount.toString(),
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'إجمالي الحضور',
                            style: TextStyle(
                              color: AppColors.accentWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            records.length.toString(),
                            style: const TextStyle(
                              color: AppColors.accentWhite,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else if (state is AttendanceFailure) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'فشل في تحميل الإحصائيات',
                      style: TextStyle(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1.clamp(0.0, 1.0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
