import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saint_demiana_children/features/makhdoum_layout/home/view/screen/home_screen.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../authentication/repository/i_authentication_repository.dart';
import '../../../../feed/view/screen/feed_screen.dart';
import '../../../attendance/view/screen/attendance_screen.dart';

class MakhdoumMainScreen extends StatefulWidget {
  const MakhdoumMainScreen({super.key});

  @override
  State<MakhdoumMainScreen> createState() => _MakhdoumMainScreenState();
}

class _MakhdoumMainScreenState extends State<MakhdoumMainScreen>
    with TickerProviderStateMixin {
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _cardAnimationController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _searchController.dispose();
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
              Icons.person,
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
                  'مرحباً بك أيها المخدوم',
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
        if (value == 'profile') {
          context.push('/profile');
        }
        if (value == 'logout') {
          _handleLogout(context);
        }
      },
      itemBuilder: (context) => [
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
          _buildTabButton(1, Icons.newspaper, 'الأخبار'),
          _buildTabDivider(),
          _buildTabButton(2, Icons.event_note, 'الحضور'),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabSelected(index),
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
                  color: isSelected
                      ? AppColors.primaryMaroon
                      : AppColors.primaryMaroon,
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

  void _onTabSelected(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return const HomeScreen();
      case 1:
        return const FeedScreen();
      case 2:
        return const AttendanceScreen();
      default:
        return const HomeScreen();
    }
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
