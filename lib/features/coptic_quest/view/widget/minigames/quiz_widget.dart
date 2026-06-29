import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/quest_scoring.dart';
import '../../../model/quiz_question.dart';
import '../../../theme/coptic_quest_colors.dart';
import '../../../theme/level_visuals.dart';
import '../guide_character.dart';

class QuizWidget extends StatefulWidget {
  final List<QuizQuestion> questions;
  final String lang;
  final String tier;
  final int currentIndex;
  final int currentCombo;
  final String progressLabel;
  final String correctLabel;
  final String wrongLabel;
  final void Function(bool correct) onAnswered;

  const QuizWidget({
    super.key,
    required this.questions,
    required this.lang,
    required this.tier,
    required this.currentIndex,
    this.currentCombo = 0,
    required this.progressLabel,
    required this.correctLabel,
    required this.wrongLabel,
    required this.onAnswered,
  });

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  bool? _wasCorrect;
  bool _showFeedback = false;
  late final AnimationController _timerController;

  int get _maxOptions {
    if (widget.tier == 'T1') return 2;
    return 4;
  }

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..forward();
  }

  @override
  void didUpdateWidget(QuizWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _selectedIndex = null;
      _wasCorrect = null;
      _showFeedback = false;
      _timerController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (_showFeedback) return;
    _timerController.stop();
    final q = widget.questions[widget.currentIndex];
    final correct = index == q.answerIndex;
    setState(() {
      _selectedIndex = index;
      _wasCorrect = correct;
      _showFeedback = true;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) widget.onAnswered(correct);
    });
  }

  static const _optionLetters = ['أ', 'ب', 'ج', 'د'];

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: cqPrimaryButton(
          label: widget.correctLabel,
          onPressed: () => widget.onAnswered(true),
        ),
      );
    }

    final q = widget.questions[widget.currentIndex];
    final options = q.options.take(_maxOptions).toList();
    final isRtl = widget.lang == 'ar';
    final progress = (widget.currentIndex + 1) / widget.questions.length;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      color: CopticQuestColors.funGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${widget.currentIndex + 1}/${widget.questions.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _timerController,
              builder: (context, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 1 - _timerController.value,
                    minHeight: 4,
                    backgroundColor: Colors.transparent,
                    color: CopticQuestColors.funOrange.withValues(alpha: 0.7),
                  ),
                );
              },
            ),
            if (widget.currentCombo >= 2) ...[
              const SizedBox(height: 10),
              Text(
                QuestScoring.comboLabel(widget.currentCombo, widget.lang),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                ),
              ).animate().scale(curve: Curves.elasticOut),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: CopticQuestColors.cardDecoration(),
              child: Text(
                q.question.forLang(widget.lang),
                style: const TextStyle(
                  color: CopticQuestColors.textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ).animate(key: ValueKey(widget.currentIndex)).fadeIn().slideY(begin: 0.1),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final opt = options[index];
                  final optionColor = LevelVisuals
                      .optionColors[index % LevelVisuals.optionColors.length];

                  Color bg = optionColor.withValues(alpha: 0.15);
                  Color border = optionColor.withValues(alpha: 0.4);
                  if (_showFeedback && _selectedIndex == index) {
                    bg = _wasCorrect == true
                        ? CopticQuestColors.funGreen.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.25);
                    border = _wasCorrect == true
                        ? CopticQuestColors.funGreen
                        : Colors.redAccent;
                  } else if (_showFeedback && index == q.answerIndex) {
                    bg = CopticQuestColors.funGreen.withValues(alpha: 0.2);
                    border = CopticQuestColors.funGreen;
                  }

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _select(index),
                      borderRadius: BorderRadius.circular(20),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: border, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: optionColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    widget.lang == 'ar'
                                        ? _optionLetters[index]
                                        : String.fromCharCode(65 + index),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  opt.text.forLang(widget.lang),
                                  style: const TextStyle(
                                    color: CopticQuestColors.textDark,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate(delay: (80 * index).ms)
                      .fadeIn()
                      .slideX(begin: 0.1, curve: Curves.easeOutCubic);
                },
              ),
            ),
            if (_showFeedback)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _wasCorrect == true ? '🎉' : '💪',
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _wasCorrect == true
                          ? widget.correctLabel
                          : widget.wrongLabel,
                      style: TextStyle(
                        color: _wasCorrect == true
                            ? CopticQuestColors.funGreen
                            : Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ).animate().scale(curve: Curves.elasticOut),
          ],
        ),
      ),
    );
  }
}
