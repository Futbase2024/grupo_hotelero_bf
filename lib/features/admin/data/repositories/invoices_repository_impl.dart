import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/repositories/invoices_repository.dart';

class InvoicesRepositoryImpl implements InvoicesRepository {
  InvoicesRepositoryImpl({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;
  static const _tableName = 'invoices';

  @override
  Future<List<InvoiceEntity>> getAll() async {
    debugPrint('🔵 [InvoicesRepository] getAll - Fetching all invoices');
    final response = await _client
        .from(_tableName)
        .select('''
          *,
          bookings(
            booking_code,
            unit_id,
            units(name)
          )
        ''')
        .order('created_at', ascending: false);

    final invoices = (response as List)
        .map((json) => _mapToEntity(json))
        .toList();
    debugPrint('🔵 [InvoicesRepository] getAll - Found ${invoices.length} invoices');
    return invoices;
  }

  @override
  Future<List<InvoiceEntity>> getByStatus(InvoiceStatus status) async {
    debugPrint('🔵 [InvoicesRepository] getByStatus - Fetching invoices with status: ${status.name}');
    final response = await _client
        .from(_tableName)
        .select('''
          *,
          bookings(
            booking_code,
            unit_id,
            units(name)
          )
        ''')
        .eq('status', status.toDbString())
        .order('created_at', ascending: false);

    final invoices = (response as List)
        .map((json) => _mapToEntity(json))
        .toList();
    debugPrint('🔵 [InvoicesRepository] getByStatus - Found ${invoices.length} invoices');
    return invoices;
  }

  @override
  Future<List<InvoiceEntity>> getByPropertyId(String propertyId) async {
    debugPrint('🔵 [InvoicesRepository] getByPropertyId - Fetching invoices for property: $propertyId');
    final response = await _client
        .from(_tableName)
        .select('''
          *,
          bookings(
            booking_code,
            unit_id,
            units(name)
          )
        ''')
        .eq('property_id', propertyId)
        .order('created_at', ascending: false);

    final invoices = (response as List)
        .map((json) => _mapToEntity(json))
        .toList();
    debugPrint('🔵 [InvoicesRepository] getByPropertyId - Found ${invoices.length} invoices');
    return invoices;
  }

  @override
  Future<InvoiceEntity?> getById(String id) async {
    debugPrint('🔵 [InvoicesRepository] getById - Fetching invoice: $id');
    final response = await _client
        .from(_tableName)
        .select('''
          *,
          bookings(
            booking_code,
            unit_id,
            units(name)
          )
        ''')
        .eq('id', id)
        .maybeSingle();

    if (response == null) {
      debugPrint('🔵 [InvoicesRepository] getById - Invoice not found');
      return null;
    }

    final invoice = _mapToEntity(response);
    debugPrint('🔵 [InvoicesRepository] getById - Invoice found: ${invoice.invoiceNumber}');
    return invoice;
  }

  @override
  Future<List<InvoiceEntity>> getByBookingId(String bookingId) async {
    debugPrint('🔵 [InvoicesRepository] getByBookingId - Fetching invoices for booking: $bookingId');
    final response = await _client
        .from(_tableName)
        .select('''
          *,
          bookings(
            booking_code,
            unit_id,
            units(name)
          )
        ''')
        .eq('booking_id', bookingId)
        .order('created_at', ascending: false);

    final invoices = (response as List)
        .map((json) => _mapToEntity(json))
        .toList();
    debugPrint('🔵 [InvoicesRepository] getByBookingId - Found ${invoices.length} invoices');
    return invoices;
  }

  @override
  Future<InvoiceEntity> create(InvoiceEntity invoice) async {
    debugPrint('🔵 [InvoicesRepository] create - Creating invoice');
    final invoiceNumber = await generateInvoiceNumber();
    debugPrint('🔵 [InvoicesRepository] create - Generated invoice number: $invoiceNumber');

    final now = DateTime.now().toIso8601String();
    final data = invoice.toJson();

    // Establecer valores obligatorios y sobrescribir nulls
    data['invoice_number'] = invoiceNumber;
    data['created_by'] = _client.auth.currentUser?.id;
    data['created_at'] = now;
    data['updated_at'] = now;

    // Eliminar campos null que puedan causar problemas
    data.removeWhere((key, value) => value == null);

    debugPrint('🔵 [InvoicesRepository] create - Data to insert:');
    debugPrint('   ├── id: ${data['id']}');
    debugPrint('   ├── invoice_number: ${data['invoice_number']}');
    debugPrint('   ├── booking_id: ${data['booking_id']}');
    debugPrint('   ├── property_id: ${data['property_id']}');
    debugPrint('   ├── client_name: ${data['client_name']}');
    debugPrint('   ├── concept: ${data['concept']}');
    debugPrint('   ├── total: ${data['total_including_tax']}');
    debugPrint('   └── status: ${data['status']}');
    debugPrint('🔵 [InvoicesRepository] create - Full data keys: ${data.keys.toList()}');

    try {
      final response = await _client
          .from(_tableName)
          .insert(data)
          .select('''
            *,
            bookings(
              booking_code,
              unit_id,
              units(name)
            )
          ''')
          .single();

      debugPrint('🟢 [InvoicesRepository] create - Response received from Supabase');
      final created = _mapToEntity(response);
      debugPrint('🟢 [InvoicesRepository] create - Invoice created: ${created.invoiceNumber}');
      return created;
    } catch (e, s) {
      debugPrint('🔴 [InvoicesRepository] create - Error: $e');
      debugPrint('🔴 [InvoicesRepository] create - StackTrace: $s');
      rethrow;
    }
  }

  @override
  Future<InvoiceEntity> update(InvoiceEntity invoice) async {
    debugPrint('🔵 [InvoicesRepository] update - Updating invoice: ${invoice.id}');
    final response = await _client
        .from(_tableName)
        .update(invoice.toJson())
        .eq('id', invoice.id)
        .select('''
          *,
          bookings(
            booking_code,
            unit_id,
            units(name)
          )
        ''')
        .single();

    final updated = _mapToEntity(response);
    debugPrint('🔵 [InvoicesRepository] update - Invoice updated: ${updated.invoiceNumber}');
    return updated;
  }

  @override
  Future<InvoiceEntity> issue(String invoiceId) async {
    debugPrint('🔵 [InvoicesRepository] issue - Issuing invoice: $invoiceId');
    final response = await _client
        .from(_tableName)
        .update({
          'status': 'issued',
          'issued_at': DateTime.now().toIso8601String(),
        })
        .eq('id', invoiceId)
        .select('''
          *,
          bookings(
            booking_code,
            unit_id,
            units(name)
          )
        ''')
        .single();

    final invoice = _mapToEntity(response);
    debugPrint('🔵 [InvoicesRepository] issue - Invoice issued: ${invoice.invoiceNumber}');
    return invoice;
  }

  @override
  Future<InvoiceEntity> markAsPaid(String invoiceId) async {
    debugPrint('🔵 [InvoicesRepository] markAsPaid - Marking invoice as paid: $invoiceId');
    final response = await _client
        .from(_tableName)
        .update({
          'status': 'paid',
          'paid_at': DateTime.now().toIso8601String(),
        })
        .eq('id', invoiceId)
        .select('''
          *,
          bookings(
            booking_code,
            unit_id,
            units(name)
          )
        ''')
        .single();

    final invoice = _mapToEntity(response);
    debugPrint('🔵 [InvoicesRepository] markAsPaid - Invoice marked as paid: ${invoice.invoiceNumber}');
    return invoice;
  }

  @override
  Future<InvoiceEntity> cancel(String invoiceId, String reason) async {
    debugPrint('🔵 [InvoicesRepository] cancel - Cancelling invoice: $invoiceId');
    final response = await _client
        .from(_tableName)
        .update({
          'status': 'cancelled',
          'cancelled_at': DateTime.now().toIso8601String(),
          'cancellation_reason': reason,
        })
        .eq('id', invoiceId)
        .select('''
          *,
          bookings(
            booking_code,
            unit_id,
            units(name)
          )
        ''')
        .single();

    final invoice = _mapToEntity(response);
    debugPrint('🔵 [InvoicesRepository] cancel - Invoice cancelled: ${invoice.invoiceNumber}');
    return invoice;
  }

  @override
  Future<void> delete(String invoiceId) async {
    debugPrint('🔵 [InvoicesRepository] delete - Deleting invoice: $invoiceId');
    await _client
        .from(_tableName)
        .delete()
        .eq('id', invoiceId);
    debugPrint('🔵 [InvoicesRepository] delete - Invoice deleted');
  }

  @override
  Future<List<InvoiceEntity>> search(String query) async {
    debugPrint('🔵 [InvoicesRepository] search - Searching for: $query');
    final searchPattern = '%$query%';
    final response = await _client
        .from(_tableName)
        .select('''
          *,
          bookings(
            booking_code,
            unit_id,
            units(name)
          )
        ''')
        .or('invoice_number.ilike.$searchPattern,client_name.ilike.$searchPattern,concept.ilike.$searchPattern')
        .order('created_at', ascending: false);

    final invoices = (response as List)
        .map((json) => _mapToEntity(json))
        .toList();
    debugPrint('🔵 [InvoicesRepository] search - Found ${invoices.length} invoices');
    return invoices;
  }

  @override
  Future<String> generateInvoiceNumber() async {
    debugPrint('🔵 [InvoicesRepository] generateInvoiceNumber - Generating new invoice number');
    final response = await _client.rpc('generate_invoice_number');
    final invoiceNumber = response as String;
    debugPrint('🔵 [InvoicesRepository] generateInvoiceNumber - Generated: $invoiceNumber');
    return invoiceNumber;
  }

  /// Mapea la respuesta de Supabase a InvoiceEntity
  InvoiceEntity _mapToEntity(Map<String, dynamic> json) {
    debugPrint('🔵 [_mapToEntity] Mapping JSON to InvoiceEntity');
    debugPrint('   ├── invoice_number: ${json['invoice_number']}');
    debugPrint('   ├── booking_id: ${json['booking_id']}');
    debugPrint('   ├── property_id: ${json['property_id']}');
    debugPrint('   ├── client_name: ${json['client_name']}');
    debugPrint('   └── status: ${json['status']}');

    // Extraer datos de la reserva relacionada
    final booking = json['bookings'] as Map<String, dynamic>?;
    final bookingCode = booking?['booking_code'] as String?;
    final unitName = (booking?['units'] as Map<String, dynamic>?)?['name'] as String?;

    debugPrint('   ├── booking_code (from join): $bookingCode');
    debugPrint('   └── unit_name (from join): $unitName');

    return InvoiceEntity.fromJson({
      ...json,
      'booking_code': bookingCode,
      'unit_name': unitName,
    });
  }
}
