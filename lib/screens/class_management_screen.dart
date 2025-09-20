import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../models/class_model.dart';
import '../models/class_membership_model.dart';
import '../models/user_model.dart';
import '../providers/class_provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Animation controllers
  late AnimationController _fabAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    _tabController.dispose();
    _searchController.dispose();
    _fabAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final classProvider = Provider.of<ClassProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    await Future.wait([
      classProvider.loadClasses(),
      userProvider.loadUsers(),
    ]);
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
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildClassesTab(),
                    _buildMembersTab(),
                    _buildAssignmentsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
        vertical: 20,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/khadem');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryMaroon.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة الفصول',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.06,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'إدارة الفصول والأعضاء والتعيينات',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.035,
                    color: AppColors.textSecondary,
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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, color: AppColors.primaryMaroon),
                  SizedBox(width: 12),
                  Text('تحديث البيانات'),
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
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryMaroon.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.more_vert,
              color: AppColors.primaryMaroon,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMaroon.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primaryMaroon,
        ),
        labelColor: AppColors.accentWhite,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: isSmallScreen ? 12 : 14,
        ),
        tabs: [
          Tab(
            icon: Icon(Icons.class_, size: isSmallScreen ? 18 : 20),
            text: 'الفصول',
          ),
          Tab(
            icon: Icon(Icons.people, size: isSmallScreen ? 18 : 20),
            text: 'الأعضاء',
          ),
          Tab(
            icon: Icon(Icons.assignment, size: isSmallScreen ? 18 : 20),
            text: 'التعيينات',
          ),
        ],
      ),
    );
  }

  Widget _buildClassesTab() {
    return Consumer<ClassProvider>(
      builder: (context, classProvider, child) {
        final classes = classProvider.classes;
        final filteredClasses = _searchQuery.isEmpty
            ? classes
            : classes.where((cls) =>
                cls.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (cls.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)).toList();

        return Column(
          children: [
            _buildSearchSection(),
            Expanded(
              child: filteredClasses.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.class_,
                      title: 'لا توجد فصول',
                      subtitle: 'ابدأ بإنشاء فصل جديد لإدارة الأعضاء',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredClasses.length,
                      itemBuilder: (context, index) {
                        final classItem = filteredClasses[index];
                        return _buildClassCard(classItem);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMembersTab() {
    return Consumer2<ClassProvider, UserProvider>(
      builder: (context, classProvider, userProvider, child) {
        final allUsers = userProvider.users;
        final filteredUsers = _searchQuery.isEmpty
            ? allUsers
            : allUsers.where((user) =>
                user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                user.email.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        return Column(
          children: [
            _buildSearchSection(),
            Expanded(
              child: filteredUsers.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.people,
                      title: 'لا يوجد أعضاء',
                      subtitle: 'لا توجد أعضاء مسجلين في النظام',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return _buildUserCard(user);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAssignmentsTab() {
    return _buildEmptyState(
      icon: Icons.assignment,
      title: 'قريباً: إدارة التعيينات',
      subtitle: 'ستتمكن من إدارة تعيينات الأعضاء للفصول',
    );
  }

  Widget _buildSearchSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      margin: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMaroon.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'البحث...',
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: screenWidth * 0.04,
          ),
          prefixIcon: Icon(
            Icons.search, 
            color: AppColors.primaryMaroon,
            size: screenWidth * 0.05,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: Icon(
                    Icons.clear, 
                    color: AppColors.textSecondary,
                    size: screenWidth * 0.05,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04, 
            vertical: screenWidth * 0.03,
          ),
        ),
        style: TextStyle(fontSize: screenWidth * 0.04),
      ),
    );
  }

  Widget _buildClassCard(ClassModel classItem) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: Container(
            margin: EdgeInsets.only(bottom: screenWidth * 0.04),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryMaroon.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          color: AppColors.primaryMaroon.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.class_,
                          color: AppColors.primaryMaroon,
                          size: screenWidth * 0.06,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classItem.name,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (classItem.description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                classItem.description!,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleClassAction(value, classItem),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: AppColors.primaryMaroon),
                                SizedBox(width: 12),
                                Text('تعديل'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'members',
                            child: Row(
                              children: [
                                Icon(Icons.people, color: AppColors.primaryMaroon),
                                SizedBox(width: 12),
                                Text('الأعضاء'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: AppColors.error),
                                SizedBox(width: 12),
                                Text('حذف'),
                              ],
                            ),
                          ),
                        ],
                        child: Icon(
                          Icons.more_vert,
                          color: AppColors.textSecondary,
                          size: screenWidth * 0.05,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: screenWidth * 0.04),
                  
                  // Class stats - responsive layout
                  isSmallScreen 
                    ? Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatChip(
                                  icon: Icons.people,
                                  label: 'الأعضاء',
                                  value: '${classItem.memberCount}',
                                  color: AppColors.primaryMaroon,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(
                                child: _buildStatChip(
                                  icon: Icons.person,
                                  label: 'الخدام',
                                  value: '${classItem.khademCount}',
                                  color: AppColors.accentGold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenWidth * 0.02),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatChip(
                                  icon: Icons.child_care,
                                  label: 'المخدومين',
                                  value: '${classItem.makhdoumCount}',
                                  color: AppColors.primaryBrown,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(child: Container()), // Empty space
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          _buildStatChip(
                            icon: Icons.people,
                            label: 'الأعضاء',
                            value: '${classItem.memberCount}',
                            color: AppColors.primaryMaroon,
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          _buildStatChip(
                            icon: Icons.person,
                            label: 'الخدام',
                            value: '${classItem.khademCount}',
                            color: AppColors.accentGold,
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          _buildStatChip(
                            icon: Icons.child_care,
                            label: 'المخدومين',
                            value: '${classItem.makhdoumCount}',
                            color: AppColors.primaryBrown,
                          ),
                        ],
                      ),
                  
                  if (classItem.location != null) ...[
                    SizedBox(height: screenWidth * 0.03),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on, 
                          size: screenWidth * 0.04, 
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Expanded(
                          child: Text(
                            classItem.location!,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  if (classItem.schedule != null) ...[
                    SizedBox(height: screenWidth * 0.02),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule, 
                          size: screenWidth * 0.04, 
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Expanded(
                          child: Text(
                            classItem.scheduleText,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: AppColors.textSecondary,
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
      },
    );
  }

  Widget _buildUserCard(UserModel user) {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryMaroon.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getRoleColor(user.role).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getRoleIcon(user.role),
                      color: _getRoleColor(user.role),
                      size: 24,
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getRoleColor(user.role).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user.roleDisplayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getRoleColor(user.role),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleUserAction(value, user),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, color: AppColors.primaryMaroon),
                            SizedBox(width: 12),
                            Text('عرض التفاصيل'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'assign',
                        child: Row(
                          children: [
                            Icon(Icons.assignment, color: AppColors.primaryMaroon),
                            SizedBox(width: 12),
                            Text('تعيين لفصل'),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
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

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$value $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryMaroon.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 48,
              color: AppColors.primaryMaroon,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: FloatingActionButton(
            onPressed: _showCreateClassDialog,
            backgroundColor: AppColors.primaryMaroon,
            child: const Icon(
              Icons.add,
              color: AppColors.accentWhite,
            ),
          ),
        );
      },
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.khadem:
        return AppColors.accentGold;
      case UserRole.makhdoum:
        return AppColors.primaryBrown;
      case UserRole.admin:
        return AppColors.primaryMaroon;
      case UserRole.superAdmin:
        return AppColors.primaryBlue;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.khadem:
        return Icons.person;
      case UserRole.makhdoum:
        return Icons.child_care;
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.superAdmin:
        return Icons.supervisor_account;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        _loadData();
        break;
      case 'settings':
        // TODO: Navigate to settings
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  void _handleClassAction(String action, ClassModel classItem) {
    switch (action) {
      case 'edit':
        _showEditClassDialog(classItem);
        break;
      case 'members':
        _showClassMembersDialog(classItem);
        break;
      case 'delete':
        _showDeleteClassDialog(classItem);
        break;
    }
  }

  void _handleUserAction(String action, UserModel user) {
    switch (action) {
      case 'view':
        _showUserDetailsDialog(user);
        break;
      case 'assign':
        _showAssignUserDialog(user);
        break;
    }
  }

  void _handleMembershipAction(String action, ClassMembershipModel membership, ClassModel classItem) {
    switch (action) {
      case 'remove':
        _showRemoveMemberDialog(membership, classItem);
        break;
    }
  }

  void _showRemoveMemberDialog(ClassMembershipModel membership, ClassModel classItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إزالة عضو من الفصل'),
        content: Text('هل أنت متأكد من إزالة ${membership.user?.name ?? 'هذا العضو'} من "${classItem.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final classProvider = Provider.of<ClassProvider>(context, listen: false);
              await classProvider.removeClassMember(classItem.id, membership.userId);
              Navigator.pop(context);
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم إزالة ${membership.user?.name ?? 'العضو'} من الفصل')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.accentWhite,
            ),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout();
    context.go('/login');
  }

  void _showCreateClassDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    final maxMembersController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنشاء فصل جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الفصل',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'وصف الفصل',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'الموقع',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxMembersController,
                decoration: const InputDecoration(
                  labelText: 'الحد الأقصى للأعضاء',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final classProvider = Provider.of<ClassProvider>(context, listen: false);
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final newClass = ClassModel(
                  id: '',
                  name: nameController.text,
                  description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                  location: locationController.text.isNotEmpty ? locationController.text : null,
                  maxMembers: maxMembersController.text.isNotEmpty ? int.tryParse(maxMembersController.text) : null,
                  isActive: true,
                  createdBy: authProvider.currentUser?.id ?? '',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                await classProvider.createClass(newClass);
                Navigator.pop(context);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إنشاء الفصل بنجاح')),
                );
              }
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }

  void _showEditClassDialog(ClassModel classItem) {
    final nameController = TextEditingController(text: classItem.name);
    final descriptionController = TextEditingController(text: classItem.description ?? '');
    final locationController = TextEditingController(text: classItem.location ?? '');
    final maxMembersController = TextEditingController(text: classItem.maxMembers?.toString() ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الفصل'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الفصل',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'وصف الفصل',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'الموقع',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxMembersController,
                decoration: const InputDecoration(
                  labelText: 'الحد الأقصى للأعضاء',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final classProvider = Provider.of<ClassProvider>(context, listen: false);
                final updatedClass = classItem.copyWith(
                  name: nameController.text,
                  description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                  location: locationController.text.isNotEmpty ? locationController.text : null,
                  maxMembers: maxMembersController.text.isNotEmpty ? int.tryParse(maxMembersController.text) : null,
                  updatedAt: DateTime.now(),
                );
                await classProvider.updateClass(updatedClass);
                Navigator.pop(context);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث الفصل بنجاح')),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showClassMembersDialog(ClassModel classItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('أعضاء ${classItem.name}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Consumer<ClassProvider>(
            builder: (context, classProvider, child) {
              final memberships = classItem.memberships ?? [];
              
              if (memberships.isEmpty) {
                return const Center(
                  child: Text('لا يوجد أعضاء في هذا الفصل'),
                );
              }
              
              return ListView.builder(
                itemCount: memberships.length,
                itemBuilder: (context, index) {
                  final membership = memberships[index];
                  final user = membership.user;
                  
                  if (user == null) return const SizedBox.shrink();
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.1),
                      child: Icon(
                        _getRoleIcon(user.role),
                        color: _getRoleColor(user.role),
                      ),
                    ),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) => _handleMembershipAction(value, membership, classItem),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.remove_circle, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('إزالة من الفصل'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showDeleteClassDialog(ClassModel classItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الفصل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من حذف "${classItem.name}"؟'),
            const SizedBox(height: 8),
            const Text(
              'تحذير: سيتم حذف الفصل وجميع التعيينات المرتبطة به نهائياً.',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final classProvider = Provider.of<ClassProvider>(context, listen: false);
              await classProvider.deleteClass(classItem.id);
              Navigator.pop(context);
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم حذف الفصل "${classItem.name}" بنجاح')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.accentWhite,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showUserDetailsDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('البريد الإلكتروني', user.email),
            _buildDetailRow('رقم الهاتف', user.phoneNumber),
            _buildDetailRow('الدور', user.roleDisplayName),
            if (user.fathersPhoneNumber?.isNotEmpty == true)
              _buildDetailRow('هاتف الأب', user.fathersPhoneNumber!),
            if (user.mothersPhoneNumber?.isNotEmpty == true)
              _buildDetailRow('هاتف الأم', user.mothersPhoneNumber!),
            if (user.birthdate != null)
              _buildDetailRow('تاريخ الميلاد', _formatDate(user.birthdate!)),
            if (user.address?.isNotEmpty == true)
              _buildDetailRow('العنوان', user.address!),
            if (user.fatherOfConfession?.isNotEmpty == true)
              _buildDetailRow('أب الاعتراف', user.fatherOfConfession!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _showAssignUserDialog(UserModel user) {
    String? selectedClassId;
    String? selectedRole = user.role == UserRole.khadem ? 'khadem' : 'makhdoum';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعيين ${user.name}'),
        content: Consumer<ClassProvider>(
          builder: (context, classProvider, child) {
            final classes = classProvider.classes;
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedClassId,
                  decoration: const InputDecoration(
                    labelText: 'اختيار الفصل',
                    border: OutlineInputBorder(),
                  ),
                  items: classes.map((cls) {
                    return DropdownMenuItem(
                      value: cls.id,
                      child: Text(cls.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedClassId = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'الدور في الفصل',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'khadem',
                      child: Text('خادم'),
                    ),
                    DropdownMenuItem(
                      value: 'makhdoum',
                      child: Text('مخدوم'),
                    ),
                  ],
                  onChanged: (value) => setState(() => selectedRole = value),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedClassId != null && selectedRole != null) {
                final classProvider = Provider.of<ClassProvider>(context, listen: false);
                await classProvider.addClassMember(
                  selectedClassId!,
                  user.id,
                  UserModel.parseRole(selectedRole!),
                );
                Navigator.pop(context);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم تعيين ${user.name} للفصل بنجاح')),
                );
              }
            },
            child: const Text('تعيين'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}