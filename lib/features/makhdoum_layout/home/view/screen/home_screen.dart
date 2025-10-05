import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../authentication/model/user_model.dart';
import '../../../../profile/repository/i_profile_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final UserModel user = sl<IProfileRepository>().user!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(user),
        ],
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
            child: SingleChildScrollView(
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
          ),
        ],
      ),
    );
  }
}
