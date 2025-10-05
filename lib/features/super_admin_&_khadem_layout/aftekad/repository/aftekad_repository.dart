import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/repository/i_aftekad_repository.dart';

import '../../../../core/services/interface/i_api_service.dart';

class AftekadRepository implements IAftekadRepository {
  final IApiService _apiService;

  AftekadRepository(this._apiService);
}
