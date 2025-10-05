import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/makhdoum_layout/attendance/viewmodel/attendance_cubit.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BlocProvider(
        create: (context) => AttendanceCubit(),
        child: BlocBuilder<AttendanceCubit, AttendanceState>(
          builder: (context, state) {
            return const Center(child: Text("Attendance Screen"));
          },
        ),
      ),
    );
  }
}
