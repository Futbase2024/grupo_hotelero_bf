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

/// Nombres de tablas en Supabase
class SupabaseTables {
  SupabaseTables._();

  // Usuarios y autenticación
  static const String users = 'users';
  static const String roles = 'roles';
  static const String userRoles = 'user_roles';

  // Reservas y huéspedes
  static const String bookings = 'bookings';
  static const String guests = 'guests';
  static const String rooms = 'rooms';
  static const String properties = 'properties';

  // Check-in
  static const String checkins = 'checkins';
  static const String documents = 'documents';
  static const String signatures = 'signatures';

  // Access Box
  static const String accessCodes = 'access_codes';
  static const String accessLogs = 'access_logs';

  // Stay Guide
  static const String guides = 'guides';
  static const String guideSections = 'guide_sections';
  static const String amenities = 'amenities';
  static const String faqs = 'faqs';

  // Chat
  static const String conversations = 'conversations';
  static const String messages = 'messages';

  // Staff
  static const String staffAssignments = 'staff_assignments';
  static const String tasks = 'tasks';
}

/// Nombres de funciones RPC en Supabase
class SupabaseFunctions {
  SupabaseFunctions._();

  static const String verifyAccessCode = 'verify_access_code';
  static const String generateAccessCode = 'generate_access_code';
  static const String getGuestBookings = 'get_guest_bookings';
  static const String getStaffDashboard = 'get_staff_dashboard';
}
