import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/config/supabase_config.dart';
import '../../domain/entities/guest_access_entity.dart';
import '../../domain/repositories/guest_access_repository.dart';

/// Implementación del repositorio de códigos de acceso del huésped.
///
/// Es la única vía del huésped para obtener los códigos: la RPC
/// `get_guest_access` decide en el servidor si puede verlos.
class GuestAccessRepositoryImpl implements GuestAccessRepository {
  GuestAccessRepositoryImpl({required SupabaseClient supabase})
      : _supabase = supabase;

  final SupabaseClient _supabase;

  @override
  Future<GuestAccessEntity> getAccess(String bookingId) async {
    final response = await _supabase.rpc(
      SupabaseFunctions.getGuestAccess,
      params: {'p_booking_id': bookingId},
    );

    final access = GuestAccessEntity.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
    debugPrint(
      '🔑 [GuestAccessRepository] Reserva $bookingId: ${access.reason.name}, '
      '${access.units.length} unidad(es)',
    );
    return access;
  }
}
