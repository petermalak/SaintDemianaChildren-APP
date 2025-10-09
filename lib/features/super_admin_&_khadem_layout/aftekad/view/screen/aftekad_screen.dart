import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/viewmodel/get_aftekad/get_aftekad_cubit.dart';

import '../../../../../core/di/service_locator.dart';
import '../../repository/i_aftekad_repository.dart';
import '../widget/aftekad_list_tile.dart';

class AftekadScreen extends StatelessWidget {
  const AftekadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BlocProvider(
        create: (context) =>
            GetAftekadCubit(sl<IAftekadRepository>())..getAftekad(),
        child: BlocBuilder<GetAftekadCubit, GetAftekadState>(
          builder: (context, state) {
            if (state is GetAftekadLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is GetAftekadFailure) {
              return Text(state.errorMessage);
            } else if (state is GetAftekadSuccess) {
              final aftekad = state.aftekad;
              return Column(
                children: [
                  const Text("اعتبر ان فى حاجة بتختار منها الاسبوع وحسب كل اسبوع الداتا تحت بتتغير",style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 18
                  ),),
                  const SizedBox(height: 10,),
                  Expanded(
                    child: ListView.separated(
                        itemBuilder: (context, index) => AftekadListTile(
                              aftekad: aftekad[index],
                            ),
                        separatorBuilder: (_, __) => const SizedBox(
                              height: 10,
                            ),
                        itemCount: aftekad.length),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
