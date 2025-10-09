import 'package:get_it/get_it.dart';
import 'package:saint_demiana_children/core/services/interface/i_api_service.dart';
import 'package:saint_demiana_children/core/services/interface/i_storage_service.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/repository/aftekad_repository.dart';

import '../../features/authentication/repository/authentication_repository.dart';
import '../../features/authentication/repository/i_authentication_repository.dart';
import '../../features/feed/repository/feed_repository.dart';
import '../../features/feed/repository/i_feed_repository.dart';
import '../../features/profile/repository/profile_repository.dart';
import '../../features/super_admin_&_khadem_layout/aftekad/repository/i_aftekad_repository.dart';
import '../../features/super_admin_&_khadem_layout/attendance/repository/attendance_repository.dart';
import '../../features/super_admin_&_khadem_layout/attendance/repository/i_attendance_repository.dart';
import '../../features/super_admin_&_khadem_layout/home/repository/home_repository.dart';
import '../../features/super_admin_&_khadem_layout/home/repository/i_home_repository.dart';
import '../../features/super_admin_&_khadem_layout/members/repository/i_members_repository.dart';
import '../../features/super_admin_&_khadem_layout/members/repository/members_repository.dart';
import '../../features/super_admin_&_khadem_layout/super_admin/class_management/repository/class_repository.dart';
import '../../features/super_admin_&_khadem_layout/super_admin/class_management/repository/i_class_repository.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

final GetIt sl = GetIt.instance;
Future<void> setupServiceLocator() async {
  //services
  sl.registerLazySingleton<IApiService>(() => ApiService.instance);
  sl.registerLazySingleton<IStorageService>(() => StorageService.instance);
  // Repositories
  sl.registerLazySingleton<IAuthenticationRepository>(() =>
      AuthenticationRepository(sl<IApiService>(), sl<IProfileRepository>()));
  sl.registerLazySingleton<IHomeRepository>(
      () => HomeRepository(sl<IApiService>()));
  sl.registerLazySingleton<IMembersRepository>(
      () => MembersRepository(sl<IApiService>()));
  sl.registerLazySingleton<IAttendanceRepository>(
      () => AttendanceRepository(sl<IApiService>()));
  sl.registerLazySingleton<IAftekadRepository>(
      () => AftekadRepository(sl<IApiService>()));
  sl.registerLazySingleton<IProfileRepository>(
      () => ProfileRepository(sl<IApiService>(), sl<IStorageService>()));
  sl.registerLazySingleton<IFeedRepository>(
      () => FeedRepository(sl<IApiService>()));
  sl.registerLazySingleton<IClassRepository>(
      () => ClassRepository(sl<IApiService>()));
}
