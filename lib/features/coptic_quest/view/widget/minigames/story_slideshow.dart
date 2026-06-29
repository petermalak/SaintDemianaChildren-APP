import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../model/lesson_model.dart';
import '../../../theme/coptic_quest_colors.dart';
import '../../../theme/level_visuals.dart';
import '../guide_character.dart';

class StorySlideshow extends StatefulWidget {
  final List<StorySlide> slides;
  final String lang;
  final String levelId;
  final String nextLabel;
  final String finishLabel;
  final VoidCallback onComplete;
  final VoidCallback onNext;

  const StorySlideshow({
    super.key,
    required this.slides,
    required this.lang,
    required this.levelId,
    required this.nextLabel,
    required this.finishLabel,
    required this.onComplete,
    required this.onNext,
  });

  @override
  State<StorySlideshow> createState() => _StorySlideshowState();
}

class _StorySlideshowState extends State<StorySlideshow> {
  final AudioPlayer _player = AudioPlayer();
  int _index = 0;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String? assetPath) async {
    if (assetPath == null || assetPath.isEmpty) return;
    try {
      final fullPath = assetPath.startsWith('assets/')
          ? assetPath
          : 'assets/coptic_quest/$assetPath';
      await _player.setAsset(fullPath);
      await _player.play();
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.slides.isNotEmpty) {
        _playAudio(widget.slides[0].audioForLang(widget.lang));
      }
    });
  }

  void _goNext() {
    if (_index < widget.slides.length - 1) {
      setState(() => _index++);
      _playAudio(widget.slides[_index].audioForLang(widget.lang));
      widget.onNext();
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: cqPrimaryButton(
          label: widget.finishLabel,
          onPressed: widget.onComplete,
        ),
      );
    }

    final slide = widget.slides[_index];
    final isRtl = widget.lang == 'ar';
    final isLast = _index >= widget.slides.length - 1;
    final emoji = LevelVisuals.slideEmoji(widget.levelId, _index);
    final gradient = LevelVisuals.levelGradient(widget.levelId);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.15, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
                  );
                },
                child: SingleChildScrollView(
                  key: ValueKey(_index),
                  child: Column(
                    children: [
                      if (slide.image != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            slide.image!.startsWith('assets/')
                                ? slide.image!
                                : 'assets/coptic_quest/${slide.image}',
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _IllustrationCard(emoji: emoji, gradient: gradient),
                          ),
                        )
                      else
                        _IllustrationCard(emoji: emoji, gradient: gradient),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: CopticQuestColors.cardDecoration(),
                        child: Text(
                          slide.text.forLang(widget.lang),
                          style: const TextStyle(
                            color: CopticQuestColors.textDark,
                            fontSize: 20,
                            height: 1.6,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.slides.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: active
                        ? CopticQuestColors.funOrange
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            cqPrimaryButton(
              label: isLast ? widget.finishLabel : widget.nextLabel,
              onPressed: _goNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _IllustrationCard extends StatelessWidget {
  final String emoji;
  final List<Color> gradient;

  const _IllustrationCard({
    required this.emoji,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 16,
            right: 24,
            child: Text('✨', style: TextStyle(fontSize: 28, color: Colors.white.withValues(alpha: 0.6))),
          ),
          Positioned(
            bottom: 20,
            left: 24,
            child: Text('🌟', style: TextStyle(fontSize: 24, color: Colors.white.withValues(alpha: 0.5))),
          ),
          Text(emoji, style: const TextStyle(fontSize: 88)),
        ],
      ),
    );
  }
}
