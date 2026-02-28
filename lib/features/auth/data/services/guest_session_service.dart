import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_entity.dart';

/// Servicio para gestionar la sesión de huéspedes
/// Usa Supabase Auth anónimo + SharedPreferences para datos adicionales
class GuestSessionService {
  GuestSessionService._();
  static final GuestSessionService _instance = GuestSessionService._();
  static GuestSessionService get instance => _instance;

  final _supabase = Supabase.instance.client;

  static const _keyBookingCode = 'guest_booking_code';
  static const _keyBookingId = 'guest_booking_id';
  static const _keyPropertyId = 'guest_property_id';
  static const _keyGuestName = 'guest_guest_name';
  static const _keyCheckinDate = 'guest_checkin_date';
  static const _keyCheckoutDate = 'guest_checkout_date';
  static const _keyUnitId = 'guest_unit_id';
  static const _keyCheckInCompleted = 'guest_checkin_completed';
  static const _keySupabaseUserId = 'guest_supabase_user_id';

  /// Guarda la sesión del huésped en local y crea/authentica sesión anónima en Supabase
  Future<void> saveSession({
    required String bookingCode,
    required String bookingId,
    required String propertyId,
    required String guestName,
    required String unitId,
    required DateTime checkinDate,
    required DateTime checkoutDate,
  }) async {
    // Crear o recuperar sesión anónima de Supabase
    final supabaseUserId = await _ensureAnonymousSession();

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_keyBookingCode, bookingCode),
      prefs.setString(_keyBookingId, bookingId),
      prefs.setString(_keyPropertyId, propertyId),
      prefs.setString(_keyGuestName, guestName),
      prefs.setString(_keyUnitId, unitId),
      prefs.setString(_keyCheckinDate, checkinDate.toIso8601String()),
      prefs.setString(_keyCheckoutDate, checkoutDate.toIso8601String()),
      if (supabaseUserId != null) prefs.setString(_keySupabaseUserId, supabaseUserId),
    ]);
    debugPrint('💾 [GuestSessionService] Sesión guardada: $bookingCode, supabaseUserId: $supabaseUserId');
  }

  /// Asegura que existe una sesión anónima de Supabase
  Future<String?> _ensureAnonymousSession() async {
    try {
      // Si ya hay sesión activa, usarla
      final currentSession = _supabase.auth.currentSession;
      if (currentSession != null) {
        debugPrint('🔵 [GuestSessionService] Sesión Supabase existente: ${currentSession.user.id}');
        return currentSession.user.id;
      }

      // Crear nueva sesión anónima
      final response = await _supabase.auth.signInAnonymously();
      final userId = response.user?.id;
      debugPrint('✅ [GuestSessionService] Sesión anónima creada: $userId');
      return userId;
    } catch (e) {
      debugPrint('🔴 [GuestSessionService] Error creando sesión anónima: $e');
      return null;
    }
  }

  /// Obtiene el ID de usuario de Supabase actual
  String? get currentSupabaseUserId => _supabase.auth.currentUser?.id;

  /// Obtiene la sesión actual del huésped
  Future<GuestSession?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final bookingCode = prefs.getString(_keyBookingCode);
    if (bookingCode == null) return null;

    // Asegurar que hay sesión de Supabase activa
    await _ensureAnonymousSession();

    return GuestSession(
      bookingCode: bookingCode,
      bookingId: prefs.getString(_keyBookingId) ?? '',
      propertyId: prefs.getString(_keyPropertyId) ?? '',
      guestName: prefs.getString(_keyGuestName) ?? '',
      unitId: prefs.getString(_keyUnitId) ?? '',
      checkinDate: DateTime.parse(prefs.getString(_keyCheckinDate) ?? DateTime.now().toIso8601String()),
      checkoutDate: DateTime.parse(prefs.getString(_keyCheckoutDate) ?? DateTime.now().toIso8601String()),
      checkInCompleted: prefs.getBool(_keyCheckInCompleted) ?? false,
      supabaseUserId: prefs.getString(_keySupabaseUserId),
    );
  }

  /// Verifica si hay una sesión activa
  Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyBookingCode);
  }

  /// Obtiene el código de reserva actual
  Future<String?> getBookingCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBookingCode);
  }

  /// Obtiene el ID de la reserva actual
  Future<String?> getBookingId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBookingId);
  }

  /// Marca el check-in como completado
  Future<void> markCheckInCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCheckInCompleted, true);
    debugPrint('✅ [GuestSessionService] Check-in marcado como completado');
  }

  /// Limpia la sesión del huésped
  Future<void> clearSession() async {
    // Cerrar sesión de Supabase
    try {
      await _supabase.auth.signOut();
      debugPrint('📤 [GuestSessionService] Sesión Supabase cerrada');
    } catch (e) {
      debugPrint('🔴 [GuestSessionService] Error cerrando sesión Supabase: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_keyBookingCode),
      prefs.remove(_keyBookingId),
      prefs.remove(_keyPropertyId),
      prefs.remove(_keyGuestName),
      prefs.remove(_keyUnitId),
      prefs.remove(_keyCheckinDate),
      prefs.remove(_keyCheckoutDate),
      prefs.remove(_keyCheckInCompleted),
      prefs.remove(_keySupabaseUserId),
    ]);
    debugPrint('🗑️ [GuestSessionService] Sesión eliminada');
  }
}

/// Datos de la sesión del huésped
class GuestSession {
  final String bookingCode;
  final String bookingId;
  final String propertyId;
  final String guestName;
  final String unitId;
  final DateTime checkinDate;
  final DateTime checkoutDate;
  final bool checkInCompleted;
  final String? supabaseUserId;

  const GuestSession({
    required this.bookingCode,
    required this.bookingId,
    required this.propertyId,
    required this.guestName,
    required this.unitId,
    required this.checkinDate,
    required this.checkoutDate,
    this.checkInCompleted = false,
    this.supabaseUserId,
  });

  /// Convierte a UserEntity para usar en la app
  /// Usa el ID de Supabase si está disponible, sino usa bookingId como fallback
  UserEntity toUserEntity() {
    return UserEntity(
      id: supabaseUserId ?? bookingId, // Usar Supabase ID si está disponible
      email: '',
      role: UserRole.guest,
      name: guestName,
      bookingId: bookingId,
      propertyId: propertyId,
      checkInCompleted: checkInCompleted,
    );
  }

  GuestSession copyWith({
    String? bookingCode,
    String? bookingId,
    String? propertyId,
    String? guestName,
    String? unitId,
    DateTime? checkinDate,
    DateTime? checkoutDate,
    bool? checkInCompleted,
    String? supabaseUserId,
  }) {
    return GuestSession(
      bookingCode: bookingCode ?? this.bookingCode,
      bookingId: bookingId ?? this.bookingId,
      propertyId: propertyId ?? this.propertyId,
      guestName: guestName ?? this.guestName,
      unitId: unitId ?? this.unitId,
      checkinDate: checkinDate ?? this.checkinDate,
      checkoutDate: checkoutDate ?? this.checkoutDate,
      checkInCompleted: checkInCompleted ?? this.checkInCompleted,
      supabaseUserId: supabaseUserId ?? this.supabaseUserId,
    );
  }
}
