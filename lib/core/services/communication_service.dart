import 'package:dartz/dartz.dart';
import 'package:url_launcher/url_launcher.dart';

import 'interface/i_communication_service.dart';

class CommunicationService implements ICommunicationService {
  static final CommunicationService _instance =
      CommunicationService._privateConstructor();
  factory CommunicationService() => _instance;
  CommunicationService._privateConstructor();

  @override
  Future<Either<String, Unit>> makePhoneCall(String phoneNumber) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        return right(unit);
      } else {
        return left('لا يمكن إجراء المكالمة على هذا الجهاز');
      }
    } catch (e) {
      return left('خطأ في إجراء المكالمة: $e');
    }
  }

  @override
  Future<Either<String, Unit>> openWhatsAppChat(String phoneNumber)async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      String formattedNumber = cleanNumber;
      if (formattedNumber.startsWith('+')) {
        formattedNumber = formattedNumber.substring(1);
      }
      final Uri whatsappUri = Uri.parse('https://wa.me/$formattedNumber');

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        );

        return right(unit);
      } else {
        final Uri whatsappAppUri =
            Uri.parse('whatsapp://send?phone=$formattedNumber');

        if (await canLaunchUrl(whatsappAppUri)) {
          await launchUrl(
            whatsappAppUri,
            mode: LaunchMode.externalApplication,
          );

          return right(unit);
        } else {
          return left('لا يمكن فتح واتساب على هذا الجهاز');
        }
      }
    } catch (e) {
      return left('خطأ في فتح واتساب: $e');
    }
  }
}
