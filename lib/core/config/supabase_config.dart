import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_config.dart';

/// Configuración e inicialización de Supabase
class SupabaseConfig {
  SupabaseConfig._();

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  /// Inicializa Supabase con la configuración del ambiente
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      debug: AppConfig.isDevelopment,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// Obtiene la sesión actual
  static Session? get currentSession => auth.currentSession;

  /// Obtiene el usuario actual
  static User? get currentUser => auth.currentUser;

  /// Verifica si hay un usuario autenticado
  static bool get isAuthenticated => currentUser != null;

  /// Stream de cambios de estado de autenticación
  static Stream<AuthState> get authStateChanges => auth.onAuthStateChange;
}

/// Nombres de tablas en Supabase (según schema 0001_bf_stay_init.sql)
class SupabaseTables {
  SupabaseTables._();

  // Roles y autenticación
  static const String userRoles = 'user_roles';

  // Propiedades y unidades
  static const String properties = 'properties';
  static const String units = 'units';

  // Reservas y huéspedes
  static const String bookings = 'bookings';
  static const String guests = 'guests';
  static const String bookingGuests = 'booking_guests';

  // Check-in
  static const String checkins = 'checkins';
  static const String guestDocuments = 'guest_documents';

  // Stay Guide
  static const String guideItems = 'guide_items';

  // Chat
  static const String conversations = 'conversations';
  static const String conversationParticipants = 'conversation_participants';
  static const String messages = 'messages';

  // Payments
  static const String payments = 'payments';

  // Reviews
  static const String reviews = 'reviews';

  // Incidents
  static const String incidents = 'incidents';
}

/// Nombres de funciones RPC en Supabase
class SupabaseFunctions {
  SupabaseFunctions._();

  static const String getAccessForBooking = 'get_access_for_booking';
  static const String currentRole = 'current_role';
  static const String currentPropertyId = 'current_property_id';
  static const String isAdmin = 'is_admin';
  static const String isStaff = 'is_staff';
}
