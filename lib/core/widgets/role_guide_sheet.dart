import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

import '../constants/app_colors.dart';
import '../guide/app_guide.dart';

const String _guideBox = 'userBox';

bool guideWasSeen(String userId) {
  if (!Hive.isBoxOpen(_guideBox)) return false;
  return Hive.box(_guideBox).get('guide_seen_v2_$userId') == true;
}

Future<void> markGuideSeen(String userId) async {
  if (!Hive.isBoxOpen(_guideBox)) return;
  await Hive.box(_guideBox).put('guide_seen_v2_$userId', true);
}

class GuideButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GuideButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'دليل الاستخدام',
      onPressed: onPressed,
      icon: const Icon(Icons.help_outline, color: AppColors.accentWhite),
    );
  }
}

void showRoleGuide(BuildContext context, List<GuideTopic> topics, {bool firstLogin = false}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundPrimary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _RoleGuideSheet(topics: topics, firstLogin: firstLogin),
  );
}

class _RoleGuideSheet extends StatefulWidget {
  final List<GuideTopic> topics;
  final bool firstLogin;

  const _RoleGuideSheet({required this.topics, this.firstLogin = false});

  @override
  State<_RoleGuideSheet> createState() => _RoleGuideSheetState();
}

class _RoleGuideSheetState extends State<_RoleGuideSheet> {
  int? _open;

  @override
  void initState() {
    super.initState();
    if (widget.firstLogin && widget.topics.isNotEmpty) _open = 0;
  }

  @override
  Widget build(BuildContext context) {
    final topic = _open == null ? null : widget.topics[_open!];
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.86,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primaryMaroon.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  if (topic != null)
                    IconButton(
                      tooltip: 'المواضيع',
                      onPressed: () => setState(() => _open = null),
                      icon: const Icon(Icons.arrow_forward, color: AppColors.primaryMaroon),
                    )
                  else
                    const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      topic?.title ?? 'دليل الاستخدام',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: topic == null ? _topics() : _walkthrough(topic),
            ),
            if (widget.firstLogin) _nextButton(),
          ],
        ),
      ),
    );
  }

  Widget _nextButton() {
    final last = _open != null && _open! + 1 >= widget.topics.length;
    final label = _open == null ? 'ابدأ' : (last ? 'تمام' : 'التالي');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryMaroon,
            foregroundColor: AppColors.accentWhite,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () {
            if (_open == null) {
              setState(() => _open = 0);
              return;
            }
            if (last) {
              Navigator.of(context).pop();
              return;
            }
            setState(() => _open = _open! + 1);
          },
          child: Text(label),
        ),
      ),
    );
  }

  Widget _topics() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: widget.topics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final topic = widget.topics[index];
        return Material(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            title: Text(topic.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(topic.summary),
            trailing: const Icon(Icons.chevron_left, color: AppColors.primaryMaroon),
            onTap: () => setState(() => _open = index),
          ),
        );
      },
    );
  }

  Widget _walkthrough(GuideTopic topic) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        if (widget.firstLogin && _open == 0)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'أول دخول للحساب. امشِ على الخطوات، وبعدين التالي لباقي المواضيع.',
              style: TextStyle(height: 1.4, fontWeight: FontWeight.w600),
            ),
          ),
        Text(topic.summary, style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
        const SizedBox(height: 16),
        for (var index = 0; index < topic.steps.length; index++) ...[
          _step(index + 1, topic.steps[index]),
          const SizedBox(height: 10),
        ],
        if (topic.boundary != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryMaroon.withValues(alpha: 0.25)),
            ),
            child: Text(topic.boundary!, style: const TextStyle(height: 1.4)),
          ),
        ],
      ],
    );
  }

  Widget _step(int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.primaryMaroon,
          child: Text('$number', style: const TextStyle(color: AppColors.accentWhite, fontSize: 13)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
      ],
    );
  }
}
