import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/invoice_entity.dart';
import '../bloc/invoices_bloc.dart';
import '../bloc/invoices_event.dart';
import '../bloc/invoices_state.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import 'create_invoice_bottom_sheet.dart';
import 'edit_invoice_bottom_sheet.dart';
import '../screens/invoice_detail_screen.dart';

/// Tab de facturas del dashboard de administración
class InvoicesTab extends StatefulWidget {
  const InvoicesTab({super.key});

  @override
  State<InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends State<InvoicesTab> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar facturas al iniciar
    context.read<InvoicesBloc>().add(const InvoicesLoadRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Content
        BlocBuilder<InvoicesBloc, InvoicesState>(
          builder: (context, state) {
            return Column(
              children: [
                // Header
                _buildHeader(context, state),

                // Search bar
                _buildSearchBar(context, state),

                // Invoices list
                Expanded(
                  child: _buildInvoicesList(context, state),
                ),
              ],
            );
          },
        ),

        // FAB
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: null,
            onPressed: () => _showCreateInvoiceSheet(context),
            backgroundColor: AppColors.gold,
            child: const Icon(Icons.add, color: AppColors.black),
          ),
        ),
      ],
    );
  }

  void _showCreateInvoiceSheet(BuildContext context) {
    final bloc = context.read<InvoicesBloc>();

    // Cargar reservas si no están cargadas
    if (bloc.state.bookings.isEmpty) {
      bloc.add(const InvoicesLoadBookingsRequested());
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: bloc,
        child: CreateInvoiceBottomSheet(
          onSave: (invoice) async {
            bloc.add(InvoiceCreateRequested(invoice));
          },
        ),
      ),
    );
  }

  void _showEditInvoiceSheet(BuildContext context, InvoiceEntity invoice) {
    final bloc = context.read<InvoicesBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: bloc,
        child: EditInvoiceBottomSheet(
          invoice: invoice,
          onSave: (updatedInvoice) async {
            bloc.add(InvoiceUpdateRequested(updatedInvoice));
          },
        ),
      ),
    ).then((_) {
      // Mostrar mensaje de éxito
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Factura actualizada correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  Future<void> _confirmDelete(BuildContext context, InvoiceEntity invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        title: Text(
          '¿Eliminar factura?',
          style: const TextStyle(color: AppColors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta acción no se puede deshacer.',
              style: const TextStyle(color: AppColors.gray400),
            ),
            const SizedBox(height: 8),
            Text(
              invoice.invoiceNumber,
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.gray400),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<InvoicesBloc>().add(InvoiceDeleteRequested(invoice.id));
    }
  }

  Widget _buildHeader(BuildContext context, InvoicesState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Text(
            'Facturas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, InvoicesState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          context.read<InvoicesBloc>().add(
            InvoicesSearchChanged(value.isEmpty ? null : value),
          );
        },
        style: const TextStyle(color: AppColors.white),
        decoration: InputDecoration(
          hintText: 'Buscar por numero de factura, cliente o concepto...',
          hintStyle: const TextStyle(color: AppColors.gray500),
          prefixIcon: const Icon(Icons.search, color: AppColors.gray500),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildInvoicesList(BuildContext context, InvoicesState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    final invoices = state.invoices;

    if (invoices.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.receipt_long_outlined,
        title: 'Sin facturas',
        subtitle: 'Crea la primera factura desde una reserva',
        actionLabel: null,
        onAction: null,
      );
    }

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.darkSurface,
      onRefresh: () async {
        context.read<InvoicesBloc>().add(
          const InvoicesRefreshRequested(),
        );
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          final invoice = invoices[index];
          return _InvoiceListTile(
            invoice: invoice,
            bloc: context.read<InvoicesBloc>(),
            onEdit: invoice.isEditable ? () => _showEditInvoiceSheet(context, invoice) : null,
            onDelete: invoice.isEditable ? () => _confirmDelete(context, invoice) : null,
          );
        },
      ),
    );
  }
}

/// Tile individual de factura
class _InvoiceListTile extends StatelessWidget {
  const _InvoiceListTile({
    required this.invoice,
    required this.bloc,
    this.onEdit,
    this.onDelete,
  });

  final InvoiceEntity invoice;
  final InvoicesBloc bloc;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showActionsMenu(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              invoice.invoiceNumber,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          InvoiceStatusBadge(status: invoice.status),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Client name
                      Text(
                        invoice.clientName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.gray300,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Details row
                      Row(
                        children: [
                          // Date
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: AppColors.gray500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  invoice.formattedIssueDate,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Total
                          Text(
                            invoice.formattedTotal,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),

                      // Booking info
                      if (invoice.bookingCode != null && invoice.bookingCode!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.hotel_outlined,
                              size: 14,
                              color: AppColors.gray500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Reserva ${invoice.bookingCode}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.gray500,
                              ),
                            ),
                            if (invoice.unitName != null && invoice.unitName!.isNotEmpty)
                              Text(
                                ' - ${invoice.unitName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.gray500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header con info de factura
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Número de factura y estado
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invoice.invoiceNumber,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                invoice.clientName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.gray400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InvoiceStatusBadge(status: invoice.status, fontSize: 11),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Info adicional
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.blackWithAlpha20,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Fecha
                          Expanded(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: AppColors.gray500,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  invoice.formattedIssueDate,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Total
                          Expanded(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.euro_outlined,
                                  size: 18,
                                  color: AppColors.gold,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  invoice.formattedTotal,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: AppColors.darkBorder, height: 1),

              // Actions grid
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Row(
                  children: [
                    _MenuActionButton(
                      icon: Icons.visibility_outlined,
                      label: 'Ver detalle',
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToDetail(context);
                      },
                    ),
                    if (invoice.isEditable) ...[
                      const SizedBox(width: 12),
                      _MenuActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Editar',
                        onPressed: () {
                          Navigator.pop(context);
                          onEdit?.call();
                        },
                      ),
                    ],
                    if (invoice.isEditable) ...[
                      const SizedBox(width: 12),
                      _MenuActionButton(
                        icon: Icons.delete_outline,
                        label: 'Eliminar',
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete?.call();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: bloc,
          child: InvoiceDetailScreen(invoice: invoice),
        ),
      ),
    );
  }
}

/// Botón de acción profesional para el menú
class _MenuActionButton extends StatelessWidget {
  const _MenuActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.black, size: 22),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Configuracion interna de cada estado de factura
class _InvoiceStatusConfig {
  const _InvoiceStatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
}

/// Badge de estado de factura
class InvoiceStatusBadge extends StatelessWidget {
  const InvoiceStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 10,
  });

  final InvoiceStatus status;
  final double fontSize;

  static Map<InvoiceStatus, _InvoiceStatusConfig> get _statusConfigs => {
    InvoiceStatus.draft: _InvoiceStatusConfig(
      label: 'BORRADOR',
      backgroundColor: AppColors.gray500.withValues(alpha: 0.15),
      textColor: AppColors.gray400,
    ),
    InvoiceStatus.issued: _InvoiceStatusConfig(
      label: 'EMITIDA',
      backgroundColor: AppColors.infoLight,
      textColor: AppColors.info,
    ),
    InvoiceStatus.paid: _InvoiceStatusConfig(
      label: 'PAGADA',
      backgroundColor: AppColors.successLight,
      textColor: AppColors.success,
    ),
    InvoiceStatus.cancelled: _InvoiceStatusConfig(
      label: 'CANCELADA',
      backgroundColor: AppColors.errorLight,
      textColor: AppColors.error,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final config = _statusConfigs[status]!;
    return Align(
      alignment: Alignment.centerLeft,
      child: IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: config.backgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            config.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: config.textColor,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
