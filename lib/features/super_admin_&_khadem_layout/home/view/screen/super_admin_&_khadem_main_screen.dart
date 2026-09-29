import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saint_demiana_children/features/authentication/repository/i_authentication_repository.dart';
import 'package:saint_demiana_children/features/feed/view/screen/feed_screen.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/view/screen/aftekad_screen.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/attendance/view/screen/attendance_screen.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/home/view/screen/home_screen.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/view/screen/members_screen.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/scoring/view/screen/khadem_scoring_screen.dart';
import 'package:saint_demiana_children/features/shop/view/screen/khadem_shop_screen.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/model/class_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/repository/i_class_repository.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/widgets/app_shell.dart';
import '../../../../../core/utils/role_helper.dart';
import '../../../../authentication/model/user_model.dart';
import '../../../../profile/repository/i_profile_repository.dart';
import '../../../../scoring/view/screen/scoring_config_screen.dart';
import '../../../../scoring/repository/i_scoring_repository.dart';
import '../../../../scoring/viewmodel/config_cubit/config_cubit.dart';
import '../../../../scoring/viewmodel/score_definition_cubit/score_definition_cubit.dart';
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
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _cardAnimation;
  List<UserModel> _selectedMembers = [];
  final Map<int, Widget> _cachedTabs = {};
  final Map<int, ScrollController> _scrollControllers = {};
  RoleClassSelection? _selectedRoleClass;
  List<ClassModel> _classesForShop = [];
  bool _classesForShopLoaded = false;

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
    _pageController = PageController();
    _initializeAnimations();
    _initializeScrollControllers();
    _initializeRoleSelection();
    _loadClassesForShop();
  }

  Future<void> _loadClassesForShop() async {
    final user = sl<IProfileRepository>().user;
    if (user == null) return;
    final isSuperAdmin = user.role == UserRole.superAdmin;
    final repo = sl<IClassRepository>();
    final result =
        isSuperAdmin ? await repo.loadClasses() : await repo.loadMyClasses();
    result.fold(
      (_) => null,
      (classes) {
        if (mounted) {
          setState(() {
            _classesForShop = classes;
            _classesForShopLoaded = true;
          });
        }
      },
    );
  }

  bool get _selectedClassHasShop {
    if (!_classesForShopLoaded) {
      return false;
    }
    // Show shop tab if ANY class has shop enabled (not just the selected one)
    // This allows users to switch to a class with shop even when viewing a class without shop
    return _classesForShop.any((c) => c.hasShop);
  }

  // Get the first class with shop, or the selected class if it has shop
  String? get _shopClassId {
    if (!_classesForShopLoaded) return null;
    // If current class has shop, use it
    if (_selectedRoleClass?.classId != null) {
      final currentHasShop = _classesForShop.any(
        (c) => c.id == _selectedRoleClass!.classId && c.hasShop,
      );
      if (currentHasShop) return _selectedRoleClass!.classId;
    }
    // Otherwise, use the first class with shop
    final shopClass = _classesForShop.firstWhere(
      (c) => c.hasShop,
      orElse: () => _classesForShop.first,
    );
    return shopClass.id;
  }

  void _initializeRoleSelection() {
    final user = sl<IProfileRepository>().user;
    if (user == null) return;

    // Initialize with primary role
    final primaryRole = RoleHelper.getPrimaryRole(user);
    if (primaryRole == UserRole.khadem || primaryRole == UserRole.superAdmin) {
      final khademClasses = RoleHelper.getKhademClasses(user);
      if (khademClasses.isNotEmpty) {
        _selectedRoleClass = RoleClassSelection(
          role: UserRole.khadem,
          classId: khademClasses.first.classId,
          className: khademClasses.first.className,
        );
      } else {
        _selectedRoleClass = const RoleClassSelection(role: UserRole.khadem);
      }
    }
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

  void _initializeScrollControllers() {
    for (int i = 0; i < 7; i++) {
      _scrollControllers[i] = ScrollController();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    _cardAnimationController.dispose();
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = sl<IProfileRepository>().user;
    final name = firstNameOf(user?.name, fallback: 'الخادم');
    return AppShell(
      title: 'مرحباً $name',
      subtitle: user?.role == UserRole.superAdmin
          ? 'لوحة المدير'
          : 'لوحة الخادم',
      headerIcon: Icons.church,
      actions: [_buildProfileMenu()],
      tabs: _tabItems(),
      selectedIndex: _selectedTab,
      onTabSelected: onTabSelected,
      floatingActionButton: _buildEnhancedFAB(),
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _tabCount,
        onPageChanged: (index) {
          setState(() => _selectedTab = index);
          _fabAnimationController.reset();
          _fabAnimationController.forward();
        },
        itemBuilder: (context, index) =>
            _buildTabWidget(index, _scrollControllers[index]),
      ),
    );
  }

  int get _tabCount => _tabItems().length;

  List<AppTabItem> _tabItems() {
    if (_isInMakhdoumMode) {
      return const [
        AppTabItem(icon: Icons.home_rounded, label: 'الرئيسية'),
        AppTabItem(icon: Icons.event_note_rounded, label: 'الحضور'),
        AppTabItem(icon: Icons.newspaper_rounded, label: 'الأخبار'),
        AppTabItem(icon: Icons.emoji_events_rounded, label: 'التايو'),
      ];
    }
    return [
      const AppTabItem(icon: Icons.home_rounded, label: 'الرئيسية'),
      const AppTabItem(icon: Icons.newspaper_rounded, label: 'الأخبار'),
      const AppTabItem(icon: Icons.people_rounded, label: 'الأعضاء'),
      const AppTabItem(icon: Icons.event_note_rounded, label: 'الحضور'),
      const AppTabItem(icon: Icons.person_search_rounded, label: 'الافتقاد'),
      const AppTabItem(icon: Icons.emoji_events_rounded, label: 'التايو'),
      if (_selectedClassHasShop)
        const AppTabItem(icon: Icons.storefront_rounded, label: 'المتجر'),
    ];
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
        } else if (value == 'scoring-config') {
          _navigateToGlobalScoringConfig(context);
        } else if (value == 'switch-to-makhdoum') {
          // Switch to makhdoum UI
          context.go('/makhdoum');
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
          const PopupMenuItem(
            value: 'scoring-config',
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: AppColors.accentGold),
                SizedBox(width: 12),
                Text('نظام التايو العام'),
              ],
            ),
          ),
        ],
        // Role switcher for users with mixed roles
        if (RoleHelper.hasMixedRoles(sl<IProfileRepository>().user) &&
            RoleHelper.canAccessMakhdoumFeatures(
                sl<IProfileRepository>().user)) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'switch-to-makhdoum',
            child: Row(
              children: [
                Icon(Icons.swap_horiz, color: AppColors.primaryMaroon),
                SizedBox(width: 12),
                Text('التبديل إلى واجهة المخدوم'),
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

  void onTabSelected(int index) {
    _pageController.animateToPage(
      index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
    );
  }

  Widget _buildTabWidget(int index, ScrollController? scrollController) {
    // Use cached widget if available
    return _cachedTabs.putIfAbsent(
      index,
      () => _buildTabContent(index, scrollController),
    );
  }

  Widget _buildTabContent(int index, ScrollController? scrollController) {
    if (_isInMakhdoumMode) {
      // Makhdoum-specific content
      switch (index) {
        case 0:
          // Home screen for makhdoum
          return Provider.value(
            value: onTabSelected,
            child: HomeScreen(
              cardAnimation: _cardAnimation,
              scrollController: scrollController,
            ),
          );
        case 1:
          // Attendance screen for makhdoum
          return AttendanceScreen(
            scrollController: scrollController,
          );
        case 2:
          // Feed screen
          return FeedScreen(scrollController: scrollController);
        case 3:
          // Scoring screen for makhdoum
          return const SizedBox(); // TODO: Add makhdoum scoring screen
        default:
          return HomeScreen(
            cardAnimation: _cardAnimation,
            scrollController: scrollController,
          );
      }
    } else {
      // Khadem-specific content
      switch (index) {
        case 0:
          return Provider.value(
            value: onTabSelected,
            child: HomeScreen(
              cardAnimation: _cardAnimation,
              scrollController: scrollController,
            ),
          );
        case 1:
          return FeedScreen(scrollController: scrollController);
        case 2:
          return MembersScreen(
            cardAnimation: _cardAnimation,
            scrollController: scrollController,
            onSelectionChanged: (selected) {
              setState(() {
                _selectedMembers = List<UserModel>.from(selected);
              });
            },
          );
        case 3:
          return AttendanceScreen(scrollController: scrollController);
        case 4:
          return AftekadScreen(scrollController: scrollController);
        case 5:
          return KhademScoringScreen(scrollController: scrollController);
        case 6:
          return KhademShopScreen(
            scrollController: scrollController,
            initialClassId: _shopClassId ?? _selectedRoleClass?.classId,
          );
        default:
          return HomeScreen(
            cardAnimation: _cardAnimation,
            scrollController: scrollController,
          );
      }
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

  void _navigateToGlobalScoringConfig(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => ConfigCubit(sl<IScoringRepository>()),
            ),
            BlocProvider(
              create: (context) =>
                  ScoreDefinitionCubit(sl<IScoringRepository>()),
            ),
          ],
          child: const ScoringConfigScreen(
            classId: null,
            className: null,
          ),
        ),
      ),
    );
  }

  /// Check if current selected role/class allows khadem features
  bool get _isInKhademMode {
    return _selectedRoleClass?.role == UserRole.khadem ||
        _selectedRoleClass?.role == UserRole.superAdmin;
  }

  /// Check if current selected role/class allows makhdoum features
  bool get _isInMakhdoumMode {
    return _selectedRoleClass?.role == UserRole.makhdoum;
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
