import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/repository/i_aftekad_repository.dart';

part 'aftekad_state.dart';

class AftekadCubit extends Cubit<AftekadState> {
  AftekadCubit(this._aftekadRepository) : super(AftekadInitial());
  final IAftekadRepository _aftekadRepository;
  Future<void> getAftekad() async {
    emit(AftekadLoading());
    // final result = await _aftekadRepository.getAftekad();
    // result.fold(
    //   (failure) => emit(AftekadFailure(failure.errorMessage)),
    //   (aftekad) => emit(AftekadSuccess(aftekad)),
    // );
  }
}
