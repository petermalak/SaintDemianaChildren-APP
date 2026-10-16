import 'package:dartz/dartz.dart';
import '../model/agenda_model.dart';

abstract class IAgendaRepository {
  Future<Either<String, PhaseAgenda>> getMyAgenda();

  Future<Either<String, PhaseAgenda>> getAgendaForPhase(int phase);
}
