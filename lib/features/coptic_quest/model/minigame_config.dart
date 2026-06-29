import 'package:equatable/equatable.dart';

import 'localized_text.dart';

class MatchingPair extends Equatable {
  final LocalizedText left;
  final LocalizedText right;
  final String? leftImage;
  final String? rightImage;

  const MatchingPair({
    required this.left,
    required this.right,
    this.leftImage,
    this.rightImage,
  });

  factory MatchingPair.fromJson(Map<String, dynamic> json) {
    return MatchingPair(
      left: LocalizedText.fromJson(json['left'] as Map<String, dynamic>),
      right: LocalizedText.fromJson(json['right'] as Map<String, dynamic>),
      leftImage: json['leftImage'] as String?,
      rightImage: json['rightImage'] as String?,
    );
  }

  @override
  List<Object?> get props => [left, right, leftImage, rightImage];
}

class SequenceItem extends Equatable {
  final LocalizedText text;
  final String? image;

  const SequenceItem({required this.text, this.image});

  factory SequenceItem.fromJson(Map<String, dynamic> json) {
    return SequenceItem(
      text: LocalizedText.fromJson(json['text'] as Map<String, dynamic>),
      image: json['image'] as String?,
    );
  }

  @override
  List<Object?> get props => [text, image];
}

class PracticeConfig extends Equatable {
  final String type;
  final List<MatchingPair> pairs;
  final List<SequenceItem> sequenceItems;

  const PracticeConfig({
    required this.type,
    this.pairs = const [],
    this.sequenceItems = const [],
  });

  factory PracticeConfig.fromJson(Map<String, dynamic> json) {
    return PracticeConfig(
      type: json['type'] as String? ?? 'matching',
      pairs: (json['pairs'] as List<dynamic>?)
              ?.map((e) => MatchingPair.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sequenceItems: (json['items'] as List<dynamic>?)
              ?.map((e) => SequenceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [type, pairs, sequenceItems];
}
