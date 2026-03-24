import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/admin_booking_entity.dart';
import '../../../domain/entities/invoice_entity.dart';
import '../bloc/invoices_bloc.dart';
import '../bloc/invoices_event.dart';
import '../bloc/invoices_state.dart';
import 'booking_selector_dialog.dart';

/// Modo de creación de factura
enum InvoiceCreationMode {
  fromBooking,
  manual,
}

/// Línea de factura temporal para el formulario
class InvoiceLineItemDraft {
  InvoiceLineItemDraft({
    String? id,
    this.description = '',
    this.quantity = 1,
    this.unitPrice = 0.0,
    this.taxRate = 10.0,
  }) : id = id ?? const Uuid().v4();

  final String id;
  String description;
  int quantity;
  double unitPrice;
  double taxRate;

  double get subtotal => quantity * unitPrice;
  double get taxAmount => subtotal * (taxRate / 100);
  double get total => subtotal + taxAmount;

  InvoiceLineItem toEntity() => InvoiceLineItem(
        description: description,
        quantity: quantity,
        unitPrice: unitPrice,
        taxRate: taxRate,
      );
}

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

  // Modo de creación
  InvoiceCreationMode _creationMode = InvoiceCreationMode.manual;

  // Reserva seleccionada (modo fromBooking)
  AdminBookingEntity? _selectedBooking;

  // Propiedad seleccionada (modo manual)
  Map<String, dynamic>? _selectedProperty;

  // Líneas de factura
  final List<InvoiceLineItemDraft> _lineItems = [];

  // Controladores comunes
  final _notesController = TextEditingController();

  // Controladores de cliente (ambos modos, pero editables en manual)
  final _clientNameController = TextEditingController();
  final _clientNifController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientAddressController = TextEditingController();
  final _clientCityController = TextEditingController();
  final _clientPostalCodeController = TextEditingController();

  // Fechas de estancia (modo manual)
  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  // Tipo de IVA global - 10% por defecto para alojamientos turísticos
  double _globalTaxRate = 10.0;

  final List<Map<String, dynamic>> _taxRates = [
    {'rate': 10.0, 'label': '10% - Alojamiento turístico'},
    {'rate': 21.0, 'label': '21% - IVA general'},
    {'rate': 4.0, 'label': '4% - IVA reducido'},
    {'rate': 0.0, 'label': '0% - Exento'},
  ];

  @override
  void initState() {
    super.initState();
    // Cargar propiedades al iniciar
    context.read<InvoicesBloc>().add(const InvoicesLoadPropertiesRequested());
    // Añadir una línea vacía por defecto
    _addLineItem();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _clientNameController.dispose();
    _clientNifController.dispose();
    _clientEmailController.dispose();
    _clientPhoneController.dispose();
    _clientAddressController.dispose();
    _clientCityController.dispose();
    _clientPostalCodeController.dispose();
    super.dispose();
  }

  void _addLineItem() {
    setState(() {
      _lineItems.add(InvoiceLineItemDraft(taxRate: _globalTaxRate));
    });
  }

  void _removeLineItem(int index) {
    if (_lineItems.length > 1) {
      setState(() {
        _lineItems.removeAt(index);
      });
    }
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
      _clientCityController.clear();
      _clientPostalCodeController.clear();

      // Crear línea de factura con los datos de la reserva
      _lineItems.clear();
      _lineItems.add(InvoiceLineItemDraft(
        description: 'Alojamiento ${booking?.unitName ?? ""} - ${booking?.bookingCode ?? ""}',
        quantity: 1,
        unitPrice: 0,
        taxRate: _globalTaxRate,
      ));
    });
  }

  void _onModeChanged(InvoiceCreationMode mode) {
    setState(() {
      _creationMode = mode;
      // Limpiar selección anterior
      _selectedBooking = null;
      _selectedProperty = null;
      _checkInDate = null;
      _checkOutDate = null;
      _clientNameController.clear();
      _clientNifController.clear();
      _clientEmailController.clear();
      _clientPhoneController.clear();
      _clientAddressController.clear();
      _clientCityController.clear();
      _clientPostalCodeController.clear();
      _lineItems.clear();
      _addLineItem();
    });
  }

  Future<void> _showBookingSelectorDialog() async {
    final bloc = context.read<InvoicesBloc>();
    var state = bloc.state;

    // Si está cargando bookings, mostrar diálogo de espera
    if (state.isLoadingBookings) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      for (int i = 0; i < 50; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        state = bloc.state;
        if (!state.isLoadingBookings) break;
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    }

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

  /// Suma de todos los subtotales (base imponible)
  double get _totalBaseAmount {
    return _lineItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  /// Suma de todos los importes de IVA
  double get _totalTaxAmount {
    return _lineItems.fold(0.0, (sum, item) => sum + item.taxAmount);
  }

  /// Total de la factura (base + IVA)
  double get _grandTotal {
    return _totalBaseAmount + _totalTaxAmount;
  }

  /// Cierra el teclado
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar que hay al menos una línea con descripción y precio
    final validLines = _lineItems.where((l) => l.description.trim().isNotEmpty && l.unitPrice > 0).toList();

    if (validLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade al menos una línea con descripción e importe'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_creationMode == InvoiceCreationMode.fromBooking) {
      if (_selectedBooking == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona una reserva'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    } else {
      if (_selectedProperty == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona una propiedad'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (_clientNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El nombre del cliente es obligatorio'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final String propertyId;
      final String? bookingId;
      final String? bookingCode;
      final String? unitName;

      if (_creationMode == InvoiceCreationMode.fromBooking) {
        propertyId = _selectedBooking!.propertyId;
        bookingId = _selectedBooking!.id;
        bookingCode = _selectedBooking!.bookingCode;
        unitName = _selectedBooking!.unitName;
      } else {
        propertyId = _selectedProperty!['id'] as String;
        bookingId = null;
        bookingCode = null;
        unitName = null;
      }

      // Convertir líneas a entidades
      final lineItemsEntities = validLines.map((l) => l.toEntity()).toList();

      final invoice = InvoiceEntity(
        id: const Uuid().v4(),
        invoiceNumber: '', // Se generará en el repositorio
        bookingId: bookingId,
        propertyId: propertyId,
        issuerName: 'BF Stay',
        issuerNif: '', // TODO: Configurar desde settings
        clientName: _clientNameController.text.trim().isNotEmpty
            ? _clientNameController.text.trim()
            : _selectedBooking?.guestFullName ?? '',
        clientNif: _clientNifController.text.trim().isNotEmpty
            ? _clientNifController.text.trim()
            : null,
        clientEmail: _clientEmailController.text.trim().isNotEmpty
            ? _clientEmailController.text.trim()
            : _selectedBooking?.guestEmail,
        clientPhone: _clientPhoneController.text.trim().isNotEmpty
            ? _clientPhoneController.text.trim()
            : _selectedBooking?.guestPhone,
        clientAddress: _clientAddressController.text.trim().isNotEmpty
            ? _clientAddressController.text.trim()
            : null,
        clientCity: _clientCityController.text.trim().isNotEmpty
            ? _clientCityController.text.trim()
            : null,
        clientPostalCode: _clientPostalCodeController.text.trim().isNotEmpty
            ? _clientPostalCodeController.text.trim()
            : null,
        issueDate: DateTime.now(),
        concept: validLines.length == 1 ? validLines.first.description : 'Factura múltiple',
        // Fechas de estancia: usar fechas de reserva o las seleccionadas manualmente
        periodStart: _creationMode == InvoiceCreationMode.fromBooking
            ? _selectedBooking?.checkInDate
            : _checkInDate,
        periodEnd: _creationMode == InvoiceCreationMode.fromBooking
            ? _selectedBooking?.checkOutDate
            : _checkOutDate,
        lineItems: lineItemsEntities,
        subtotalExcludingTax: _totalBaseAmount,
        taxBase: _totalBaseAmount,
        taxRate: _globalTaxRate,
        taxAmount: _totalTaxAmount,
        totalIncludingTax: _grandTotal,
        status: InvoiceStatus.draft,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: DateTime.now(),
        bookingCode: bookingCode,
        unitName: unitName,
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
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return Stack(
      children: [
        // Contenido principal
        GestureDetector(
          onTap: _dismissKeyboard,
          child: Container(
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
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Paso 0: Selección de modo
                          _buildSectionTitle('Tipo de factura'),
                          _buildModeSelector(),
                          const SizedBox(height: 24),

                          // Contenido según modo
                          if (_creationMode == InvoiceCreationMode.fromBooking) ...[
                            // Paso 1: Seleccionar reserva
                            _buildSectionTitle('1. Seleccionar reserva'),
                            _buildBookingSelector(),
                            if (_selectedBooking != null) ...[
                              const SizedBox(height: 12),
                              _buildBookingInfo(),
                            ],
                          ] else ...[
                            // Modo manual
                            _buildSectionTitle('1. Propiedad'),
                            _buildPropertySelector(),
                            const SizedBox(height: 16),
                            _buildSectionTitle('2. Datos del cliente'),
                            _buildClientFields(),
                            const SizedBox(height: 16),
                            _buildSectionTitle('3. Fechas de estancia'),
                            _buildDateFields(),
                          ],
                          const SizedBox(height: 24),

                          // Líneas de factura
                          _buildSectionTitle(
                            _creationMode == InvoiceCreationMode.fromBooking
                                ? '2. Conceptos de factura'
                                : '4. Conceptos de factura',
                          ),
                          _buildLineItems(),
                          const SizedBox(height: 16),

                          // Botón añadir línea
                          _buildAddLineButton(),
                          const SizedBox(height: 24),

                          // Tipo de IVA global
                          _buildSectionTitle(
                            _creationMode == InvoiceCreationMode.fromBooking
                                ? '3. Tipo de IVA'
                                : '5. Tipo de IVA',
                          ),
                          _buildTaxRateSelector(),
                          const SizedBox(height: 24),

                          // Resumen de totales
                          if (_grandTotal > 0) _buildTotals(),
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
          ),
        ),

        // Botón de "Hecho" encima del teclado
        if (isKeyboardVisible)
          Positioned(
            bottom: keyboardHeight,
            left: 0,
            right: 0,
            child: _buildKeyboardDoneButton(),
          ),
      ],
    );
  }

  /// Botón para cerrar el teclado (especialmente útil en iOS)
  Widget _buildKeyboardDoneButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
          bottom: BorderSide(color: AppColors.darkBorder),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _dismissKeyboard,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Hecho',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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

  Widget _buildModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeOption(
              mode: InvoiceCreationMode.fromBooking,
              icon: Icons.hotel_outlined,
              label: 'Desde reserva',
            ),
          ),
          Expanded(
            child: _buildModeOption(
              mode: InvoiceCreationMode.manual,
              icon: Icons.edit_document,
              label: 'Manual',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required InvoiceCreationMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _creationMode == mode;

    return InkWell(
      onTap: () => _onModeChanged(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldWithAlpha10 : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.gold : AppColors.gray500,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.gold : AppColors.gray400,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ],
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
                ? AppColors.goldWithAlpha50
                : AppColors.darkBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.goldWithAlpha10,
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
              color: AppColors.goldWithAlpha50,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertySelector() {
    return BlocBuilder<InvoicesBloc, InvoicesState>(
      builder: (context, state) {
        if (state.isLoadingProperties) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
              ),
            ),
          );
        }

        if (state.properties.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'No hay propiedades disponibles',
                    style: TextStyle(color: AppColors.gray400, fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedProperty != null
                  ? AppColors.goldWithAlpha50
                  : AppColors.darkBorder,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              value: _selectedProperty,
              isExpanded: true,
              hint: const Text(
                'Seleccionar propiedad',
                style: TextStyle(color: AppColors.gray500),
              ),
              icon: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.goldWithAlpha50,
              ),
              dropdownColor: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(8),
              items: state.properties.map((property) {
                return DropdownMenuItem(
                  value: property,
                  child: Text(
                    property['name'] ?? 'Sin nombre',
                    style: const TextStyle(color: AppColors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedProperty = value);
              },
            ),
          ),
        );
      },
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
        border: Border.all(color: AppColors.goldWithAlpha30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con info de la reserva
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldWithAlpha10,
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
        ],
      ),
    );
  }

  Widget _buildClientFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          // Nombre
          _buildEditableField(
            controller: _clientNameController,
            label: 'Nombre completo *',
            icon: Icons.person_outline,
            isRequired: true,
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
          const SizedBox(height: 12),

          // Ciudad y CP en fila
          Row(
            children: [
              Expanded(
                child: _buildEditableField(
                  controller: _clientCityController,
                  label: 'Ciudad',
                  icon: Icons.location_city_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEditableField(
                  controller: _clientPostalCodeController,
                  label: 'C.P.',
                  icon: Icons.markunread_mailbox_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Campos de fecha de check-in y check-out
  Widget _buildDateFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          // Check-in
          Expanded(
            child: _buildDateField(
              label: 'Check-in',
              date: _checkInDate,
              onTap: () => _selectDate(isCheckIn: true),
            ),
          ),
          const SizedBox(width: 12),
          // Check-out
          Expanded(
            child: _buildDateField(
              label: 'Check-out',
              date: _checkOutDate,
              onTap: () => _selectDate(isCheckIn: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final hasDate = date != null;
    final formattedDate = hasDate
        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
        : 'Seleccionar';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasDate ? AppColors.goldWithAlpha50 : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: hasDate ? AppColors.gold : AppColors.gray500,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: hasDate ? AppColors.white : AppColors.gray500,
                      fontSize: 14,
                      fontWeight: hasDate ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (hasDate)
              InkWell(
                onTap: () {
                  setState(() {
                    if (label == 'Check-in') {
                      _checkInDate = null;
                    } else {
                      _checkOutDate = null;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    color: AppColors.gray500,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate({required bool isCheckIn}) async {
    final now = DateTime.now();
    DateTime tempDate = isCheckIn ? _checkInDate ?? now : _checkOutDate ?? now;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (modalContext) => Container(
        height: 300,
        padding: const EdgeInsets.only(top: 6),
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Header con botones
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(modalContext).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: AppColors.gray400),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(modalContext).pop();
                      setState(() {
                        if (isCheckIn) {
                          _checkInDate = tempDate;
                          // Si check-out es anterior al nuevo check-in, limpiarlo
                          if (_checkOutDate != null &&
                              _checkOutDate!.isBefore(tempDate)) {
                            _checkOutDate = null;
                          }
                        } else {
                          _checkOutDate = tempDate;
                        }
                      });
                    },
                    child: const Text(
                      'Confirmar',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.darkBorder, height: 1),
            // Date picker
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: tempDate,
                minimumDate: DateTime(2020),
                maximumDate: DateTime(2030),
                backgroundColor: AppColors.darkSurface,
                onDateTimeChanged: (DateTime newDate) {
                  tempDate = newDate;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppColors.white, fontSize: 14),
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: TextInputAction.next,
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo obligatorio';
              }
              return null;
            }
          : null,
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
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
      ),
    );
  }

  Widget _buildLineItems() {
    return Column(
      children: [
        for (int i = 0; i < _lineItems.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _buildLineItemCard(i),
        ],
      ],
    );
  }

  Widget _buildLineItemCard(int index) {
    final item = _lineItems[index];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con número de línea y botón eliminar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldWithAlpha10,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Línea ${index + 1}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (_lineItems.length > 1)
                InkWell(
                  onTap: () => _removeLineItem(index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Descripción
          TextFormField(
            initialValue: item.description,
            style: const TextStyle(color: AppColors.white, fontSize: 14),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Concepto',
              labelStyle: TextStyle(color: AppColors.gray500, fontSize: 12),
              filled: true,
              fillColor: AppColors.darkBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            onChanged: (value) {
              item.description = value;
              setState(() {});
            },
          ),
          const SizedBox(height: 10),

          // Cantidad y Precio en fila
          Row(
            children: [
              // Cantidad
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  style: const TextStyle(color: AppColors.white, fontSize: 14),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Uds.',
                    labelStyle: TextStyle(color: AppColors.gray500, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.darkBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    item.quantity = int.tryParse(value) ?? 1;
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 10),

              // Precio unitario
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: item.unitPrice > 0 ? item.unitPrice.toStringAsFixed(2) : '',
                  style: const TextStyle(color: AppColors.white, fontSize: 14),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Precio unitario (€)',
                    labelStyle: TextStyle(color: AppColors.gray500, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.darkBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    item.unitPrice = double.tryParse(value.replaceAll(',', '.')) ?? 0;
                    setState(() {});
                  },
                  onFieldSubmitted: (_) => _dismissKeyboard(),
                ),
              ),
            ],
          ),

          // Subtotal de la línea
          if (item.subtotal > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'IVA ${item.taxRate.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 11,
                  ),
                ),
                Text(
                  'Subtotal: ${item.subtotal.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    color: AppColors.gray400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddLineButton() {
    return InkWell(
      onTap: _addLineItem,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.goldWithAlpha30, style: BorderStyle.solid),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: AppColors.gold,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Añadir otra línea',
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
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
          final isSelected = _globalTaxRate == rate;

          return InkWell(
            onTap: () {
              setState(() {
                _globalTaxRate = rate;
                // Actualizar todas las líneas
                for (final item in _lineItems) {
                  item.taxRate = rate;
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.goldWithAlpha10 : null,
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
        border: Border.all(color: AppColors.goldWithAlpha30),
      ),
      child: Column(
        children: [
          _buildTotalRow('Base imponible', _totalBaseAmount),
          const SizedBox(height: 8),
          _buildTotalRow('IVA (${_globalTaxRate.toStringAsFixed(0)}%)', _totalTaxAmount),
          const Divider(color: AppColors.darkBorder, height: 24),
          _buildTotalRow('Total factura', _grandTotal, isTotal: true),
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
      textInputAction: TextInputAction.done,
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
      onFieldSubmitted: (_) => _dismissKeyboard(),
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
