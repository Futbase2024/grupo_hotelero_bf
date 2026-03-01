import 'package:equatable/equatable.dart';
import '../../../../admin/domain/entities/admin_booking_entity.dart';

/// Estados del BLoC de la pantalla home del huésped
abstract class GuestHomeState extends Equatable {
  const GuestHomeState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class GuestHomeInitial extends GuestHomeState {
  const GuestHomeInitial();
}

/// Estado de carga
class GuestHomeLoading extends GuestHomeState {
  const GuestHomeLoading();
}

/// Estado con datos de la reserva cargados
class GuestHomeLoaded extends GuestHomeState {
  const GuestHomeLoaded({
    required this.booking,
    this.isRefreshing = false,
  });

  final AdminBookingEntity booking;
  final bool isRefreshing;

  @override
  List<Object?> get props => [booking, isRefreshing];
}

/// Estado de error
class GuestHomeError extends GuestHomeState {
  const GuestHomeError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Estado sin reserva asociada
class GuestHomeNoBooking extends GuestHomeState {
  const GuestHomeNoBooking();
}
