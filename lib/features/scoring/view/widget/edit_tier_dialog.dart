import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../model/scoring_models.dart';

class EditTierDialog extends StatefulWidget {
  final ScoringTierModel? tier;

  const EditTierDialog({
    Key? key,
    this.tier,
  }) : super(key: key);

  @override
  State<EditTierDialog> createState() => _EditTierDialogState();
}

class _EditTierDialogState extends State<EditTierDialog> {
  late TextEditingController _nameController;
  late TextEditingController _minPointsController;
  late TextEditingController _maxPointsController;
  late TextEditingController _orderController;
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tier?.name ?? '');
    _minPointsController =
        TextEditingController(text: widget.tier?.minPoints.toString() ?? '0');
    _maxPointsController =
        TextEditingController(text: widget.tier?.maxPoints?.toString() ?? '');
    _orderController =
        TextEditingController(text: widget.tier?.order.toString() ?? '1');

    if (widget.tier?.color != null) {
      try {
        _selectedColor = Color(
          int.parse(widget.tier!.color!.replaceFirst('#', '0xFF')),
        );
      } catch (e) {
        _selectedColor = Colors.blue;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minPointsController.dispose();
    _maxPointsController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.tier == null ? 'Create Tier' : 'Edit Tier'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tier Name',
                hintText: 'e.g., Bronze, Silver, Gold',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _minPointsController,
              decoration: const InputDecoration(
                labelText: 'Minimum Points',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxPointsController,
              decoration: const InputDecoration(
                labelText: 'Maximum Points (leave empty for highest tier)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _orderController,
              decoration: const InputDecoration(
                labelText: 'Order',
                hintText: 'Lower numbers appear first',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Color: '),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _pickColor(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                ),
              ],
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
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a tier name'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            final minPoints = int.tryParse(_minPointsController.text);
            if (minPoints == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid minimum points'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            final order = int.tryParse(_orderController.text) ?? 1;
            final maxPoints = _maxPointsController.text.isEmpty
                ? null
                : int.tryParse(_maxPointsController.text);

            final colorHex =
                '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';

            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'minPoints': minPoints,
              'maxPoints': maxPoints,
              'color': colorHex,
              'order': order,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _pickColor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
