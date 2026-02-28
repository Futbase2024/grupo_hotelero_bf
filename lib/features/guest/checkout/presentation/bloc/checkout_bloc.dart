import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/checkout_repository.dart';
import 'checkout_event.dart';
import 'checkout_state.dart';

/// BLoC para gestionar el flujo de check-out
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc({
    required CheckoutRepository repository,
  })  : _repository = repository,
        super(const CheckoutInitial()) {
    on<CheckoutStarted>(_onStarted);
    on<CheckoutConfirmed>(_onConfirmed);
    on<CheckoutRetry>(_onRetry);
  }

  final CheckoutRepository _repository;

  Future<void> _onStarted(
    CheckoutStarted event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(const CheckoutLoading());

    try {
      // Cargar datos de la reserva
      final bookingData = await _repository.getBookingForCheckout(event.bookingId);

      // Verificar si ya se hizo check-out
      final isAlreadyCheckedOut = await _repository.isCheckoutCompleted(event.bookingId);

      if (isAlreadyCheckedOut) {
        debugPrint('✅ [CheckoutBloc] Check-out ya completado anteriormente');
      }

      emit(CheckoutLoaded(
        bookingData: bookingData,
        isAlreadyCheckedOut: isAlreadyCheckedOut,
      ));
    } catch (e) {
      debugPrint('❌ [CheckoutBloc] Error al cargar datos: $e');
      emit(CheckoutError(e.toString()));
    }
  }

  Future<void> _onConfirmed(
    CheckoutConfirmed event,
    Emitter<CheckoutState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CheckoutLoaded) return;

    emit(const CheckoutSubmitting());

    try {
      await _repository.completeCheckout(
        bookingId: currentState.bookingData.bookingId,
        feedback: event.feedback,
        rating: event.rating,
      );

      debugPrint('✅ [CheckoutBloc] Check-out completado exitosamente');
      emit(const CheckoutSuccess());
    } catch (e) {
      debugPrint('❌ [CheckoutBloc] Error al completar check-out: $e');
      emit(CheckoutError('Error al procesar el check-out: $e'));
    }
  }

  void _onRetry(
    CheckoutRetry event,
    Emitter<CheckoutState> emit,
  ) {
    if (state is CheckoutError) {
      emit(const CheckoutInitial());
    }
  }
}
