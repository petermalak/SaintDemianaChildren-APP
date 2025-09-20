import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class CommunicationService {
  static final CommunicationService _instance = CommunicationService._internal();
  factory CommunicationService() => _instance;
  CommunicationService._internal();

  /// Makes a phone call to the specified phone number
  /// Returns true if the call was initiated successfully
  Future<bool> makePhoneCall(String phoneNumber, {BuildContext? context}) async {
    try {
      // Clean the phone number (remove spaces, dashes, etc.)
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Create the tel: URL
      final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);
      
      // Check if the device can handle tel: URLs
      if (await canLaunchUrl(phoneUri)) {
        final launched = await launchUrl(phoneUri);
        if (launched && context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('جاري الاتصال بـ $phoneNumber'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return launched;
      } else {
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا يمكن إجراء المكالمة على هذا الجهاز'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إجراء المكالمة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Opens WhatsApp chat with the specified phone number
  /// Returns true if WhatsApp was opened successfully
  Future<bool> openWhatsAppChat(String phoneNumber, {BuildContext? context}) async {
    try {
      // Clean the phone number (remove spaces, dashes, etc.)
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Remove the + if present and ensure it starts with country code
      String formattedNumber = cleanNumber;
      if (formattedNumber.startsWith('+')) {
        formattedNumber = formattedNumber.substring(1);
      }
      
      // Create the WhatsApp URL
      final Uri whatsappUri = Uri.parse('https://wa.me/$formattedNumber');
      
      // Check if the device can handle WhatsApp URLs
      if (await canLaunchUrl(whatsappUri)) {
        final launched = await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched && context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('جاري فتح واتساب للتواصل مع $phoneNumber'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return launched;
      } else {
        // Fallback: try to open WhatsApp app directly
        final Uri whatsappAppUri = Uri.parse('whatsapp://send?phone=$formattedNumber');
        
        if (await canLaunchUrl(whatsappAppUri)) {
          final launched = await launchUrl(
            whatsappAppUri,
            mode: LaunchMode.externalApplication,
          );
          
          if (launched && context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('جاري فتح واتساب للتواصل مع $phoneNumber'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return launched;
        } else {
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تطبيق واتساب غير مثبت على هذا الجهاز'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return false;
        }
      }
    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في فتح واتساب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Opens WhatsApp with a pre-written message
  Future<bool> openWhatsAppWithMessage(
    String phoneNumber, 
    String message, {
    BuildContext? context,
  }) async {
    try {
      // Clean the phone number
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      String formattedNumber = cleanNumber;
      if (formattedNumber.startsWith('+')) {
        formattedNumber = formattedNumber.substring(1);
      }
      
      // URL encode the message
      final encodedMessage = Uri.encodeComponent(message);
      
      // Create the WhatsApp URL with message
      final Uri whatsappUri = Uri.parse('https://wa.me/$formattedNumber?text=$encodedMessage');
      
      if (await canLaunchUrl(whatsappUri)) {
        final launched = await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched && context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('جاري فتح واتساب للتواصل مع $phoneNumber'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return launched;
      } else {
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تطبيق واتساب غير مثبت على هذا الجهاز'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في فتح واتساب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Validates if a phone number is in a valid format
  bool isValidPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except +
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Check if it's a valid phone number (at least 7 digits, can start with +)
    return RegExp(r'^\+?[1-9]\d{6,14}$').hasMatch(cleanNumber);
  }

  /// Formats a phone number for display
  String formatPhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If it starts with +, keep it
    if (cleanNumber.startsWith('+')) {
      return cleanNumber;
    }
    
    // Add + if it doesn't have it and looks like an international number
    if (cleanNumber.length > 10) {
      return '+$cleanNumber';
    }
    
    return cleanNumber;
  }
}
