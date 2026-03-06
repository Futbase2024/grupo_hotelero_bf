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

  // Consulta directa a la base de datos (más robusto que Edge Function)
  @override
  Future<DashboardSummaryEntity> getDashboardSummary({
    String? propertyId,
  }) async {
    try {
      debugPrint('📊 [getDashboardSummary] Iniciando consulta...');

      // 1. Contar check-ins pendientes (status: draft o submitted)
      var pendingCheckinsQuery = _client.from('checkins').select('id');
      if (propertyId != null) {
        pendingCheckinsQuery = pendingCheckinsQuery.eq('property_id', propertyId);
      }
      final pendingCheckinsResponse = await pendingCheckinsQuery.inFilter('status', ['draft', 'submitted']);
      final pendingCheckins = (pendingCheckinsResponse as List).length;

      // 2. Contar llegadas próximas (check-in en los próximos 7 días)
      final now = DateTime.now();
      final sevenDaysLater = now.add(const Duration(days: 7));
      var upcomingQuery = _client.from('bookings').select('id');
      if (propertyId != null) {
        upcomingQuery = upcomingQuery.eq('property_id', propertyId);
      }
      final upcomingResponse = await upcomingQuery
          .gte('checkin_date', now.toIso8601String().split('T').first)
          .lte('checkin_date', sevenDaysLater.toIso8601String().split('T').first)
          .not('status', 'in', '(cancelled,closed)');
      final upcomingCheckins = (upcomingResponse as List).length;

      // 3. Contar unidades activas
      var unitsQuery = _client.from('units').select('id');
      if (propertyId != null) {
        unitsQuery = unitsQuery.eq('property_id', propertyId);
      }
      final unitsResponse = await unitsQuery;
      final totalUnits = (unitsResponse as List).length;

      // 4. Contar notificaciones no leídas
      var notificationsQuery = _client.from('staff_notifications').select('id');
      if (propertyId != null) {
        notificationsQuery = notificationsQuery.eq('property_id', propertyId);
      }
      final notificationsResponse = await notificationsQuery.eq('is_read', false);
      final unreadNotifications = (notificationsResponse as List).length;

      // 5. Obtener últimos 5 check-ins con información completa
      var recentCheckinsQuery = _client.from('checkins').select('''
            id,
            status,
            submitted_at,
            booking_id,
            bookings (
              id,
              booking_code,
              guest_first_name,
              last_name,
              unit_id,
              units (
                name
              )
            )
          ''');
      if (propertyId != null) {
        recentCheckinsQuery = recentCheckinsQuery.eq('property_id', propertyId);
      }
      final recentCheckinsResponse = await recentCheckinsQuery
          .not('submitted_at', 'is', null)
          .order('submitted_at', ascending: false)
          .limit(5);

      // Mapear recent_checkins al formato esperado
      final recentCheckins = (recentCheckinsResponse as List).map((row) {
        final booking = row['bookings'] as Map<String, dynamic>?;
        final unit = booking?['units'] as Map<String, dynamic>?;
        final guestFirstName = (booking?['guest_first_name'] as String?) ?? '';
        final lastName = (booking?['last_name'] as String?) ?? '';
        final guestName = '$guestFirstName $lastName'.trim();

        return {
          'booking_id': booking?['id'] ?? row['booking_id'],
          'booking_code': booking?['booking_code'] ?? '',
          'guest_name': guestName.isNotEmpty ? guestName : 'Huésped',
          'unit_name': unit?['name'] ?? '',
          'checkin_status': row['status'] ?? 'draft',
          'submitted_at': row['submitted_at'],
        };
      }).toList();

      debugPrint('📊 [getDashboardSummary] pendientes: $pendingCheckins, próximos: $upcomingCheckins, unidades: $totalUnits, recientes: ${recentCheckins.length}');

      return DashboardSummaryEntity.fromJson({
        'pending_checkins': pendingCheckins,
        'upcoming_checkins': upcomingCheckins,
        'unread_notifications': unreadNotifications,
        'total_units': totalUnits,
        'recent_checkins': recentCheckins,
      });
    } catch (e, s) {
      debugPrint('❌ [getDashboardSummary] Error: $e');
      debugPrint('❌ [getDashboardSummary] StackTrace: $s');
      rethrow;
    }
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

      // Columnas disponibles en la tabla bookings:
      // id, property_id, unit_id, booking_code, last_name, checkin_date, checkout_date,
      // status, primary_guest_user_id, created_at, num_guests, staff_notes,
      // code_first_used_at, guest_first_name, guest_email, guest_phone, code_sent_at,
      // keybox_code, num_adults, num_children, children_ages
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
            guest_first_name,
            guest_email,
            guest_phone,
            num_guests,
            num_adults,
            num_children,
            staff_notes,
            code_first_used_at,
            code_sent_at,
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
          'num_guests': row['num_guests'] ?? 1,
          'status': row['status'] ?? 'confirmed',
          'booking_status': row['status'] ?? 'confirmed', // Usar status como booking_status
          'checkout_status': null, // No existe en la tabla
          'guest_email': row['guest_email'] ?? '',
          'guest_first_name': row['guest_first_name'],
          'guest_last_name': row['last_name'],
          'guest_phone': row['guest_phone'],
          'staff_notes': row['staff_notes'],
          'code_first_used_at': row['code_first_used_at'],
          'code_sent_at': row['code_sent_at'],
          'checkin_id': checkin?['id'],
          'checkin_status': checkin?['status'],
          'docs_pending': 0,
          'activated_at': null, // No existe en la tabla
          'closed_at': null, // No existe en la tabla
          'checkout_requested_at': null, // No existe en la tabla
          'checkout_validated_at': null, // No existe en la tabla
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
    try {
      debugPrint('📋 [getBooking] Consultando booking: $bookingId');
      final data = await _client
          .from('admin_bookings_dashboard')
          .select()
          .eq('booking_id', bookingId)
          .maybeSingle();

      if (data == null) {
        debugPrint('📋 [getBooking] No se encontró booking');
        return null;
      }

      debugPrint('📋 [getBooking] Datos recibidos, parseando entity...');
      final entity = AdminBookingEntity.fromJson(data);
      debugPrint('📋 [getBooking] Entity creado: unitName=${entity.unitName}');
      return entity;
    } on PostgrestException catch (e) {
      debugPrint('❌ [getBooking] PostgrestException: ${e.message}');
      debugPrint('❌ [getBooking] Code: ${e.code}');
      debugPrint('❌ [getBooking] Details: ${e.details}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ [getBooking] Error: $e');
      debugPrint('❌ [getBooking] StackTrace: $stackTrace');
      rethrow;
    }
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
    int numAdults = 1,
    int numChildren = 0,
    List<int> childrenAges = const [],
    String? staffNotes,
    String? propertyId,
  }) async {
    // num_guests se calcula automáticamente en la RPC (num_adults + num_children)
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
        'num_adults': numAdults,
        'num_children': numChildren,
        'children_ages': childrenAges,
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

  /// Cancela un check-in usando RPC
  /// A diferencia del rechazo, la cancelación NO permite corrección por el huésped
  @override
  Future<void> cancelCheckin({
    required String checkinId,
    required String bookingId,
    String? reason,
  }) async {
    try {
      debugPrint('🚫 [cancelCheckin] Cancelando check-in: $checkinId');

      final success = await _client.rpc(
        'cancel_checkin',
        params: {
          'p_checkin_id': checkinId,
          'p_reason': reason ?? 'Sin motivo especificado',
        },
      ) as bool?;

      if (success != true) {
        throw Exception('No se pudo cancelar el check-in');
      }

      debugPrint('✅ [cancelCheckin] Check-in cancelado correctamente');
    } catch (e, s) {
      debugPrint('❌ [cancelCheckin] Error: $e');
      debugPrint('❌ [cancelCheckin] StackTrace: $s');
      rethrow;
    }
  }

  /// Obtiene el detalle completo de un check-in usando la función RPC
  @override
  Future<CheckinDetailEntity> getCheckinDetail(String checkinId) async {
    try {
      debugPrint('📋 [getCheckinDetail] Obteniendo detalle: $checkinId');

      final response = await _client.rpc(
        'get_checkin_details',
        params: {'p_checkin_id': checkinId},
      );

      if (response == null || (response is List && response.isEmpty)) {
        throw Exception('Check-in no encontrado');
      }

      final data = response is List ? response.first : response;
      debugPrint('📋 [getCheckinDetail] Datos recibidos');

      return CheckinDetailEntity.fromJson(data as Map<String, dynamic>);
    } catch (e, s) {
      debugPrint('❌ [getCheckinDetail] Error: $e');
      debugPrint('❌ [getCheckinDetail] StackTrace: $s');
      rethrow;
    }
  }

  /// Obtiene la URL firmada para ver un documento
  @override
  Future<String> getDocumentUrl(String storagePath) async {
    try {
      debugPrint('📄 [getDocumentUrl] Generando URL para: $storagePath');

      // Generar URL firmada válida por 1 año (31536000 segundos)
      final url = await _client.storage
          .from('guest-documents')
          .createSignedUrl(storagePath, 31536000);

      debugPrint('✅ [getDocumentUrl] URL generada');
      return url;
    } catch (e, s) {
      debugPrint('❌ [getDocumentUrl] Error: $e');
      debugPrint('❌ [getDocumentUrl] StackTrace: $s');
      rethrow;
    }
  }

  // ==================== MÉTODOS DE CHECK-OUT ====================

  /// Valida el check-out de una reserva usando RPC
  @override
  Future<void> validateCheckout({
    required String bookingId,
    String? notes,
  }) async {
    try {
      debugPrint('✅ [validateCheckout] Validando check-out: $bookingId');

      final success = await _client.rpc(
        'validate_checkout',
        params: {
          'p_booking_id': bookingId,
          if (notes != null) 'p_notes': notes,
        },
      ) as bool?;

      if (success != true) {
        throw Exception('No se pudo validar el check-out');
      }

      debugPrint('✅ [validateCheckout] Check-out validado correctamente');
    } catch (e, s) {
      debugPrint('❌ [validateCheckout] Error: $e');
      debugPrint('❌ [validateCheckout] StackTrace: $s');
      rethrow;
    }
  }

  /// Rechaza el check-out con motivo (incidencias)
  @override
  Future<void> rejectCheckout({
    required String bookingId,
    required String reason,
  }) async {
    try {
      debugPrint('🔴 [rejectCheckout] Rechazando check-out: $bookingId');

      final success = await _client.rpc(
        'reject_checkout',
        params: {
          'p_booking_id': bookingId,
          'p_reason': reason,
        },
      ) as bool?;

      if (success != true) {
        throw Exception('No se pudo rechazar el check-out');
      }

      debugPrint('✅ [rejectCheckout] Check-out rechazado correctamente');
    } catch (e, s) {
      debugPrint('❌ [rejectCheckout] Error: $e');
      debugPrint('❌ [rejectCheckout] StackTrace: $s');
      rethrow;
    }
  }

  /// Cierra una reserva manualmente
  @override
  Future<void> closeBooking({
    required String bookingId,
    String? notes,
  }) async {
    try {
      debugPrint('🔒 [closeBooking] Cerrando reserva: $bookingId');

      final success = await _client.rpc(
        'close_booking',
        params: {
          'p_booking_id': bookingId,
          if (notes != null) 'p_notes': notes,
        },
      ) as bool?;

      if (success != true) {
        throw Exception('No se pudo cerrar la reserva');
      }

      debugPrint('✅ [closeBooking] Reserva cerrada correctamente');
    } catch (e, s) {
      debugPrint('❌ [closeBooking] Error: $e');
      debugPrint('❌ [closeBooking] StackTrace: $s');
      rethrow;
    }
  }

  /// Cancela una reserva
  @override
  Future<void> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    try {
      debugPrint('🚫 [cancelBooking] Cancelando reserva: $bookingId');

      final success = await _client.rpc(
        'cancel_booking',
        params: {
          'p_booking_id': bookingId,
          if (reason != null) 'p_reason': reason,
        },
      ) as bool?;

      if (success != true) {
        throw Exception('No se pudo cancelar la reserva');
      }

      debugPrint('✅ [cancelBooking] Reserva cancelada correctamente');
    } catch (e, s) {
      debugPrint('❌ [cancelBooking] Error: $e');
      debugPrint('❌ [cancelBooking] StackTrace: $s');
      rethrow;
    }
  }

  // ==================== MÉTODOS DE UNIDADES ====================

  /// Lista unidades de una propiedad directamente desde la base de datos
  @override
  Future<List<AdminUnitEntity>> listUnits(String propertyId) async {
    try {
      debugPrint('🏠 [listUnits] Cargando unidades de propiedad: $propertyId');

      final response = await _client
          .from('units')
          .select('''
            id,
            property_id,
            name,
            unit_type,
            address_line1,
            city,
            postal_code,
            box_code,
            access_instructions,
            wifi_network,
            wifi_password,
            created_at
          ''')
          .eq('property_id', propertyId)
          .order('name');

      final units = (response as List)
          .map((e) => AdminUnitEntity.fromJson(e as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [listUnits] ${units.length} unidades encontradas');
      return units;
    } catch (e, s) {
      debugPrint('❌ [listUnits] Error: $e');
      debugPrint('❌ [listUnits] StackTrace: $s');
      rethrow;
    }
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

  /// Actualiza los datos de WiFi de una unidad
  @override
  Future<void> updateUnitWifi({
    required String unitId,
    required String wifiNetwork,
    required String wifiPassword,
  }) async {
    try {
      debugPrint('📶 [updateUnitWifi] Actualizando WiFi de unidad: $unitId');

      await _client
          .from('units')
          .update({
            'wifi_network': wifiNetwork,
            'wifi_password': wifiPassword,
          })
          .eq('id', unitId);

      debugPrint('✅ [updateUnitWifi] WiFi actualizado correctamente');
    } catch (e, s) {
      debugPrint('❌ [updateUnitWifi] Error: $e');
      debugPrint('❌ [updateUnitWifi] StackTrace: $s');
      rethrow;
    }
  }

  /// Actualiza el código de la puerta principal de una propiedad
  @override
  Future<void> updatePropertyMainDoorKeycode({
    required String propertyId,
    required String keycode,
  }) async {
    try {
      debugPrint('🔑 [updatePropertyMainDoorKeycode] Actualizando keycode de propiedad: $propertyId');

      await _client
          .from('properties')
          .update({'main_door_keycode': keycode})
          .eq('id', propertyId);

      debugPrint('✅ [updatePropertyMainDoorKeycode] Keycode actualizado correctamente');
    } catch (e, s) {
      debugPrint('❌ [updatePropertyMainDoorKeycode] Error: $e');
      debugPrint('❌ [updatePropertyMainDoorKeycode] StackTrace: $s');
      rethrow;
    }
  }

  // Obtener notificaciones directamente desde la base de datos
  @override
  Future<List<StaffNotificationEntity>> getNotifications({
    String? propertyId,
    bool? unreadOnly,
  }) async {
    try {
      debugPrint('📬 [getNotifications] Obteniendo notificaciones...');

      var query = _client
          .from('staff_notifications')
          .select('''
            id,
            property_id,
            type,
            title,
            body,
            booking_id,
            data,
            is_read,
            created_at
          ''');

      if (propertyId != null) {
        query = query.eq('property_id', propertyId);
      }

      if (unreadOnly == true) {
        query = query.eq('is_read', false);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(100);

      final notifications = (response as List)
          .map((e) => StaffNotificationEntity.fromJson(e as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [getNotifications] ${notifications.length} notificaciones encontradas');
      return notifications;
    } catch (e, s) {
      debugPrint('❌ [getNotifications] Error: $e');
      debugPrint('❌ [getNotifications] StackTrace: $s');
      rethrow;
    }
  }

  // La EF no tiene 'mark_notifications_read' → actualización directa
  @override
  Future<void> markNotificationsAsRead(List<String> notificationIds) async {
    try {
      debugPrint('📬 [markNotificationsAsRead] Marcando ${notificationIds.length} notificaciones como leídas');
      await _client
          .from('staff_notifications')
          .update({'is_read': true})
          .inFilter('id', notificationIds);
      debugPrint('✅ [markNotificationsAsRead] Notificaciones marcadas como leídas');
    } catch (e, s) {
      debugPrint('❌ [markNotificationsAsRead] Error: $e');
      debugPrint('❌ [markNotificationsAsRead] StackTrace: $s');
      rethrow;
    }
  }

  @override
  Future<void> markAllNotificationsAsRead() async {
    try {
      debugPrint('📬 [markAllNotificationsAsRead] Marcando todas las notificaciones como leídas');
      await _client
          .from('staff_notifications')
          .update({'is_read': true})
          .eq('is_read', false);
      debugPrint('✅ [markAllNotificationsAsRead] Todas las notificaciones marcadas como leídas');
    } catch (e, s) {
      debugPrint('❌ [markAllNotificationsAsRead] Error: $e');
      debugPrint('❌ [markAllNotificationsAsRead] StackTrace: $s');
      rethrow;
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      debugPrint('🗑️ [deleteNotification] Eliminando notificación: $notificationId');
      await _client
          .from('staff_notifications')
          .delete()
          .eq('id', notificationId);
      debugPrint('✅ [deleteNotification] Notificación eliminada');
    } catch (e, s) {
      debugPrint('❌ [deleteNotification] Error: $e');
      debugPrint('❌ [deleteNotification] StackTrace: $s');
      rethrow;
    }
  }

  @override
  Future<void> deleteAllNotifications() async {
    try {
      debugPrint('🗑️ [deleteAllNotifications] Eliminando todas las notificaciones');
      await _client
          .from('staff_notifications')
          .delete()
          .neq('id', '00000000-0000-0000-0000-000000000000'); // Truco para eliminar todas
      debugPrint('✅ [deleteAllNotifications] Todas las notificaciones eliminadas');
    } catch (e, s) {
      debugPrint('❌ [deleteAllNotifications] Error: $e');
      debugPrint('❌ [deleteAllNotifications] StackTrace: $s');
      rethrow;
    }
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

  @override
  Stream<void> watchCheckins({
    String? propertyId,
  }) {
    // Stream que emite cuando hay cambios en la tabla checkins
    // Solo nos interesa saber que hubo un cambio, no los datos específicos
    return _client
        .from('checkins')
        .stream(primaryKey: ['id'])
        .map((_) {});
  }

  // ==================== MÉTODOS DE DOCUMENTOS ====================

  /// Limpia documentos expirados (más de 1 año)
  @override
  Future<CleanupResult> cleanupExpiredDocuments() async {
    try {
      debugPrint('🧹 [cleanupExpiredDocuments] Iniciando limpieza...');

      final response = await _client.rpc('cleanup_expired_documents');

      final result = CleanupResult.fromJson(response as Map<String, dynamic>);
      debugPrint('✅ [cleanupExpiredDocuments] Eliminados: ${result.deletedCount}, Errores: ${result.errorCount}');

      return result;
    } catch (e, s) {
      debugPrint('❌ [cleanupExpiredDocuments] Error: $e');
      debugPrint('❌ [cleanupExpiredDocuments] StackTrace: $s');
      rethrow;
    }
  }

  /// Obtiene documentos próximos a expirar
  @override
  Future<List<ExpiringDocument>> getDocumentsExpiringSoon({int daysBefore = 7}) async {
    try {
      debugPrint('📅 [getDocumentsExpiringSoon] Buscando documentos que expiran en $daysBefore días...');

      final response = await _client.rpc(
        'get_documents_expiring_soon',
        params: {'days_before': daysBefore},
      );

      final documents = (response as List)
          .map((e) => ExpiringDocument.fromJson(e as Map<String, dynamic>))
          .toList();

      debugPrint('📅 [getDocumentsExpiringSoon] Encontrados: ${documents.length}');
      return documents;
    } catch (e, s) {
      debugPrint('❌ [getDocumentsExpiringSoon] Error: $e');
      debugPrint('❌ [getDocumentsExpiringSoon] StackTrace: $s');
      rethrow;
    }
  }
}