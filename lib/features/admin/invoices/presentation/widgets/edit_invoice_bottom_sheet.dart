import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/invoice_entity.dart';
import '../bloc/invoices_bloc.dart';
import '../bloc/invoices_event.dart';
import '../bloc/invoices_state.dart';

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

  factory InvoiceLineItemDraft.fromEntity(InvoiceLineItem item) {
    return InvoiceLineItemDraft(
      description: item.description,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      taxRate: item.taxRate,
    );
  }
}

/// Bottom sheet para editar una factura existente (solo borradores)
class EditInvoiceBottomSheet extends StatefulWidget {
  const EditInvoiceBottomSheet({
    super.key,
    required this.invoice,
    this.onSave,
  });

  final InvoiceEntity invoice;
  final Future<void> Function(InvoiceEntity invoice)? onSave;

  @override
  State<EditInvoiceBottomSheet> createState() => _EditInvoiceBottomSheetState();
}

class _EditInvoiceBottomSheetState extends State<EditInvoiceBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controladores de cliente
  late final TextEditingController _clientNameController;
  late final TextEditingController _clientNifController;
  late final TextEditingController _clientEmailController;
  late final TextEditingController _clientPhoneController;
  late final TextEditingController _clientAddressController;
  late final TextEditingController _clientCityController;
  late final TextEditingController _clientPostalCodeController;
  late final TextEditingController _notesController;

  // Propiedad seleccionada
  String? _selectedPropertyId;

  // Líneas de factura
  final List<InvoiceLineItemDraft> _lineItems = [];

  // Fechas
  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  // Tipo de IVA
  late double _globalTaxRate;

  final List<Map<String, dynamic>> _taxRates = [
    {'rate': 10.0, 'label': '10% - Alojamiento turístico'},
    {'rate': 21.0, 'label': '21% - IVA general'},
    {'rate': 4.0, 'label': '4% - IVA reducido'},
    {'rate': 0.0, 'label': '0% - Exento'},
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar controladores con datos de la factura
    _clientNameController = TextEditingController(text: widget.invoice.clientName);
    _clientNifController = TextEditingController(text: widget.invoice.clientNif ?? '');
    _clientEmailController = TextEditingController(text: widget.invoice.clientEmail ?? '');
    _clientPhoneController = TextEditingController(text: widget.invoice.clientPhone ?? '');
    _clientAddressController = TextEditingController(text: widget.invoice.clientAddress ?? '');
    _clientCityController = TextEditingController(text: widget.invoice.clientCity ?? '');
    _clientPostalCodeController = TextEditingController(text: widget.invoice.clientPostalCode ?? '');
    _notesController = TextEditingController(text: widget.invoice.notes ?? '');

    // Propiedad actual
    _selectedPropertyId = widget.invoice.propertyId;

    // Cargar propiedades desde el bloc
    context.read<InvoicesBloc>().add(const InvoicesLoadPropertiesRequested());

    // Cargar líneas de factura
    _globalTaxRate = widget.invoice.taxRate;
    _checkInDate = widget.invoice.periodStart;
    _checkOutDate = widget.invoice.periodEnd;

    if (widget.invoice.lineItems.isNotEmpty) {
      for (final item in widget.invoice.lineItems) {
        _lineItems.add(InvoiceLineItemDraft.fromEntity(item));
      }
    } else {
      // Si no hay líneas, crear una con el concepto existente
      _lineItems.add(InvoiceLineItemDraft(
        description: widget.invoice.concept,
        unitPrice: widget.invoice.taxBase,
        taxRate: widget.invoice.taxRate,
      ));
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientNifController.dispose();
    _clientEmailController.dispose();
    _clientPhoneController.dispose();
    _clientAddressController.dispose();
    _clientCityController.dispose();
    _clientPostalCodeController.dispose();
    _notesController.dispose();
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

    // Validar propiedad seleccionada
    if (_selectedPropertyId == null || _selectedPropertyId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una propiedad'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

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

    setState(() => _isLoading = true);

    try {
      // Convertir líneas a entidades
      final lineItemsEntities = validLines.map((l) => l.toEntity()).toList();

      // Crear factura actualizada
      final updatedInvoice = widget.invoice.copyWith(
        propertyId: _selectedPropertyId,
        clientName: _clientNameController.text.trim().isNotEmpty
            ? _clientNameController.text.trim()
            : widget.invoice.clientName,
        clientNif: _clientNifController.text.trim().isNotEmpty
            ? _clientNifController.text.trim()
            : null,
        clientEmail: _clientEmailController.text.trim().isNotEmpty
            ? _clientEmailController.text.trim()
            : null,
        clientPhone: _clientPhoneController.text.trim().isNotEmpty
            ? _clientPhoneController.text.trim()
            : null,
        clientAddress: _clientAddressController.text.trim().isNotEmpty
            ? _clientAddressController.text.trim()
            : null,
        clientCity: _clientCityController.text.trim().isNotEmpty
            ? _clientCityController.text.trim()
            : null,
        clientPostalCode: _clientPostalCodeController.text.trim().isNotEmpty
            ? _clientPostalCodeController.text.trim()
            : null,
        periodStart: _checkInDate,
        periodEnd: _checkOutDate,
        concept: validLines.length == 1 ? validLines.first.description : 'Factura múltiple',
        lineItems: lineItemsEntities,
        subtotalExcludingTax: _totalBaseAmount,
        taxRate: _globalTaxRate,
        taxBase: _totalBaseAmount,
        taxAmount: _totalTaxAmount,
        totalIncludingTax: _grandTotal,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (widget.onSave != null) {
        await widget.onSave!(updatedInvoice);
      } else {
        // Si no hay callback, disparar evento directamente
        if (mounted) {
          context.read<InvoicesBloc>().add(InvoiceUpdateRequested(updatedInvoice));
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Factura actualizada correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar factura: $e'),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Editar Factura',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.invoice.invoiceNumber,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: AppColors.gray400),
                      ),
                    ],
                  ),
                ),

                // Info banner
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Solo puedes editar facturas en estado BORRADOR',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

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
                          // Propiedad
                          _buildSectionTitle('Propiedad'),
                          _buildPropertySelector(),
                          const SizedBox(height: 24),

                          // Datos del cliente
                          _buildSectionTitle('Datos del cliente'),
                          _buildClientFields(),
                          const SizedBox(height: 24),

                          // Fechas de estancia
                          _buildSectionTitle('Fechas de estancia'),
                          _buildDateFields(),
                          const SizedBox(height: 24),

                          // Líneas de factura
                          _buildSectionTitle('Conceptos de factura'),
                          _buildLineItems(),
                          const SizedBox(height: 16),

                          // Botón añadir línea
                          _buildAddLineButton(),
                          const SizedBox(height: 24),

                          // Tipo de IVA global
                          _buildSectionTitle('Tipo de IVA'),
                          _buildTaxRateSelector(),
                          const SizedBox(height: 24),

                          // Resumen de totales
                          if (_grandTotal > 0) _buildTotals(),
                          const SizedBox(height: 16),

                          // Notas
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

        // Buscar la propiedad seleccionada
        Map<String, dynamic>? selectedProperty;
        for (final prop in state.properties) {
          if (prop['id'] == _selectedPropertyId) {
            selectedProperty = prop;
            break;
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedPropertyId != null
                  ? AppColors.goldWithAlpha50
                  : AppColors.darkBorder,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              value: selectedProperty,
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
                setState(() {
                  _selectedPropertyId = value?['id'] as String?;
                });
              },
            ),
          ),
        );
      },
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
          _buildEditableField(
            controller: _clientNameController,
            label: 'Nombre completo *',
            icon: Icons.person_outline,
            isRequired: true,
          ),
          const SizedBox(height: 12),
          _buildEditableField(
            controller: _clientNifController,
            label: 'NIF/CIF',
            icon: Icons.badge_outlined,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 12),
          _buildEditableField(
            controller: _clientEmailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildEditableField(
            controller: _clientPhoneController,
            label: 'Teléfono',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _buildEditableField(
            controller: _clientAddressController,
            label: 'Dirección',
            icon: Icons.home_outlined,
          ),
          const SizedBox(height: 12),
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
          Expanded(
            child: _buildDateField(
              label: 'Check-in',
              date: _checkInDate,
              onTap: () => _selectDate(isCheckIn: true),
            ),
          ),
          const SizedBox(width: 12),
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

          // Cantidad y Precio
          Row(
            children: [
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
          border: Border.all(color: AppColors.goldWithAlpha30),
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
                    'Guardar cambios',
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
