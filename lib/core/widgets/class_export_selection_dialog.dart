import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ClassExportSelectionDialog extends StatefulWidget {
  final List<ClassOption> availableClasses;
  final String title;
  final bool allowMultiple;

  const ClassExportSelectionDialog({
    Key? key,
    required this.availableClasses,
    this.title = 'اختر الفصول للتصدير',
    this.allowMultiple = true,
  }) : super(key: key);

  @override
  State<ClassExportSelectionDialog> createState() =>
      _ClassExportSelectionDialogState();
}

class ClassOption {
  final String id;
  final String name;

  ClassOption({required this.id, required this.name});
}

class _ClassExportSelectionDialogState
    extends State<ClassExportSelectionDialog> {
  final Set<String> _selectedClassIds = {};

  @override
  void initState() {
    super.initState();
    // Pre-select all classes by default
    if (widget.allowMultiple) {
      _selectedClassIds
          .addAll(widget.availableClasses.map((c) => c.id).toSet());
    } else if (widget.availableClasses.isNotEmpty) {
      _selectedClassIds.add(widget.availableClasses.first.id);
    }
  }

  void _toggleClass(String classId) {
    setState(() {
      if (_selectedClassIds.contains(classId)) {
        _selectedClassIds.remove(classId);
      } else {
        _selectedClassIds.add(classId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedClassIds.clear();
      _selectedClassIds
          .addAll(widget.availableClasses.map((c) => c.id).toSet());
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedClassIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.allowMultiple && widget.availableClasses.length > 1) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _selectAll,
                    child: const Text('تحديد الكل'),
                  ),
                  TextButton(
                    onPressed: _deselectAll,
                    child: const Text('إلغاء التحديد'),
                  ),
                ],
              ),
              const Divider(),
            ],
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.availableClasses.length,
                itemBuilder: (context, index) {
                  final classOption = widget.availableClasses[index];
                  final isSelected = _selectedClassIds.contains(classOption.id);

                  return CheckboxListTile(
                    title: Text(classOption.name),
                    value: isSelected,
                    onChanged: widget.allowMultiple
                        ? (_) => _toggleClass(classOption.id)
                        : null,
                    activeColor: AppColors.primaryMaroon,
                  );
                },
              ),
            ),
            if (!widget.allowMultiple && widget.availableClasses.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'يمكنك اختيار فصل واحد فقط',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _selectedClassIds.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selectedClassIds.toList()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryMaroon,
            foregroundColor: AppColors.accentWhite,
          ),
          child: Text(
            widget.allowMultiple
                ? 'تصدير (${_selectedClassIds.length})'
                : 'تصدير',
          ),
        ),
      ],
    );
  }
}
