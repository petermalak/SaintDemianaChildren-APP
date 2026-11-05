import 'package:dartz/dartz.dart';

import '../model/aftekad_model.dart';

abstract class IAftekadRepository {
  Future<Either<String, List<AftekadModel>>> getAftekadByWeek(
    String fridayDate, {
    String? khademId,
    String? classId,
    String? khademName,
    String? khademScope,
  });
  Future<Either<String, Unit>> addAftekad(
      {required AftekadType type,
      required DateTime date,
      required String makhdoumId,
      required String khademId,
      required String classId,
      String? notes});
  Map<String, int>? get lastMakhdoumsMissedFridays;
}
