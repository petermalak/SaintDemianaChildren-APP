import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/viewmodel/aftekad_cubit.dart';

import '../../../../../core/di/service_locator.dart';
import '../../repository/i_aftekad_repository.dart';

class AftekadScreen extends StatelessWidget {
  const AftekadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) => AftekadCubit(sl<IAftekadRepository>()),
        child: BlocBuilder<AftekadCubit, AftekadState>(
          builder: (context, state) {
            return const Center(child: Text('Soooooooooooooon'));
          },
        ));
  }
}
