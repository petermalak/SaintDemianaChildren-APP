import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/model/aftekad_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/repository/i_aftekad_repository.dart';

part 'add_aftekad_state.dart';

class AddAftekadCubit extends Cubit<AddAftekadState> {
  AddAftekadCubit(this._aftekadRepository) : super(AddAftekadInitial());
  final IAftekadRepository _aftekadRepository;

  Future<void> addAftekad({
    required AftekadType type,
    String? outcome,
    required DateTime date,
    required String khademId,
    required String makhdoumId,
    required String classId,
  }) async {
    emit(AddAftekadLoading());
    final result = await _aftekadRepository.addAftekad(
      type: type,
      classId: classId,
      khademId: khademId,
      makhdoumId: makhdoumId,
      date: date,
      notes: outcome,
    );
    result.fold(
      (failure) => emit(AddAftekadFailure(failure)),
      (_) => emit(AddAftekadSuccess()),
    );
  }
}
