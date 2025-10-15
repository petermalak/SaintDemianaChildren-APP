import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saint_demiana_children/features/authentication/repository/i_authentication_repository.dart';
import 'package:saint_demiana_children/features/feed/view/screen/feed_screen.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/view/screen/aftekad_screen.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/attendance/view/screen/attendance_screen.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/home/view/screen/home_screen.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/repository/i_members_repository.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/view/screen/members_screen.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/viewmodel/get_members/get_members_cubit.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../authentication/model/user_model.dart';
import '../../../../profile/repository/i_profile_repository.dart';
import '../../../members/view/widget/add_user_dialog.dart';
import '../../../members/view/widget/attendance_dialog.dart';

class KhademMainScreen extends StatefulWidget {
  const KhademMainScreen({super.key});

  @override
  State<KhademMainScreen> createState() => _KhademMainScreenState();
}

class _KhademMainScreenState extends State<KhademMainScreen>
    with TickerProviderStateMixin {
  int _selectedTab = 0;
  late AnimationController _fabAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _cardAnimation;
  List<UserModel> _selectedMembers = [];
  final Map<int, Widget> _cachedTabs = {};

  @override
  void initState() {
    // sl<IProfileRepository>().user = UserModel(
    //     id: "1",
    //     role: UserRole.superAdmin,
    //     name: "felo",
    //     token:
    //         "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjA0OTBlOTk3LWQ5N2QtNDhlNC04NzFlLTQyYjhmM2FhNGU0ZSIsIm5hbWUiOiJTdXBlciBBZG1pbiIsImVtYWlsIjoic3VwZXJhZG1pbkB0ZXN0LmNvbSIsInBob25lTnVtYmVyIjoiKzEyMzQ1Njc4OTAiLCJyb2xlIjoic3VwZXJfYWRtaW4iLCJwcm9maWxlSW1hZ2UiOm51bGwsInBhc3N3b3JkSGFzaCI6IiQyYiQxMCRTdWZEdy51cjVHM0dXVEtleGVPR1JPaXY1aUouODZmRmQ5aGguRC50S3VoQUZabEQ4U0NycSIsImZhdGhlcnNQaG9uZU51bWJlciI6bnVsbCwibW90aGVyc1Bob25lTnVtYmVyIjpudWxsLCJiaXJ0aGRhdGUiOm51bGwsImFkZHJlc3MiOiIxMjMgU3VwZXIgQWRtaW4gU3QiLCJhZGRyZXNzTG9jYXRpb25MaW5rIjpudWxsLCJmYXRoZXJPZkNvbmZlc3Npb24iOm51bGwsImNyZWF0ZWRBdCI6IjIwMjUtMTAtMDFUMTE6NTE6MjAuMDAwWiIsInVwZGF0ZWRBdCI6IjIwMjUtMTAtMDFUMTE6NTE6MjAuMDAwWiIsImlhdCI6MTc1OTg0MzMyMSwiZXhwIjoxNzYwNDQ4MTIxfQ.S3HoTHbZ8HhsPgFNmz_UZJJP8vcPR2MHeW8iS0LD-KM",
    //     email: "superAdmin@test.com");
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeInOut,
    );

    _fabAnimationController.forward();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildEnhancedAppBar(),
              _buildTabNavigation(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      )),
                      child: child,
                    );
                  },
                  child: _buildTabContent(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildEnhancedFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildEnhancedAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1.clamp(0.0, 1.0)),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
              AppColors.accentWhite.withValues(alpha: 0.2.clamp(0.0, 1.0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: AppColors.accentWhite,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'لوحة التحكم',
                  style: TextStyle(
                    color: AppColors.accentWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'مرحباً بك أيها الخادم',
                  style: TextStyle(
                    color: AppColors.accentWhite
                        .withValues(alpha: 0.9.clamp(0.0, 1.0)),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildProfileMenu(),
        ],
      ),
    );
  }

  Widget _buildProfileMenu() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.accentWhite.withValues(alpha: 0.2.clamp(0.0, 1.0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.person,
          color: AppColors.accentWhite,
          size: 20,
        ),
      ),
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) {
        if (value == 'logout') {
          _handleLogout(context);
        } else if (value == '/class-management') {
          context.push('/class-management');
        } else if (value == 'profile') {
          context.push('/profile');
        }
      },
      itemBuilder: (context) =>
      [
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person, color: AppColors.primaryMaroon),
              SizedBox(width: 12),
              Text('الملف الشخصي'),
            ],
          ),
        ),
        if (sl<IProfileRepository>().user!.role == UserRole.superAdmin) ...[
          const PopupMenuItem(
            value: '/class-management',
            child: Row(
              children: [
                Icon(Icons.dashboard, color: AppColors.primaryBlue),
                SizedBox(width: 12),
                Text('لوحة التحكم'),
              ],
            ),
          ),
        ],
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: AppColors.error),
              SizedBox(width: 12),
              Text('تسجيل الخروج'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          _buildTabButton(0, Icons.dashboard, 'الرئيسية'),
          _buildTabDivider(),
          _buildTabButton(1, Icons.newspaper, "الأخبار"),
          _buildTabDivider(),
          _buildTabButton(2, Icons.people, 'الأعضاء'),
          _buildTabDivider(),
          _buildTabButton(3, Icons.event_note, 'الحضور'),
          _buildTabDivider(),
          _buildTabButton(4, Icons.person, "الأفتقاد"),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryMaroon : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentWhite
                      : AppColors.primaryMaroon
                      .withValues(alpha: 0.1.clamp(0.0, 1.0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryMaroon,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.accentWhite
                      : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabDivider() {
    return Container(
      height: 30,
      width: 1,
      color: AppColors.borderLight,
    );
  }

  void onTabSelected(int index) {
    setState(() {
      _selectedTab = index;
    });
    _fabAnimationController.reset();
    _fabAnimationController.forward();
  }

  Widget _buildTabContent() {
    return IndexedStack(
      index: _selectedTab,
      children: List.generate(5, (index) {
        return _cachedTabs.putIfAbsent(index, () => _buildTabWidget(index));
      }),
    );
  }

  Widget _buildTabWidget(int index) {
    switch (index) {
      case 0:
        return Provider.value(
          value: onTabSelected,
          child: HomeScreen(
            cardAnimation: _cardAnimation,
          ),
        );
      case 1:
        return const FeedScreen();
      case 2:
        return MembersScreen(
          cardAnimation: _cardAnimation,
          onSelectionChanged: (selected) {
            setState(() {
              _selectedMembers = List<UserModel>.from(selected);
            });
          },
        );
      case 3:
        return const AttendanceScreen();
      case 4:
        return const AftekadScreen();
      default:
        return HomeScreen(cardAnimation: _cardAnimation);
    }
  }

  Widget _buildEnhancedFAB() {
    final shouldShowFAB = _selectedTab == 2;
    final isMemberSelected = _selectedTab == 2 && _selectedMembers.isNotEmpty;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.5),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
      child: shouldShowFAB
          ? FloatingActionButton.extended(
        key: const ValueKey('fab'),
        onPressed: isMemberSelected
            ? () => _showAddAttendanceDialog()
            : () => _showAddUserDialog(),
        backgroundColor:
        isMemberSelected ? Colors.green : AppColors.primaryMaroon,
        icon: Icon(
          isMemberSelected ? Icons.check : Icons.person_add,
          color: AppColors.accentWhite,
        ),
        label: Text(
          isMemberSelected ? 'تسجيل حضور' : 'إضافة عضو',
          style: const TextStyle(
            color: AppColors.accentWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AddUserDialog(
          onSuccess: () {
            // Force the members screen to refresh by switching tabs
            if (_selectedTab == 2) {
              setState(() {
                _cachedTabs.remove(2); // Clear cached members screen
              });
            }
          },
        );
      },
    );
  }

  void _showAddAttendanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AddAttendanceDialog(members: _selectedMembers),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('تسجيل الخروج'),
            content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    sl<IAuthenticationRepository>().logout();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      context.go('/login');
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('حدث خطأ أثناء تسجيل الخروج'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
    );
  }
}
