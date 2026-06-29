import 'dart:math' as math;

import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  final bool active;

  const ConfettiOverlay({super.key, required this.active});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(24, _Particle.random);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    if (widget.active) {
      _controller.forward().whenComplete(() {
        if (mounted) setState(() => _finished = true);
      });
    }
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _finished = false;
      _controller.forward(from: 0).whenComplete(() {
        if (mounted) setState(() => _finished = true);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || _finished) return const SizedBox.shrink();

    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _controller.value,
                  ),
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Particle {
  final double x;
  final double speed;
  final double wobble;
  final Color color;
  final double size;

  const _Particle({
    required this.x,
    required this.speed,
    required this.wobble,
    required this.color,
    required this.size,
  });

  static _Particle random(int i) {
    const colors = [
      Color(0xFFFFD54F),
      Color(0xFFFF7043),
      Color(0xFF58CC02),
      Color(0xFF5C6BC0),
      Color(0xFFFF6B9D),
      Color(0xFF26C6DA),
    ];
    return _Particle(
      x: (i * 0.13) % 1.0,
      speed: 0.5 + (i % 5) * 0.1,
      wobble: i * 0.7,
      color: colors[i % colors.length],
      size: 6 + (i % 4) * 2.0,
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    for (final p in particles) {
      final y = progress * size.height * p.speed;
      final x =
          (p.x * size.width) + math.sin(progress * 8 + p.wobble) * 20;
      final paint = Paint()
        ..color = p.color.withValues(alpha: (1 - progress * 0.7).clamp(0.0, 1.0));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, y),
            width: p.size,
            height: p.size * 0.6,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
