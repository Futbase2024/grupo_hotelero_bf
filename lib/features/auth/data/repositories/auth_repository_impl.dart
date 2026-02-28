import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/guest_session_service.dart';

/// Implementación del repositorio de autenticación con Supabase
/// Para guests: usa validación de código + sesión local (sin usuarios anónimos)
/// Para staff/admin: usa Supabase Auth normal
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  final GuestSessionService _guestSession = GuestSessionService.instance;

  @override
  Future<UserEntity?> getCurrentUser() async {
    // Primero verificar si hay sesión local de guest
    final guestSession = await _guestSession.getSession();
    if (guestSession != null) {
      debugPrint('👤 [getCurrentUser] Sesión local de guest encontrada');
      // Verificar que la reserva sigue siendo válida y obtener estado del check-in
      final bookingResponse = await _supabase
          .from(SupabaseTables.bookings)
          .select('''
            id,
            status,
            checkins (
              status
            )
          ''')
          .eq('id', guestSession.bookingId)
          .inFilter('status', ['confirmed', 'checked_in'])
          .maybeSingle();

      if (bookingResponse != null) {
        // Verificar estado del check-in
        // Supabase puede devolver un Map (relación uno-a-uno) o un List
        String? checkinStatus;
        final checkinsData = bookingResponse['checkins'];
        if (checkinsData is Map<String, dynamic>) {
          // Relación uno-a-uno: devuelve un solo objeto
          checkinStatus = checkinsData['status'] as String?;
        } else if (checkinsData is List && checkinsData.isNotEmpty) {
          // Relación uno-a-muchos: devuelve una lista
          checkinStatus = (checkinsData.first as Map<String, dynamic>)['status'] as String?;
        }
        // Solo 'validated' significa check-in completado
        // 'submitted' = pendiente de validación por admin
        final checkInCompleted = checkinStatus == 'validated';

        debugPrint('👤 [getCurrentUser] Check-in status: $checkinStatus, completed: $checkInCompleted');

        return guestSession.toUserEntity().copyWith(
          checkInCompleted: checkInCompleted,
          checkinStatus: checkinStatus,
        );
      } else {
        // La reserva ya no es válida, limpiar sesión
        debugPrint('⚠️ [getCurrentUser] Reserva ya no válida, limpiando sesión');
        await _guestSession.clearSession();
        return null;
      }
    }

    // Si no hay sesión de guest, verificar Supabase Auth (staff/admin)
    final user = _supabase.auth.currentUser;

    if (user == null) return null;

    // Obtener el rol del usuario desde user_roles
    try {
      final roleResponse = await _supabase
          .from(SupabaseTables.userRoles)
          .select('role, property_id')
          .eq('user_id', user.id)
          .maybeSingle();

      final role = roleResponse != null
          ? UserRole.fromString(roleResponse['role'] as String)
          : UserRole.guest;
      final propertyId = roleResponse?['property_id'] as String?;

      // Si es guest, obtener booking activo y estado del check-in
      String? bookingId;
      bool checkInCompleted = false;
      String? checkinStatus;

      if (role == UserRole.guest) {
        final bookingResponse = await _supabase
            .from(SupabaseTables.bookings)
            .select('''
              id,
              checkins (
                status
              )
            ''')
            .eq('primary_guest_user_id', user.id)
            .inFilter('status', ['confirmed', 'checked_in'])
            .order('checkin_date', ascending: false)
            .limit(1)
            .maybeSingle();

        bookingId = bookingResponse?['id'] as String?;

        // Verificar estado del check-in
        if (bookingResponse != null) {
          // Supabase puede devolver un Map (relación uno-a-uno) o un List
          final checkinsData = bookingResponse['checkins'];
          if (checkinsData is Map<String, dynamic>) {
            checkinStatus = checkinsData['status'] as String?;
          } else if (checkinsData is List && checkinsData.isNotEmpty) {
            checkinStatus = (checkinsData.first as Map<String, dynamic>)['status'] as String?;
          }
          // Solo 'validated' significa check-in completado
          // 'submitted' = pendiente de validación por admin
          checkInCompleted = checkinStatus == 'validated';
        }
      }

      return UserEntity(
        id: user.id,
        email: user.email ?? '',
        role: role,
        name: user.userMetadata?['full_name'],
        phone: user.userMetadata?['phone'],
        avatarUrl: user.userMetadata?['avatar_url'],
        bookingId: bookingId,
        propertyId: propertyId,
        checkInCompleted: checkInCompleted,
        checkinStatus: checkinStatus,
      );
    } catch (e) {
      // Si hay error, retornar entity básico
      return UserEntity(
        id: user.id,
        email: user.email ?? '',
        role: UserRole.guest,
        name: user.userMetadata?['full_name'],
      );
    }
  }

  @override
  Future<UserEntity> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    if (response.user == null) {
      throw Exception('Error al iniciar sesión');
    }

    // Esperar un momento para que los datos estén disponibles
    await Future.delayed(const Duration(milliseconds: 500));

    return (await getCurrentUser())!;
  }

  @override
  Future<UserEntity> loginWithBookingCode({
    required String bookingCode,
  }) async {
    debugPrint('🔑 [loginWithBookingCode] Iniciando login con código: $bookingCode');

    try {
      // Buscar la reserva por código único
      // Solo permite acceso si status es 'confirmed' o 'checked_in'
      debugPrint('📋 [loginWithBookingCode] Buscando reserva...');
      final bookingResponse = await _supabase
          .from(SupabaseTables.bookings)
          .select('''
            id,
            property_id,
            unit_id,
            booking_code,
            guest_first_name,
            last_name,
            guest_email,
            num_guests,
            checkin_date,
            checkout_date,
            status
          ''')
          .eq('booking_code', bookingCode.toUpperCase().trim())
          .inFilter('status', ['confirmed', 'checked_in'])
          .maybeSingle();

      debugPrint('📋 [loginWithBookingCode] Respuesta: $bookingResponse');

      if (bookingResponse == null) {
        debugPrint('❌ [loginWithBookingCode] Reserva no encontrada o no válida');
        throw Exception('booking not found');
      }

      final String guestName = '${bookingResponse['guest_first_name'] ?? ''} ${bookingResponse['last_name'] ?? ''}'.trim();
      final String guestEmail = (bookingResponse['guest_email'] as String?)?.toLowerCase().trim() ?? '';
      final String bookingId = bookingResponse['id'] as String;
      final String propertyId = bookingResponse['property_id'] as String;
      final String unitId = bookingResponse['unit_id'] as String;
      final DateTime checkinDate = DateTime.parse(bookingResponse['checkin_date'] as String);
      final DateTime checkoutDate = DateTime.parse(bookingResponse['checkout_date'] as String);

      // 🔑 Crear/login usuario con email del huésped
      // Contraseña genérica para todos los huéspedes (acceso protegido por booking_code)
      const String guestPassword = 'BFGuest2024!';
      String? supabaseUserId;

      if (guestEmail.isNotEmpty) {
        debugPrint('🔐 [loginWithBookingCode] Intentando login con email: $guestEmail');

        // Intentar login primero
        try {
          final response = await _supabase.auth.signInWithPassword(
            email: guestEmail,
            password: guestPassword,
          );
          supabaseUserId = response.user?.id;
          debugPrint('✅ [loginWithBookingCode] Login exitoso: $supabaseUserId');
        } catch (e) {
          debugPrint('⚠️ [loginWithBookingCode] Login falló, intentando registro: $e');

          // Si falla, intentar registro
          try {
            final response = await _supabase.auth.signUp(
              email: guestEmail,
              password: guestPassword,
            );
            supabaseUserId = response.user?.id;
            debugPrint('✅ [loginWithBookingCode] Registro exitoso: $supabaseUserId');
          } catch (signUpError) {
            debugPrint('⚠️ [loginWithBookingCode] Registro falló, usando sesión anónima: $signUpError');
          }
        }
      }

      // Si no hay email o falló login/registro, usar sesión anónima
      if (supabaseUserId == null) {
        debugPrint('🔐 [loginWithBookingCode] Creando sesión anónima...');
        try {
          final anonSession = await _supabase.auth.signInAnonymously();
          supabaseUserId = anonSession.user?.id;
          debugPrint('✅ [loginWithBookingCode] Sesión anónima creada: $supabaseUserId');
        } catch (e) {
          debugPrint('⚠️ [loginWithBookingCode] Error creando sesión anónima: $e');
        }
      }

      // Asignar primary_guest_user_id a la reserva usando función RPC con SECURITY DEFINER
      if (supabaseUserId != null) {
        try {
          await _supabase.rpc(
            'assign_primary_guest_to_booking',
            params: {
              'p_booking_id': bookingId,
              'p_user_id': supabaseUserId,
            },
          );
          debugPrint('✅ [loginWithBookingCode] primary_guest_user_id asignado via RPC');
        } catch (e) {
          debugPrint('⚠️ [loginWithBookingCode] Error asignando via RPC: $e');
        }
      }

      // Guardar sesión local
      await _guestSession.saveSession(
        bookingCode: bookingCode.toUpperCase().trim(),
        bookingId: bookingId,
        propertyId: propertyId,
        guestName: guestName,
        unitId: unitId,
        checkinDate: checkinDate,
        checkoutDate: checkoutDate,
      );
      debugPrint('✅ [loginWithBookingCode] Sesión local guardada correctamente');

      return UserEntity(
        id: supabaseUserId ?? bookingId, // Usar ID de Supabase si está disponible
        email: guestEmail,
        role: UserRole.guest,
        name: guestName,
        bookingId: bookingId,
        propertyId: propertyId,
      );
    } on PostgrestException catch (e) {
      debugPrint('❌ [loginWithBookingCode] PostgrestException: ${e.message}');
      debugPrint('❌ [loginWithBookingCode] Code: ${e.code}');
      debugPrint('❌ [loginWithBookingCode] Details: ${e.details}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ [loginWithBookingCode] Error: $e');
      debugPrint('❌ [loginWithBookingCode] StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<UserEntity> loginWithBookingCodeAndEmail({
    required String email,
    required String bookingCode,
  }) async {
    // Normalizar el código (mayúsculas, sin espacios extra)
    final normalizedCode = bookingCode.toUpperCase().trim();
    final normalizedEmail = email.toLowerCase().trim();

    // Buscar la reserva por código único
    final bookingResponse = await _supabase
        .from(SupabaseTables.bookings)
        .select('''
          id,
          property_id,
          unit_id,
          booking_code,
          guest_first_name,
          last_name,
          guest_email,
          num_guests,
          checkin_date,
          checkout_date,
          status,
          code_expires_at
        ''')
        .eq('booking_code', normalizedCode)
        .maybeSingle();

    // Código no encontrado
    if (bookingResponse == null) {
      throw Exception('code_not_found');
    }

    // Verificar si el código ha expirado
    final codeExpiresAt = bookingResponse['code_expires_at'];
    if (codeExpiresAt != null) {
      final expiresAt = DateTime.parse(codeExpiresAt as String);
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('code_expired');
      }
    }

    // Verificar que el estado es válido
    final status = bookingResponse['status'] as String?;
    if (status != null && !['confirmed', 'checked_in'].contains(status)) {
      throw Exception('code_expired');
    }

    // Verificar que el email coincide con el de la reserva
    final bookingEmail = (bookingResponse['guest_email'] as String?)?.toLowerCase().trim();
    if (bookingEmail != null && bookingEmail != normalizedEmail) {
      throw Exception('email_mismatch');
    }

    // Crear sesión anónima para el huésped
    final anonSession = await _supabase.auth.signInAnonymously();
    final userId = anonSession.user!.id;

    // Asignar rol de guest al usuario
    await _supabase.from(SupabaseTables.userRoles).upsert({
      'user_id': userId,
      'role': 'guest',
      'property_id': bookingResponse['property_id'],
    });

    // Actualizar la reserva con el user_id del huésped y marcar primer uso
    final updateData = <String, dynamic>{
      'primary_guest_user_id': userId,
      'guest_email': normalizedEmail,
    };

    // Marcar código como usado si es la primera vez
    if (bookingResponse['code_first_used_at'] == null) {
      updateData['code_first_used_at'] = DateTime.now().toIso8601String();
    }

    await _supabase
        .from(SupabaseTables.bookings)
        .update(updateData)
        .eq('id', bookingResponse['id']);

    return UserEntity(
      id: userId,
      email: normalizedEmail,
      role: UserRole.guest,
      name: '${bookingResponse['guest_first_name'] ?? ''} ${bookingResponse['last_name'] ?? ''}'.trim(),
      bookingId: bookingResponse['id'] as String,
      propertyId: bookingResponse['property_id'] as String?,
    );
  }

  @override
  Future<void> logout() async {
    // Limpiar sesión local de guest
    await _guestSession.clearSession();
    // También cerrar sesión de Supabase Auth si la hay
    await _supabase.auth.signOut();
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.asyncMap((event) async {
      if (event.event == AuthChangeEvent.signedOut) {
        return null;
      }

      return getCurrentUser();
    });
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim());
  }

  @override
  bool get isAuthenticated => _supabase.auth.currentUser != null;
}
