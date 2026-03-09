import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/admin_booking_entity.dart';
import '../../../domain/entities/invoice_entity.dart';
import '../bloc/invoices_bloc.dart';
import 'booking_selector_dialog.dart';

/// Bottom sheet para crear una nueva factura
class CreateInvoiceBottomSheet extends StatefulWidget {
  const CreateInvoiceBottomSheet({
    super.key,
    this.initialBookings,
    this.onSave,
  });

  final List<AdminBookingEntity>? initialBookings;
  final Future<void> Function(InvoiceEntity invoice)? onSave;

  @override
  State<CreateInvoiceBottomSheet> createState() => _CreateInvoiceBottomSheetState();
}

class _CreateInvoiceBottomSheetState extends State<CreateInvoiceBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Reserva seleccionada
  AdminBookingEntity? _selectedBooking;

  // Controladores
  final _amountController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientNifController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientAddressController = TextEditingController();
  final _notesController = TextEditingController();

  // Tipo de IVA - 10% por defecto para alojamientos turísticos
  double _selectedTaxRate = 10.0;

  final List<Map<String, dynamic>> _taxRates = [
    {'rate': 10.0, 'label': '10% - Alojamiento turístico'},
    {'rate': 21.0, 'label': '21% - IVA general'},
    {'rate': 4.0, 'label': '4% - IVA reducido'},
    {'rate': 0.0, 'label': '0% - Exento'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _clientNameController.dispose();
    _clientNifController.dispose();
    _clientEmailController.dispose();
    _clientPhoneController.dispose();
    _clientAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onBookingSelected(AdminBookingEntity? booking) {
    setState(() {
      _selectedBooking = booking;
      // Rellenar campos con datos del huésped
      _clientNameController.text = booking?.guestFullName ?? '';
      _clientNifController.clear();
      _clientEmailController.text = booking?.guestEmail ?? '';
      _clientPhoneController.text = booking?.guestPhone ?? '';
      _clientAddressController.clear();
    });
  }

  Future<void> _showBookingSelectorDialog() async {
    final bloc = context.read<InvoicesBloc>();
    var state = bloc.state;

    // Si está cargando bookings, mostrar diálogo de espera
    if (state.isLoadingBookings) {
      // Mostrar loading dialog mientras se cargan las reservas
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );

      // Esperar a que termine de cargar
      await Future.delayed(const Duration(milliseconds: 500));

      // Verificar cada 100ms si ya terminó de cargar
      for (int i = 0; i < 50; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        state = bloc.state;
        if (!state.isLoadingBookings) break;
      }

      // Cerrar loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();
    }

    // Volver a obtener el estado actualizado
    state = bloc.state;
    final bookings = state.bookings;

    if (!mounted) return;

    if (bookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay reservas disponibles'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final selectedBooking = await showBookingSelectorDialog(
      context,
      bookings: bookings,
    );
    if (selectedBooking != null) {
      _onBookingSelected(selectedBooking);
    }
  }

  double get _baseAmount {
    return double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
  }

  double get _taxAmount {
    return _baseAmount * (_selectedTaxRate / 100);
  }

  double get _totalAmount {
    return _baseAmount + _taxAmount;
  }

  Future<void> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBooking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una reserva'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_baseAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El importe debe ser mayor que 0'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Crear línea de factura única con el importe total
      final lineItem = InvoiceLineItem(
        description: 'Alojamiento ${_selectedBooking!.unitName} - ${_selectedBooking!.bookingCode}',
        quantity: 1,
        unitPrice: _baseAmount,
        taxRate: _selectedTaxRate,
      );

      final invoice = InvoiceEntity(
        id: const Uuid().v4(),
        invoiceNumber: '', // Se generará en el repositorio
        bookingId: _selectedBooking!.id,
        propertyId: _selectedBooking!.propertyId,
        issuerName: 'BF Stay',
        issuerNif: '', // TODO: Configurar datos del emisor
        clientName: _clientNameController.text.trim().isNotEmpty
            ? _clientNameController.text.trim()
            : _selectedBooking!.guestFullName,
        clientNif: _clientNifController.text.trim().isNotEmpty
            ? _clientNifController.text.trim()
            : null,
        clientEmail: _clientEmailController.text.trim().isNotEmpty
            ? _clientEmailController.text.trim()
            : _selectedBooking!.guestEmail,
        clientPhone: _clientPhoneController.text.trim().isNotEmpty
            ? _clientPhoneController.text.trim()
            : _selectedBooking!.guestPhone,
        clientAddress: _clientAddressController.text.trim().isNotEmpty
            ? _clientAddressController.text.trim()
            : null,
        issueDate: DateTime.now(),
        concept: 'Alojamiento turístico',
        lineItems: [lineItem],
        subtotalExcludingTax: _baseAmount,
        taxBase: _baseAmount,
        taxRate: _selectedTaxRate,
        taxAmount: _taxAmount,
        totalIncludingTax: _totalAmount,
        status: InvoiceStatus.draft,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: DateTime.now(),
        bookingCode: _selectedBooking!.bookingCode,
        unitName: _selectedBooking!.unitName,
      );

      if (widget.onSave != null) {
        await widget.onSave!(invoice);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Factura creada correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear factura: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Nueva Factura',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.gray400),
                ),
              ],
            ),
          ),

          // Form
          Flexible(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Paso 1: Seleccionar reserva
                    _buildSectionTitle('1. Seleccionar reserva'),
                    _buildBookingSelector(),
                    if (_selectedBooking != null) ...[
                      const SizedBox(height: 12),
                      _buildBookingInfo(),
                    ],
                    const SizedBox(height: 24),

                    // Paso 2: Importe
                    _buildSectionTitle('2. Importe de la factura'),
                    _buildAmountField(),
                    const SizedBox(height: 24),

                    // Paso 3: Tipo de IVA
                    _buildSectionTitle('3. Tipo de IVA'),
                    _buildTaxRateSelector(),
                    const SizedBox(height: 24),

                    // Resumen de totales
                    if (_baseAmount > 0) _buildTotals(),
                    const SizedBox(height: 16),

                    // Notas internas
                    _buildSectionTitle('Notas internas'),
                    _buildNotesField(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),

          // Botón de guardar
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.gold,
        ),
      ),
    );
  }

  Widget _buildBookingSelector() {
    return InkWell(
      onTap: _showBookingSelectorDialog,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _selectedBooking != null
                ? AppColors.gold.withValues(alpha: 0.5)
                : AppColors.darkBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.hotel_outlined,
                color: AppColors.gold,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedBooking?.bookingCode ?? 'Seleccionar reserva',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  if (_selectedBooking != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${_selectedBooking!.guestFullName} • ${_selectedBooking!.unitName}',
                      style: const TextStyle(
                        color: AppColors.gray400,
                        fontSize: 12,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 2),
                    const Text(
                      'Click para buscar y seleccionar',
                      style: TextStyle(
                        color: AppColors.gray500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.gold.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(AdminBookingEntity booking) {
    final checkIn = '${booking.checkInDate.day}/${booking.checkInDate.month}';
    final checkOut = '${booking.checkOutDate.day}/${booking.checkOutDate.month}';
    return '$checkIn - $checkOut';
  }

  Widget _buildBookingInfo() {
    if (_selectedBooking == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con info de la reserva (no editable)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _selectedBooking!.bookingCode,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDateRange(_selectedBooking!),
                style: const TextStyle(
                  color: AppColors.gray400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _selectedBooking!.unitName,
            style: const TextStyle(
              color: AppColors.gray400,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.darkBorder, height: 1),
          const SizedBox(height: 16),

          // Datos del cliente (editables)
          const Text(
            'Datos del cliente (editables)',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Nombre
          _buildEditableField(
            controller: _clientNameController,
            label: 'Nombre completo',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),

          // NIF/CIF
          _buildEditableField(
            controller: _clientNifController,
            label: 'NIF/CIF',
            icon: Icons.badge_outlined,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 12),

          // Email
          _buildEditableField(
            controller: _clientEmailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          // Teléfono
          _buildEditableField(
            controller: _clientPhoneController,
            label: 'Teléfono',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),

          // Dirección
          _buildEditableField(
            controller: _clientAddressController,
            label: 'Dirección',
            icon: Icons.home_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppColors.white, fontSize: 14),
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.gray500, fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.gray500, size: 20),
        filled: true,
        fillColor: AppColors.darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: 'Base imponible (€)',
        labelStyle: const TextStyle(color: AppColors.gray500),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 12, right: 8),
          child: Text(
            '€',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildTaxRateSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: _taxRates.map((taxRate) {
          final rate = taxRate['rate'] as double;
          final label = taxRate['label'] as String;
          final isSelected = _selectedTaxRate == rate;

          return InkWell(
            onTap: () => setState(() => _selectedTaxRate = rate),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? AppColors.gold : AppColors.gray500,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppColors.gold : AppColors.gray400,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotals() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildTotalRow('Base imponible', _baseAmount),
          const SizedBox(height: 8),
          _buildTotalRow('IVA (${_selectedTaxRate.toStringAsFixed(0)}%)', _taxAmount),
          const Divider(color: AppColors.darkBorder, height: 24),
          _buildTotalRow('Total factura', _totalAmount, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: isTotal ? AppColors.white : AppColors.gray400,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} €',
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? AppColors.gold : AppColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      style: const TextStyle(color: AppColors.white),
      maxLines: 2,
      decoration: InputDecoration(
        labelText: 'Notas internas (opcional)',
        labelStyle: const TextStyle(color: AppColors.gray500),
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _onSavePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.black,
                    ),
                  )
                : const Text(
                    'Crear factura (borrador)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
