import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/invoices_repository.dart';
import '../../../domain/repositories/admin_panel_repository.dart';
import 'invoices_event.dart';
import 'invoices_state.dart';

class InvoicesBloc extends Bloc<InvoicesEvent, InvoicesState> {
  InvoicesBloc({
    required InvoicesRepository repository,
    required AdminPanelRepository adminRepository,
  })  : _repository = repository,
        _adminRepository = adminRepository,
        super(const InvoicesState()) {
    on<InvoicesLoadRequested>(_onLoadRequested);
    on<InvoicesRefreshRequested>(_onRefreshRequested);
    on<InvoicesFilterChanged>(_onFilterChanged);
    on<InvoicesSearchChanged>(_onSearchChanged);
    on<InvoiceCreateRequested>(_onCreateRequested);
    on<InvoiceUpdateRequested>(_onUpdateRequested);
    on<InvoiceIssueRequested>(_onIssueRequested);
    on<InvoiceMarkPaidRequested>(_onMarkPaidRequested);
    on<InvoiceCancelRequested>(_onCancelRequested);
    on<InvoiceDeleteRequested>(_onDeleteRequested);
    on<InvoiceSelected>(_onSelected);
    on<InvoiceSelectionCleared>(_onSelectionCleared);
    on<InvoicesLoadBookingsRequested>(_onLoadBookingsRequested);
  }

  final InvoicesRepository _repository;
  final AdminPanelRepository _adminRepository;

  Future<void> _onLoadRequested(
    InvoicesLoadRequested event,
    Emitter<InvoicesState> emit,
  ) async {
    debugPrint('🔵 [InvoicesBloc] _onLoadRequested');
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final invoices = await _repository.getAll();
      debugPrint('🔵 [InvoicesBloc] Loaded ${invoices.length} invoices');
      emit(state.copyWith(
        invoices: invoices,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('🔴 [InvoicesBloc] Error loading invoices: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Error al cargar facturas: $e',
      ));
    }
  }

  Future<void> _onRefreshRequested(
    InvoicesRefreshRequested event,
    Emitter<InvoicesState> emit,
  ) async {
    debugPrint('🔵 [InvoicesBloc] _onRefreshRequested');
    emit(state.copyWith(isRefreshing: true, clearError: true));

    try {
      final invoices = await _repository.getAll();
      debugPrint('🔵 [InvoicesBloc] Refreshed ${invoices.length} invoices');
      emit(state.copyWith(
        invoices: invoices,
        isRefreshing: false,
      ));
    } catch (e) {
      debugPrint('🔴 [InvoicesBloc] Error refreshing invoices: $e');
      emit(state.copyWith(
        isRefreshing: false,
        error: 'Error al refrescar facturas: $e',
      ));
    }
  }

  void _onFilterChanged(
    InvoicesFilterChanged event,
    Emitter<InvoicesState> emit,
  ) {
    debugPrint('🔵 [InvoicesBloc] _onFilterChanged: ${event.status}');
    emit(state.copyWith(
      statusFilter: event.status,
      clearStatusFilter: event.status == null,
    ));
  }

  void _onSearchChanged(
    InvoicesSearchChanged event,
    Emitter<InvoicesState> emit,
  ) {
    debugPrint('🔵 [InvoicesBloc] _onSearchChanged: ${event.query}');
    emit(state.copyWith(
      searchQuery: event.query,
      clearSearchQuery: event.query == null || event.query!.isEmpty,
    ));
  }

  Future<void> _onCreateRequested(
    InvoiceCreateRequested event,
    Emitter<InvoicesState> emit,
  ) async {
    debugPrint('🔵 [InvoicesBloc] _onCreateRequested');
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final newInvoice = await _repository.create(event.invoice);
      debugPrint('🔵 [InvoicesBloc] Invoice created: ${newInvoice.invoiceNumber}');

      final updatedInvoices = [newInvoice, ...state.invoices];
      emit(state.copyWith(
        invoices: updatedInvoices,
        isLoading: false,
        selectedInvoice: newInvoice,
      ));
    } catch (e) {
      debugPrint('🔴 [InvoicesBloc] Error creating invoice: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Error al crear factura: $e',
      ));
    }
  }

  Future<void> _onUpdateRequested(
    InvoiceUpdateRequested event,
    Emitter<InvoicesState> emit,
  ) async {
    debugPrint('🔵 [InvoicesBloc] _onUpdateRequested: ${event.invoice.id}');
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final updatedInvoice = await _repository.update(event.invoice);
      debugPrint('🔵 [InvoicesBloc] Invoice updated: ${updatedInvoice.invoiceNumber}');

      final updatedInvoices = state.invoices.map((i) {
        return i.id == updatedInvoice.id ? updatedInvoice : i;
      }).toList();

      emit(state.copyWith(
        invoices: updatedInvoices,
        isLoading: false,
        selectedInvoice: updatedInvoice,
      ));
    } catch (e) {
      debugPrint('🔴 [InvoicesBloc] Error updating invoice: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Error al actualizar factura: $e',
      ));
    }
  }

  Future<void> _onIssueRequested(
    InvoiceIssueRequested event,
    Emitter<InvoicesState> emit,
  ) async {
    debugPrint('🔵 [InvoicesBloc] _onIssueRequested: ${event.invoiceId}');
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final issuedInvoice = await _repository.issue(event.invoiceId);
      debugPrint('🔵 [InvoicesBloc] Invoice issued: ${issuedInvoice.invoiceNumber}');

      final updatedInvoices = state.invoices.map((i) {
        return i.id == issuedInvoice.id ? issuedInvoice : i;
      }).toList();

      emit(state.copyWith(
        invoices: updatedInvoices,
        isLoading: false,
        selectedInvoice: issuedInvoice,
      ));
    } catch (e) {
      debugPrint('🔴 [InvoicesBloc] Error issuing invoice: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Error al emitir factura: $e',
      ));
    }
  }

  Future<void> _onMarkPaidRequested(
    InvoiceMarkPaidRequested event,
    Emitter<InvoicesState> emit,
  ) async {
    debugPrint('🔵 [InvoicesBloc] _onMarkPaidRequested: ${event.invoiceId}');
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final paidInvoice = await _repository.markAsPaid(event.invoiceId);
      debugPrint('🔵 [InvoicesBloc] Invoice marked as paid: ${paidInvoice.invoiceNumber}');

      final updatedInvoices = state.invoices.map((i) {
        return i.id == paidInvoice.id ? paidInvoice : i;
      }).toList();

      emit(state.copyWith(
        invoices: updatedInvoices,
        isLoading: false,
        selectedInvoice: paidInvoice,
      ));
    } catch (e) {
      debugPrint('🔴 [InvoicesBloc] Error marking invoice as paid: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Error al marcar factura como pagada: $e',
      ));
    }
  }

  Future<void> _onCancelRequested(
    InvoiceCancelRequested event,
    Emitter<InvoicesState> emit,
  ) async {
    debugPrint('🔵 [InvoicesBloc] _onCancelRequested: ${event.invoiceId}');
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final cancelledInvoice = await _repository.cancel(
        event.invoiceId,
        event.reason,
      );
      debugPrint('🔵 [InvoicesBloc] Invoice cancelled: ${cancelledInvoice.invoiceNumber}');

      final updatedInvoices = state.invoices.map((i) {
        return i.id == cancelledInvoice.id ? cancelledInvoice : i;
      }).toList();

      emit(state.copyWith(
        invoices: updatedInvoices,
        isLoading: false,
        selectedInvoice: cancelledInvoice,
      ));
    } catch (e) {
      debugPrint('🔴 [InvoicesBloc] Error cancelling invoice: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Error al cancelar factura: $e',
      ));
    }
  }

  Future<void> _onDeleteRequested(
    InvoiceDeleteRequested event,
    Emitter<InvoicesState> emit,
  ) async {
    debugPrint('🔵 [InvoicesBloc] _onDeleteRequested: ${event.invoiceId}');
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      await _repository.delete(event.invoiceId);
      debugPrint('🔵 [InvoicesBloc] Invoice deleted');

      final updatedInvoices = state.invoices
          .where((i) => i.id != event.invoiceId)
          .toList();

      emit(state.copyWith(
        invoices: updatedInvoices,
        isLoading: false,
        clearSelectedInvoice: true,
      ));
    } catch (e) {
      debugPrint('🔴 [InvoicesBloc] Error deleting invoice: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Error al eliminar factura: $e',
      ));
    }
  }

  void _onSelected(
    InvoiceSelected event,
    Emitter<InvoicesState> emit,
  ) {
    debugPrint('🔵 [InvoicesBloc] _onSelected: ${event.invoice.invoiceNumber}');
    emit(state.copyWith(selectedInvoice: event.invoice));
  }

  void _onSelectionCleared(
    InvoiceSelectionCleared event,
    Emitter<InvoicesState> emit,
  ) {
    debugPrint('🔵 [InvoicesBloc] _onSelectionCleared');
    emit(state.copyWith(clearSelectedInvoice: true));
  }

  Future<void> _onLoadBookingsRequested(
    InvoicesLoadBookingsRequested event,
    Emitter<InvoicesState> emit,
  ) async {
    debugPrint('🔵 [InvoicesBloc] _onLoadBookingsRequested');
    emit(state.copyWith(isLoadingBookings: true, clearError: true));

    try {
      final bookings = await _adminRepository.listBookings();
      debugPrint('🔵 [InvoicesBloc] Loaded ${bookings.length} bookings');
      emit(state.copyWith(
        bookings: bookings,
        isLoadingBookings: false,
      ));
    } catch (e) {
      debugPrint('🔴 [InvoicesBloc] Error loading bookings: $e');
      emit(state.copyWith(
        isLoadingBookings: false,
        error: 'Error al cargar reservas: $e',
      ));
    }
  }
}
