import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../model/localized_text.dart';
import '../../../model/minigame_config.dart';
import '../../../theme/coptic_quest_colors.dart';
import '../guide_character.dart';

class MatchingPairs extends StatefulWidget {
  final List<MatchingPair> pairs;
  final String lang;
  final String title;
  final String continueLabel;
  final VoidCallback onComplete;

  const MatchingPairs({
    super.key,
    required this.pairs,
    required this.lang,
    required this.title,
    required this.continueLabel,
    required this.onComplete,
  });

  @override
  State<MatchingPairs> createState() => _MatchingPairsState();
}

class _MatchingPairsState extends State<MatchingPairs>
    with SingleTickerProviderStateMixin {
  String? _selectedLeft;
  final Set<String> _matched = {};
  String? _lastMatchedId;
  late final AnimationController _shake;
  bool _shaking = false;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _wrongMatch() async {
    setState(() => _shaking = true);
    await _shake.forward(from: 0);
    if (mounted) setState(() => _shaking = false);
  }

  void _tapLeft(String id) {
    if (_matched.contains(id)) return;
    setState(() => _selectedLeft = id);
  }

  void _tapRight(String rightId, String leftId) {
    if (_matched.contains(leftId)) return;
    if (_selectedLeft == null) return;

    if (_selectedLeft == leftId) {
      setState(() {
        _matched.add(leftId);
        _selectedLeft = null;
        _lastMatchedId = leftId;
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _lastMatchedId = null);
      });
      if (_matched.length == widget.pairs.length) {
        Future.delayed(const Duration(milliseconds: 600), widget.onComplete);
      }
    } else {
      setState(() => _selectedLeft = null);
      _wrongMatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pairs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: cqPrimaryButton(label: widget.continueLabel, onPressed: widget.onComplete),
      );
    }

    final isRtl = widget.lang == 'ar';
    final rights = widget.pairs
        .asMap()
        .entries
        .map((e) => _RightEntry(e.key, e.value.right))
        .toList()
      ..shuffle(Random());

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '🎯 ${widget.title}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_matched.length}/${widget.pairs.length} ✓',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedBuilder(
                animation: _shake,
                builder: (context, child) {
                  final offset = _shaking
                      ? sin(_shake.value * pi * 6) * 8
                      : 0.0;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.pairs.length,
                        itemBuilder: (context, i) {
                          final pair = widget.pairs[i];
                          final id = 'left_$i';
                          return _MatchTile(
                            label: pair.left.forLang(widget.lang),
                            matched: _matched.contains(id),
                            justMatched: _lastMatchedId == id,
                            selected: _selectedLeft == id,
                            colorIndex: i,
                            onTap: () => _tapLeft(id),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: rights.length,
                        itemBuilder: (context, i) {
                          final entry = rights[i];
                          final leftId = 'left_${entry.pairIndex}';
                          return _MatchTile(
                            label: entry.text.forLang(widget.lang),
                            matched: _matched.contains(leftId),
                            justMatched: _lastMatchedId == leftId,
                            selected: false,
                            colorIndex: entry.pairIndex + 2,
                            onTap: () => _tapRight('right_$i', leftId),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final String label;
  final bool matched;
  final bool justMatched;
  final bool selected;
  final int colorIndex;
  final VoidCallback onTap;

  const _MatchTile({
    required this.label,
    required this.matched,
    this.justMatched = false,
    required this.selected,
    required this.colorIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF5C6BC0),
      const Color(0xFF26A69A),
      const Color(0xFFFF7043),
      const Color(0xFFAB47BC),
    ];
    final accent = colors[colorIndex % colors.length];

    Widget tile = Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: matched ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: matched
                  ? CopticQuestColors.funGreen.withValues(alpha: 0.25)
                  : selected
                      ? accent.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: matched
                    ? CopticQuestColors.funGreen
                    : selected
                        ? accent
                        : Colors.white.withValues(alpha: 0.5),
                width: matched || selected ? 2.5 : 1.5,
              ),
              boxShadow: matched
                  ? [
                      BoxShadow(
                        color: CopticQuestColors.funGreen.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                if (matched)
                  const Text('✅', style: TextStyle(fontSize: 18))
                else if (selected)
                  Text('👆', style: TextStyle(fontSize: 16, color: accent)),
                if (matched || selected) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: matched
                          ? CopticQuestColors.funGreen
                          : CopticQuestColors.textDark,
                      fontWeight: selected || matched
                          ? FontWeight.bold
                          : FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (justMatched) {
      return tile
          .animate()
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.08, 1.08),
            duration: 200.ms,
          )
          .then()
          .scale(end: const Offset(1, 1), duration: 200.ms);
    }
    return tile;
  }
}

class _RightEntry {
  final int pairIndex;
  final LocalizedText text;
  _RightEntry(this.pairIndex, this.text);
}
