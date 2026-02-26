import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/repositories/admin_panel_repository.dart';

/// Implementación del repositorio del panel de administración.
/// Todas las operaciones van a través de Edge Functions de Supabase.
class AdminPanelRepositoryImpl implements AdminPanelRepository {
  AdminPanelRepositoryImpl();

  SupabaseClient get _client => SupabaseConfig.client;
  String get _accessToken => SupabaseConfig.currentSession?.accessToken ?? '';

  Future<Map<String, dynamic>> _callAdminPanel({
    required String action,
    Map<String, dynamic>? params,
  }) async {
    final response = await _client.functions.invoke(
      'admin-panel',
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: {
        'action': action,
        ...?params,
      },
    );

    if (response.status != 200) {
      final data = response.data as Map<String, dynamic>?;
      throw Exception(
        data?['message'] ?? data?['error'] ?? 'Error en la operación: ${response.status}',
      );
    }

    return response.data as Map<String, dynamic>;
  }

  // EF devuelve: { success, summary: { pending_checkins, ... } }
  @override
  Future<DashboardSummaryEntity> getDashboardSummary({
    String? propertyId,
  }) async {
    final response = await _callAdminPanel(
      action: 'dashboard_summary',
      params: propertyId != null ? {'property_id': propertyId} : null,
    );

    return DashboardSummaryEntity.fromJson(
      response['summary'] as Map<String, dynamic>,
    );
  }

  // Consulta directa a la base de datos (sin Edge Function)
  @override
  Future<List<AdminBookingEntity>> listBookings({
    String? propertyId,
    String? statusFilter,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
  }) async {
    try {
      debugPrint('📋 [listBookings] Iniciando consulta...');

      // Construir query base con joins
      // Schema original: id, property_id, unit_id, booking_code, last_name,
      // checkin_date, checkout_date, status, primary_guest_user_id, created_at
      var query = _client
          .from('bookings')
          .select('''
            id,
            booking_code,
            unit_id,
            property_id,
            checkin_date,
            checkout_date,
            status,
            last_name,
            created_at,
            units!bookings_unit_id_fkey (
              name
            ),
            properties!bookings_property_id_fkey (
              name
            ),
            checkins (
              id,
              status
            )
          ''');

      // Aplicar filtros ANTES del order
      if (propertyId != null) {
        query = query.eq('property_id', propertyId);
      }
      if (statusFilter != null && statusFilter != 'all') {
        query = query.eq('status', statusFilter);
      }
      if (fromDate != null) {
        query = query.gte('checkin_date', fromDate.toIso8601String().split('T').first);
      }
      if (toDate != null) {
        query = query.lte('checkout_date', toDate.toIso8601String().split('T').first);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Buscar por código de reserva o apellido
        query = query.or('booking_code.ilike.%$searchQuery%,last_name.ilike.%$searchQuery%');
      }

      // Aplicar orden DESPUÉS de los filtros
      final response = await query.order('created_at', ascending: false);

      debugPrint('📋 [listBookings] Respuesta recibida: ${response.length} registros');

      // Mapear respuesta a entidades
      return (response as List).map((row) {
        // units y properties pueden ser Map o null
        final unitRaw = row['units'];
        final unit = unitRaw != null && unitRaw is Map<String, dynamic>
            ? unitRaw
            : null;

        final propertyRaw = row['properties'];
        final property = propertyRaw != null && propertyRaw is Map<String, dynamic>
            ? propertyRaw
            : null;

        // checkins puede ser un Map (relación uno-a-uno) o null
        final checkinRaw = row['checkins'];
        final checkin = checkinRaw != null && checkinRaw is Map<String, dynamic>
            ? checkinRaw
            : null;

        debugPrint('📋 [listBookings] Procesando booking: ${row['booking_code']}, unit: ${unit?['name']}, property: ${property?['name']}');

        return AdminBookingEntity.fromJson({
          'id': row['id'],
          'booking_code': row['booking_code'],
          'unit_id': row['unit_id'],
          'unit_name': unit?['name'] ?? '',
          'property_id': row['property_id'],
          'property_name': property?['name'] ?? '',
          'check_in_date': row['checkin_date'],
          'check_out_date': row['checkout_date'],
          'num_guests': 1,
          'status': row['status'] ?? 'confirmed',
          'guest_email': '',
          'guest_first_name': null,
          'guest_last_name': row['last_name'],
          'guest_phone': null,
          'staff_notes': null,
          'code_first_used_at': null,
          'code_sent_at': null,
          'checkin_id': checkin?['id'],
          'checkin_status': checkin?['status'],
          'docs_pending': 0,
          'created_at': row['created_at'],
          'updated_at': null,
        });
      }).toList();
    } catch (e, s) {
      debugPrint('❌ [listBookings] Error: $e');
      debugPrint('❌ [listBookings] StackTrace: $s');
      rethrow;
    }
  }

  // La EF no tiene get_booking individual → consulta directa a la vista
  @override
  Future<AdminBookingEntity?> getBooking(String bookingId) async {
    final data = await _client
        .from('admin_bookings_dashboard')
        .select()
        .eq('booking_id', bookingId)
        .maybeSingle();

    if (data == null) return null;
    return AdminBookingEntity.fromJson(data);
  }

  // EF devuelve: { success, booking: {...}, email_sent, email_result }
  @override
  Future<CreateBookingResult> createBooking({
    required String unitId,
    required String guestFirstName,
    required String guestLastName,
    required String guestEmail,
    String? guestPhone,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int numGuests,
    String? staffNotes,
    String? propertyId,
  }) async {
    final response = await _callAdminPanel(
      action: 'create_booking',
      params: {
        if (propertyId != null) 'property_id': propertyId,
        'unit_id': unitId,
        'guest_first_name': guestFirstName,
        'last_name': guestLastName,           // EF usa 'last_name'
        'guest_email': guestEmail,
        if (guestPhone != null) 'guest_phone': guestPhone,
        'checkin_date': checkInDate.toIso8601String().split('T').first,
        'checkout_date': checkOutDate.toIso8601String().split('T').first,
        'num_guests': numGuests,
        if (staffNotes != null) 'staff_notes': staffNotes,
      },
    );

    return CreateBookingResult.fromJson(
      response['booking'] as Map<String, dynamic>,
    );
  }

  // EF devuelve: { success, new_code: "BF-XXXX-XXXX", email_sent, ... }
  @override
  Future<String> regenerateCode(String bookingId) async {
    final response = await _callAdminPanel(
      action: 'regenerate_code',
      params: {'booking_id': bookingId},
    );

    return response['new_code'] as String;
  }

  // EF devuelve aplanado: { success, recipient, provider_id, code }
  @override
  Future<ResendCodeResult> resendCode(String bookingId) async {
    final response = await _callAdminPanel(
      action: 'resend_code',
      params: {'booking_id': bookingId},
    );

    return ResendCodeResult.fromJson(response);
  }

  @override
  Future<void> validateCheckin({
    required String checkinId,
    required String bookingId,
  }) async {
    await _callAdminPanel(
      action: 'validate_checkin',
      params: {
        'checkin_id': checkinId,
        'booking_id': bookingId,
      },
    );
  }

  @override
  Future<void> rejectCheckin({
    required String checkinId,
    required String bookingId,
    String? reason,
  }) async {
    await _callAdminPanel(
      action: 'reject_checkin',
      params: {
        'checkin_id': checkinId,
        'booking_id': bookingId,
        if (reason != null) 'rejection_reason': reason,  // EF usa 'rejection_reason'
      },
    );
  }

  // EF devuelve: { success, units: [...] }
  @override
  Future<List<AdminUnitEntity>> listUnits(String propertyId) async {
    final response = await _callAdminPanel(
      action: 'list_units',
      params: {'property_id': propertyId},
    );

    final data = (response['units'] as List<dynamic>?) ?? [];
    return data
        .map((e) => AdminUnitEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Consulta directa + RPC is_unit_available
  @override
  Future<List<UnitWithAvailability>> listUnitsWithAvailability({
    String? propertyId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
  }) async {
    var query = _client.from('units').select(
      'id, property_id, name, unit_type, address_line1, city, '
      'postal_code, box_code, access_instructions, max_guests, created_at',
    );

    if (propertyId != null) query = query.eq('property_id', propertyId);

    final unitsResponse = await query;
    final units = (unitsResponse as List)
        .map((e) => AdminUnitEntity.fromJson(e as Map<String, dynamic>))
        .toList();

    if (checkInDate == null || checkOutDate == null) {
      return units
          .map((u) => UnitWithAvailability(unit: u, isAvailable: true))
          .toList();
    }

    final checkIn  = checkInDate.toIso8601String().split('T').first;
    final checkOut = checkOutDate.toIso8601String().split('T').first;

    final result = <UnitWithAvailability>[];
    for (final unit in units) {
      final available = await _client.rpc('is_unit_available', params: {
        'p_unit_id':  unit.id,
        'p_checkin':  checkIn,
        'p_checkout': checkOut,
      }) as bool? ?? true;

      String? conflictingGuestName;
      String? conflictingBookingId;
      if (!available) {
        final conflicts = await _client
            .from('bookings')
            .select('id, guest_first_name, last_name')
            .eq('unit_id', unit.id)
            .not('status', 'in', '(cancelled,checked_out)')
            .lt('checkin_date', checkOut)
            .gt('checkout_date', checkIn)
            .limit(1);

        if ((conflicts as List).isNotEmpty) {
          final b = conflicts.first;
          conflictingBookingId = b['id'] as String?;
          final first = (b['guest_first_name'] as String?) ?? '';
          final last  = (b['last_name'] as String?) ?? '';
          final name  = '$first $last'.trim();
          conflictingGuestName = name.isEmpty ? null : name;
        }
      }

      result.add(UnitWithAvailability(
        unit: unit,
        isAvailable: available,
        conflictingBookingId: conflictingBookingId,
        conflictingGuestName: conflictingGuestName,
      ));
    }

    return result;
  }

  // EF devuelve: { success, notifications: [...] }
  @override
  Future<List<StaffNotificationEntity>> getNotifications({
    String? propertyId,
    bool? unreadOnly,
  }) async {
    final params = <String, dynamic>{};
    if (propertyId != null) params['property_id'] = propertyId;

    final response = await _callAdminPanel(
      action: 'get_notifications',
      params: params.isNotEmpty ? params : null,
    );

    final data = (response['notifications'] as List<dynamic>?) ?? [];
    return data
        .map((e) => StaffNotificationEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // La EF no tiene 'mark_notifications_read' → actualización directa
  @override
  Future<void> markNotificationsAsRead(List<String> notificationIds) async {
    await _client
        .from('staff_notifications')
        .update({'is_read': true})
        .inFilter('id', notificationIds);
  }

  @override
  Stream<StaffNotificationEntity> watchNotifications({
    String? propertyId,
  }) {
    return _client
        .from('staff_notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50)
        .expand((list) => list)
        .where((row) => propertyId == null || row['property_id'] == propertyId)
        .map((row) => StaffNotificationEntity.fromJson(row));
  }
}