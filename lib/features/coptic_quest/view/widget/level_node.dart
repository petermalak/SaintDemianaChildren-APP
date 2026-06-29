import 'package:flutter/material.dart';

import '../../theme/coptic_quest_colors.dart';
import '../../theme/level_visuals.dart';

class LevelNode extends StatefulWidget {
  final String levelId;
  final String title;
  final int stars;
  final bool unlocked;
  final bool completed;
  final String lockedLabel;
  final VoidCallback? onTap;

  const LevelNode({
    super.key,
    required this.levelId,
    required this.title,
    required this.stars,
    required this.unlocked,
    required this.completed,
    required this.lockedLabel,
    this.onTap,
  });

  @override
  State<LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<LevelNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.unlocked && !widget.completed) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LevelNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.unlocked && !widget.completed) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = LevelVisuals.levelGradient(widget.levelId);
    final emoji = LevelVisuals.levelEmoji(widget.levelId);
    final scale = widget.unlocked && !widget.completed
        ? 1.0 + _pulse.value * 0.08
        : 1.0;

    return GestureDetector(
      onTap: widget.unlocked ? widget.onTap : null,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.unlocked
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradient,
                      )
                    : null,
                color: widget.unlocked ? null : Colors.white.withValues(alpha: 0.3),
                border: Border.all(
                  color: widget.completed
                      ? CopticQuestColors.funGreen
                      : widget.unlocked
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                  width: 3,
                ),
                boxShadow: widget.unlocked
                    ? [
                        BoxShadow(
                          color: gradient.first.withValues(alpha: 0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: widget.unlocked
                    ? Text(emoji, style: const TextStyle(fontSize: 36))
                    : const Icon(Icons.lock_rounded, color: Colors.white70, size: 32),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: widget.unlocked ? 0.9 : 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: widget.unlocked
                    ? CopticQuestColors.textDark
                    : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (!widget.unlocked)
            Text(
              widget.lockedLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Text(
                  i < widget.stars ? '⭐' : '☆',
                  style: TextStyle(
                    fontSize: 16,
                    color: i < widget.stars
                        ? CopticQuestColors.accentGold
                        : Colors.white54,
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

/// Dotted trail connector between level nodes on the path map.
class PathTrail extends StatelessWidget {
  final bool completed;

  const PathTrail({super.key, this.completed = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: List.generate(4, (i) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed
                  ? CopticQuestColors.funGreen.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.5),
            ),
          );
        }),
      ),
    );
  }
}
