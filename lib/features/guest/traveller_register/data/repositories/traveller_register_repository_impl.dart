import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/traveller_entity.dart';
import '../../domain/entities/traveller_register_status.dart';
import '../../domain/repositories/traveller_register_repository.dart';

class TravellerRegisterRepositoryImpl implements TravellerRegisterRepository {
  TravellerRegisterRepositoryImpl({required SupabaseClient client})
      : _client = client;

  final SupabaseClient _client;

  static const String _guestColumns = '''
    id, full_name, first_name, last_name_1, last_name_2, sex, birth_date,
    nationality, document_type, document_number, document_support_number,
    residence_address, residence_city, residence_postal_code, residence_country,
    phone, landline_phone, email, register_format
  ''';

  @override
  Future<List<TravellerEntity>> getTravellers(String bookingId) async {
    final rows = await _client
        .from('booking_guests')
        .select('guest_id, is_primary, responsible_guest_id, relationship, '
            'created_at, guests($_guestColumns)')
        .eq('booking_id', bookingId)
        .order('is_primary', ascending: false)
        .order('created_at');

    return rows.map(TravellerEntity.fromBookingGuestJson).toList();
  }

  @override
  Future<String> saveTraveller({
    required String bookingId,
    required TravellerEntity traveller,
  }) {
    return _call('save_traveller_guest', {
      'p_booking_id': bookingId,
      'p_guest_id': traveller.id,
      'p_data': traveller.toRpcData(),
    }).then((result) => result as String);
  }

  @override
  Future<TravellerRegisterStatus> getStatus(String bookingId) async {
    final result = await _call(
      'traveller_register_issues',
      {'p_booking_id': bookingId},
    );
    return TravellerRegisterStatus.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<String> signEntryForm({
    required String bookingId,
    required String guestId,
    required String signatureSvg,
  }) {
    return _call('sign_traveller_entry_form', {
      'p_booking_id': bookingId,
      'p_guest_id': guestId,
      'p_signature_svg': signatureSvg,
      'p_form_version': kTravellerEntryFormVersion,
    }).then((result) => result as String);
  }

  @override
  Future<void> submit(String bookingId) =>
      _call('submit_traveller_checkin', {'p_booking_id': bookingId});

  /// Llama a una RPC y traduce los errores de Postgres a códigos conocidos.
  /// No se registran los parámetros: llevan datos personales.
  Future<dynamic> _call(String rpc, Map<String, dynamic> params) async {
    try {
      return await _client.rpc(rpc, params: params);
    } on PostgrestException catch (e) {
      debugPrint('❌ [TravellerRegister] $rpc: ${e.code} ${e.message}');
      throw TravellerRegisterException.fromServerMessage(e.message);
    }
  }
}
