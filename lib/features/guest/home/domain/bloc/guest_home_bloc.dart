import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../admin/domain/entities/admin_booking_entity.dart';
import '../../../../admin/domain/repositories/admin_panel_repository.dart';
import 'guest_home_event.dart';
import 'guest_home_state.dart';

/// BLoC para la pantalla home del huésped
class GuestHomeBloc extends Bloc<GuestHomeEvent, GuestHomeState> {
  GuestHomeBloc({
    required AdminPanelRepository repository,
  })  : _repository = repository,
        super(const GuestHomeInitial()) {
    on<GuestHomeLoadBooking>(_onLoadBooking);
    on<GuestHomeRefreshBooking>(_onRefreshBooking);
  }

  final AdminPanelRepository _repository;

  Future<void> _onLoadBooking(
    GuestHomeLoadBooking event,
    Emitter<GuestHomeState> emit,
  ) async {
    emit(const GuestHomeLoading());

    try {
      final booking = await _repository.getBooking(event.bookingId);

      if (booking == null) {
        emit(const GuestHomeNoBooking());
        return;
      }

      emit(GuestHomeLoaded(booking: booking));
    } catch (e) {
      emit(GuestHomeError(e.toString()));
    }
  }

  Future<void> _onRefreshBooking(
    GuestHomeRefreshBooking event,
    Emitter<GuestHomeState> emit,
  ) async {
    // Mantener los datos anteriores mientras se refresca
    AdminBookingEntity? currentBooking;
    if (state is GuestHomeLoaded) {
      currentBooking = (state as GuestHomeLoaded).booking;
    }

    if (currentBooking != null) {
      emit(GuestHomeLoaded(booking: currentBooking, isRefreshing: true));
    }

    try {
      final booking = await _repository.getBooking(event.bookingId);

      if (booking == null) {
        emit(const GuestHomeNoBooking());
        return;
      }

      emit(GuestHomeLoaded(booking: booking));
    } catch (e) {
      // Si hay error, volver al estado anterior sin isRefreshing
      if (currentBooking != null) {
        emit(GuestHomeLoaded(booking: currentBooking));
      } else {
        emit(GuestHomeError(e.toString()));
      }
    }
  }
}
