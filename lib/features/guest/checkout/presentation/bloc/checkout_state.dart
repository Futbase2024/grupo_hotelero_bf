import 'package:equatable/equatable.dart';

import '../../domain/repositories/checkout_repository.dart';

/// Estados del BLoC de Check-out
abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class CheckoutInitial extends CheckoutState {
  const CheckoutInitial();
}

/// Cargando datos de la reserva
class CheckoutLoading extends CheckoutState {
  const CheckoutLoading();
}

/// Datos cargados, mostrando resumen
class CheckoutLoaded extends CheckoutState {
  const CheckoutLoaded({
    required this.bookingData,
    this.isAlreadyCheckedOut = false,
  });

  final CheckoutBookingData bookingData;
  final bool isAlreadyCheckedOut;

  @override
  List<Object?> get props => [bookingData, isAlreadyCheckedOut];
}

/// Procesando el check-out
class CheckoutSubmitting extends CheckoutState {
  const CheckoutSubmitting();
}

/// Check-out completado exitosamente
class CheckoutSuccess extends CheckoutState {
  const CheckoutSuccess();
}

/// Error en el check-out
class CheckoutError extends CheckoutState {
  const CheckoutError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
