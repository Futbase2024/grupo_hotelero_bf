import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/traveller_form_admin_repository.dart';

class TravellerFormAdminRepositoryImpl implements TravellerFormAdminRepository {
  TravellerFormAdminRepositoryImpl({required SupabaseClient client})
      : _client = client;

  final SupabaseClient _client;

  // La vista admin_bookings_dashboard no incluye la columna (está construida
  // para enmascarar secretos y no conviene rehacerla por un booleano): el
  // staff puede leer `bookings` directamente por RLS.
  @override
  Future<bool> isEnabled(String bookingId) async {
    final data = await _client
        .from('bookings')
        .select('traveller_form_enabled')
        .eq('id', bookingId)
        .maybeSingle();
    return data?['traveller_form_enabled'] as bool? ?? false;
  }

  @override
  Future<bool> setEnabled({
    required String bookingId,
    required bool enabled,
  }) async {
    debugPrint('⚙️ [setTravellerForm] Reserva: $bookingId, activado: $enabled');

    final response = await _client.rpc(
      'set_booking_traveller_form',
      params: {'p_booking_id': bookingId, 'p_enabled': enabled},
    );

    final data = response as Map<String, dynamic>?;
    if (data == null || data['success'] != true) {
      final code = data?['error'] as String? ?? 'unknown';
      debugPrint('❌ [setTravellerForm] Rechazado: $code');
      throw TravellerFormToggleException(code);
    }

    return data['traveller_form_enabled'] as bool? ?? enabled;
  }
}
