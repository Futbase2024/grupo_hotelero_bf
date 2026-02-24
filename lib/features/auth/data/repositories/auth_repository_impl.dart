import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementación del repositorio de autenticación con Supabase
/// Usa el schema definido en 0001_bf_stay_init.sql
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  @override
  Future<UserEntity?> getCurrentUser() async {
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

      // Si es guest, obtener booking activo
      String? bookingId;
      if (role == UserRole.guest) {
        final bookingResponse = await _supabase
            .from(SupabaseTables.bookings)
            .select('id')
            .eq('primary_guest_user_id', user.id)
            .inFilter('status', ['confirmed', 'checked_in'])
            .order('checkin_date', ascending: false)
            .limit(1)
            .maybeSingle();

        bookingId = bookingResponse?['id'] as String?;
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
    required String lastName,
  }) async {
    // Buscar la reserva por código y apellido (según schema)
    final bookingResponse = await _supabase
        .from(SupabaseTables.bookings)
        .select('''
          id,
          property_id,
          unit_id,
          booking_code,
          last_name,
          checkin_date,
          checkout_date,
          status
        ''')
        .eq('booking_code', bookingCode.toUpperCase().trim())
        .eq('last_name', lastName.toUpperCase().trim())
        .inFilter('status', ['confirmed', 'checked_in'])
        .maybeSingle();

    if (bookingResponse == null) {
      throw Exception('booking not found');
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

    // Actualizar la reserva con el user_id del huésped
    await _supabase
        .from(SupabaseTables.bookings)
        .update({'primary_guest_user_id': userId}).eq('id', bookingResponse['id']);

    return UserEntity(
      id: userId,
      email: anonSession.user?.email ?? '',
      role: UserRole.guest,
      bookingId: bookingResponse['id'] as String,
      propertyId: bookingResponse['property_id'] as String?,
    );
  }

  @override
  Future<void> logout() async {
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
