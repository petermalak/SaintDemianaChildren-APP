import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/viewmodel/get_classes/get_classes_cubit.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/di/service_locator.dart';
import '../../model/class_model.dart';
import '../../repository/i_class_repository.dart';
import '../widget/add_class_dialog.dart';
import '../widget/class_card.dart';

class MainClassManagementScreen extends StatelessWidget {
  const MainClassManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          GetClassesCubit(sl<IClassRepository>())..loadClasses(),
      child: const _MainClassManagementScreenContent(),
    );
  }
}

class _MainClassManagementScreenContent extends StatefulWidget {
  const _MainClassManagementScreenContent();

  @override
  State<_MainClassManagementScreenContent> createState() =>
      _MainClassManagementScreenContentState();
}

class _MainClassManagementScreenContentState extends State<_MainClassManagementScreenContent>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fabAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
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
    _searchController.dispose();
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
              _buildHeader(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: BlocBuilder<GetClassesCubit, GetClassesState>(
                    builder: (context, state) {
                      if (state is GetClassesLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (state is GetClassesFailure) {
                        return Center(
                          child: Text(
                            'حدث خطأ: ${state.errorMessage}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      } else if (state is GetClassesSuccess) {
                        return ClassesScreen(
                          cardAnimation: _cardAnimation,
                          classes: state.classes,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final getClassesCubit = context.read<GetClassesCubit>();
          showDialog(
            context: context,
            builder: (dialogContext) => AddClassDialog(
              onSuccess: () => getClassesCubit.refreshClasses(),
            ),
          );
        },
        backgroundColor: AppColors.primaryMaroon,
        icon: const Icon(Icons.add,color:AppColors.accentWhite ,),
        label:  const Text('إضافة فصل جديد', style: TextStyle(color: AppColors.accentWhite),
      ),
    ),
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
              Navigator.pop(context);
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
        ],
      ),
    );
  }
}

class ClassesScreen extends StatefulWidget {
  const ClassesScreen(
      {super.key, required this.cardAnimation, required this.classes});
  final Animation<double> cardAnimation;
  final List<ClassModel> classes;
  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  @override
  Widget build(BuildContext context) {
    return widget.classes.isEmpty
        ? _buildEmptyState(
            icon: Icons.class_,
            title: 'لا توجد فصول',
            subtitle: 'ابدأ بإنشاء فصل جديد لإدارة الأعضاء',
          )
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: widget.classes.length,
            itemBuilder: (context, index) {
              return ClassCard(
                  classItem: widget.classes[index],
                  cardAnimation: widget.cardAnimation, );
            },
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
}
