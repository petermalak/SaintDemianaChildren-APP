import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/viewmodel/get_aftekad/get_aftekad_cubit.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/repository/i_members_repository.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/model/aftekad_model.dart';
import 'package:intl/intl.dart';

import '../../../../../core/di/service_locator.dart';
import '../../repository/i_aftekad_repository.dart';
import '../widget/aftekad_list_tile.dart';

class AftekadScreen extends StatefulWidget {
  const AftekadScreen({super.key});

  @override
  State<AftekadScreen> createState() => _AftekadScreenState();
}

class _AftekadScreenState extends State<AftekadScreen> {
  String? selectedFridayDate;
  List<DateTime> fridayDates = [];

  @override
  void initState() {
    super.initState();
    _generateFridayDates();
  }

  void _generateFridayDates() {
    final startDate = DateTime(2025, 10, 3); // 3-10-2025
    final endDate = DateTime.now();

    DateTime current = startDate;

    // Find the first Friday from start date
    while (current.weekday != DateTime.friday) {
      current = current.add(const Duration(days: 1));
    }

    // Generate all Fridays until current date
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      fridayDates.add(current);
      current = current.add(const Duration(days: 7));
    }

    // Set the most recent Friday as default
    if (fridayDates.isNotEmpty) {
      selectedFridayDate = DateFormat('yyyy-MM-dd').format(fridayDates.last);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BlocProvider(
        create: (context) {
          final cubit = GetAftekadCubit(sl<IAftekadRepository>());
          // Load data for the default selected date
          if (selectedFridayDate != null) {
            cubit.getAftekad(selectedFridayDate!, sl<IProfileRepository>().user!.id!); // You may need to pass appropriate khademId
          }
          return cubit;
        },
        child: Column(
          children: [
            // FilterChip section
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fridayDates.length,
                itemBuilder: (context, index) {
                  final date = fridayDates[index];
                  final dateString = DateFormat('yyyy-MM-dd').format(date);
                  final displayDate = DateFormat('MMM dd').format(date);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(displayDate),
                      selected: selectedFridayDate == dateString,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedFridayDate = dateString;
                          });
                          // Fetch data for selected date
                          context.read<GetAftekadCubit>().getAftekad(dateString, sl<IProfileRepository>().user!.id!);
                        }
                      },
                      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      checkmarkColor: Theme.of(context).primaryColor,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10,),
            BlocBuilder<GetAftekadCubit, GetAftekadState>(
              builder: (context, state) {
                if (state is GetAftekadLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is GetAftekadFailure) {
                  return Text(state.errorMessage);
                } else {
                  // Get all members from repository
                  final allMembers = sl<IMembersRepository>().members
                      .where((member) => member.role == UserRole.makhdoum)
                      .toList();

                  // Get completed aftekad data if available
                  List<AftekadModel> completedAftekad = [];
                  if (state is GetAftekadSuccess) {
                    completedAftekad = state.aftekad.where((aftekad) => aftekad.status == true).toList();
                  }

                  // Create a combined list showing completion status for each member
                  final displayList = allMembers.map((member) {
                    // Check if this member has completed aftekad
                    final memberAftekad = completedAftekad.firstWhere(
                      (aftekad) => aftekad.makhdoum?.id == member.id,
                      orElse: () => AftekadModel(
                        makhdoumId: member.id,
                        status: false,
                        classId: member.classId,
                        makhdoum: Makhdoum(
                          id: member.id,
                          name: member.name,
                        ),
                      ),
                    );

                    return memberAftekad;
                  }).toList();

                  return Expanded(
                    child: ListView.separated(
                        itemBuilder: (context, index) => AftekadListTile(
                              aftekad: displayList[index],
                            ),
                        separatorBuilder: (_, __) => const SizedBox(
                              height: 10,
                            ),
                        itemCount: displayList.length),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
