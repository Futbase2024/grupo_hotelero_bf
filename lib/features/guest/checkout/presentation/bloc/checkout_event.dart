import 'package:equatable/equatable.dart';

/// Eventos del BLoC de Check-out
abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

/// Iniciar el flujo de check-out
class CheckoutStarted extends CheckoutEvent {
  const CheckoutStarted(this.bookingId);

  final String bookingId;

  @override
  List<Object?> get props => [bookingId];
}

/// Confirmar el check-out
class CheckoutConfirmed extends CheckoutEvent {
  const CheckoutConfirmed({
    this.feedback,
    this.rating,
  });

  final String? feedback;
  final int? rating;

  @override
  List<Object?> get props => [feedback, rating];
}

/// Reintentar después de un error
class CheckoutRetry extends CheckoutEvent {
  const CheckoutRetry();
}
