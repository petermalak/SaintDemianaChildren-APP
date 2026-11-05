import "package:flutter/material.dart";
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../model/class_model.dart';
import '../../repository/i_class_repository.dart';
part 'get_classes_state.dart';

class GetClassesCubit extends Cubit<GetClassesState> {
  GetClassesCubit(this._classRepository) : super(GetClassesInitial());
  final IClassRepository _classRepository;

  Future<void> loadClasses() async {
    emit(GetClassesLoading());
    final result = await _classRepository.loadClasses();
    result.fold(
      (failure) => emit(GetClassesFailure(failure)),
      (classes) => emit(GetClassesSuccess(classes)),
    );
  }

  void refreshClasses() {
    emit(GetClassesSuccess(_classRepository.classes));
  }
}
