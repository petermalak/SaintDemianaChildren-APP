import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/widgets/app_shell.dart';
import '../../../../authentication/model/user_model.dart';
import '../../../../profile/repository/i_profile_repository.dart';
import '../../../../../core/session/session_context.dart';
import '../../../../../core/utils/role_helper.dart';
import '../../../../pope_athanasius/view/widget/meeting_profile_section.dart';
import '../../../../super_admin_&_khadem_layout/attendance_qr/constants.dart';
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
            if (_showsPopeMeeting(user)) ...[
              const SizedBox(height: 20),
              _buildAgendaCard(context),
              if (user.popeAthnasiusMeetingData != null) ...[
                const SizedBox(height: 12),
                MeetingProfileSection(
                  meeting: user.popeAthnasiusMeetingData!,
                  viewOnly: true,
                ),
              ],
            ],
            const SizedBox(height: 20),
            _buildProfileSection(user),
            const SizedBox(height: 20),
            _buildAttendanceStatsSection(),
          ],
        ),
      ),
    );
  }

  bool _showsPopeMeeting(UserModel? user) {
    if (user == null) return false;
    if (user.isPopeAthnasius == true) return true;
    final session = SessionContext.instance.current;
    final makhdoumClasses = RoleHelper.getMakhdoumClasses(user);
    final inContext = session?.role == UserRole.makhdoum
        ? makhdoumClasses.where((info) => info.classId == session?.classId)
        : makhdoumClasses;
    return inContext.any(
      (info) =>
          info.classId == kLegacyPopeAthanasiusClassId ||
          isPopeAthanasiusClassName(info.className) ||
          isPopeAthanasiusClassName(info.classDescription),
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
                Text(
                  'أهلاً ${firstNameOf(user?.name, fallback: 'المخدوم')}',
                  style: const TextStyle(
                    color: AppColors.accentWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'نورت كنيسة القديسة دميانة',
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

  Widget _buildAgendaCard(BuildContext context) {
    final meeting = sl<IProfileRepository>().user?.popeAthnasiusMeetingData;
    final levelLabel = switch (meeting?.studyLevel) {
      1 => 'الفرقة الأولى',
      2 => 'الفرقة الثانية',
      3 => 'الفرقة الثالثة',
      4 => 'الفرقة الرابعة',
      _ => 'فرقتك',
    };
    final groupLabel = switch (meeting?.classPhase) {
      1 => 'الاسر',
      2 => 'شباب و خريجين',
      3 => 'اعدادى و ثانوى',
      _ => null,
    };
    final phaseLabel = groupLabel == null ? levelLabel : '$levelLabel · $groupLabel';
    return Material(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/pope-my-course'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.menu_book, color: AppColors.primaryMaroon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('المادة الحالية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('عرض فقط · $phaseLabel', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: AppColors.textSecondary),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sl<IProfileRepository>().user?.isPopeAthnasius == true
                          ? 'حضوري'
                          : 'إحصائيات الحضور',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (sl<IProfileRepository>().user?.isPopeAthnasius == true)
                      Text(
                        'عرض فقط',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                  ],
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
                final levelTwo = sl<IProfileRepository>().user?.popeAthnasiusMeetingData?.studyLevel == 2;
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
                            levelTwo ? 'عقيدة' : 'اجتماع خاص',
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
                            levelTwo ? 'كتاب المقدس' : 'اجتماع عام',
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
        mainAxisSize: MainAxisSize.min,
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
