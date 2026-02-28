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
import '../../features/guest/chat/data/repositories/chat_repository_impl.dart';
import '../../features/guest/chat/domain/repositories/chat_repository.dart';
import '../../features/guest/checkin/data/repositories/checkin_repository_impl.dart';
import '../../features/guest/checkin/domain/repositories/checkin_repository.dart';
import '../../features/guest/access_box/data/repositories/access_box_repository_impl.dart';
import '../../features/guest/access_box/domain/repositories/access_box_repository.dart';
import '../../features/guest/checkout/data/repositories/checkout_repository_impl.dart';
import '../../features/guest/checkout/domain/repositories/checkout_repository.dart';

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

  // Chat repository
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(),
  );

  // Checkin repository
  getIt.registerLazySingleton<CheckinRepository>(
    () => CheckinRepositoryImpl(),
  );

  // Access Box repository
  getIt.registerLazySingleton<AccessBoxRepository>(
    () => AccessBoxRepositoryImpl(supabase: getIt<SupabaseClient>()),
  );

  // Checkout repository
  getIt.registerLazySingleton<CheckoutRepository>(
    () => CheckoutRepositoryImpl(),
  );

  // BLoCs/Cubits se crean con BlocProvider en la UI
}
