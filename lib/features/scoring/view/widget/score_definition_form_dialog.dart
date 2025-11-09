import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/scoring_models.dart';
import '../../viewmodel/score_definition_cubit/score_definition_cubit.dart';

class ScoreDefinitionFormDialog extends StatefulWidget {
  final ScoreDefinitionModel? definition;
  final Map<String, int>? attendanceDefaults;

  const ScoreDefinitionFormDialog({
    super.key,
    this.definition,
    this.attendanceDefaults,
  });

  @override
  State<ScoreDefinitionFormDialog> createState() =>
      _ScoreDefinitionFormDialogState();
}

class _ScoreDefinitionFormDialogState extends State<ScoreDefinitionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _massPointsController;
  late final TextEditingController _generalPointsController;
  late final TextEditingController _specialPointsController;
  late final TextEditingController _praisePointsController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final defaults = widget.attendanceDefaults ?? const {};
    _nameController =
        TextEditingController(text: widget.definition?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.definition?.description ?? '');
    _massPointsController = TextEditingController(
      text: _initialPoints(
        widget.definition?.massPoints,
        defaults['mass'],
      ).toString(),
    );
    _generalPointsController = TextEditingController(
      text: _initialPoints(
        widget.definition?.generalMeetingPoints,
        defaults['generalMeeting'],
      ).toString(),
    );
    _specialPointsController = TextEditingController(
      text: _initialPoints(
        widget.definition?.specialMeetingPoints,
        defaults['specialMeeting'],
      ).toString(),
    );
    _praisePointsController = TextEditingController(
      text: _initialPoints(
        widget.definition?.praisePoints,
        defaults['praise'],
      ).toString(),
    );
  }

  int _initialPoints(int? definitionValue, int? defaultValue) {
    if (definitionValue != null) return definitionValue;
    if (defaultValue != null) return defaultValue;
    return 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _massPointsController.dispose();
    _generalPointsController.dispose();
    _specialPointsController.dispose();
    _praisePointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.definition != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Score Profile' : 'Create Score Profile'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Profile name',
                  hintText: 'Enter a descriptive name',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add notes about this profile',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              const Text(
                'Attendance points',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildPointsField(
                controller: _massPointsController,
                label: 'Mass',
              ),
              _buildPointsField(
                controller: _generalPointsController,
                label: 'General meeting',
              ),
              _buildPointsField(
                controller: _specialPointsController,
                label: 'Special meeting',
              ),
              _buildPointsField(
                controller: _praisePointsController,
                label: 'Praise',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  Widget _buildPointsField({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: '$label points',
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required';
          }
          final parsed = int.tryParse(value);
          if (parsed == null) {
            return 'Enter a valid number';
          }
          if (parsed < 0) {
            return 'Points cannot be negative';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final cubit = context.read<ScoreDefinitionCubit>();

    final payload = _buildPayload();

    final result = widget.definition == null
        ? await cubit.createDefinition(payload)
        : await cubit.updateDefinition(widget.definition!.id, payload);

    if (!mounted) return;

    if (result != null) {
      Navigator.of(context).pop(result);
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  Map<String, dynamic> _buildPayload() {
    final descriptionText = _descriptionController.text.trim();
    return {
      'name': _nameController.text.trim(),
      'description': descriptionText.isEmpty ? null : descriptionText,
      'criteria': {
        'attendance': {
          'mass': int.parse(_massPointsController.text),
          'generalMeeting': int.parse(_generalPointsController.text),
          'specialMeeting': int.parse(_specialPointsController.text),
          'praise': int.parse(_praisePointsController.text),
        },
      },
    };
  }
}
