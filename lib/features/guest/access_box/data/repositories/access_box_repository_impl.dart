import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/access_box_entity.dart';
import '../../domain/repositories/access_box_repository.dart';

/// Implementación del repositorio de códigos de acceso
class AccessBoxRepositoryImpl implements AccessBoxRepository {
  AccessBoxRepositoryImpl({required SupabaseClient supabase})
      : _supabase = supabase;

  final SupabaseClient _supabase;

  @override
  Future<AccessBoxEntity?> getAccessBox(String bookingId) async {
    try {
      debugPrint('🔑 [AccessBoxRepository] Obteniendo datos para booking: $bookingId');

      // 1. Obtener datos de la reserva con información de la unidad
      final bookingResponse = await _supabase
          .from('bookings')
          .select('''
            id,
            keybox_code,
            checkin_date,
            checkout_date,
            unit_id,
            units (
              id,
              name,
              box_location_text,
              access_instructions,
              wifi_network,
              wifi_password
            )
          ''')
          .eq('id', bookingId)
          .maybeSingle();

      if (bookingResponse == null) {
        debugPrint('🔑 [AccessBoxRepository] No se encontró la reserva');
        return null;
      }

      debugPrint('🔑 [AccessBoxRepository] Reserva encontrada: ${bookingResponse['id']}');

      // 2. Extraer datos de la unidad
      final unitData = bookingResponse['units'] as Map<String, dynamic>?;
      final boxLocation = unitData?['box_location_text'] as String?;
      final accessInstructions = unitData?['access_instructions'] as String?;
      final wifiNetwork = unitData?['wifi_network'] as String?;
      final wifiPassword = unitData?['wifi_password'] as String?;

      // 3. Obtener código principal desde la reserva (único por booking)
      final mainCode = bookingResponse['keybox_code'] as String? ?? '';

      if (mainCode.isEmpty) {
        debugPrint('⚠️ [AccessBoxRepository] No hay código de acceso configurado para esta reserva');
      }

      // 4. Obtener fechas de validez
      final checkInDate = DateTime.parse(bookingResponse['checkin_date'] as String);
      final checkOutDate = DateTime.parse(bookingResponse['checkout_date'] as String);

      // 5. Construir códigos adicionales
      final additionalCodes = <AdditionalCode>[];

      // Añadir WiFi si está disponible
      if (wifiNetwork != null && wifiPassword != null) {
        additionalCodes.add(AdditionalCode(
          icon: 'wifi',
          title: 'WiFi',
          subtitle: 'Red: $wifiNetwork',
          code: wifiPassword,
        ));
        debugPrint('🔑 [AccessBoxRepository] WiFi encontrado: $wifiNetwork');
      } else {
        debugPrint('⚠️ [AccessBoxRepository] No hay WiFi configurado para la unidad');
      }

      debugPrint('🔑 [AccessBoxRepository] Código principal: $mainCode');
      debugPrint('🔑 [AccessBoxRepository] Válido del $checkInDate al $checkOutDate');

      return AccessBoxEntity(
        mainCode: mainCode,
        wifiNetwork: wifiNetwork,
        wifiPassword: wifiPassword,
        additionalCodes: additionalCodes,
        validFrom: checkInDate,
        validUntil: checkOutDate,
        accessInstructions: accessInstructions,
        boxLocation: boxLocation,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [AccessBoxRepository] Error: $e');
      debugPrint('❌ [AccessBoxRepository] StackTrace: $stackTrace');
      rethrow;
    }
  }
}
