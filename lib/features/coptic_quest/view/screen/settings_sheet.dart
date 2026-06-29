import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../coptic_quest_strings.dart';
import '../../theme/coptic_quest_colors.dart';
import '../../viewmodel/coptic_quest_progress_cubit/coptic_quest_progress_cubit.dart';

void showCopticQuestSettings(BuildContext context, String lang) {
  showModalBottomSheet(
    context: context,
    backgroundColor: CopticQuestColors.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return BlocProvider.value(
        value: context.read<CopticQuestProgressCubit>(),
        child: _SettingsSheet(lang: lang),
      );
    },
  );
}

class _SettingsSheet extends StatelessWidget {
  final String lang;

  const _SettingsSheet({required this.lang});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CopticQuestProgressCubit, CopticQuestProgressState>(
      builder: (context, state) {
        final currentLang = state is CopticQuestProgressLoaded
            ? state.progress.lessonLanguage
            : lang;
        final currentTier =
            state is CopticQuestProgressLoaded ? state.progress.tier : 'T1';

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                CopticQuestStrings.get('settings', currentLang),
                style: const TextStyle(
                  color: CopticQuestColors.accentGold,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                CopticQuestStrings.get('lessonLanguage', currentLang),
                style: const TextStyle(color: CopticQuestColors.paleSlate),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _LangChip(
                      label: CopticQuestStrings.get('arabic', currentLang),
                      selected: currentLang == 'ar',
                      onTap: () => context
                          .read<CopticQuestProgressCubit>()
                          .setLessonLanguage('ar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _LangChip(
                      label: CopticQuestStrings.get('english', currentLang),
                      selected: currentLang == 'en',
                      onTap: () => context
                          .read<CopticQuestProgressCubit>()
                          .setLessonLanguage('en'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                CopticQuestStrings.get('tier', currentLang),
                style: const TextStyle(color: CopticQuestColors.paleSlate),
              ),
              const SizedBox(height: 8),
              _TierOption(
                label: CopticQuestStrings.get('tier1', currentLang),
                value: 'T1',
                group: currentTier,
                onSelect: (v) =>
                    context.read<CopticQuestProgressCubit>().setTier(v),
              ),
              _TierOption(
                label: CopticQuestStrings.get('tier2', currentLang),
                value: 'T2',
                group: currentTier,
                onSelect: (v) =>
                    context.read<CopticQuestProgressCubit>().setTier(v),
              ),
              _TierOption(
                label: CopticQuestStrings.get('tier3', currentLang),
                value: 'T3',
                group: currentTier,
                onSelect: (v) =>
                    context.read<CopticQuestProgressCubit>().setTier(v),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? CopticQuestColors.accentGold.withValues(alpha: 0.25)
          : CopticQuestColors.deepMocha,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? CopticQuestColors.accentGold
                  : CopticQuestColors.paleSlate,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _TierOption extends StatelessWidget {
  final String label;
  final String value;
  final String group;
  final ValueChanged<String> onSelect;

  const _TierOption({
    required this.label,
    required this.value,
    required this.group,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == group;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? CopticQuestColors.accentGold : CopticQuestColors.dimGrey,
      ),
      title: Text(label, style: const TextStyle(color: CopticQuestColors.paleSlate)),
      onTap: () => onSelect(value),
    );
  }
}
