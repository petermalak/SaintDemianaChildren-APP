import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/model/aftekad_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/repository/i_aftekad_repository.dart';

part 'get_aftekad_state.dart';

class GetAftekadCubit extends Cubit<GetAftekadState> {
  GetAftekadCubit(this._aftekadRepository) : super(GetAftekadInitial());
  final IAftekadRepository _aftekadRepository;
  Future<void> getAftekad() async {
    emit(GetAftekadLoading());
    final result = await _aftekadRepository.getAftekad();
    result.fold(
      (failure) => emit(GetAftekadFailure(failure)),
      (aftekad) => emit(GetAftekadSuccess(aftekad)),
    );
  }
}
