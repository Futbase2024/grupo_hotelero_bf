import 'package:equatable/equatable.dart';

/// Eventos del BLoC de la pantalla home del huésped
abstract class GuestHomeEvent extends Equatable {
  const GuestHomeEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar los datos de la reserva
class GuestHomeLoadBooking extends GuestHomeEvent {
  const GuestHomeLoadBooking(this.bookingId);

  final String bookingId;

  @override
  List<Object?> get props => [bookingId];
}

/// Evento para refrescar los datos de la reserva
class GuestHomeRefreshBooking extends GuestHomeEvent {
  const GuestHomeRefreshBooking(this.bookingId);

  final String bookingId;

  @override
  List<Object?> get props => [bookingId];
}
