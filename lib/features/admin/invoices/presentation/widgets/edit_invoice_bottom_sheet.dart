import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/invoice_entity.dart';
import '../bloc/invoices_bloc.dart';
import '../bloc/invoices_event.dart';

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

  // Controladores
  late final TextEditingController _clientNameController;
  late final TextEditingController _clientNifController;
  late final TextEditingController _clientEmailController;
  late final TextEditingController _clientPhoneController;
  late final TextEditingController _clientAddressController;
  late final TextEditingController _clientCityController;
  late final TextEditingController _clientPostalCodeController;
  late final TextEditingController _notesController;
  late final TextEditingController _unitNameController;
  late final TextEditingController _baseAmountController;

  // Tipo de IVA
  late double _selectedTaxRate;

  final List<Map<String, dynamic>> _taxRates = [
    {'rate': 10.0, 'label': '10% - Alojamiento turistico'},
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
    _unitNameController = TextEditingController(text: widget.invoice.unitName ?? '');
    _baseAmountController = TextEditingController(text: widget.invoice.taxBase.toStringAsFixed(2));
    _selectedTaxRate = widget.invoice.taxRate;
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
    _unitNameController.dispose();
    _baseAmountController.dispose();
    super.dispose();
  }

  double get _baseAmount {
    return double.tryParse(_baseAmountController.text.replaceAll(',', '.')) ?? 0;
  }

  double get _taxAmount {
    return _baseAmount * (_selectedTaxRate / 100);
  }

  double get _totalAmount {
    return _baseAmount + _taxAmount;
  }

  Future<void> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) return;

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
      // Actualizar líneas de factura con el nuevo importe
      List<InvoiceLineItem> updatedLineItems;
      if (widget.invoice.lineItems.isNotEmpty) {
        // Actualizar la primera línea con el nuevo precio
        final firstLine = widget.invoice.lineItems.first;
        updatedLineItems = [
          firstLine.copyWith(
            unitPrice: _baseAmount,
            taxRate: _selectedTaxRate,
          ),
          ...widget.invoice.lineItems.skip(1),
        ];
      } else {
        // Crear una línea nueva si no existe
        updatedLineItems = [
          InvoiceLineItem(
            description: widget.invoice.concept.isNotEmpty
                ? widget.invoice.concept
                : 'Alojamiento turístico',
            quantity: 1,
            unitPrice: _baseAmount,
            taxRate: _selectedTaxRate,
          ),
        ];
      }

      // Crear factura actualizada
      final updatedInvoice = widget.invoice.copyWith(
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
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        unitName: _unitNameController.text.trim().isNotEmpty
            ? _unitNameController.text.trim()
            : null,
        lineItems: updatedLineItems,
        subtotalExcludingTax: _baseAmount,
        taxRate: _selectedTaxRate,
        taxBase: _baseAmount,
        taxAmount: _taxAmount,
        totalIncludingTax: _totalAmount,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Datos del alojamiento
                    _buildSectionTitle('Datos del alojamiento'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _unitNameController,
                      label: 'Nombre del alojamiento',
                      icon: Icons.hotel_outlined,
                    ),
                    const SizedBox(height: 20),

                    // Importes
                    _buildSectionTitle('Importes'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _baseAmountController,
                      label: 'Base imponible (EUR)',
                      icon: Icons.euro_outlined,
                      isRequired: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    _buildTaxRateSelector(),
                    const SizedBox(height: 20),

                    // Datos del cliente
                    _buildSectionTitle('Datos del cliente'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _clientNameController,
                      label: 'Nombre del cliente',
                      icon: Icons.person_outline,
                      isRequired: true,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _clientNifController,
                      label: 'CIF/NIF',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _clientEmailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _clientPhoneController,
                      label: 'Telefono',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _clientAddressController,
                      label: 'Direccion',
                      icon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _clientPostalCodeController,
                            label: 'CP',
                            icon: Icons.markunread_mailbox_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: _buildTextField(
                            controller: _clientCityController,
                            label: 'Ciudad',
                            icon: Icons.location_city_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Notas
                    _buildSectionTitle('Notas'),
                    const SizedBox(height: 12),
                    _buildTextField(
                        controller: _notesController,
                        label: 'Notas adicionales',
                        icon: Icons.note_outlined,
                        maxLines: 3,
                      ),
                    const SizedBox(height: 20),

                    // Resumen de importes
                    _buildSectionTitle('Resumen de importes'),
                    const SizedBox(height: 12),
                    _buildAmountSummary(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Save button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.darkSurface,
              border: Border(
                top: BorderSide(color: AppColors.darkBorder),
              ),
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
                      borderRadius: BorderRadius.circular(12),
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
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.gray300,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.white),
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Este campo es obligatorio';
              }
              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.gray500),
        prefixIcon: Icon(icon, color: AppColors.gray500, size: 20),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildTaxRateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<double>(
          value: _selectedTaxRate,
          isExpanded: true,
          dropdownColor: AppColors.darkSurface,
          style: const TextStyle(color: AppColors.white),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.gold),
          items: _taxRates.map((tax) {
            return DropdownMenuItem<double>(
              value: tax['rate'] as double,
              child: Text(tax['label'] as String),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedTaxRate = value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildAmountSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          _buildAmountRow('Base imponible', _baseAmount),
          const SizedBox(height: 8),
          _buildAmountRow('IVA (${_selectedTaxRate.toStringAsFixed(0)}%)', _taxAmount),
          const Divider(color: AppColors.darkBorder, height: 24),
          _buildAmountRow('Total', _totalAmount, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, {bool isTotal = false}) {
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
          '${amount.toStringAsFixed(2).replaceAll('.', ',')} EUR',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? AppColors.gold : AppColors.white,
          ),
        ),
      ],
    );
  }
}
