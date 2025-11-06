import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/repository/i_class_repository.dart';

part 'add_class_state.dart';

class AddClassCubit extends Cubit<AddClassState> {
  AddClassCubit(this._classRepository) : super(AddClassInitial());
  final IClassRepository _classRepository;

  Future<void> addClass(String name, String location) async {
    emit(AddClassLoading());
    final result = await _classRepository.addClass(name, location);
    result.fold(
      (failure) => emit(AddClassFailure(failure)),
      (_) => emit(AddClassSuccess()),
    );
  }

  Future<void> updateClass(String id, String name, String location) async {
    emit(AddClassLoading());
    final result = await _classRepository.updateClass(id, name, location);
    result.fold(
      (failure) => emit(AddClassFailure(failure)),
      (_) => emit(AddClassSuccess()),
    );
  }
}
