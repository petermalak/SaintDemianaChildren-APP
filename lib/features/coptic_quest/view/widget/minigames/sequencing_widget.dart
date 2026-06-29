import 'package:flutter/material.dart';

import '../../../model/minigame_config.dart';
import '../../../theme/coptic_quest_colors.dart';
import '../../../theme/level_visuals.dart';
import '../guide_character.dart';

class SequencingWidget extends StatefulWidget {
  final List<SequenceItem> items;
  final String lang;
  final String title;
  final String continueLabel;
  final String wrongLabel;
  final VoidCallback onComplete;

  const SequencingWidget({
    super.key,
    required this.items,
    required this.lang,
    required this.title,
    required this.continueLabel,
    required this.wrongLabel,
    required this.onComplete,
  });

  @override
  State<SequencingWidget> createState() => _SequencingWidgetState();
}

class _SequencingWidgetState extends State<SequencingWidget> {
  late List<int> _order;
  bool _checking = false;
  bool? _correct;

  @override
  void initState() {
    super.initState();
    _order = List.generate(widget.items.length, (i) => i)..shuffle();
  }

  void _check() {
    final correct = List.generate(widget.items.length, (i) => i);
    final isCorrect = _listEquals(_order, correct);
    setState(() {
      _checking = true;
      _correct = isCorrect;
    });
    if (isCorrect) {
      Future.delayed(const Duration(milliseconds: 600), widget.onComplete);
    } else {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _checking = false;
            _correct = null;
          });
        }
      });
    }
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: cqPrimaryButton(label: widget.continueLabel, onPressed: widget.onComplete),
      );
    }

    final isRtl = widget.lang == 'ar';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '📋 ${widget.title}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                cqStr('dragHint', widget.lang),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _order.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _order.removeAt(oldIndex);
                    _order.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, displayIndex) {
                  final itemIndex = _order[displayIndex];
                  final item = widget.items[itemIndex];
                  final color = LevelVisuals.optionColors[
                      displayIndex % LevelVisuals.optionColors.length];

                  return Container(
                    key: ValueKey('seq_$itemIndex'),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: CopticQuestColors.cardDecoration().copyWith(
                      border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        radius: 18,
                        child: Text(
                          '${displayIndex + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        item.text.forLang(widget.lang),
                        style: const TextStyle(
                          color: CopticQuestColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(Icons.drag_indicator_rounded, color: color),
                    ),
                  );
                },
              ),
            ),
            if (_checking && _correct == false)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('💪', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      widget.wrongLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ),
            cqPrimaryButton(
              label: widget.continueLabel,
              onPressed: _check,
            ),
          ],
        ),
      ),
    );
  }
}
