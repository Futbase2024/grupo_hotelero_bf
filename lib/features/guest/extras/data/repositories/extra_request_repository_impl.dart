import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/config/supabase_config.dart';
import '../../domain/entities/extra_request_entity.dart';
import '../../domain/repositories/extra_request_repository.dart';

/// Implementación con Supabase del repositorio de solicitudes de extras.
class ExtraRequestRepositoryImpl implements ExtraRequestRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  static const String _table = 'extra_requests';

  /// Código Postgres de violación de restricción única.
  static const String _uniqueViolationCode = '23505';

  /// Mensaje que lanza el trigger `extra_requests_check_request_window`.
  static const String _windowClosedMarker = 'ROMANTIC_PACK_WINDOW_CLOSED';

  @override
  Future<ExtraRequestEntity> create(ExtraRequestEntity request) async {
    debugPrint('💝 [ExtraRequest] Creando solicitud: ${request.extraType}');
    try {
      final response = await _client
          .from(_table)
          .insert(request.toInsertJson())
          .select()
          .single();
      debugPrint('✅ [ExtraRequest] Solicitud creada');
      return ExtraRequestEntity.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == _uniqueViolationCode) {
        debugPrint('⚠️ [ExtraRequest] Solicitud duplicada rechazada por la BD');
        throw const ExtraAlreadyRequestedException();
      }
      if (e.message.contains(_windowClosedMarker)) {
        debugPrint('⚠️ [ExtraRequest] Solicitud fuera de plazo (24 h)');
        throw const ExtraRequestWindowClosedException();
      }
      rethrow;
    }
  }

  @override
  Future<ExtraRequestEntity?> getActiveByBookingAndType({
    required String bookingId,
    required String extraType,
  }) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('booking_id', bookingId)
        .eq('extra_type', extraType)
        .neq('status', ExtraRequestStatus.cancelled.dbValue)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return ExtraRequestEntity.fromJson(response);
  }

  @override
  Future<List<ExtraRequestEntity>> getAll({
    String? propertyId,
    ExtraRequestStatus? status,
  }) async {
    var query = _client.from(_table).select();

    if (propertyId != null && propertyId.isNotEmpty) {
      query = query.eq('property_id', propertyId);
    }
    if (status != null) {
      query = query.eq('status', status.dbValue);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((json) => ExtraRequestEntity.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<List<ExtraRequestEntity>> watchAll({String? propertyId}) {
    var stream = _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return stream.map((rows) {
      final items = rows
          .map((json) => ExtraRequestEntity.fromJson(json))
          .where((r) =>
              propertyId == null ||
              propertyId.isEmpty ||
              r.propertyId == propertyId)
          .toList();
      return items;
    });
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
    debugPrint('🗑️ [ExtraRequest] Solicitud eliminada: $id');
  }

  @override
  Future<void> markAsManaged(
    String id, {
    String? managedBy,
    String? notes,
  }) {
    return updateStatus(
      id,
      ExtraRequestStatus.managed,
      managedBy: managedBy,
      notes: notes,
    );
  }

  @override
  Future<void> updateStatus(
    String id,
    ExtraRequestStatus status, {
    String? managedBy,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'status': status.dbValue,
    };
    if (status == ExtraRequestStatus.managed) {
      payload['managed_at'] = DateTime.now().toIso8601String();
      if (managedBy != null) payload['managed_by'] = managedBy;
    }
    if (notes != null) payload['notes'] = notes;

    await _client.from(_table).update(payload).eq('id', id);
    debugPrint('✅ [ExtraRequest] Estado actualizado a ${status.dbValue}');
  }
}
