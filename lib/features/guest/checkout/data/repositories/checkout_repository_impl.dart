import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/checkout_repository.dart';

/// Implementación del repositorio de check-out
class CheckoutRepositoryImpl implements CheckoutRepository {
  CheckoutRepositoryImpl({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  @override
  Future<CheckoutBookingData> getBookingForCheckout(String bookingId) async {
    try {
      debugPrint('📋 [CheckoutRepository] Obteniendo datos de reserva: $bookingId');

      // Consulta base sin JOINs problemáticos (en web causan aserción si son null)
      final response = await _supabase
          .from('bookings')
          .select('''
            id,
            booking_code,
            checkin_date,
            checkout_date,
            num_adults,
            num_children,
            guest_first_name,
            last_name,
            guest_email,
            unit_id,
            property_id
          ''')
          .eq('id', bookingId)
          .single();

      // Obtener datos de unit y property por separado
      String? unitName;
      String? propertyName;
      String? propertyId;

      final unitId = response['unit_id'] as String?;
      final propId = response['property_id'] as String?;

      if (unitId != null) {
        try {
          final unitResponse = await _supabase
              .from('units')
              .select('name')
              .eq('id', unitId)
              .maybeSingle();
          unitName = unitResponse?['name'] as String?;
        } catch (e) {
          debugPrint('⚠️ [CheckoutRepository] Error obteniendo unit: $e');
        }
      }

      if (propId != null) {
        try {
          final propertyResponse = await _supabase
              .from('properties')
              .select('id, name')
              .eq('id', propId)
              .maybeSingle();
          propertyId = propertyResponse?['id'] as String?;
          propertyName = propertyResponse?['name'] as String?;
        } catch (e) {
          debugPrint('⚠️ [CheckoutRepository] Error obteniendo property: $e');
        }
      }

      return CheckoutBookingData(
        bookingId: response['id'] as String,
        bookingCode: response['booking_code'] as String,
        unitName: unitName ?? '',
        propertyName: propertyName ?? '',
        checkInDate: DateTime.parse(response['checkin_date'] as String),
        checkOutDate: DateTime.parse(response['checkout_date'] as String),
        numGuests: (response['num_adults'] as int? ?? 1) + (response['num_children'] as int? ?? 0),
        guestFullName: '${response['guest_first_name'] ?? ''} ${response['last_name'] ?? ''}'.trim(),
        guestEmail: response['guest_email'] as String? ?? '',
        propertyId: propertyId ?? propId,
      );
    } catch (e) {
      debugPrint('❌ [CheckoutRepository] Error obteniendo reserva: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isCheckoutCompleted(String bookingId) async {
    try {
      final response = await _supabase
          .from('checkins')
          .select('checkout_status')
          .eq('booking_id', bookingId)
          .maybeSingle();

      if (response == null) return false;

      final status = response['checkout_status'] as String?;
      return status == 'completed';
    } catch (e) {
      debugPrint('❌ [CheckoutRepository] Error verificando checkout: $e');
      return false;
    }
  }

  @override
  Future<void> completeCheckout({
    required String bookingId,
    String? feedback,
    int? rating,
  }) async {
    try {
      debugPrint('✅ [CheckoutRepository] Completando checkout para reserva: $bookingId');

      // El RPC registra el check-out en `checkins` y cierra la reserva entera
      // (status, booking_status, checkout_status y closed_at) en el servidor.
      // Antes se hacía un UPDATE directo que solo cambiaba `status`, y la
      // reserva quedaba a medio cerrar.
      final closed = await _supabase.rpc(
        'complete_guest_checkout',
        params: {
          'p_booking_id': bookingId,
          'p_feedback': feedback,
          'p_rating': rating,
        },
      ) as bool?;

      if (closed != true) {
        // La reserva ya estaba cerrada o cancelada: no hay nada más que hacer.
        debugPrint('ℹ️ [CheckoutRepository] La reserva ya estaba cerrada');
      }

      debugPrint('✅ [CheckoutRepository] Checkout completado correctamente');
    } catch (e) {
      debugPrint('❌ [CheckoutRepository] Error completando checkout: $e');
      rethrow;
    }
  }
}
