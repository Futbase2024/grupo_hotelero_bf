import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementación del repositorio de autenticación con Supabase
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return null;

    // Obtener datos adicionales del usuario desde la tabla users
    try {
      final response = await _supabase
          .from('users')
          .select('''
            id,
            email,
            name,
            phone,
            avatar_url,
            role,
            booking_id,
            property_id
          ''')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        // Si no existe en la tabla users, crear entity básico
        return UserEntity(
          id: user.id,
          email: user.email ?? '',
          role: UserRole.guest,
          name: user.userMetadata?['name'],
        );
      }

      return _mapToEntity(response);
    } catch (e) {
      // Si hay error, retornar entity básico
      return UserEntity(
        id: user.id,
        email: user.email ?? '',
        role: UserRole.guest,
        name: user.userMetadata?['name'],
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

    // Esperar un momento para que el trigger cree el usuario en la tabla
    await Future.delayed(const Duration(milliseconds: 500));

    return (await getCurrentUser())!;
  }

  @override
  Future<UserEntity> loginWithBookingCode({
    required String bookingCode,
    required String lastName,
  }) async {
    // Buscar la reserva por código y apellido
    final bookingResponse = await _supabase
        .from('bookings')
        .select('''
          id,
          code,
          guest_id,
          property_id,
          guests!inner(
            id,
            email,
            name,
            last_name,
            phone
          )
        ''')
        .eq('code', bookingCode.toUpperCase().trim())
        .eq('guests.last_name', lastName.toUpperCase().trim())
        .maybeSingle();

    if (bookingResponse == null) {
      throw Exception('booking not found');
    }

    final guest = bookingResponse['guests'] as Map<String, dynamic>;

    // Crear o obtener sesión anónima para el huésped
    final anonSession = await _supabase.auth.signInAnonymously();

    // Actualizar el usuario en la tabla users con el rol de guest
    await _supabase.from('users').upsert({
      'id': anonSession.user!.id,
      'email': guest['email'],
      'name': '${guest['name']} ${guest['last_name']}',
      'phone': guest['phone'],
      'role': 'guest',
      'booking_id': bookingResponse['id'],
      'property_id': bookingResponse['property_id'],
    });

    return UserEntity(
      id: anonSession.user!.id,
      email: guest['email'] ?? '',
      role: UserRole.guest,
      name: '${guest['name']} ${guest['last_name']}',
      phone: guest['phone'],
      bookingId: bookingResponse['id'],
      propertyId: bookingResponse['property_id'],
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

  /// Mapea la respuesta de Supabase a UserEntity
  UserEntity _mapToEntity(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String,
      email: json['email'] as String,
      role: UserRole.fromString(json['role'] as String? ?? 'guest'),
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bookingId: json['booking_id'] as String?,
      propertyId: json['property_id'] as String?,
    );
  }
}
