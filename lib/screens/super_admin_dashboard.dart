import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/class_provider.dart';
import '../providers/user_provider.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final classProvider = Provider.of<ClassProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Load classes and users in parallel
      final results = await Future.wait([
        classProvider.loadClasses(),
        authProvider.getAllUsers(),
      ]);

      // Update userProvider with the loaded users
      final users = results[1] as List<UserModel>;
      userProvider.setUsers(users);
      
      print('Super Admin Dashboard: Loaded ${users.length} users');
      print('Super Admin Dashboard: Loaded ${classProvider.classes.length} classes');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Super Admin Dashboard: Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryCream,
              AppColors.primaryCream.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                   Expanded(
                     child: _isLoading
                         ? Center(
                             child: Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 const CircularProgressIndicator(),
                                 const SizedBox(height: 16),
                                 Text(
                                   'جاري تحميل البيانات...',
                                   style: TextStyle(
                                     fontSize: 16,
                                     color: AppColors.textSecondary,
                                   ),
                                 ),
                               ],
                             ),
                           )
                         : SingleChildScrollView(
                             padding: const EdgeInsets.all(20),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 _buildWelcomeSection(),
                                 const SizedBox(height: 24),
                                 _buildDebugInfo(),
                                 const SizedBox(height: 24),
                                 _buildQuickStats(),
                                 const SizedBox(height: 24),
                                 _buildQuickActions(),
                                 const SizedBox(height: 24),
                                 _buildManagementSections(),
                                 const SizedBox(height: 24),
                                 _buildSystemOverview(),
                               ],
                             ),
                           ),
                   ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryMaroon,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMaroon.withValues(alpha: 0.3),
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
              color: AppColors.accentWhite.withValues(alpha: 0.2),
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
                  'لوحة تحكم المدير العام',
                  style: TextStyle(
                    color: AppColors.accentWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'إدارة شاملة لنظام القديسة دميانة',
                  style: TextStyle(
                    color: AppColors.accentWhite.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
           Row(
             mainAxisSize: MainAxisSize.min,
             children: [
               IconButton(
                 onPressed: _loadData,
                 icon: _isLoading 
                   ? const SizedBox(
                       width: 20,
                       height: 20,
                       child: CircularProgressIndicator(
                         strokeWidth: 2,
                         valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentWhite),
                       ),
                     )
                   : const Icon(
                       Icons.refresh,
                       color: AppColors.accentWhite,
                     ),
               ),
               IconButton(
                 onPressed: () => context.go('/khadem'),
                 icon: const Icon(
                   Icons.arrow_back,
                   color: AppColors.accentWhite,
                 ),
               ),
             ],
           ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accentGold.withValues(alpha: 0.1),
                AppColors.primaryMaroon.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accentGold.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.waving_hand,
                  color: AppColors.accentGold,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً، ${user?.name ?? 'المدير العام'}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'مرحباً بك في لوحة التحكم الرئيسية. استخدم "إدارة الفصول والأعضاء" للوصول إلى جميع الميزات الرئيسية.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDebugInfo() {
    return Consumer2<ClassProvider, UserProvider>(
      builder: (context, classProvider, userProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accentGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bug_report, color: AppColors.accentGold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'معلومات التصحيح',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('عدد الفصول: ${classProvider.classes.length}'),
              Text('عدد المستخدمين: ${userProvider.users.length}'),
              if (userProvider.users.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('المستخدمين:'),
                ...userProvider.users.take(3).map((user) => 
                  Text('  - ${user.name} (${user.role.name})')
                ),
                if (userProvider.users.length > 3)
                  Text('  ... و ${userProvider.users.length - 3} آخرين'),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: AppColors.primaryMaroon,
                      ),
                      child: const Text('إعادة تحميل البيانات'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _testAssignment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMaroon,
                        foregroundColor: AppColors.accentWhite,
                      ),
                      child: const Text('اختبار التعيين'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _testAssignment() async {
    try {
      final classProvider = Provider.of<ClassProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      if (classProvider.classes.isEmpty || userProvider.users.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد فصول أو مستخدمين للاختبار'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      final firstClass = classProvider.classes.first;
      final firstUser = userProvider.users.first;
      
      print('Testing assignment: User ${firstUser.name} to Class ${firstClass.name}');
      
      final success = await classProvider.addClassMember(
        firstClass.id,
        firstUser.id,
        firstUser.role,
        notes: 'Test assignment from dashboard',
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم اختبار التعيين بنجاح: ${firstUser.name} -> ${firstClass.name}'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadData(); // Refresh data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في اختبار التعيين'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Test assignment error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في اختبار التعيين: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildQuickStats() {
    return Consumer2<ClassProvider, UserProvider>(
      builder: (context, classProvider, userProvider, child) {
        final totalClasses = classProvider.classes.length;
        final totalUsers = userProvider.users.length;
        final khademCount = userProvider.users.where((u) => u.role == UserRole.khadem).length;
        final makhdoumCount = userProvider.users.where((u) => u.role == UserRole.makhdoum).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'الإحصائيات السريعة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // Debug info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${totalUsers} مستخدم',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.class_,
                    title: 'إجمالي الفصول',
                    value: totalClasses.toString(),
                    color: AppColors.primaryMaroon,
                    onTap: () => context.go('/class-management'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.people,
                    title: 'إجمالي المستخدمين',
                    value: totalUsers.toString(),
                    color: AppColors.primaryBrown,
                    onTap: () => _showUsersOverview(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.supervisor_account,
                    title: 'الخدام',
                    value: khademCount.toString(),
                    color: AppColors.accentGold,
                    onTap: () => _showRoleOverview(UserRole.khadem),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.person,
                    title: 'المخدومين',
                    value: makhdoumCount.toString(),
                    color: AppColors.primaryBlue,
                    onTap: () => _showRoleOverview(UserRole.makhdoum),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color.withValues(alpha: 0.6),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الإجراءات السريعة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_circle_outline,
                title: 'إنشاء فصل جديد',
                subtitle: 'إضافة فصل جديد للنظام',
                color: AppColors.primaryMaroon,
                onTap: () => context.go('/class-management'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.person_add,
                title: 'إضافة مستخدم',
                subtitle: 'تسجيل مستخدم جديد',
                color: AppColors.primaryBrown,
                onTap: () => _showAddUserDialog(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.assignment_ind,
                title: 'تعيين الأعضاء',
                subtitle: 'إدارة تعيينات الفصول',
                color: AppColors.accentGold,
                onTap: () => context.go('/class-management'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.analytics,
                title: 'التقارير',
                subtitle: 'عرض إحصائيات النظام',
                color: AppColors.primaryBlue,
                onTap: () => _showReportsDialog(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أقسام الإدارة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildManagementCard(
          icon: Icons.class_,
          title: 'إدارة الفصول',
          description: 'إدارة الفصول والأعضاء والتعيينات',
          color: AppColors.primaryMaroon,
          onTap: () => context.go('/class-management'),
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          icon: Icons.people,
          title: 'إدارة المستخدمين',
          description: 'إدارة جميع المستخدمين في النظام',
          color: AppColors.primaryBrown,
          onTap: () => _showUsersManagement(),
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          icon: Icons.settings,
          title: 'إعدادات النظام',
          description: 'إعدادات عامة للنظام',
          color: AppColors.accentGold,
          onTap: () => _showSystemSettings(),
        ),
      ],
    );
  }

  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withValues(alpha: 0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'نظرة عامة على النظام',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer2<ClassProvider, UserProvider>(
            builder: (context, classProvider, userProvider, child) {
              return Column(
                children: [
                  _buildOverviewItem(
                    'آخر تحديث',
                    DateTime.now().toString().split(' ')[0],
                    Icons.update,
                  ),
                  const SizedBox(height: 12),
                  _buildOverviewItem(
                    'حالة النظام',
                    'يعمل بشكل طبيعي',
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildOverviewItem(
                    'إجمالي الفصول النشطة',
                    '${classProvider.classes.length} فصل',
                    Icons.class_,
                  ),
                  const SizedBox(height: 12),
                  _buildOverviewItem(
                    'إجمالي المستخدمين',
                    '${userProvider.users.length} مستخدم',
                    Icons.people,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(
          icon,
          color: color ?? AppColors.textSecondary,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // Dialog methods
  void _showUsersOverview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نظرة عامة على المستخدمين'),
        content: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final users = userProvider.users;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('إجمالي المستخدمين: ${users.length}'),
                const SizedBox(height: 16),
                ...UserRole.values.map((role) {
                  final count = users.where((u) => u.role == role).length;
                  return ListTile(
                    leading: Icon(_getRoleIcon(role), color: _getRoleColor(role)),
                    title: Text(_getRoleDisplayName(role)),
                    trailing: Text(count.toString()),
                  );
                }),
              ],
            );
          },
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

  void _showRoleOverview(UserRole role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_getRoleDisplayName(role)} - نظرة عامة'),
        content: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final users = userProvider.users.where((u) => u.role == role).toList();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('عدد ${_getRoleDisplayName(role)}: ${users.length}'),
                const SizedBox(height: 16),
                if (users.isNotEmpty)
                  ...users.take(5).map((user) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRoleColor(role).withValues(alpha: 0.1),
                      child: Text(
                        user.name[0],
                        style: TextStyle(color: _getRoleColor(role)),
                      ),
                    ),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                  )),
                if (users.length > 5)
                  Text('و ${users.length - 5} آخرين...'),
              ],
            );
          },
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

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مستخدم جديد'),
        content: const Text('هذه الميزة ستكون متاحة قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showReportsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('التقارير والإحصائيات'),
        content: const Text('هذه الميزة ستكون متاحة قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showUsersManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إدارة المستخدمين'),
        content: const Text('هذه الميزة ستكون متاحة قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showSystemSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعدادات النظام'),
        content: const Text('هذه الميزة ستكون متاحة قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.khadem:
        return Icons.supervisor_account;
      case UserRole.makhdoum:
        return Icons.person;
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.superAdmin:
        return Icons.security;
    }
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

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.khadem:
        return 'خادم';
      case UserRole.makhdoum:
        return 'مخدوم';
      case UserRole.admin:
        return 'مدير';
      case UserRole.superAdmin:
        return 'مدير عام';
    }
  }
}
