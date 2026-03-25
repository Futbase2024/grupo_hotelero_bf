import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/enums/enums.dart';

/// Tile de reserva profesional para usar en listas.
/// Diseño moderno con indicador de status, información clara y feedback táctil.
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
    this.totalUnits = 1,
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
  final int totalUnits;
  final VoidCallback? onTap;

  /// Indica si la reserva tiene múltiples unidades
  bool get hasMultipleUnits => totalUnits > 1;

  String _formatDateLong(DateTime date) {
    final months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${date.day} ${months[date.month - 1]}';
  }

  Color _getStatusColor() {
    return switch (status) {
      BookingStatus.created => AppColors.gray500,
      BookingStatus.confirmed => AppColors.info,
      BookingStatus.active => AppColors.success,
      BookingStatus.inHouse => AppColors.success,
      BookingStatus.checkedIn => AppColors.success, // Legacy
      BookingStatus.checkedOut => AppColors.gray500,
      BookingStatus.closed => AppColors.gray500,
      BookingStatus.cancelled => AppColors.error,
    };
  }

  IconData _getStatusIcon() {
    return switch (status) {
      BookingStatus.created => Icons.add_circle_outline,
      BookingStatus.confirmed => Icons.event_available_rounded,
      BookingStatus.active => Icons.home_work_rounded,
      BookingStatus.inHouse => Icons.home_rounded,
      BookingStatus.checkedIn => Icons.home_rounded, // Legacy
      BookingStatus.checkedOut => Icons.luggage_rounded,
      BookingStatus.closed => Icons.check_circle_outline,
      BookingStatus.cancelled => Icons.cancel_rounded,
    };
  }

  int get _nights => checkOutDate.difference(checkInDate).inDays;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.darkBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.blackWithAlpha20,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Indicador lateral de color
                  Container(
                    width: 4,
                    height: double.infinity,
                    color: statusColor,
                  ),

                // Contenido principal
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fila 1: Alojamiento + Badge de noches
                        Row(
                          children: [
                            // Icono del alojamiento
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.goldWithAlpha20,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.apartment_rounded,
                                color: AppColors.gold,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          hasMultipleUnits ? '$totalUnits habitaciones' : unitName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Badge con número de unidades si tiene múltiples
                                      if (hasMultipleUnits) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.gold,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '×$totalUnits',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$numGuests ${numGuests == 1 ? "huésped" : "huéspedes"}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.getTextSecondaryColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Badge de noches
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$_nights ${_nights == 1 ? "noche" : "noches"}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Fila 2: Fechas con diseño visual
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.darkBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              // Check-in
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.login_rounded,
                                        color: AppColors.success,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ENTRADA',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.getTextSecondaryColor(context),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        Text(
                                          _formatDateLong(checkInDate),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Separador
                              Container(
                                height: 24,
                                width: 1,
                                color: AppColors.darkBorder,
                              ),

                              // Check-out
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'SALIDA',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.getTextSecondaryColor(context),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        Text(
                                          _formatDateLong(checkOutDate),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.logout_rounded,
                                        color: AppColors.warning,
                                        size: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Fila 3: Status badge + docs pendientes
                        Row(
                          children: [
                            // Status con icono
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(),
                                    size: 14,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getStatusText(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Docs pendientes
                            if (docsPending > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.errorLight,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.description_outlined,
                                      size: 14,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$docsPending ${docsPending == 1 ? "doc pendiente" : "docs pendientes"}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const Spacer(),

                            // Flecha de navegación
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.goldWithAlpha20,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Panel derecho: Código BF y huésped
                Container(
                  width: 100,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.goldWithAlpha10,
                    border: Border(
                      left: BorderSide(
                        color: AppColors.goldWithAlpha30,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Código BF
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.goldWithAlpha20,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          bookingCode,
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (guestName != null && guestName!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          guestName!,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.getTextSecondaryColor(context),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
    ),
    );
  }

  String _getStatusText() {
    return switch (status) {
      BookingStatus.created => 'Creada',
      BookingStatus.confirmed => 'Confirmada',
      BookingStatus.active => 'Activa',
      BookingStatus.inHouse => 'En casa',
      BookingStatus.checkedIn => 'Activa', // Legacy - mostrar como Activa
      BookingStatus.checkedOut => 'Finalizada',
      BookingStatus.closed => 'Cerrada',
      BookingStatus.cancelled => 'Cancelada',
    };
  }
}
