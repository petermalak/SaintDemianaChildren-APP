import 'package:equatable/equatable.dart';

import 'localized_text.dart';
import 'minigame_config.dart';
import 'quiz_question.dart';

class StorySlide extends Equatable {
  final String? image;
  final LocalizedText text;
  final Map<String, String> audio;

  const StorySlide({
    this.image,
    required this.text,
    this.audio = const {},
  });

  factory StorySlide.fromJson(Map<String, dynamic> json) {
    final audioRaw = json['audio'];
    final audio = <String, String>{};
    if (audioRaw is Map) {
      audioRaw.forEach((key, value) {
        if (value is String) audio[key.toString()] = value;
      });
    }
    return StorySlide(
      image: json['image'] as String?,
      text: LocalizedText.fromJson(json['text'] as Map<String, dynamic>),
      audio: audio,
    );
  }

  String? audioForLang(String lang) => audio[lang] ?? audio['en'];

  @override
  List<Object?> get props => [image, text, audio];
}

class TierContent extends Equatable {
  final List<StorySlide> slides;

  const TierContent({required this.slides});

  factory TierContent.fromJson(Map<String, dynamic> json) {
    return TierContent(
      slides: (json['slides'] as List<dynamic>?)
              ?.map((e) => StorySlide.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [slides];
}

class LessonRewards extends Equatable {
  final List<double> starThresholds;
  final String? stickerId;

  const LessonRewards({
    required this.starThresholds,
    this.stickerId,
  });

  factory LessonRewards.fromJson(Map<String, dynamic> json) {
    return LessonRewards(
      starThresholds: (json['starThresholds'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [0.5, 0.75, 1.0],
      stickerId: json['stickerId'] as String?,
    );
  }

  int starsForScore(double score) {
    var stars = 0;
    for (final threshold in starThresholds) {
      if (score >= threshold) stars++;
    }
    return stars.clamp(0, 3);
  }

  @override
  List<Object?> get props => [starThresholds, stickerId];
}

class LessonModel extends Equatable {
  final String id;
  final String path;
  final int order;
  final LocalizedText title;
  final LocalizedText hook;
  final Map<String, TierContent> tiers;
  final PracticeConfig practice;
  final List<QuizQuestion> quiz;
  final LessonRewards rewards;

  const LessonModel({
    required this.id,
    required this.path,
    required this.order,
    required this.title,
    required this.hook,
    required this.tiers,
    required this.practice,
    required this.quiz,
    required this.rewards,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    final tiersRaw = json['tiers'] as Map<String, dynamic>? ?? {};
    final tiers = <String, TierContent>{};
    tiersRaw.forEach((key, value) {
      tiers[key] = TierContent.fromJson(value as Map<String, dynamic>);
    });

    return LessonModel(
      id: json['id'] as String,
      path: json['path'] as String,
      order: json['order'] as int? ?? 0,
      title: LocalizedText.fromJson(json['title'] as Map<String, dynamic>),
      hook: LocalizedText.fromJson(json['hook'] as Map<String, dynamic>),
      tiers: tiers,
      practice: PracticeConfig.fromJson(
        json['practice'] as Map<String, dynamic>? ?? {},
      ),
      quiz: (json['quiz'] as List<dynamic>?)
              ?.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      rewards: LessonRewards.fromJson(
        json['rewards'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  TierContent tierContent(String tier) {
    return tiers[tier] ?? tiers['T1'] ?? const TierContent(slides: []);
  }

  @override
  List<Object?> get props =>
      [id, path, order, title, hook, tiers, practice, quiz, rewards];
}
