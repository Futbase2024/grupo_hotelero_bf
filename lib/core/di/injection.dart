import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/admin/data/repositories/admin_panel_repository_impl.dart';
import '../../features/admin/domain/repositories/admin_panel_repository.dart';
import '../../features/guest/alojamientos/data/repositories/properties_repository_impl.dart';
import '../../features/guest/alojamientos/domain/repositories/properties_repository.dart';
import '../../features/guest/house_rules/data/repositories/house_rules_repository_impl.dart';
import '../../features/guest/house_rules/domain/repositories/house_rules_repository.dart';
import '../../features/guest/que_ver/data/repositories/places_repository_impl.dart';
import '../../features/guest/que_ver/domain/repositories/places_repository.dart';
import '../../features/guest/parkings/data/repositories/parkings_repository_impl.dart';
import '../../features/guest/parkings/domain/repositories/parkings_repository.dart';
import '../../features/guest/reviews/data/repositories/reviews_repository_impl.dart';
import '../../features/guest/reviews/domain/repositories/reviews_repository.dart';

final getIt = GetIt.instance;

/// Configura la inyección de dependencias
Future<void> configureDependencies() async {
  // Supabase client
  getIt.registerSingleton<SupabaseClient>(Supabase.instance.client);

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(),
  );
  getIt.registerLazySingleton<PropertiesRepository>(
    () => PropertiesRepositoryImpl(),
  );
  getIt.registerLazySingleton<HouseRulesRepository>(
    () => HouseRulesRepositoryImpl(),
  );
  getIt.registerLazySingleton<PlacesRepository>(
    () => PlacesRepositoryImpl(),
  );
  getIt.registerLazySingleton<ParkingsRepository>(
    () => ParkingsRepositoryImpl(supabaseClient: getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<ReviewsRepository>(
    () => ReviewsRepositoryImpl(),
  );

  // Admin repositories
  getIt.registerLazySingleton<AdminPanelRepository>(
    () => AdminPanelRepositoryImpl(),
  );

  // BLoCs/Cubits se crean con BlocProvider en la UI
}
