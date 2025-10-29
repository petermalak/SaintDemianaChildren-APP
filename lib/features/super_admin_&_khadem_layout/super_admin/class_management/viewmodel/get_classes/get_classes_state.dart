part of 'get_classes_cubit.dart';

@immutable
sealed class GetClassesState {}

final class GetClassesInitial extends GetClassesState {}

final class GetClassesLoading extends GetClassesState {}

final class GetClassesSuccess extends GetClassesState {
  final List<ClassModel> classes;
  GetClassesSuccess(this.classes);
}

final class GetClassesFailure extends GetClassesState {
  final String errorMessage;
  GetClassesFailure(this.errorMessage);
}
