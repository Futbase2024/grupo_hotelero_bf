import 'package:equatable/equatable.dart';
import '../../../domain/entities/admin_entities.dart';

class InvoicesState extends Equatable {
  const InvoicesState({
    this.invoices = const [],
    this.bookings = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingBookings = false,
    this.error,
    this.statusFilter,
    this.searchQuery,
    this.selectedInvoice,
  });

  final List<InvoiceEntity> invoices;
  final List<AdminBookingEntity> bookings;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingBookings;
  final String? error;
  final InvoiceStatus? statusFilter;
  final String? searchQuery;
  final InvoiceEntity? selectedInvoice;

  /// Facturas filtradas según estado y búsqueda
  List<InvoiceEntity> get filteredInvoices {
    var result = invoices;

    // Filtrar por estado
    if (statusFilter != null) {
      result = result.where((i) => i.status == statusFilter).toList();
    }

    // Filtrar por búsqueda
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      result = result.where((i) {
        return i.invoiceNumber.toLowerCase().contains(query) ||
            i.clientName.toLowerCase().contains(query) ||
            i.concept.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }

  /// Facturas agrupadas por estado
  Map<InvoiceStatus, List<InvoiceEntity>> get invoicesByStatus {
    final map = <InvoiceStatus, List<InvoiceEntity>>{};
    for (final invoice in invoices) {
      map.putIfAbsent(invoice.status, () => []).add(invoice);
    }
    return map;
  }

  /// Contador de facturas por estado
  int countByStatus(InvoiceStatus status) {
    return invoices.where((i) => i.status == status).length;
  }

  /// Total de facturas en borrador
  int get draftCount => countByStatus(InvoiceStatus.draft);

  /// Total de facturas emitidas
  int get issuedCount => countByStatus(InvoiceStatus.issued);

  /// Total de facturas pagadas
  int get paidCount => countByStatus(InvoiceStatus.paid);

  /// Total de facturas canceladas
  int get cancelledCount => countByStatus(InvoiceStatus.cancelled);

  /// Suma total de facturas pagadas
  double get totalPaid {
    return invoices
        .where((i) => i.status == InvoiceStatus.paid)
        .fold(0.0, (sum, i) => sum + i.totalIncludingTax);
  }

  /// Suma total de facturas pendientes (emitidas no pagadas)
  double get totalPending {
    return invoices
        .where((i) => i.status == InvoiceStatus.issued)
        .fold(0.0, (sum, i) => sum + i.totalIncludingTax);
  }

  InvoicesState copyWith({
    List<InvoiceEntity>? invoices,
    List<AdminBookingEntity>? bookings,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingBookings,
    String? error,
    InvoiceStatus? statusFilter,
    String? searchQuery,
    InvoiceEntity? selectedInvoice,
    bool clearError = false,
    bool clearSelectedInvoice = false,
    bool clearStatusFilter = false,
    bool clearSearchQuery = false,
  }) {
    return InvoicesState(
      invoices: invoices ?? this.invoices,
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingBookings: isLoadingBookings ?? this.isLoadingBookings,
      error: clearError ? null : (error ?? this.error),
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      selectedInvoice: clearSelectedInvoice ? null : (selectedInvoice ?? this.selectedInvoice),
    );
  }

  @override
  List<Object?> get props => [
        invoices,
        bookings,
        isLoading,
        isRefreshing,
        isLoadingBookings,
        error,
        statusFilter,
        searchQuery,
        selectedInvoice,
      ];
}
