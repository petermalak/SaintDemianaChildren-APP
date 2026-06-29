import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/level_progress.dart';
import '../../model/path_model.dart';
import '../../repository/i_coptic_quest_repository.dart';

abstract class CopticQuestProgressState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CopticQuestProgressInitial extends CopticQuestProgressState {}

class CopticQuestProgressLoading extends CopticQuestProgressState {}

class CopticQuestProgressLoaded extends CopticQuestProgressState {
  final CopticQuestManifest manifest;
  final UserCopticQuestProgress progress;

  CopticQuestProgressLoaded({
    required this.manifest,
    required this.progress,
  });

  bool isUnlocked(String pathId, String levelId) {
    final path = manifest.pathById(pathId);
    if (path == null) return false;
    final ids = path.levels.map((l) => l.id).toList();
    return progress.isLevelUnlocked(pathId, levelId, ids);
  }

  LevelProgress levelProgress(String pathId, String levelId) {
    return progress.levelProgress(pathId, levelId);
  }

  @override
  List<Object?> get props => [manifest, progress];
}

class CopticQuestProgressError extends CopticQuestProgressState {
  final String message;
  CopticQuestProgressError(this.message);
  @override
  List<Object?> get props => [message];
}

class CopticQuestProgressCubit extends Cubit<CopticQuestProgressState> {
  final ICopticQuestRepository _repository;

  CopticQuestProgressCubit(this._repository)
      : super(CopticQuestProgressInitial());

  Future<void> load() async {
    emit(CopticQuestProgressLoading());
    try {
      final manifest = await _repository.getManifest();
      final progress = await _repository.getProgress();
      emit(CopticQuestProgressLoaded(manifest: manifest, progress: progress));
    } catch (e) {
      emit(CopticQuestProgressError(e.toString()));
    }
  }

  Future<void> setTier(String tier) async {
    await _repository.setTier(tier);
    await load();
  }

  Future<void> setLessonLanguage(String lang) async {
    await _repository.setLessonLanguage(lang);
    await load();
  }
}
