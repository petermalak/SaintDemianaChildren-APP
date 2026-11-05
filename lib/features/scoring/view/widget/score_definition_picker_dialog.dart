import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/scoring_models.dart';
import '../../viewmodel/score_definition_cubit/score_definition_cubit.dart';
import '../../viewmodel/score_definition_cubit/score_definition_state.dart';
import 'score_definition_form_dialog.dart';

class ScoreDefinitionPickerDialog extends StatefulWidget {
  final bool selectable;
  final String? initialSelectionId;
  final ScoringConfigModel? currentConfig;

  const ScoreDefinitionPickerDialog({
    super.key,
    this.selectable = true,
    this.initialSelectionId,
    this.currentConfig,
  });

  @override
  State<ScoreDefinitionPickerDialog> createState() =>
      _ScoreDefinitionPickerDialogState();
}

class _ScoreDefinitionPickerDialogState
    extends State<ScoreDefinitionPickerDialog> {
  String? _selectedDefinitionId;

  @override
  void initState() {
    super.initState();
    _selectedDefinitionId = widget.initialSelectionId;
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.selectable ? 'Assign score profile' : 'Manage score profiles';

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: BlocBuilder<ScoreDefinitionCubit, ScoreDefinitionState>(
          builder: (context, state) {
            final definitions = state.definitions;

            if (state.isLoading && definitions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (definitions.isEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'No score profiles found. Create one to get started.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _handleCreateDefinition,
                    icon: const Icon(Icons.add),
                    label: const Text('Create profile'),
                  ),
                ],
              );
            }

            return SizedBox(
              height: 360,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: definitions.length,
                      itemBuilder: (context, index) {
                        final definition = definitions[index];
                        final subtitle =
                            'Mass ${definition.massPoints} • General ${definition.generalMeetingPoints} • Special ${definition.specialMeetingPoints} • Praise ${definition.praisePoints}';

                        if (widget.selectable) {
                          return RadioListTile<String>(
                            value: definition.id,
                            groupValue: _selectedDefinitionId,
                            onChanged: (value) {
                              setState(() {
                                _selectedDefinitionId = value;
                              });
                            },
                            title: Text(definition.name),
                            subtitle: Text(subtitle),
                            secondary: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _handleEditDefinition(definition),
                            ),
                          );
                        } else {
                          return ListTile(
                            title: Text(definition.name),
                            subtitle: Text(subtitle),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _handleEditDefinition(definition),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: OutlinedButton.icon(
                      onPressed: _handleCreateDefinition,
                      icon: const Icon(Icons.add),
                      label: const Text('Create new profile'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Close'),
        ),
        if (widget.selectable)
          ElevatedButton(
            onPressed: _selectedDefinitionId == null ? null : _confirmSelection,
            child: const Text('Assign'),
          ),
      ],
    );
  }

  Future<void> _handleCreateDefinition() async {
    final cubit = context.read<ScoreDefinitionCubit>();
    final defaults = widget.currentConfig == null
        ? null
        : {
            'mass': widget.currentConfig!.massPoints,
            'generalMeeting': widget.currentConfig!.generalMeetingPoints,
            'specialMeeting': widget.currentConfig!.specialMeetingPoints,
            'praise': widget.currentConfig!.praisePoints,
          };

    final created = await showDialog<ScoreDefinitionModel?>(
      context: context,
      builder: (context) => BlocProvider.value(
        value: cubit,
        child: ScoreDefinitionFormDialog(
          attendanceDefaults: defaults,
        ),
      ),
    );

    if (created != null && mounted && widget.selectable) {
      setState(() {
        _selectedDefinitionId = created.id;
      });
    }
  }

  Future<void> _handleEditDefinition(ScoreDefinitionModel definition) async {
    final cubit = context.read<ScoreDefinitionCubit>();
    final updated = await showDialog<ScoreDefinitionModel?>(
      context: context,
      builder: (context) => BlocProvider.value(
        value: cubit,
        child: ScoreDefinitionFormDialog(definition: definition),
      ),
    );

    if (updated != null && mounted && widget.selectable) {
      setState(() {
        // Keep current selection if editing the selected item
        if (_selectedDefinitionId == null ||
            _selectedDefinitionId == updated.id) {
          _selectedDefinitionId = updated.id;
        }
      });
    }
  }

  void _confirmSelection() {
    Navigator.of(context).pop(_selectedDefinitionId);
  }
}
