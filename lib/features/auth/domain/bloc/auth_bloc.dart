import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

// ============== EVENTS ==============

/// Eventos base del AuthBloc
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para verificar el estado de autenticación al iniciar
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Evento para iniciar sesión con email y contraseña
class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Evento para iniciar sesión con código de reserva
/// El código es único y está ligado a un alojamiento y número de huéspedes
class AuthLoginWithBookingRequested extends AuthEvent {
  const AuthLoginWithBookingRequested({
    required this.bookingCode,
  });

  final String bookingCode;

  @override
  List<Object?> get props => [bookingCode];
}

/// Evento para iniciar sesión con código de reserva y verificación de email
/// El código tiene formato BF-XXXX-XXXX
class AuthLoginWithBookingAndEmailRequested extends AuthEvent {
  const AuthLoginWithBookingAndEmailRequested({
    required this.email,
    required this.bookingCode,
  });

  final String email;
  final String bookingCode;

  @override
  List<Object?> get props => [email, bookingCode];
}

/// Evento para cerrar sesión
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Evento para enviar email de recuperación de contraseña
class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

// ============== STATES ==============

/// Estados base del AuthBloc
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial (sin verificar)
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Estado de carga (verificando autenticación)
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Estado autenticado
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user});

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

/// Estado no autenticado
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Estado de error
class AuthError extends AuthState {
  const AuthError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// ============== BLOC ==============

/// BLoC para gestionar el estado de autenticación
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLoginWithBookingRequested>(_onLoginWithBookingRequested);
    on<AuthLoginWithBookingAndEmailRequested>(_onLoginWithBookingAndEmailRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);

    // Escuchar cambios de autenticación
    _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        add(AuthCheckRequested());
      }
    });
  }

  final AuthRepository _authRepository;

  /// Verifica el estado de autenticación actual
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.getCurrentUser();

      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Maneja el inicio de sesión con email
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.loginWithEmail(
        email: event.email,
        password: event.password,
      );

      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: _getErrorMessage(e)));
    }
  }

  /// Maneja el inicio de sesión con código de reserva
  Future<void> _onLoginWithBookingRequested(
    AuthLoginWithBookingRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.loginWithBookingCode(
        bookingCode: event.bookingCode,
      );

      emit(AuthAuthenticated(user: user));
    } catch (e) {
      debugPrint('❌ [_onLoginWithBookingRequested] Error: $e');
      debugPrint('❌ [_onLoginWithBookingRequested] Error type: ${e.runtimeType}');
      emit(AuthError(message: _getErrorMessage(e)));
    }
  }

  /// Maneja el inicio de sesión con código de reserva y verificación de email
  Future<void> _onLoginWithBookingAndEmailRequested(
    AuthLoginWithBookingAndEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.loginWithBookingCodeAndEmail(
        email: event.email,
        bookingCode: event.bookingCode,
      );

      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: _getErrorMessage(e)));
    }
  }

  /// Maneja el cierre de sesión
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authRepository.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: _getErrorMessage(e)));
    }
  }

  /// Maneja el envío de email de recuperación
  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authRepository.sendPasswordResetEmail(event.email);
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: _getErrorMessage(e)));
    }
  }

  /// Obtiene un mensaje de error amigable
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('invalid credentials') ||
        errorString.contains('invalid login')) {
      return 'Credenciales incorrectas. Por favor, verifica tu email y contraseña.';
    }

    if (errorString.contains('user not found')) {
      return 'Usuario no encontrado. Por favor, verifica tu email.';
    }

    if (errorString.contains('booking not found')) {
      return 'Reserva no encontrada. Verifica el código y tu apellido.';
    }

    // Errores específicos del login con código + email
    if (errorString.contains('code_not_found')) {
      return 'Código no encontrado. Revisa que esté bien escrito.';
    }

    if (errorString.contains('code_expired')) {
      return 'Este código ya no está activo.';
    }

    if (errorString.contains('email_mismatch')) {
      return 'El correo no coincide con esta reserva.';
    }

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Sin conexión. Comprueba tu red e inténtalo de nuevo.';
    }

    if (errorString.contains('too many requests')) {
      return 'Demasiados intentos. Por favor, espera unos minutos.';
    }

    return 'Ha ocurrido un error. Por favor, intenta de nuevo.';
  }
}
