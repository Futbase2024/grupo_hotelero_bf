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
            property_id,
            unit:units!bookings_unit_id_fkey (
              name,
              property:properties!units_property_id_fkey (
                id,
                name
              )
            )
          ''')
          .eq('id', bookingId)
          .single();

      final unitData = response['unit'] as Map<String, dynamic>?;
      final propertyData = unitData?['property'] as Map<String, dynamic>?;

      return CheckoutBookingData(
        bookingId: response['id'] as String,
        bookingCode: response['booking_code'] as String,
        unitName: unitData?['name'] as String? ?? '',
        propertyName: propertyData?['name'] as String? ?? '',
        checkInDate: DateTime.parse(response['checkin_date'] as String),
        checkOutDate: DateTime.parse(response['checkout_date'] as String),
        numGuests: (response['num_adults'] as int? ?? 1) + (response['num_children'] as int? ?? 0),
        guestFullName: '${response['guest_first_name'] ?? ''} ${response['last_name'] ?? ''}'.trim(),
        guestEmail: response['guest_email'] as String? ?? '',
        propertyId: propertyData?['id'] as String?,
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

      // 1. Actualizar el check-in con el estado de checkout
      await _supabase
          .from('checkins')
          .update({
            'checkout_status': 'completed',
            'checkout_at': DateTime.now().toIso8601String(),
            'checkout_feedback': feedback,
            'checkout_rating': rating,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('booking_id', bookingId);

      // 2. Actualizar el estado de la reserva a 'checked_out'
      await _supabase
          .from('bookings')
          .update({
            'status': 'checked_out',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId);

      debugPrint('✅ [CheckoutRepository] Checkout completado correctamente');
    } catch (e) {
      debugPrint('❌ [CheckoutRepository] Error completando checkout: $e');
      rethrow;
    }
  }
}
