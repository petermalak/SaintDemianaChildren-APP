import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:saint_demiana_children/features/makhdoum_layout/home/view/screen/home_screen.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../authentication/repository/i_authentication_repository.dart';
import '../../../../profile/repository/i_profile_repository.dart';
import '../../../../authentication/model/user_model.dart';
import '../../../../scoring/view/screen/scoring_dashboard_screen.dart';
import '../../../../scoring/viewmodel/scoring_cubit/scoring_cubit.dart';
import '../../../../scoring/repository/i_scoring_repository.dart';
import '../../../attendance/view/screen/attendance_screen.dart';
import '../../../../feed/view/screen/feed_screen.dart';
import '../../../../feed/viewmodel/get_feed/get_feed_cubit.dart';
import '../../../../feed/viewmodel/add_feed/add_feed_cubit.dart';
import '../../../../feed/repository/i_feed_repository.dart';

class MakhdoumMainScreen extends StatefulWidget {
  const MakhdoumMainScreen({super.key});

  @override
  State<MakhdoumMainScreen> createState() => _MakhdoumMainScreenState();
}

class _MakhdoumMainScreenState extends State<MakhdoumMainScreen>
    with TickerProviderStateMixin {
  int _selectedTab = 0;
  late PageController _pageController;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _cardAnimationController;
  final Map<int, ScrollController> _scrollControllers = {};
  bool _isTabBarVisible = true;
  double _lastScrollOffset = 0;
  List<UserClassInfo> _makhdoumClasses = const [];
  String? _selectedMakhdoumClassId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeAnimations();
    _initializeScrollControllers();
    _hydrateMakhdoumClasses();
  }

  void _initializeAnimations() {
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _cardAnimationController.forward();
  }

  void _initializeScrollControllers() {
    for (int i = 0; i < 4; i++) {
      _scrollControllers[i] = ScrollController()
        ..addListener(() => _handleScroll(i));
    }
  }

  void _hydrateMakhdoumClasses() {
    final user = sl<IProfileRepository>().user;
    if (user == null) return;

    final relevantClasses = user.classes
        .where((info) => info.membershipRole == 'makhdoum')
        .toList();

    _makhdoumClasses = relevantClasses;

    if (_selectedMakhdoumClassId == null) {
      if (_makhdoumClasses.isNotEmpty) {
        _selectedMakhdoumClassId = _makhdoumClasses.first.classId;
      } else if (user.classId != null && user.classId!.isNotEmpty) {
        _selectedMakhdoumClassId = user.classId;
      }
    }
  }

  String? get _effectiveMakhdoumClassId {
    if (_selectedMakhdoumClassId != null &&
        _selectedMakhdoumClassId!.isNotEmpty) {
      return _selectedMakhdoumClassId;
    }
    if (_makhdoumClasses.isNotEmpty) {
      return _makhdoumClasses.first.classId;
    }
    final user = sl<IProfileRepository>().user;
    return user?.classId;
  }

  String? _getClassNameById(String? classId) {
    if (classId == null || classId.isEmpty) {
      return null;
    }
    try {
      return _makhdoumClasses
              .firstWhere((info) => info.classId == classId)
              .className ??
          'فصلي';
    } catch (_) {
      final user = sl<IProfileRepository>().user;
      if (user != null && user.classId == classId) {
        return 'فصلي';
      }
      return null;
    }
  }

  void _handleScroll(int index) {
    if (index != _selectedTab) return;

    final controller = _scrollControllers[index];
    if (controller == null || !controller.hasClients) return;

    final currentOffset = controller.offset;
    final delta = currentOffset - _lastScrollOffset;

    // Only react to significant scroll changes
    if (delta.abs() < 5) return;

    if (delta > 0 && _isTabBarVisible && currentOffset > 50) {
      // Scrolling down - hide tab bar
      setState(() {
        _isTabBarVisible = false;
      });
    } else if (delta < 0 && !_isTabBarVisible) {
      // Scrolling up - show tab bar
      setState(() {
        _isTabBarVisible = true;
      });
    }

    _lastScrollOffset = currentOffset;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cardAnimationController.dispose();
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
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
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 90), // Space for app bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _isTabBarVisible ? 80 : 0,
                    curve: Curves.easeInOut,
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _selectedTab = index;
                        });
                      },
                      children: [
                        HomeScreen(scrollController: _scrollControllers[0]),
                        AttendanceScreen(
                            scrollController: _scrollControllers[1]),
                        _buildFeedsTab(),
                        _buildScoringTab(),
                      ],
                    ),
                  ),
                ],
              ),
              // Tab navigation (middle layer)
              Positioned(
                top: 90, // Below app bar
                left: 0,
                right: 0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  offset: _isTabBarVisible ? Offset.zero : const Offset(0, -1),
                  child: _buildTabNavigation(),
                ),
              ),
              // App bar on top (highest z-index)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildEnhancedAppBar(),
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08.clamp(0.0, 1.0)),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabButton(0, Icons.home, 'الرئيسية'),
          _buildTabButton(1, Icons.event_note, 'الحضور'),
          _buildTabButton(2, Icons.feed, 'الأخبار'),
          _buildTabButton(3, Icons.emoji_events, 'التايو'),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTabSelected(index),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryMaroon
                        : AppColors.primaryMaroon
                            .withValues(alpha: 0.08.clamp(0.0, 1.0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? AppColors.accentWhite
                        : AppColors.primaryMaroon
                            .withValues(alpha: 0.6.clamp(0.0, 1.0)),
                    size: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primaryMaroon
                        : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildFeedsTab() {
    final user = sl<IProfileRepository>().user;

    print('📰 [MakhdoumMain] Building feeds tab for user: ${user?.id}');
    print('📰 [MakhdoumMain] User classId: ${user?.classId}');

    if (user == null || user.id == null) {
      return _buildMakhdoumError(
        icon: Icons.error_outline,
        title: 'User data not available',
        subtitle: 'Please login again',
      );
    }

    final classId = _effectiveMakhdoumClassId;
    if (classId == null || classId.isEmpty) {
      return _buildNoClassAssigned();
    }

    return Column(
      children: [
        _buildMakhdoumClassSelector(
          title: 'فصل الأخبار',
          selectedClassId: classId,
        ),
        Expanded(
          child: MultiBlocProvider(
            key: ValueKey('makhdoum_feed_$classId'),
            providers: [
              BlocProvider(
                create: (context) =>
                    GetFeedCubit(sl<IFeedRepository>())..getFeedsByClass(classId),
              ),
              BlocProvider(
                create: (context) => AddFeedCubit(sl<IFeedRepository>()),
              ),
            ],
            child: FeedScreen(
              classId: classId,
              isReadOnly: true,
              scrollController: _scrollControllers[2],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMakhdoumError({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoClassAssigned() {
    return _buildMakhdoumError(
      icon: Icons.class_outlined,
      title: 'لم يتم تعيين فصل لك بعد',
      subtitle: 'الرجاء التواصل مع الإدارة',
    );
  }

  Widget _buildMakhdoumClassSelector({
    required String title,
    required String selectedClassId,
  }) {
    final hasMultiple = _makhdoumClasses.length > 1;
    final className = _getClassNameById(selectedClassId) ?? 'فصلي';

    if (!hasMultiple) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        leading: const Icon(Icons.class_rounded, color: AppColors.primaryMaroon),
        title: Text(title),
        subtitle: Text(className),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedClassId,
            items: _makhdoumClasses
                .map(
                  (info) => DropdownMenuItem(
                    value: info.classId,
                    child: Text(info.className ?? 'فصل بدون اسم'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedMakhdoumClassId = value;
              });
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.class_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoringTab() {
    final user = sl<IProfileRepository>().user;

    print('🏆 [MakhdoumMain] Building scoring tab for user: ${user?.id}');
    print('🏆 [MakhdoumMain] User classId: ${user?.classId}');

    if (user == null || user.id == null) {
      return _buildMakhdoumError(
        icon: Icons.error_outline,
        title: 'User data not available',
        subtitle: 'Please login again',
      );
    }

    final classId = _effectiveMakhdoumClassId;
    if (classId == null || classId.isEmpty) {
      return _buildNoClassAssigned();
    }

    final className = _getClassNameById(classId) ?? 'فصلي';

    return Column(
      children: [
        _buildMakhdoumClassSelector(
          title: 'فصل التايو',
          selectedClassId: classId,
        ),
        Expanded(
          child: BlocProvider(
            key: ValueKey('makhdoum_scoring_$classId'),
            create: (context) => ScoringCubit(sl<IScoringRepository>()),
            child: ScoringDashboardScreen(
              userId: user.id!,
              classId: classId,
              className: className,
            ),
          ),
        ),
      ],
    );
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
