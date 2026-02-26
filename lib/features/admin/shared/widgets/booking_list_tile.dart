import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'status_badge.dart';

/// Tile de reserva para usar en listas. Compacto y legible de un vistazo.
/// Fila horizontal con indicador de color según status, contenido y código BF.
class BookingListTile extends StatelessWidget {
  const BookingListTile({
    super.key,
    required this.unitName,
    required this.numGuests,
    required this.checkInDate,
    required this.checkOutDate,
    required this.status,
    required this.bookingCode,
    this.guestName,
    this.docsPending = 0,
    this.onTap,
  });

  final String unitName;
  final int numGuests;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final BookingStatus status;
  final String bookingCode;
  final String? guestName;
  final int docsPending;
  final VoidCallback? onTap;

  String _formatDate(DateTime date) {
    // Formato simple sin locale para evitar inicialización
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor() {
    switch (status) {
      case BookingStatus.confirmed:
        return const Color(0xFF2980B9);
      case BookingStatus.checkedIn:
        return const Color(0xFF27AE60);
      case BookingStatus.checkedOut:
        return const Color(0xFF737373);
      case BookingStatus.cancelled:
        return const Color(0xFF636363);
      case BookingStatus.submitted:
        return const Color(0xFFE67E22);
      case BookingStatus.validated:
        return const Color(0xFF27AE60);
      case BookingStatus.rejected:
        return const Color(0xFFC0392B);
      case BookingStatus.draft:
        return const Color(0xFF737373);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.getBorderColor(context),
            width: 1,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Indicador de color según status (3px de ancho)
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),

              // Contenido
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Línea 1: Unit name + guests
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$unitName · $numGuests pers.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.getTextPrimaryColor(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Línea 2: Fechas
                      Text(
                        'Entrada: ${_formatDate(checkInDate)} → Salida: ${_formatDate(checkOutDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: AppColors.getTextSecondaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Línea 3: Status badge + docs badge
                      Row(
                        children: [
                          StatusBadge(status: status),
                          if (docsPending > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warningLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$docsPending docs pendientes',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Código BF + flecha
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          bookingCode,
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.gold,
                          ),
                        ),
                        if (guestName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            guestName!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w300,
                              color: AppColors.getTextSecondaryColor(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.getTextSecondaryColor(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
