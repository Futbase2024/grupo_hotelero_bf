import 'package:equatable/equatable.dart';

/// Estado de la factura
enum InvoiceStatus {
  draft('Borrador'),
  issued('Emitida'),
  paid('Pagada'),
  cancelled('Cancelada');

  const InvoiceStatus(this.label);
  final String label;

  static InvoiceStatus fromString(String value) {
    return switch (value) {
      'draft' => InvoiceStatus.draft,
      'issued' => InvoiceStatus.issued,
      'paid' => InvoiceStatus.paid,
      'cancelled' => InvoiceStatus.cancelled,
      _ => InvoiceStatus.draft,
    };
  }

  String toDbString() => name;
}

/// Línea de factura
class InvoiceLineItem extends Equatable {
  const InvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.taxRate = 10.0,
  });

  final String description;
  final int quantity;
  final double unitPrice;
  final double taxRate;

  /// Calcula el subtotal de la línea (sin impuestos)
  double get subtotal => quantity * unitPrice;

  /// Calcula el importe del impuesto
  double get taxAmount => subtotal * (taxRate / 100);

  /// Calcula el total de la línea (con impuestos)
  double get total => subtotal + taxAmount;

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItem(
      description: json['description'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 10.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'tax_rate': taxRate,
    };
  }

  InvoiceLineItem copyWith({
    String? description,
    int? quantity,
    double? unitPrice,
    double? taxRate,
  }) {
    return InvoiceLineItem(
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate ?? this.taxRate,
    );
  }

  @override
  List<Object?> get props => [description, quantity, unitPrice, taxRate];
}

/// Entity para facturas profesionales
class InvoiceEntity extends Equatable {
  const InvoiceEntity({
    required this.id,
    required this.invoiceNumber,
    required this.bookingId,
    required this.propertyId,

    // Datos del emisor
    required this.issuerName,
    required this.issuerNif,
    this.issuerAddress,
    this.issuerCity,
    this.issuerPostalCode,

    // Datos del cliente
    required this.clientName,
    this.clientNif,
    this.clientEmail,
    this.clientPhone,
    this.clientAddress,
    this.clientCity,
    this.clientPostalCode,

    // Detalles de factura
    required this.issueDate,
    this.dueDate,
    required this.concept,
    this.periodStart,
    this.periodEnd,

    // Líneas y totales
    required this.lineItems,
    required this.subtotalExcludingTax,
    required this.taxBase,
    required this.taxRate,
    required this.taxAmount,
    required this.totalIncludingTax,

    // Estado
    required this.status,
    this.issuedAt,
    this.paidAt,
    this.cancelledAt,
    this.cancellationReason,

    // Metadatos
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,

    // Datos de la reserva relacionada (para UI)
    this.bookingCode,
    this.unitName,
  });

  final String id;
  final String invoiceNumber;
  final String bookingId;
  final String propertyId;

  // Datos del emisor
  final String issuerName;
  final String issuerNif;
  final String? issuerAddress;
  final String? issuerCity;
  final String? issuerPostalCode;

  // Datos del cliente
  final String clientName;
  final String? clientNif;
  final String? clientEmail;
  final String? clientPhone;
  final String? clientAddress;
  final String? clientCity;
  final String? clientPostalCode;

  // Detalles de factura
  final DateTime issueDate;
  final DateTime? dueDate;
  final String concept;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  // Líneas y totales
  final List<InvoiceLineItem> lineItems;
  final double subtotalExcludingTax;
  final double taxBase;
  final double taxRate;
  final double taxAmount;
  final double totalIncludingTax;

  // Estado
  final InvoiceStatus status;
  final DateTime? issuedAt;
  final DateTime? paidAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  // Metadatos
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  // Datos de la reserva relacionada (para UI)
  final String? bookingCode;
  final String? unitName;

  // ==================== GETTERS ====================

  /// Si la factura es editable
  bool get isEditable => status == InvoiceStatus.draft;

  /// Si la factura puede ser emitida
  bool get canBeIssued => status == InvoiceStatus.draft && lineItems.isNotEmpty;

  /// Si la factura puede ser marcada como pagada
  bool get canBePaid => status == InvoiceStatus.issued;

  /// Si la factura puede ser cancelada
  bool get canBeCancelled => status == InvoiceStatus.draft || status == InvoiceStatus.issued;

  /// Si la factura está pagada
  bool get isPaid => status == InvoiceStatus.paid;

  /// Si la factura está cancelada
  bool get isCancelled => status == InvoiceStatus.cancelled;

  /// Formatea el total con símbolo de euro
  String get formattedTotal => '${totalIncludingTax.toStringAsFixed(2)} €';

  /// Formatea la fecha de emisión
  String get formattedIssueDate {
    final day = issueDate.day.toString().padLeft(2, '0');
    final month = issueDate.month.toString().padLeft(2, '0');
    final year = issueDate.year;
    return '$day/$month/$year';
  }

  // ==================== FACTORY ====================

  factory InvoiceEntity.fromJson(Map<String, dynamic> json) {
    // Parsear líneas de factura
    List<InvoiceLineItem> lineItems = [];
    if (json['line_items'] != null) {
      final itemsList = json['line_items'] as List;
      lineItems = itemsList.map((e) => InvoiceLineItem.fromJson(e as Map<String, dynamic>)).toList();
    }

    return InvoiceEntity(
      id: json['id'] as String? ?? '',
      invoiceNumber: json['invoice_number'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      propertyId: json['property_id'] as String? ?? '',

      issuerName: json['issuer_name'] as String? ?? '',
      issuerNif: json['issuer_nif'] as String? ?? '',
      issuerAddress: json['issuer_address'] as String?,
      issuerCity: json['issuer_city'] as String?,
      issuerPostalCode: json['issuer_postal_code'] as String?,

      clientName: json['client_name'] as String? ?? '',
      clientNif: json['client_nif'] as String?,
      clientEmail: json['client_email'] as String?,
      clientPhone: json['client_phone'] as String?,
      clientAddress: json['client_address'] as String?,
      clientCity: json['client_city'] as String?,
      clientPostalCode: json['client_postal_code'] as String?,

      issueDate: json['issue_date'] != null
          ? DateTime.parse(json['issue_date'] as String)
          : DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      concept: json['concept'] as String? ?? '',
      periodStart: json['period_start'] != null
          ? DateTime.parse(json['period_start'] as String)
          : null,
      periodEnd: json['period_end'] != null
          ? DateTime.parse(json['period_end'] as String)
          : null,

      lineItems: lineItems,
      subtotalExcludingTax: (json['subtotal_excluding_tax'] as num?)?.toDouble() ?? 0.0,
      taxBase: (json['tax_base'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 10.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      totalIncludingTax: (json['total_including_tax'] as num?)?.toDouble() ?? 0.0,

      status: InvoiceStatus.fromString(json['status'] as String? ?? 'draft'),
      issuedAt: json['issued_at'] != null
          ? DateTime.parse(json['issued_at'] as String)
          : null,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      cancellationReason: json['cancellation_reason'] as String?,

      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,

      bookingCode: json['booking_code'] as String?,
      unitName: json['unit_name'] as String?,
    );
  }

  /// Crea una factura vacía para formularios
  static InvoiceEntity empty({
    required String bookingId,
    required String propertyId,
    required String clientName,
    String? clientEmail,
    String? clientPhone,
    String bookingCode = '',
    String unitName = '',
  }) {
    return InvoiceEntity(
      id: '',
      invoiceNumber: '',
      bookingId: bookingId,
      propertyId: propertyId,
      issuerName: 'BF Stay',
      issuerNif: '',
      clientName: clientName,
      clientEmail: clientEmail,
      clientPhone: clientPhone,
      issueDate: DateTime.now(),
      concept: 'Alojamiento turístico',
      lineItems: const [],
      subtotalExcludingTax: 0,
      taxBase: 0,
      taxRate: 10,
      taxAmount: 0,
      totalIncludingTax: 0,
      status: InvoiceStatus.draft,
      createdAt: DateTime.now(),
      bookingCode: bookingCode,
      unitName: unitName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'booking_id': bookingId,
      'property_id': propertyId,
      'issuer_name': issuerName,
      'issuer_nif': issuerNif,
      'issuer_address': issuerAddress,
      'issuer_city': issuerCity,
      'issuer_postal_code': issuerPostalCode,
      'client_name': clientName,
      'client_nif': clientNif,
      'client_email': clientEmail,
      'client_phone': clientPhone,
      'client_address': clientAddress,
      'client_city': clientCity,
      'client_postal_code': clientPostalCode,
      'issue_date': issueDate.toIso8601String().split('T').first,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'concept': concept,
      'period_start': periodStart?.toIso8601String().split('T').first,
      'period_end': periodEnd?.toIso8601String().split('T').first,
      'line_items': lineItems.map((e) => e.toJson()).toList(),
      'subtotal_excluding_tax': subtotalExcludingTax,
      'tax_base': taxBase,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_including_tax': totalIncludingTax,
      'status': status.toDbString(),
      'issued_at': issuedAt?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }

  InvoiceEntity copyWith({
    String? id,
    String? invoiceNumber,
    String? bookingId,
    String? propertyId,
    String? issuerName,
    String? issuerNif,
    String? issuerAddress,
    String? issuerCity,
    String? issuerPostalCode,
    String? clientName,
    String? clientNif,
    String? clientEmail,
    String? clientPhone,
    String? clientAddress,
    String? clientCity,
    String? clientPostalCode,
    DateTime? issueDate,
    DateTime? dueDate,
    String? concept,
    DateTime? periodStart,
    DateTime? periodEnd,
    List<InvoiceLineItem>? lineItems,
    double? subtotalExcludingTax,
    double? taxBase,
    double? taxRate,
    double? taxAmount,
    double? totalIncludingTax,
    InvoiceStatus? status,
    DateTime? issuedAt,
    DateTime? paidAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? bookingCode,
    String? unitName,
  }) {
    return InvoiceEntity(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      bookingId: bookingId ?? this.bookingId,
      propertyId: propertyId ?? this.propertyId,
      issuerName: issuerName ?? this.issuerName,
      issuerNif: issuerNif ?? this.issuerNif,
      issuerAddress: issuerAddress ?? this.issuerAddress,
      issuerCity: issuerCity ?? this.issuerCity,
      issuerPostalCode: issuerPostalCode ?? this.issuerPostalCode,
      clientName: clientName ?? this.clientName,
      clientNif: clientNif ?? this.clientNif,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      clientAddress: clientAddress ?? this.clientAddress,
      clientCity: clientCity ?? this.clientCity,
      clientPostalCode: clientPostalCode ?? this.clientPostalCode,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      concept: concept ?? this.concept,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      lineItems: lineItems ?? this.lineItems,
      subtotalExcludingTax: subtotalExcludingTax ?? this.subtotalExcludingTax,
      taxBase: taxBase ?? this.taxBase,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      totalIncludingTax: totalIncludingTax ?? this.totalIncludingTax,
      status: status ?? this.status,
      issuedAt: issuedAt ?? this.issuedAt,
      paidAt: paidAt ?? this.paidAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      bookingCode: bookingCode ?? this.bookingCode,
      unitName: unitName ?? this.unitName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        invoiceNumber,
        bookingId,
        propertyId,
        issuerName,
        issuerNif,
        issuerAddress,
        issuerCity,
        issuerPostalCode,
        clientName,
        clientNif,
        clientEmail,
        clientPhone,
        clientAddress,
        clientCity,
        clientPostalCode,
        issueDate,
        dueDate,
        concept,
        periodStart,
        periodEnd,
        lineItems,
        subtotalExcludingTax,
        taxBase,
        taxRate,
        taxAmount,
        totalIncludingTax,
        status,
        issuedAt,
        paidAt,
        cancelledAt,
        cancellationReason,
        notes,
        createdAt,
        updatedAt,
        createdBy,
        bookingCode,
        unitName,
      ];
}
