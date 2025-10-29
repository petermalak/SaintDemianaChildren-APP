import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../viewmodel/scoring_cubit/scoring_cubit.dart';
import '../../viewmodel/scoring_cubit/scoring_state.dart';

class ManagePointsDialog extends StatefulWidget {
  final String userId;
  final String userName;
  final String classId;

  const ManagePointsDialog({
    Key? key,
    required this.userId,
    required this.userName,
    required this.classId,
  }) : super(key: key);

  @override
  State<ManagePointsDialog> createState() => _ManagePointsDialogState();
}

class _ManagePointsDialogState extends State<ManagePointsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pointsController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isAddition = true;

  @override
  void dispose() {
    _pointsController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScoringCubit, ScoringState>(
      listener: (context, state) {
        if (state is PointsUpdated) {
          // Pop dialog first
          Navigator.of(context).pop();
          // Show success message using root context
          Future.microtask(() {
            final messenger = ScaffoldMessenger.of(context);
            if (messenger.mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    state.wasAddition
                        ? 'تمت إضافة ${state.newPoints - state.oldPoints} نقطة'
                        : 'تم خصم ${state.oldPoints - state.newPoints} نقطة',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          });
        }

        if (state is ScoringError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: AlertDialog(
        title: Text('إدارة النقاط - ${widget.userName}'),
        content: BlocBuilder<ScoringCubit, ScoringState>(
          builder: (context, state) {
            final isLoading = state is ScoringLoading;

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('إضافة نقاط'),
                          icon: Icon(Icons.add),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('خصم نقاط'),
                          icon: Icon(Icons.remove),
                        ),
                      ],
                      selected: {_isAddition},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          _isAddition = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pointsController,
                      decoration: const InputDecoration(
                        labelText: 'النقاط',
                        hintText: 'أدخل عدد النقاط',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.stars),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال النقاط';
                        }
                        final points = int.tryParse(value);
                        if (points == null || points <= 0) {
                          return 'الرجاء إدخال رقم صحيح موجب';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        labelText: 'السبب (اختياري)',
                        hintText: 'لماذا تقوم بإضافة/خصم النقاط؟',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.comment),
                      ),
                      maxLines: 3,
                      enabled: !isLoading,
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          BlocBuilder<ScoringCubit, ScoringState>(
            builder: (context, state) {
              final isLoading = state is ScoringLoading;

              return ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          final points = int.parse(_pointsController.text);
                          final reason = _reasonController.text.trim().isEmpty
                              ? null
                              : _reasonController.text.trim();

                          if (_isAddition) {
                            context.read<ScoringCubit>().addPoints(
                                  widget.userId,
                                  widget.classId,
                                  points,
                                  reason,
                                );
                          } else {
                            context.read<ScoringCubit>().removePoints(
                                  widget.userId,
                                  widget.classId,
                                  points,
                                  reason,
                                );
                          }
                        }
                      },
                child: const Text('تأكيد'),
              );
            },
          ),
        ],
      ),
    );
  }
}
