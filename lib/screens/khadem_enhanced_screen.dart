import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../core/constants/app_colors.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/attendance_provider.dart';

class KhademEnhancedScreen extends StatefulWidget {
  const KhademEnhancedScreen({super.key});

  @override
  State<KhademEnhancedScreen> createState() => _KhademEnhancedScreenState();
}

class _KhademEnhancedScreenState extends State<KhademEnhancedScreen>
    with TickerProviderStateMixin {
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  int _attendanceTabIndex = 0;
  final List<AttendanceType> _attendanceTypes = AttendanceType.values;

  // Animation controllers
  late AnimationController _fabAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
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

    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
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
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      
      // Load users
      final users = await authProvider.getAllUsers();
      userProvider.setUsers(users);
      
      // Load attendance
      await attendanceProvider.loadAttendanceData();
    } catch (e) {
      // Error loading data
    }
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
              color: AppColors.accentWhite.withValues(alpha: 0.2.clamp(0.0, 1.0)),
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
                    color: AppColors.accentWhite.withValues(alpha: 0.9.clamp(0.0, 1.0)),
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
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings, color: AppColors.primaryMaroon),
              SizedBox(width: 12),
              Text('الإعدادات'),
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
          _buildTabButton(1, Icons.people, 'الأعضاء'),
          _buildTabDivider(),
          _buildTabButton(2, Icons.event_note, 'الحضور'),
          _buildTabDivider(),
          _buildTabButton(3, Icons.person, 'الملف الشخصي'),
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
                      : AppColors.primaryMaroon.withValues(alpha: 0.1.clamp(0.0, 1.0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primaryMaroon : AppColors.primaryMaroon,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.accentWhite : AppColors.textPrimary,
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
    _fabAnimationController.reset();
    _fabAnimationController.forward();
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildUsersTab();
      case 2:
        return _buildAttendanceTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final totalUsers = userProvider.users.length;
        final makhdoumCount = userProvider.makhdoumUsers.length;
        final khademCount = userProvider.khademUsers.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 24),
              _buildStatsGrid(totalUsers, makhdoumCount, khademCount),
              const SizedBox(height: 24),
              _buildQuickActions(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMaroon.withValues(alpha: 0.3.clamp(0.0, 1.0)),
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
              color: AppColors.accentWhite.withValues(alpha: 0.2.clamp(0.0, 1.0)),
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
                  'إدارة فعالة للأعضاء والحضور',
                  style: TextStyle(
                    color: AppColors.accentWhite.withValues(alpha: 0.9.clamp(0.0, 1.0)),
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

  Widget _buildStatsGrid(int totalUsers, int makhdoumCount, int khademCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الإحصائيات',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            _buildStatCard(
              'إجمالي الأعضاء',
              totalUsers.toString(),
              Icons.people,
              AppColors.primaryMaroon,
            ),
            _buildStatCard(
              'المخدومين',
              makhdoumCount.toString(),
              Icons.person,
              AppColors.primaryBrown,
            ),
            _buildStatCard(
              'الخدام',
              khademCount.toString(),
              Icons.admin_panel_settings,
              AppColors.accentGold,
            ),
            _buildStatCard(
              'نشاط اليوم',
              '12',
              Icons.trending_up,
              AppColors.success,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
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
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1.clamp(0.0, 1.0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الإجراءات السريعة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'إضافة عضو',
                Icons.person_add,
                AppColors.primaryMaroon,
                () => _showAddUserDialog(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                'تسجيل حضور',
                Icons.event_available,
                AppColors.primaryBrown,
                () => _showAddAttendanceDialog(AttendanceType.mass),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2.clamp(0.0, 1.0)),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05.clamp(0.0, 1.0)),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1.clamp(0.0, 1.0)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final filteredUsers = _searchController.text.isEmpty
            ? userProvider.users
            : userProvider.users.where((user) =>
                user.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                user.email.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
        
        return Column(
          children: [
            _buildSearchSection(),
            Expanded(
              child: filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppColors.primaryMaroon.withValues(alpha: 0.3.clamp(0.0, 1.0)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty 
                                ? 'لا يوجد أعضاء' 
                                : 'لا توجد نتائج للبحث',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.primaryMaroon.withValues(alpha: 0.7.clamp(0.0, 1.0)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return _buildUserCard(user, index);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05.clamp(0.0, 1.0)),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'البحث عن الأعضاء...',
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryMaroon),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.primaryMaroon.withValues(alpha: 0.7.clamp(0.0, 1.0))),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {}); // Trigger rebuild to clear search
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {}); // Trigger rebuild when search text changes
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user, int index) {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _cardAnimation.value)),
          child: Opacity(
            opacity: _cardAnimation.value.clamp(0.0, 1.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
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
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: _getRoleColor(user.role),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColors.accentWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRoleColor(user.role).withValues(alpha: 0.1.clamp(0.0, 1.0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user.role.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getRoleColor(user.role),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Implement edit functionality
                    },
                    icon: Icon(
                      Icons.more_vert,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceTab() {
    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, child) {
        return Column(
          children: [
            _buildAttendanceTypeTabs(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: attendanceProvider.attendanceRecords.length,
                itemBuilder: (context, index) {
                  final record = attendanceProvider.attendanceRecords[index];
                  return _buildAttendanceCard(record, index);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAttendanceTypeTabs() {
    return Container(
      height: 60,
      margin: const EdgeInsets.all(16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _attendanceTypes.length,
        itemBuilder: (context, index) {
          final type = _attendanceTypes[index];
          final isSelected = _attendanceTabIndex == index;
          
          return GestureDetector(
            onTap: () => setState(() => _attendanceTabIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? _getTypeColor(type) : AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? _getTypeColor(type) 
                      : AppColors.borderLight,
                  width: 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: _getTypeColor(type).withValues(alpha: 0.3.clamp(0.0, 1.0)),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Center(
                child: Text(
                  _getTypeLabel(type),
                  style: TextStyle(
                    color: isSelected ? AppColors.accentWhite : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record, int index) {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _cardAnimation.value)),
          child: Opacity(
            opacity: _cardAnimation.value.clamp(0.0, 1.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getTypeColor(record.type).withValues(alpha: 0.2.clamp(0.0, 1.0)),
                  width: 1,
                ),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getTypeColor(record.type).withValues(alpha: 0.1.clamp(0.0, 1.0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(record.type),
                      color: _getTypeColor(record.type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getTypeLabel(record.type),
                          style: TextStyle(
                            fontSize: 14,
                            color: _getTypeColor(record.type),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(record.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedFAB() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: _getFABAction(),
            backgroundColor: _getFABColor(),
            icon: Icon(_getFABIcon(), color: AppColors.accentWhite),
            label: Text(
              _getFABLabel(),
              style: const TextStyle(
                color: AppColors.accentWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  VoidCallback _getFABAction() {
    switch (_selectedTab) {
      case 0:
        return () => _showAddUserDialog();
      case 1:
        return () => _showAddUserDialog();
      case 2:
        return () => _showAddAttendanceDialog(_attendanceTypes[_attendanceTabIndex]);
      default:
        return () => _showAddUserDialog();
    }
  }

  Color _getFABColor() {
    switch (_selectedTab) {
      case 0:
      case 1:
        return AppColors.primaryMaroon;
      case 2:
        return _getTypeColor(_attendanceTypes[_attendanceTabIndex]);
      default:
        return AppColors.primaryMaroon;
    }
  }

  IconData _getFABIcon() {
    switch (_selectedTab) {
      case 0:
      case 1:
        return Icons.person_add;
      case 2:
        return Icons.event_available;
      default:
        return Icons.person_add;
    }
  }

  String _getFABLabel() {
    switch (_selectedTab) {
      case 0:
      case 1:
        return 'إضافة عضو';
      case 2:
        return 'تسجيل حضور';
      default:
        return 'إضافة عضو';
    }
  }

  // Helper methods
  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.khadem:
        return AppColors.accentGold;
      case UserRole.makhdoum:
        return AppColors.primaryBrown;
    }
  }

  Color _getTypeColor(AttendanceType type) {
    switch (type) {
      case AttendanceType.mass:
        return AppColors.primaryMaroon;
      case AttendanceType.specialMeeting:
        return AppColors.primaryBrown;
      case AttendanceType.generalMeeting:
        return AppColors.primaryBlue;
      case AttendanceType.praise:
        return AppColors.accentGreen;
    }
  }

  String _getTypeLabel(AttendanceType type) {
    switch (type) {
      case AttendanceType.mass:
        return 'قداس';
      case AttendanceType.specialMeeting:
        return 'اجتماع خاص';
      case AttendanceType.generalMeeting:
        return 'اجتماع عام';
      case AttendanceType.praise:
        return 'تسبحة';
    }
  }

  IconData _getTypeIcon(AttendanceType type) {
    switch (type) {
      case AttendanceType.mass:
        return Icons.church;
      case AttendanceType.specialMeeting:
        return Icons.people;
      case AttendanceType.generalMeeting:
        return Icons.meeting_room;
      case AttendanceType.praise:
        return Icons.music_note;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Dialog methods with full functionality
  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddUserDialog(
        onUserAdded: () {
          _loadData(); // Refresh data after adding user
        },
      ),
    );
  }

  void _showAddAttendanceDialog(AttendanceType type) {
    showDialog(
      context: context,
      builder: (context) => _AddAttendanceDialog(
        attendanceType: type,
        onAttendanceAdded: () {
          _loadData(); // Refresh data after adding attendance
        },
      ),
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
                await Provider.of<AuthProvider>(context, listen: false).logout();
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

  Widget _buildProfileTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.currentUser == null) {
          return const Center(
            child: Text('لا توجد بيانات المستخدم'),
          );
        }

        final user = authProvider.currentUser!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryMaroon.withValues(alpha: 0.3.clamp(0.0, 1.0)),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentWhite.withValues(alpha: 0.2.clamp(0.0, 1.0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.accentWhite,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'الملف الشخصي',
                      style: TextStyle(
                        color: AppColors.accentWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildEditableProfileCard(user),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditableProfileCard(UserModel user) {
    return _EditableProfileCard(user: user);
  }

}

// Editable Profile Card Widget
class _EditableProfileCard extends StatefulWidget {
  final UserModel user;

  const _EditableProfileCard({required this.user});

  @override
  State<_EditableProfileCard> createState() => _EditableProfileCardState();
}

class _EditableProfileCardState extends State<_EditableProfileCard> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _fathersPhoneController;
  late TextEditingController _mothersPhoneController;
  late TextEditingController _addressController;
  late TextEditingController _addressLocationLinkController;
  late TextEditingController _fatherOfConfessionController;
  DateTime? _selectedBirthdate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _fathersPhoneController = TextEditingController(text: widget.user.fathersPhoneNumber ?? '');
    _mothersPhoneController = TextEditingController(text: widget.user.mothersPhoneNumber ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _addressLocationLinkController = TextEditingController(text: widget.user.addressLocationLink ?? '');
    _fatherOfConfessionController = TextEditingController(text: widget.user.fatherOfConfession ?? '');
    _selectedBirthdate = widget.user.birthdate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _fathersPhoneController.dispose();
    _mothersPhoneController.dispose();
    _addressController.dispose();
    _addressLocationLinkController.dispose();
    _fatherOfConfessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          _buildProfileInfoField('الاسم', _nameController.text, true, _nameController),
          const SizedBox(height: 16),
          _buildProfileInfoField('البريد الإلكتروني', _emailController.text, true, _emailController),
          const SizedBox(height: 16),
          _buildProfileInfoField('رقم الهاتف', _phoneController.text, true, _phoneController),
          const SizedBox(height: 16),
          _buildProfileInfoField('رقم هاتف الأب', _fathersPhoneController.text, true, _fathersPhoneController),
          const SizedBox(height: 16),
          _buildProfileInfoField('رقم هاتف الأم', _mothersPhoneController.text, true, _mothersPhoneController),
          const SizedBox(height: 16),
          _buildBirthdateField(),
          const SizedBox(height: 16),
          _buildProfileInfoField('العنوان', _addressController.text, true, _addressController, maxLines: 3),
          const SizedBox(height: 16),
          _buildLocationField(),
          const SizedBox(height: 16),
          _buildProfileInfoField('أب الاعتراف', _fatherOfConfessionController.text, true, _fatherOfConfessionController),
          const SizedBox(height: 16),
          _buildProfileInfoField('الدور', widget.user.role.name, false, null),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveProfile,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentWhite),
                      ),
                    )
                  : const Icon(Icons.save, color: AppColors.accentWhite),
              label: Text(
                _isLoading ? 'جاري الحفظ...' : 'حفظ التغييرات',
                style: const TextStyle(
                  color: AppColors.accentWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMaroon,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoField(String label, String value, bool isEditable, TextEditingController? controller, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryMaroon.withValues(alpha: 0.8.clamp(0.0, 1.0)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: isEditable && controller != null
              ? TextFormField(
                  controller: controller,
                  maxLines: maxLines,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primaryMaroon, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final updateData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'fathersPhoneNumber': _fathersPhoneController.text.trim().isEmpty ? null : _fathersPhoneController.text.trim(),
        'mothersPhoneNumber': _mothersPhoneController.text.trim().isEmpty ? null : _mothersPhoneController.text.trim(),
        'birthdate': _selectedBirthdate?.toIso8601String().split('T')[0],
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'addressLocationLink': _addressLocationLinkController.text.trim().isEmpty ? null : _addressLocationLinkController.text.trim(),
        'fatherOfConfession': _fatherOfConfessionController.text.trim().isEmpty ? null : _fatherOfConfessionController.text.trim(),
      };

      final updatedUser = await authProvider.updateUserProfile(updateData);

      if (updatedUser != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ التغييرات بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حفظ التغييرات: ${authProvider.errorMessage}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ التغييرات: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildBirthdateField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 120,
          child: Text(
            'تاريخ الميلاد',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryMaroon,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: _selectBirthdate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppColors.primaryMaroon,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedBirthdate != null 
                        ? '${_selectedBirthdate!.day}/${_selectedBirthdate!.month}/${_selectedBirthdate!.year}'
                        : 'لم يتم تحديد تاريخ الميلاد',
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedBirthdate != null ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 120,
          child: Text(
            'رابط موقع العنوان',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryMaroon,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _addressLocationLinkController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primaryMaroon, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.location_on, size: 18),
                label: const Text('موقعي'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  foregroundColor: AppColors.accentWhite,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectBirthdate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedBirthdate = date;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('تم رفض إذن الموقع');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError('تم رفض إذن الموقع نهائياً. يرجى تفعيله من الإعدادات');
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Create Google Maps link
      final locationLink = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
      
      // Close loading dialog
      Navigator.of(context).pop();

      // Update the text field
      setState(() {
        _addressLocationLinkController.text = locationLink;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم الحصول على موقعك بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      // Close loading dialog if it's open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      _showLocationError('فشل في الحصول على الموقع: ${e.toString()}');
    }
  }

  void _showLocationError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطأ في الموقع'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}

// Add User Dialog
class _AddUserDialog extends StatefulWidget {
  final VoidCallback onUserAdded;

  const _AddUserDialog({required this.onUserAdded});

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fathersPhoneController = TextEditingController();
  final _mothersPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressLocationLinkController = TextEditingController();
  final _fatherOfConfessionController = TextEditingController();
  DateTime? _selectedBirthdate;
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.makhdoum;
  String? _selectedImagePath;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _fathersPhoneController.dispose();
    _mothersPhoneController.dispose();
    _addressController.dispose();
    _addressLocationLinkController.dispose();
    _fatherOfConfessionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500, 
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_add,
                    color: AppColors.accentWhite,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'إضافة عضو جديد',
                    style: TextStyle(
                      color: AppColors.accentWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.accentWhite,
                    ),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'الاسم',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال الاسم';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'البريد الإلكتروني',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال البريد الإلكتروني';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'يرجى إدخال بريد إلكتروني صحيح';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'رقم الهاتف',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال رقم الهاتف';
                          }
                          if (!RegExp(r'^[+]?[\d\s-()]+$').hasMatch(value)) {
                            return 'يرجى إدخال رقم هاتف صحيح';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'كلمة المرور',
                        icon: Icons.lock,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال كلمة المرور';
                          }
                          if (value.length < 6) {
                            return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _fathersPhoneController,
                        label: 'رقم هاتف الأب (اختياري)',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            if (!RegExp(r'^[+]?[\d\s-()]+$').hasMatch(value)) {
                              return 'يرجى إدخال رقم هاتف صحيح';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _mothersPhoneController,
                        label: 'رقم هاتف الأم (اختياري)',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            if (!RegExp(r'^[+]?[\d\s-()]+$').hasMatch(value)) {
                              return 'يرجى إدخال رقم هاتف صحيح';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildBirthdateSelector(),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _addressController,
                        label: 'العنوان (اختياري)',
                        icon: Icons.location_on,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _addressLocationLinkController,
                        label: 'رابط موقع العنوان (اختياري)',
                        icon: Icons.link,
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            if (!RegExp(r'^https?:\/\/').hasMatch(value)) {
                              return 'يجب أن يبدأ الرابط بـ http:// أو https://';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _fatherOfConfessionController,
                        label: 'أب الاعتراف (اختياري)',
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 16),
                      _buildRoleSelector(),
                      const SizedBox(height: 16),
                      _buildImageSelector(),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAddUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMaroon,
                        foregroundColor: AppColors.accentWhite,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentWhite),
                              ),
                            )
                          : const Text('إضافة العضو'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryMaroon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryMaroon, width: 2),
        ),
      ),
    );
  }

  Widget _buildBirthdateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تاريخ الميلاد (اختياري)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectBirthdate,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.primaryMaroon),
                const SizedBox(width: 12),
                Text(
                  _selectedBirthdate != null 
                      ? '${_selectedBirthdate!.day}/${_selectedBirthdate!.month}/${_selectedBirthdate!.year}'
                      : 'اختيار تاريخ الميلاد',
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedBirthdate != null ? AppColors.textPrimary : AppColors.textSecondary,
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

  Future<void> _selectBirthdate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedBirthdate = date;
      });
    }
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الدور',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<UserRole>(
                title: const Text('مخدوم'),
                value: UserRole.makhdoum,
                groupValue: _selectedRole,
                onChanged: (value) => setState(() => _selectedRole = value!),
                activeColor: AppColors.primaryMaroon,
              ),
            ),
            Expanded(
              child: RadioListTile<UserRole>(
                title: const Text('خادم'),
                value: UserRole.khadem,
                groupValue: _selectedRole,
                onChanged: (value) => setState(() => _selectedRole = value!),
                activeColor: AppColors.primaryMaroon,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'صورة الملف الشخصي (اختيارية)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: Text(_selectedImagePath != null ? 'تغيير الصورة' : 'اختيار صورة'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (_selectedImagePath != null) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _selectedImagePath = null),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.accentWhite,
                    size: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (_selectedImagePath != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(_selectedImagePath!),
              height: 80,
              width: 80,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _handleAddUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Create user data for API call (including password)
      final userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'password': _passwordController.text,
        'role': _selectedRole.name,
        'fathersPhoneNumber': _fathersPhoneController.text.trim().isEmpty ? null : _fathersPhoneController.text.trim(),
        'mothersPhoneNumber': _mothersPhoneController.text.trim().isEmpty ? null : _mothersPhoneController.text.trim(),
        'birthdate': _selectedBirthdate?.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'addressLocationLink': _addressLocationLinkController.text.trim().isEmpty ? null : _addressLocationLinkController.text.trim(),
        'fatherOfConfession': _fatherOfConfessionController.text.trim().isEmpty ? null : _fatherOfConfessionController.text.trim(),
        if (_selectedImagePath != null) 'profileImage': _selectedImagePath,
      };

      // Use the new method to create user with raw data
      final createdUser = await authProvider.addUserWithData(userData);
      
      if (createdUser == null) {
        throw Exception('Failed to create user');
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة العضو بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onUserAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة العضو: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

}

// Add Attendance Dialog
class _AddAttendanceDialog extends StatefulWidget {
  final AttendanceType attendanceType;
  final VoidCallback onAttendanceAdded;

  const _AddAttendanceDialog({
    required this.attendanceType,
    required this.onAttendanceAdded,
  });

  @override
  State<_AddAttendanceDialog> createState() => _AddAttendanceDialogState();
}

class _AddAttendanceDialogState extends State<_AddAttendanceDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedUserId;
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500, 
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getTypeIcon(widget.attendanceType),
                    color: AppColors.accentWhite,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'تسجيل حضور - ${_getTypeLabel(widget.attendanceType)}',
                    style: const TextStyle(
                      color: AppColors.accentWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.accentWhite,
                    ),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserSelector(),
                      const SizedBox(height: 16),
                      _buildDateSelector(),
                      const SizedBox(height: 16),
                      _buildNotesField(),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAddAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getTypeColor(widget.attendanceType),
                        foregroundColor: AppColors.accentWhite,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentWhite),
                              ),
                            )
                          : const Text('تسجيل الحضور'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSelector() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختيار العضو',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedUserId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryMaroon, width: 2),
                ),
              ),
              items: userProvider.users.map((user) {
                return DropdownMenuItem(
                  value: user.id,
                  child: Text(user.name),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedUserId = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى اختيار العضو';
                }
                return null;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تاريخ الحضور',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.primaryMaroon),
                const SizedBox(width: 12),
                Text(
                  _formatDate(_selectedDate),
                  style: const TextStyle(fontSize: 16),
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

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ملاحظات (اختيارية)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'أدخل أي ملاحظات...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryMaroon, width: 2),
            ),
          ),
        ),
      ],
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Get user name from the selected user ID
      final selectedUser = userProvider.users.firstWhere(
        (user) => user.id == _selectedUserId!,
        orElse: () => throw Exception('User not found'),
      );

      await attendanceProvider.addAttendanceRecord(
        userId: _selectedUserId!,
        userName: selectedUser.name,
        type: widget.attendanceType,
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل الحضور بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onAttendanceAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الحضور: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper methods
  Color _getTypeColor(AttendanceType type) {
    switch (type) {
      case AttendanceType.mass:
        return AppColors.primaryMaroon;
      case AttendanceType.specialMeeting:
        return AppColors.primaryBrown;
      case AttendanceType.generalMeeting:
        return AppColors.primaryBlue;
      case AttendanceType.praise:
        return AppColors.accentGreen;
    }
  }

  String _getTypeLabel(AttendanceType type) {
    switch (type) {
      case AttendanceType.mass:
        return 'قداس';
      case AttendanceType.specialMeeting:
        return 'اجتماع خاص';
      case AttendanceType.generalMeeting:
        return 'اجتماع عام';
      case AttendanceType.praise:
        return 'تسبحة';
    }
  }

  IconData _getTypeIcon(AttendanceType type) {
    switch (type) {
      case AttendanceType.mass:
        return Icons.church;
      case AttendanceType.specialMeeting:
        return Icons.people;
      case AttendanceType.generalMeeting:
        return Icons.meeting_room;
      case AttendanceType.praise:
        return Icons.music_note;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
