import 'package:equatable/equatable.dart';

import 'localized_text.dart';

class PathLevelRef extends Equatable {
  final String id;
  final String file;
  final int order;
  final LocalizedText? title;

  const PathLevelRef({
    required this.id,
    required this.file,
    required this.order,
    this.title,
  });

  factory PathLevelRef.fromJson(Map<String, dynamic> json) {
    return PathLevelRef(
      id: json['id'] as String,
      file: json['file'] as String,
      order: json['order'] as int? ?? 0,
      title: json['title'] != null
          ? LocalizedText.fromJson(json['title'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, file, order, title];
}

class PathDefinition extends Equatable {
  final String id;
  final LocalizedText title;
  final LocalizedText description;
  final String icon;
  final bool enabled;
  final List<PathLevelRef> levels;

  const PathDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.enabled,
    required this.levels,
  });

  factory PathDefinition.fromJson(Map<String, dynamic> json) {
    return PathDefinition(
      id: json['id'] as String,
      title: LocalizedText.fromJson(json['title'] as Map<String, dynamic>),
      description:
          LocalizedText.fromJson(json['description'] as Map<String, dynamic>),
      icon: json['icon'] as String? ?? 'book',
      enabled: json['enabled'] as bool? ?? false,
      levels: (json['levels'] as List<dynamic>?)
              ?.map((e) => PathLevelRef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [id, title, description, icon, enabled, levels];
}

class CopticQuestManifest extends Equatable {
  final List<PathDefinition> paths;

  const CopticQuestManifest({required this.paths});

  factory CopticQuestManifest.fromJson(Map<String, dynamic> json) {
    return CopticQuestManifest(
      paths: (json['paths'] as List<dynamic>?)
              ?.map((e) => PathDefinition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  PathDefinition? pathById(String id) {
    try {
      return paths.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [paths];
}
