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

  /// Migra los datos del huésped (conversaciones, mensajes) de un ID antiguo a uno nuevo
  Future<void> _migrateGuestData({
    required String oldUserId,
    required String newUserId,
  }) async {
    try {
      debugPrint('🔄 [GuestSessionService] Migrando datos de $oldUserId a $newUserId');
      await _supabase.rpc(
        'migrate_guest_conversation_participant',
        params: {
          'p_old_user_id': oldUserId,
          'p_new_user_id': newUserId,
        },
      );
      debugPrint('✅ [GuestSessionService] Datos migrados correctamente');
    } catch (e) {
      debugPrint('🔴 [GuestSessionService] Error migrando datos: $e');
      // No relanzamos el error para no bloquear el flujo principal
    }
  }

  /// Vuelve a vincular la reserva con la sesión actual si quedó sin reclamar.
  ///
  /// Ocurre cuando el admin corrige el email del huésped: se libera
  /// `primary_guest_user_id` para que pueda entrar con la cuenta asociada al
  /// email nuevo. Sin este reclamo, las políticas RLS que dependen de ese campo
  /// (check-in y extras) le negarían el acceso hasta su siguiente inicio de sesión.
  Future<void> _ensureBookingClaimed(String bookingId, String? userId) async {
    if (userId == null || userId.isEmpty) return;

    try {
      final booking = await _supabase
          .from('bookings')
          .select('primary_guest_user_id')
          .eq('id', bookingId)
          .maybeSingle();

      if (booking == null) return;

      final primaryGuestUserId = booking['primary_guest_user_id'] as String?;

      // Ya está vinculada a esta sesión
      if (primaryGuestUserId == userId) return;

      // Reclamada por otra cuenta: no interferimos (la RPC lo rechazaría)
      if (primaryGuestUserId != null) {
        debugPrint('ℹ️ [GuestSessionService] Reserva reclamada por otra cuenta, no se reasigna');
        return;
      }

      debugPrint('🔑 [GuestSessionService] Reserva sin reclamar, vinculando a $userId...');
      await _supabase.rpc(
        'assign_primary_guest_to_booking',
        params: {
          'p_booking_id': bookingId,
          'p_user_id': userId,
        },
      );
      debugPrint('✅ [GuestSessionService] Reserva vinculada correctamente');
    } catch (e) {
      debugPrint('🔴 [GuestSessionService] Error vinculando la reserva: $e');
      // No relanzamos el error para no bloquear el arranque de la sesión
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

    // IMPORTANTE: Obtener el ID de la sesión ACTUAL de Supabase
    // y actualizarlo en SharedPreferences si es diferente
    final currentAuthUserId = currentSupabaseUserId;
    final savedSupabaseUserId = prefs.getString(_keySupabaseUserId);

    if (currentAuthUserId != null && currentAuthUserId != savedSupabaseUserId) {
      debugPrint('🔄 [GuestSessionService] Actualizando supabaseUserId: $savedSupabaseUserId -> $currentAuthUserId');

      // Migrar conversaciones y mensajes del ID antiguo al nuevo
      if (savedSupabaseUserId != null && savedSupabaseUserId.isNotEmpty) {
        await _migrateGuestData(
          oldUserId: savedSupabaseUserId,
          newUserId: currentAuthUserId,
        );
      }

      await prefs.setString(_keySupabaseUserId, currentAuthUserId);
    }

    final bookingId = prefs.getString(_keyBookingId);
    debugPrint('📦 [GuestSessionService] getSession - bookingId: "$bookingId"');
    debugPrint('📦 [GuestSessionService] getSession - bookingCode: "$bookingCode"');
    debugPrint('📦 [GuestSessionService] getSession - currentAuthUserId: "$currentAuthUserId"');

    if (bookingId == null) return null;

    // Si el admin corrigió el email de la reserva, ésta queda sin reclamar:
    // se vuelve a vincular con la sesión actual para no perder el acceso.
    await _ensureBookingClaimed(bookingId, currentAuthUserId);

    // Consultar el estado del check-in y el motivo del rechazo en la base de datos
    final checkinData = await _getCheckinStatus(bookingId);
    if (checkinData != null) {
      return GuestSession(
        bookingCode: bookingCode,
        bookingId: bookingId,
        propertyId: prefs.getString(_keyPropertyId) ?? '',
        guestName: prefs.getString(_keyGuestName) ?? '',
        unitId: prefs.getString(_keyUnitId) ?? '',
        checkinDate: DateTime.parse(prefs.getString(_keyCheckinDate) ?? DateTime.now().toIso8601String()),
        checkoutDate: DateTime.parse(prefs.getString(_keyCheckoutDate) ?? DateTime.now().toIso8601String()),
        checkInCompleted: checkinData['status'] == 'validated',
        supabaseUserId: prefs.getString(_keySupabaseUserId),
        checkinRejectionReason: checkinData['rejection_reason'] as String?,
        checkinCancellationReason: checkinData['cancellation_reason'] as String?,
      );
    } else {
      return GuestSession(
        bookingCode: bookingCode,
        bookingId: bookingId,
        propertyId: prefs.getString(_keyPropertyId) ?? '',
        guestName: prefs.getString(_keyGuestName) ?? '',
        unitId: prefs.getString(_keyUnitId) ?? '',
        checkinDate: DateTime.parse(prefs.getString(_keyCheckinDate) ?? DateTime.now().toIso8601String()),
        checkoutDate: DateTime.parse(prefs.getString(_keyCheckoutDate) ?? DateTime.now().toIso8601String()),
        checkInCompleted: false,
        supabaseUserId: prefs.getString(_keySupabaseUserId),
      );
    }
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

  /// Obtiene el estado del check-in desde la base de datos
  Future<Map<String, dynamic>?> _getCheckinStatus(String? bookingId) async {
    if (bookingId == null || bookingId.isEmpty) return null;

    try {
      final response = await _supabase
          .from('checkins')
          .select('status, rejection_reason, cancellation_reason')
          .eq('booking_id', bookingId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return {
        'status': response['status'] as String?,
        'rejection_reason': response['rejection_reason'] as String?,
        'cancellation_reason': response['cancellation_reason'] as String?,
      };
    } on PostgrestException catch (e) {
      debugPrint('❌ [_getCheckinStatus] PostgrestException: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ [_getCheckinStatus] Error: $e');
      return null;
    }
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
  final String? checkinRejectionReason;
  final String? checkinCancellationReason;

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
    this.checkinRejectionReason,
    this.checkinCancellationReason,
  });

  /// Convierte a UserEntity para usar en la app
  /// IMPORTANTE: Usa siempre el ID de la sesión ACTUAL de Supabase (auth.uid())
  /// para que coincida con las políticas RLS de la base de datos
  UserEntity toUserEntity() {
    // Obtener el ID de la sesión ACTUAL de Supabase
    // Esto es crítico para que las políticas RLS funcionen correctamente
    final currentAuthUserId = GuestSessionService.instance.currentSupabaseUserId;

    return UserEntity(
      // Usar siempre el ID de la sesión actual de Supabase para RLS
      id: currentAuthUserId ?? supabaseUserId ?? bookingId,
      email: '',
      role: UserRole.guest,
      name: guestName,
      bookingId: bookingId,
      propertyId: propertyId,
      checkInCompleted: checkInCompleted,
      checkinStatus: null, // Se estado del check-in se obtiene de la BD
      checkinRejectionReason: checkinRejectionReason, // Motivo del rechazo si aplica
      checkinCancellationReason: checkinCancellationReason, // Motivo de la cancelación si aplica
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
    String? checkinRejectionReason,
    String? checkinCancellationReason,
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
      checkinRejectionReason: checkinRejectionReason ?? this.checkinRejectionReason,
      checkinCancellationReason: checkinCancellationReason ?? this.checkinCancellationReason,
    );
  }
}
