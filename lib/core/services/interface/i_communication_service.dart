import 'package:dartz/dartz.dart';

abstract class ICommunicationService {
  Future<Either<String, Unit>> makePhoneCall(
    String phoneNumber,
  );
  Future<Either<String, Unit>> openWhatsAppChat(
    String phoneNumber,
  );
}
