import 'package:flutter/material.dart';

import '../../coptic_quest_strings.dart';
import '../../theme/coptic_quest_colors.dart';

class GuideCharacter extends StatefulWidget {
  final String message;
  final String lang;
  final bool excited;

  const GuideCharacter({
    super.key,
    required this.message,
    required this.lang,
    this.excited = false,
  });

  @override
  State<GuideCharacter> createState() => _GuideCharacterState();
}

class _GuideCharacterState extends State<GuideCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.lang == 'ar';
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedBuilder(
            animation: _bounce,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounce.value * 6),
                child: child,
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFD54F), Color(0xFFFF9F43)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: CopticQuestColors.funOrange.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.excited ? '🎉' : '🕊️',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: CopticQuestColors.cardDecoration().copyWith(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: CopticQuestColors.textDark,
                  fontSize: 18,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CopticQuestScaffold extends StatelessWidget {
  final String title;
  final String lang;
  final Widget body;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final Widget? header;

  const CopticQuestScaffold({
    super.key,
    required this.title,
    required this.lang,
    required this.body,
    this.actions,
    this.onBack,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: CopticQuestColors.theme(context),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: CopticQuestColors.backgroundGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: onBack ?? () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (actions != null) ...actions!,
                      if (actions == null) const SizedBox(width: 48),
                    ],
                  ),
                ),
                if (header != null) header!,
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget cqPrimaryButton({
  required String label,
  required VoidCallback onPressed,
  bool enabled = true,
}) {
  return SizedBox(
    width: double.infinity,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? CopticQuestColors.buttonGradient : null,
        color: enabled ? null : CopticQuestColors.textMuted,
        borderRadius: BorderRadius.circular(24),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: CopticQuestColors.funOrange.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: CopticQuestColors.textDark,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.white70,
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    ),
  );
}

String cqStr(String key, String lang) => CopticQuestStrings.get(key, lang);
