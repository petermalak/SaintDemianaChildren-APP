import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/services/communication_service.dart';

class CommunicationButtons extends StatelessWidget {
  final String phoneNumber;
  final String? userName;
  final bool showLabels;
  final double iconSize;
  final double buttonSize;

  const CommunicationButtons({
    super.key,
    required this.phoneNumber,
    this.userName,
    this.showLabels = true,
    this.iconSize = 20.0,
    this.buttonSize = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final communicationService = CommunicationService();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Phone call button
        _buildCommunicationButton(
          context: context,
          icon: Icons.phone,
          label: 'اتصال',
          color: Colors.green,
          onTap: () => communicationService.makePhoneCall(
            phoneNumber,
            context: context,
          ),
        ),
        
        const SizedBox(width: 8),
        
        // WhatsApp button
        _buildCommunicationButton(
          context: context,
          icon: Icons.message,
          label: 'واتساب',
          color: const Color(0xFF25D366), // WhatsApp green
          onTap: () => _openWhatsApp(context, communicationService),
        ),
      ],
    );
  }

  Widget _buildCommunicationButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(buttonSize / 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3.clamp(0.0, 1.0)),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  void _openWhatsApp(BuildContext context, CommunicationService communicationService) {
    // Create a default message if userName is provided
    String message = '';
    if (userName != null && userName!.isNotEmpty) {
      message = 'مرحباً $userName، أتمنى أن تكون بخير.';
    }
    
    if (message.isNotEmpty) {
      communicationService.openWhatsAppWithMessage(
        phoneNumber,
        message,
        context: context,
      );
    } else {
      communicationService.openWhatsAppChat(
        phoneNumber,
        context: context,
      );
    }
  }
}

/// Compact version of communication buttons for use in lists
class CompactCommunicationButtons extends StatelessWidget {
  final String phoneNumber;
  final String? userName;

  const CompactCommunicationButtons({
    super.key,
    required this.phoneNumber,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return CommunicationButtons(
      phoneNumber: phoneNumber,
      userName: userName,
      showLabels: false,
      iconSize: 16.0,
      buttonSize: 32.0,
    );
  }
}

/// Large version of communication buttons for profile screens
class LargeCommunicationButtons extends StatelessWidget {
  final String phoneNumber;
  final String? userName;

  const LargeCommunicationButtons({
    super.key,
    required this.phoneNumber,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CommunicationButtons(
          phoneNumber: phoneNumber,
          userName: userName,
          showLabels: true,
          iconSize: 24.0,
          buttonSize: 56.0,
        ),
        const SizedBox(height: 8),
        Text(
          'تواصل مع $userName',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
