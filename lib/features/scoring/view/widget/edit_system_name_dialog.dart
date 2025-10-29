import 'package:flutter/material.dart';

class EditSystemNameDialog extends StatefulWidget {
  final String currentName;

  const EditSystemNameDialog({
    Key? key,
    required this.currentName,
  }) : super(key: key);

  @override
  State<EditSystemNameDialog> createState() => _EditSystemNameDialogState();
}

class _EditSystemNameDialogState extends State<EditSystemNameDialog> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit System Name'),
      content: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'System Name',
          hintText: 'Enter new name',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().length >= 2) {
              Navigator.pop(context, _nameController.text.trim());
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Name must be at least 2 characters'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
