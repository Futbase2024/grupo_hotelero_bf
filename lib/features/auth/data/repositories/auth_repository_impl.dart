import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/enums/deposit_status.dart';
import '../../../../core/services/crashlytics_service.dart';
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
      debugPrint('👤 [getCurrentUser] bookingId: "${guestSession.bookingId}"');
      debugPrint('👤 [getCurrentUser] bookingCode: "${guestSession.bookingCode}"');
      debugPrint('👤 [getCurrentUser] supabaseUserId: "${guestSession.supabaseUserId}"');

      // Verificar que la reserva sigue siendo válida y obtener estado del check-in
      final bookingResponse = await _supabase
          .from(SupabaseTables.bookings)
          .select('''
            id,
            status,
            checkout_date,
            deposit_status,
            checkins (
              status,
              rejection_reason
            )
          ''')
          .eq('id', guestSession.bookingId)
          .inFilter('status', ['confirmed', 'checked_in'])
          .maybeSingle();

      if (bookingResponse != null) {
        // Verificar que la reserva no ha expirado
        final guestCheckoutDate = DateTime.parse(bookingResponse['checkout_date'] as String);
        if (DateTime.now().isAfter(guestCheckoutDate.add(const Duration(days: 1)))) {
          debugPrint('⚠️ [getCurrentUser] Reserva expirada, limpiando sesión');
          await _guestSession.clearSession();
          return null;
        }

        // Verificar estado del check-in
        // Supabase puede devolver un Map (relación uno-a-uno) o un List
        String? checkinStatus;
        String? checkinRejectionReason;
        final checkinsData = bookingResponse['checkins'];
        if (checkinsData is Map<String, dynamic>) {
          // Relación uno-a-uno: devuelve un solo objeto
          checkinStatus = checkinsData['status'] as String?;
          checkinRejectionReason = checkinsData['rejection_reason'] as String?;
        } else if (checkinsData is List && checkinsData.isNotEmpty) {
          // Relación uno-a-muchos: devuelve una lista
          checkinStatus = (checkinsData.first as Map<String, dynamic>)['status'] as String?;
          checkinRejectionReason = (checkinsData.first as Map<String, dynamic>)['rejection_reason'] as String?;
        }
        // Solo 'validated' significa check-in completado
        // 'submitted' = pendiente de validación por admin
        final checkInCompleted = checkinStatus == 'validated';

        debugPrint('👤 [getCurrentUser] Check-in status: $checkinStatus, completed: $checkInCompleted');

        return guestSession.toUserEntity().copyWith(
          checkInCompleted: checkInCompleted,
          checkinStatus: checkinStatus,
          checkinRejectionReason: checkinRejectionReason,
          depositStatus: DepositStatus.fromString(
            bookingResponse['deposit_status'] as String?,
          ),
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
      var depositStatus = DepositStatus.none;

      if (role == UserRole.guest) {
        final bookingResponse = await _supabase
            .from(SupabaseTables.bookings)
            .select('''
              id,
              deposit_status,
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
        depositStatus = DepositStatus.fromString(
          bookingResponse?['deposit_status'] as String?,
        );

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

        // Un huésped sin reserva activa no cuenta como sesión válida: es una
        // sesión anónima que quedó de un login fallido o a medias. Devolverlo
        // dejaría la home sin reserva y el check-in deshabilitado.
        if (bookingId == null) {
          debugPrint('⚠️ [getCurrentUser] Huésped sin reserva activa, se trata como no autenticado');
          return null;
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
        depositStatus: depositStatus,
      );
    } catch (e, stackTrace) {
      // Si hay error, reportar pero retornar entity básico
      await CrashlyticsService.recordError(
        e,
        stackTrace,
        reason: 'getCurrentUser - Error fetching user role',
        information: ['userId: ${user.id}'],
      );
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

    final user = await getCurrentUser();
    if (user == null) {
      throw Exception('user not found');
    }
    return user;
  }

  /// Garantiza que hay sesión antes de reclamar una reserva.
  ///
  /// `claim_booking_by_code` vincula la reserva a `auth.uid()`, así que sin
  /// sesión devuelve `no_session`.
  Future<void> _ensureAnonymousSession() async {
    if (_supabase.auth.currentUser != null) return;
    await _supabase.auth.signInAnonymously();
  }

  /// [getCurrentUser] sin propagar errores: al final de un login ya válido, un
  /// fallo al leer el estado del check-in no debe tumbar el login.
  Future<UserEntity?> _getCurrentUserOrNull() async {
    try {
      return await getCurrentUser();
    } catch (e) {
      debugPrint('⚠️ [AuthRepository] No se pudo obtener el usuario completo: $e');
      return null;
    }
  }

  /// Cierra la sesión anónima que deja un login con código fallido.
  ///
  /// Si se mantuviera, `getCurrentUser()` la encontraría y el huésped acabaría
  /// en la home sin reserva en lugar de ver el error del login. No toca la
  /// sesión si ya hay una sesión de huésped guardada.
  Future<void> _discardAnonymousSession() async {
    final user = _supabase.auth.currentUser;
    if (user == null || !user.isAnonymous) return;
    if (await _guestSession.hasSession()) return;

    try {
      await _supabase.auth.signOut();
      debugPrint('🧹 [AuthRepository] Sesión anónima de login fallido cerrada');
    } catch (e) {
      debugPrint('⚠️ [AuthRepository] Error cerrando sesión anónima: $e');
    }
  }

  /// Reclama una reserva por su código a través del RPC `claim_booking_by_code`.
  ///
  /// El RPC valida código, estado, caducidad y (si se pasa) email en el
  /// servidor, y vincula la reserva al usuario autenticado. Sustituye a la
  /// consulta directa a `bookings`, que obligaba a mantener una política RLS
  /// que dejaba toda la tabla legible por cualquier usuario.
  ///
  /// Traduce los errores del servidor a las mismas excepciones que ya manejaba
  /// la capa superior.
  Future<Map<String, dynamic>> _claimBooking({
    required String code,
    String? email,
  }) async {
    try {
      final response = await _supabase.rpc(
        'claim_booking_by_code',
        params: {
          'p_code': code.toUpperCase().trim(),
          if (email != null) 'p_email': email.toLowerCase().trim(),
        },
      );

      if (response == null) {
        throw Exception('code_not_found');
      }

      return Map<String, dynamic>.from(response as Map);
    } on PostgrestException catch (e) {
      // El RPC lanza el motivo como mensaje de la excepción de Postgres.
      final message = e.message;
      if (message.contains('booking_not_found')) {
        throw Exception('code_not_found');
      }
      if (message.contains('email_mismatch')) {
        throw Exception('email_mismatch');
      }
      // El RPC indica el motivo tras `code_expired:`. Se comprueba antes que
      // `code_expired`, que queda para servidores sin el motivo.
      if (message.contains('booking_cancelled')) {
        throw Exception('booking_cancelled');
      }
      if (message.contains('stay_finished')) {
        throw Exception('stay_finished');
      }
      if (message.contains('code_expired')) {
        throw Exception('code_expired');
      }
      if (message.contains('no_session')) {
        throw Exception('no_session');
      }
      rethrow;
    }
  }

  @override
  Future<UserEntity> loginWithBookingCode({
    required String bookingCode,
  }) async {
    debugPrint('🔑 [loginWithBookingCode] Iniciando login con código: $bookingCode');

    try {
      // La reserva se resuelve con `claim_booking_by_code`, que valida código,
      // estado y caducidad EN EL SERVIDOR y vincula la reserva al usuario
      // actual. Antes se consultaba `bookings` directamente, lo que obligaba a
      // tener una política RLS que dejaba toda la tabla legible por cualquiera.
      //
      // Requiere sesión: primero se crea una anónima, y si la reserva tiene
      // email se cambia a la cuenta del huésped y se revincula.
      debugPrint('📋 [loginWithBookingCode] Buscando reserva...');
      await _ensureAnonymousSession();

      final bookingResponse = await _claimBooking(
        code: bookingCode,
      );

      debugPrint('📋 [loginWithBookingCode] Respuesta: $bookingResponse');

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

      // Si no hay email o falló login/registro, seguimos con la sesión anónima
      // que ya se creó antes de reclamar la reserva.
      supabaseUserId ??= _supabase.auth.currentUser?.id;

      // Si el login con email cambió el usuario, hay que revincular la reserva:
      // la reclamó el usuario anónimo inicial, no este.
      if (supabaseUserId != null) {
        try {
          await _claimBooking(code: bookingCode);
          debugPrint('✅ [loginWithBookingCode] Reserva vinculada a $supabaseUserId');
        } catch (e) {
          debugPrint('⚠️ [loginWithBookingCode] Error revinculando la reserva: $e');
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

      // Devolver el usuario completo (con el estado del check-in), el mismo
      // que dará cualquier verificación posterior. Así la home se pinta bien
      // a la primera y no cambia al llegar el refresco de sesión.
      return await _getCurrentUserOrNull() ??
          UserEntity(
            id: supabaseUserId ?? bookingId, // Usar ID de Supabase si está disponible
            email: guestEmail,
            role: UserRole.guest,
            name: guestName,
            bookingId: bookingId,
            propertyId: propertyId,
          );
    } on PostgrestException catch (e, stackTrace) {
      debugPrint('❌ [loginWithBookingCode] PostgrestException: ${e.message}');
      debugPrint('❌ [loginWithBookingCode] Code: ${e.code}');
      debugPrint('❌ [loginWithBookingCode] Details: ${e.details}');
      await _discardAnonymousSession();
      await CrashlyticsService.recordError(
        e,
        stackTrace,
        reason: 'loginWithBookingCode - PostgrestException: code=${e.code}',
        information: ['bookingCode: $bookingCode'],
      );
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ [loginWithBookingCode] Error: $e');
      debugPrint('❌ [loginWithBookingCode] StackTrace: $stackTrace');
      await _discardAnonymousSession();
      await CrashlyticsService.recordError(
        e,
        stackTrace,
        reason: 'loginWithBookingCode - Unexpected error',
        information: ['bookingCode: $bookingCode'],
      );
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

    try {
      // La sesión debe existir antes de reclamar la reserva: el RPC vincula la
      // reserva a `auth.uid()`.
      final anonSession = await _supabase.auth.signInAnonymously();
      final userId = anonSession.user!.id;

      // Validación completa en el servidor (código, estado, checkout y email).
      // Lanza `booking_not_found`, `code_expired` o `email_mismatch`, que es lo
      // que la capa superior ya esperaba.
      //
      // Antes esto se hacía leyendo `bookings` directamente, lo que exigía una
      // política RLS que dejaba la tabla legible por cualquiera. La consulta
      // pedía además una columna `code_expires_at` que no existe en el esquema.
      final bookingResponse = await _claimBooking(
        code: normalizedCode,
        email: normalizedEmail,
      );

      // Asignar rol de guest al usuario
      await _supabase.from(SupabaseTables.userRoles).upsert({
        'user_id': userId,
        'role': 'guest',
        'property_id': bookingResponse['property_id'],
      });

      // Usuario completo (con el estado del check-in); ver loginWithBookingCode
      return await _getCurrentUserOrNull() ??
          UserEntity(
            id: userId,
            email: normalizedEmail,
            role: UserRole.guest,
            name: '${bookingResponse['guest_first_name'] ?? ''} ${bookingResponse['last_name'] ?? ''}'.trim(),
            bookingId: bookingResponse['id'] as String,
            propertyId: bookingResponse['property_id'] as String?,
          );
    } on PostgrestException catch (e, stackTrace) {
      debugPrint('❌ [loginWithBookingCodeAndEmail] PostgrestException: ${e.message}');
      await _discardAnonymousSession();
      await CrashlyticsService.recordError(
        e,
        stackTrace,
        reason: 'loginWithBookingCodeAndEmail - PostgrestException',
        information: ['bookingCode: $normalizedCode', 'email: $normalizedEmail'],
      );
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ [loginWithBookingCodeAndEmail] Error: $e');
      await _discardAnonymousSession();
      await CrashlyticsService.recordError(
        e,
        stackTrace,
        reason: 'loginWithBookingCodeAndEmail - Unexpected error',
        information: ['bookingCode: $normalizedCode', 'email: $normalizedEmail'],
      );
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    // Limpiar sesión local de guest
    await _guestSession.clearSession();
    // También cerrar sesión de Supabase Auth si la hay
    await _supabase.auth.signOut();
  }

  @override
  Stream<void> get sessionChanges {
    // Solo los eventos en los que cambia el usuario. `initialSession` ya lo
    // cubre la verificación de arranque y `tokenRefreshed` no cambia el
    // usuario. No se consulta nada aquí: quien escuche decide si verificar.
    return _supabase.auth.onAuthStateChange
        .where(
          (event) =>
              event.event == AuthChangeEvent.signedIn ||
              event.event == AuthChangeEvent.userUpdated,
        )
        .map((_) {});
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim());
  }

  @override
  bool get isAuthenticated => _supabase.auth.currentUser != null;
}
