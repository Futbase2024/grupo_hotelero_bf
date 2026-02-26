import '../entities/user_entity.dart';

/// Contrato del repositorio de autenticación
abstract class AuthRepository {
  /// Obtiene el usuario actualmente autenticado
  Future<UserEntity?> getCurrentUser();

  /// Inicia sesión con email y contraseña
  Future<UserEntity> loginWithEmail({
    required String email,
    required String password,
  });

  /// Inicia sesión con código de reserva (para huéspedes)
  /// El código es único y está ligado a un alojamiento y número de huéspedes
  Future<UserEntity> loginWithBookingCode({
    required String bookingCode,
  });

  /// Inicia sesión con código de reserva y verificación de email
  /// Valida que el email coincida con el de la reserva
  /// El código tiene formato BF-XXXX-XXXX
  Future<UserEntity> loginWithBookingCodeAndEmail({
    required String email,
    required String bookingCode,
  });

  /// Cierra la sesión del usuario actual
  Future<void> logout();

  /// Stream de cambios en el estado de autenticación
  Stream<UserEntity?> get authStateChanges;

  /// Envía un email de recuperación de contraseña
  Future<void> sendPasswordResetEmail(String email);

  /// Verifica si hay un usuario autenticado
  bool get isAuthenticated;
}
