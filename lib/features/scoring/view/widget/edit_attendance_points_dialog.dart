import 'package:flutter/material.dart';
import '../../model/scoring_models.dart';

class EditAttendancePointsDialog extends StatefulWidget {
  final ScoringConfigModel config;

  const EditAttendancePointsDialog({
    Key? key,
    required this.config,
  }) : super(key: key);

  @override
  State<EditAttendancePointsDialog> createState() =>
      _EditAttendancePointsDialogState();
}

class _EditAttendancePointsDialogState
    extends State<EditAttendancePointsDialog> {
  late TextEditingController _massController;
  late TextEditingController _generalMeetingController;
  late TextEditingController _specialMeetingController;
  late TextEditingController _praiseController;

  @override
  void initState() {
    super.initState();
    _massController =
        TextEditingController(text: widget.config.massPoints.toString());
    _generalMeetingController = TextEditingController(
        text: widget.config.generalMeetingPoints.toString());
    _specialMeetingController = TextEditingController(
        text: widget.config.specialMeetingPoints.toString());
    _praiseController =
        TextEditingController(text: widget.config.praisePoints.toString());
  }

  @override
  void dispose() {
    _massController.dispose();
    _generalMeetingController.dispose();
    _specialMeetingController.dispose();
    _praiseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Attendance Points'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _massController,
              decoration: const InputDecoration(
                labelText: 'قداس (Mass)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _generalMeetingController,
              decoration: const InputDecoration(
                labelText: 'اجتماع عام (General Meeting)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _specialMeetingController,
              decoration: const InputDecoration(
                labelText: 'اجتماع خاص (Special Meeting)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _praiseController,
              decoration: const InputDecoration(
                labelText: 'تسبحة (Praise)',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final mass = int.tryParse(_massController.text);
            final general = int.tryParse(_generalMeetingController.text);
            final special = int.tryParse(_specialMeetingController.text);
            final praise = int.tryParse(_praiseController.text);

            if (mass == null ||
                general == null ||
                special == null ||
                praise == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter valid numbers'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            Navigator.pop(context, {
              'massPoints': mass,
              'generalMeetingPoints': general,
              'specialMeetingPoints': special,
              'praisePoints': praise,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
