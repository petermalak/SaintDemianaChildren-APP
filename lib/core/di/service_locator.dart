import 'package:get_it/get_it.dart';
import 'package:saint_demiana_children/core/services/interface/i_api_service.dart';
import 'package:saint_demiana_children/core/services/interface/i_storage_service.dart';
import 'package:saint_demiana_children/core/services/interface/i_notification_service.dart';
import 'package:saint_demiana_children/core/services/interface/i_biometric_service.dart';
import 'package:saint_demiana_children/core/services/interface/i_update_service.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/repository/aftekad_repository.dart';

import '../../features/authentication/repository/authentication_repository.dart';
import '../../features/authentication/repository/i_authentication_repository.dart';
import '../../features/feed/repository/feed_repository.dart';
import '../../features/feed/repository/i_feed_repository.dart';
import '../../features/makhdoum_layout/attendance/repository/attendance_repository.dart'
    as makhdoum_attendance;
import '../../features/makhdoum_layout/attendance/repository/i_attendance_repository.dart'
    as makhdoum_attendance_interface;
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
import '../../features/notifications/repository/i_notification_repository.dart';
import '../../features/notifications/repository/notification_repository.dart';
import '../../features/scoring/repository/i_scoring_repository.dart';
import '../../features/scoring/repository/scoring_repository.dart';
import '../../features/shop/repository/i_shop_repository.dart';
import '../../features/shop/repository/shop_repository.dart';
import '../../features/coptic_quest/repository/coptic_quest_repository.dart';
import '../../features/coptic_quest/repository/i_coptic_quest_repository.dart';
import '../../features/coptic_quest/repository/lesson_content_loader.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/local_notification_service.dart';
import '../services/biometric_service.dart';
import '../services/update_service.dart';
import '../services/data_refresh_cubit.dart';

final GetIt sl = GetIt.instance;
Future<void> setupServiceLocator() async {
  print('🔧 [ServiceLocator] Setting up services...');

  // Initialize local notification service first (for beautiful notifications)
  await LocalNotificationService.instance.initialize();
  print('✅ [ServiceLocator] Local notifications initialized');

  //services
  sl.registerLazySingleton<IApiService>(() => ApiService.instance);
  sl.registerLazySingleton<IStorageService>(() => StorageService.instance);
  sl.registerLazySingleton<INotificationService>(
      () => NotificationService.instance);
  sl.registerLazySingleton<IBiometricService>(() => BiometricService());
  sl.registerLazySingleton<IUpdateService>(() => UpdateService());

  // Data Refresh Manager (Singleton for global state)
  sl.registerLazySingleton<DataRefreshCubit>(() => DataRefreshCubit());

  // Repositories
  sl.registerLazySingleton<IAuthenticationRepository>(() =>
      AuthenticationRepository(sl<IApiService>(), sl<IProfileRepository>(),
          sl<IMembersRepository>(), sl<IBiometricService>()));
  sl.registerLazySingleton<IHomeRepository>(
      () => HomeRepository(sl<IApiService>()));
  sl.registerLazySingleton<IMembersRepository>(
      () => MembersRepository(sl<IApiService>()));
  sl.registerLazySingleton<IAttendanceRepository>(
      () => AttendanceRepository(sl<IApiService>()));
  sl.registerLazySingleton<makhdoum_attendance_interface.IAttendanceRepository>(
      () => makhdoum_attendance.AttendanceRepository(sl<IApiService>()));
  sl.registerLazySingleton<IAftekadRepository>(
      () => AftekadRepository(sl<IApiService>()));
  sl.registerLazySingleton<IProfileRepository>(
      () => ProfileRepository(sl<IApiService>(), sl<IStorageService>()));
  sl.registerLazySingleton<IFeedRepository>(
      () => FeedRepository(sl<IApiService>()));
  sl.registerLazySingleton<IClassRepository>(
      () => ClassRepository(sl<IApiService>()));
  sl.registerLazySingleton<INotificationRepository>(
      () => NotificationRepository(sl<IApiService>()));
  sl.registerLazySingleton<IScoringRepository>(
      () => ScoringRepository(sl<IApiService>()));
  sl.registerLazySingleton<IShopRepository>(
      () => ShopRepository(sl<IApiService>()));
  sl.registerLazySingleton<LessonContentLoader>(() => LessonContentLoader());
  sl.registerLazySingleton<ICopticQuestRepository>(() => CopticQuestRepository(
        sl<LessonContentLoader>(),
        sl<IProfileRepository>(),
      ));

  print('✅ [ServiceLocator] All services registered');
}
