import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/scoring_models.dart';
import '../../repository/i_scoring_repository.dart';
import 'score_definition_state.dart';

class ScoreDefinitionCubit extends Cubit<ScoreDefinitionState> {
  final IScoringRepository _scoringRepository;

  ScoreDefinitionCubit(this._scoringRepository)
      : super(const ScoreDefinitionState());

  Future<void> loadDefinitions({bool forceRefresh = false}) async {
    if (state.isLoading) return;
    if (state.definitions.isNotEmpty && !forceRefresh) return;

    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _scoringRepository.getScoreDefinitions();

    result.fold(
      (error) => emit(state.copyWith(
        isLoading: false,
        errorMessage: error,
      )),
      (definitions) {
        definitions.sort((a, b) => a.name.compareTo(b.name));
        emit(state.copyWith(
          isLoading: false,
          definitions: definitions,
          clearError: true,
        ));
      },
    );
  }

  Future<ScoreDefinitionModel?> createDefinition(
      Map<String, dynamic> definitionData) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result =
        await _scoringRepository.createScoreDefinition(definitionData);

    return result.fold(
      (error) {
        emit(state.copyWith(isLoading: false, errorMessage: error));
        return null;
      },
      (definition) {
        final updated = List<ScoreDefinitionModel>.from(state.definitions)
          ..add(definition)
          ..sort((a, b) => a.name.compareTo(b.name));

        emit(state.copyWith(
          isLoading: false,
          definitions: updated,
          clearError: true,
        ));
        return definition;
      },
    );
  }

  Future<ScoreDefinitionModel?> updateDefinition(
    String definitionId,
    Map<String, dynamic> definitionData,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _scoringRepository.updateScoreDefinition(
      definitionId,
      definitionData,
    );

    return result.fold(
      (error) {
        emit(state.copyWith(isLoading: false, errorMessage: error));
        return null;
      },
      (definition) {
        final updated = state.definitions
            .map((existing) =>
                existing.id == definition.id ? definition : existing)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        emit(state.copyWith(
          isLoading: false,
          definitions: updated,
          clearError: true,
        ));
        return definition;
      },
    );
  }

  Future<ScoringConfigModel?> assignDefinitionToClass(
    String classId,
    String definitionId,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _scoringRepository.assignScoreDefinitionToClass(
      classId,
      definitionId,
    );

    return result.fold(
      (error) {
        emit(state.copyWith(isLoading: false, errorMessage: error));
        return null;
      },
      (config) {
        emit(state.copyWith(isLoading: false, clearError: true));
        return config;
      },
    );
  }

  void clearError() {
    if (state.errorMessage != null) {
      emit(state.copyWith(clearError: true));
    }
  }
}
