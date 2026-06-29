import 'package:flutter/material.dart';

import '../../../model/minigame_config.dart';
import 'matching_pairs.dart';
import 'sequencing_widget.dart';

class PracticeMinigameDispatcher extends StatelessWidget {
  final PracticeConfig config;
  final String lang;
  final String matchTitle;
  final String sequenceTitle;
  final String continueLabel;
  final String wrongLabel;
  final VoidCallback onComplete;

  const PracticeMinigameDispatcher({
    super.key,
    required this.config,
    required this.lang,
    required this.matchTitle,
    required this.sequenceTitle,
    required this.continueLabel,
    required this.wrongLabel,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    switch (config.type) {
      case 'sequence':
        return SequencingWidget(
          items: config.sequenceItems,
          lang: lang,
          title: sequenceTitle,
          continueLabel: continueLabel,
          wrongLabel: wrongLabel,
          onComplete: onComplete,
        );
      case 'matching':
      default:
        return MatchingPairs(
          pairs: config.pairs,
          lang: lang,
          title: matchTitle,
          continueLabel: continueLabel,
          onComplete: onComplete,
        );
    }
  }
}
