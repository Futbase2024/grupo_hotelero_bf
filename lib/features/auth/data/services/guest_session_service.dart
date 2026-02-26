import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/user_entity.dart';

/// Servicio para gestionar la sesión local de huéspedes
/// No usa Supabase Auth, solo SharedPreferences
class GuestSessionService {
  GuestSessionService._();
  static final GuestSessionService _instance = GuestSessionService._();
  static GuestSessionService get instance => _instance;

  static const _keyBookingCode = 'guest_booking_code';
  static const _keyBookingId = 'guest_booking_id';
  static const _keyPropertyId = 'guest_property_id';
  static const _keyGuestName = 'guest_guest_name';
  static const _keyCheckinDate = 'guest_checkin_date';
  static const _keyCheckoutDate = 'guest_checkout_date';
  static const _keyUnitId = 'guest_unit_id';

  /// Guarda la sesión del huésped en local
  Future<void> saveSession({
    required String bookingCode,
    required String bookingId,
    required String propertyId,
    required String guestName,
    required String unitId,
    required DateTime checkinDate,
    required DateTime checkoutDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_keyBookingCode, bookingCode),
      prefs.setString(_keyBookingId, bookingId),
      prefs.setString(_keyPropertyId, propertyId),
      prefs.setString(_keyGuestName, guestName),
      prefs.setString(_keyUnitId, unitId),
      prefs.setString(_keyCheckinDate, checkinDate.toIso8601String()),
      prefs.setString(_keyCheckoutDate, checkoutDate.toIso8601String()),
    ]);
    debugPrint('💾 [GuestSessionService] Sesión guardada: $bookingCode');
  }

  /// Obtiene la sesión actual del huésped
  Future<GuestSession?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final bookingCode = prefs.getString(_keyBookingCode);
    if (bookingCode == null) return null;

    return GuestSession(
      bookingCode: bookingCode,
      bookingId: prefs.getString(_keyBookingId) ?? '',
      propertyId: prefs.getString(_keyPropertyId) ?? '',
      guestName: prefs.getString(_keyGuestName) ?? '',
      unitId: prefs.getString(_keyUnitId) ?? '',
      checkinDate: DateTime.parse(prefs.getString(_keyCheckinDate) ?? DateTime.now().toIso8601String()),
      checkoutDate: DateTime.parse(prefs.getString(_keyCheckoutDate) ?? DateTime.now().toIso8601String()),
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

  /// Limpia la sesión del huésped
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_keyBookingCode),
      prefs.remove(_keyBookingId),
      prefs.remove(_keyPropertyId),
      prefs.remove(_keyGuestName),
      prefs.remove(_keyUnitId),
      prefs.remove(_keyCheckinDate),
      prefs.remove(_keyCheckoutDate),
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

  const GuestSession({
    required this.bookingCode,
    required this.bookingId,
    required this.propertyId,
    required this.guestName,
    required this.unitId,
    required this.checkinDate,
    required this.checkoutDate,
  });

  /// Convierte a UserEntity para usar en la app
  UserEntity toUserEntity() {
    return UserEntity(
      id: bookingId, // Usamos bookingId como id temporal
      email: '',
      role: UserRole.guest,
      name: guestName,
      bookingId: bookingId,
      propertyId: propertyId,
    );
  }
}
