import 'dart:convert';

import 'package:flutter/services.dart';

import '../model/lesson_model.dart';
import '../model/path_model.dart';

class LessonContentLoader {
  static const String manifestPath = 'assets/coptic_quest/manifest.json';
  static const String assetPrefix = 'assets/coptic_quest/';

  CopticQuestManifest? _cachedManifest;

  Future<CopticQuestManifest> loadManifest() async {
    if (_cachedManifest != null) return _cachedManifest!;
    final raw = await rootBundle.loadString(manifestPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cachedManifest = CopticQuestManifest.fromJson(json);
    return _cachedManifest!;
  }

  Future<LessonModel> loadLesson(String file) async {
    final path = file.startsWith('assets/') ? file : '$assetPrefix$file';
    final raw = await rootBundle.loadString(path);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return LessonModel.fromJson(json);
  }

  Future<LessonModel> loadLessonById(
    CopticQuestManifest manifest,
    String pathId,
    String levelId,
  ) async {
    final path = manifest.pathById(pathId);
    if (path == null) {
      throw StateError('Path not found: $pathId');
    }
    final ref = path.levels.firstWhere(
      (l) => l.id == levelId,
      orElse: () => throw StateError('Level not found: $levelId'),
    );
    return loadLesson(ref.file);
  }

  void clearCache() => _cachedManifest = null;
}
