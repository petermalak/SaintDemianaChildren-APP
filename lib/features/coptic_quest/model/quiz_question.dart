import 'package:equatable/equatable.dart';

import 'localized_text.dart';

class QuizOption extends Equatable {
  final LocalizedText text;
  final String? image;

  const QuizOption({required this.text, this.image});

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      text: LocalizedText.fromJson(json['text'] as Map<String, dynamic>),
      image: json['image'] as String?,
    );
  }

  @override
  List<Object?> get props => [text, image];
}

class QuizQuestion extends Equatable {
  final LocalizedText question;
  final List<QuizOption> options;
  final int answerIndex;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.answerIndex,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: LocalizedText.fromJson(json['question'] as Map<String, dynamic>),
      options: (json['options'] as List<dynamic>)
          .map((e) => QuizOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      answerIndex: json['answerIndex'] as int,
    );
  }

  @override
  List<Object?> get props => [question, options, answerIndex];
}
