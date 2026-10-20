import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/invoice_entity.dart';
import '../invoices_tab.dart';
import 'period_filters.dart';

/// Fila compacta de una factura en el listado por periodo
class PeriodInvoiceRow extends StatelessWidget {
  const PeriodInvoiceRow({super.key, required this.invoice, this.onTap});

  final InvoiceEntity invoice;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCancelled = invoice.status == InvoiceStatus.cancelled;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            invoice.formattedIssueDate,
                            style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        invoice.clientName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatPeriodCurrency(invoice.totalIncludingTax),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isCancelled ? AppColors.gray500 : AppColors.white,
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InvoiceStatusBadge(status: invoice.status),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
