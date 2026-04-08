import 'package:flutter/material.dart';
import '../../../../core/enums/enums.dart';

/// Widget de badge de estado coloreado.
/// Pequeño, compacto y legible de un vistazo.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IntrinsicWidth(
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  // ==================== FACTORIES PARA BOOKING STATUS ====================

  /// Crea un badge para el estado de reserva
  factory StatusBadge.forBookingStatus(
    BuildContext context,
    BookingStatus status, {
    double fontSize = 10,
  }) {
    final config = _bookingStatusConfigs[status]!;
    return StatusBadge(
      label: status.label(context),
      backgroundColor: config.backgroundColor,
      textColor: config.textColor,
      fontSize: fontSize,
    );
  }

  /// Crea un badge desde string de estado de reserva
  factory StatusBadge.fromBookingString(
    BuildContext context,
    String status, {
    double fontSize = 10,
  }) {
    return StatusBadge.forBookingStatus(
      context,
      BookingStatus.fromString(status),
      fontSize: fontSize,
    );
  }

  // ==================== FACTORIES PARA CHECKIN STATUS ====================

  /// Crea un badge para el estado de check-in
  factory StatusBadge.forCheckinStatus(
    BuildContext context,
    CheckinStatus status, {
    double fontSize = 10,
  }) {
    final config = _checkinStatusConfigs[status]!;
    return StatusBadge(
      label: status.label(context),
      backgroundColor: config.backgroundColor,
      textColor: config.textColor,
      fontSize: fontSize,
    );
  }

  /// Crea un badge desde string de estado de check-in
  factory StatusBadge.fromCheckinString(
    BuildContext context,
    String? status, {
    double fontSize = 10,
  }) {
    if (status == null || status.isEmpty) {
      return StatusBadge.forCheckinStatus(
        context,
        CheckinStatus.notStarted,
        fontSize: fontSize,
      );
    }
    return StatusBadge.forCheckinStatus(
      context,
      CheckinStatus.fromString(status),
      fontSize: fontSize,
    );
  }

  // ==================== FACTORIES PARA CHECKOUT STATUS ====================

  /// Crea un badge para el estado de check-out
  factory StatusBadge.forCheckoutStatus(
    BuildContext context,
    CheckoutStatus status, {
    double fontSize = 10,
  }) {
    final config = _checkoutStatusConfigs[status]!;
    return StatusBadge(
      label: status.label(context),
      backgroundColor: config.backgroundColor,
      textColor: config.textColor,
      fontSize: fontSize,
    );
  }

  /// Crea un badge desde string de estado de check-out
  factory StatusBadge.fromCheckoutString(
    BuildContext context,
    String? status, {
    double fontSize = 10,
  }) {
    if (status == null || status.isEmpty) {
      return StatusBadge.forCheckoutStatus(
        context,
        CheckoutStatus.notStarted,
        fontSize: fontSize,
      );
    }
    return StatusBadge.forCheckoutStatus(
      context,
      CheckoutStatus.fromString(status),
      fontSize: fontSize,
    );
  }

  // ==================== CONFIGURACIONES ====================

  static const Map<BookingStatus, _StatusColorConfig> _bookingStatusConfigs = {
    BookingStatus.created: _StatusColorConfig(
      backgroundColor: Color(0x26737373), // gris 15%
      textColor: Color(0xFF737373),
    ),
    BookingStatus.confirmed: _StatusColorConfig(
      backgroundColor: Color(0x262980B9), // azul 15%
      textColor: Color(0xFF2980B9),
    ),
    BookingStatus.active: _StatusColorConfig(
      backgroundColor: Color(0x2627AE60), // verde 15%
      textColor: Color(0xFF27AE60),
    ),
    BookingStatus.inHouse: _StatusColorConfig(
      backgroundColor: Color(0x2627AE60), // verde 15%
      textColor: Color(0xFF27AE60),
    ),
    BookingStatus.checkedIn: _StatusColorConfig(
      backgroundColor: Color(0x2627AE60), // verde 15%
      textColor: Color(0xFF27AE60),
    ),
    BookingStatus.checkedOut: _StatusColorConfig(
      backgroundColor: Color(0x26737373), // gris 15%
      textColor: Color(0xFF737373),
    ),
    BookingStatus.closed: _StatusColorConfig(
      backgroundColor: Color(0x26636363), // gris oscuro 15%
      textColor: Color(0xFF636363),
    ),
    BookingStatus.cancelled: _StatusColorConfig(
      backgroundColor: Color(0x26C0392B), // rojo 15%
      textColor: Color(0xFFC0392B),
    ),
  };

  static const Map<CheckinStatus, _StatusColorConfig> _checkinStatusConfigs = {
    CheckinStatus.notStarted: _StatusColorConfig(
      backgroundColor: Color(0x1A737373), // gris 10%
      textColor: Color(0xFF737373),
    ),
    CheckinStatus.inProgress: _StatusColorConfig(
      backgroundColor: Color(0x262980B9), // azul 15%
      textColor: Color(0xFF2980B9),
    ),
    CheckinStatus.submitted: _StatusColorConfig(
      backgroundColor: Color(0x26E67E22), // naranja 15%
      textColor: Color(0xFFE67E22),
    ),
    CheckinStatus.validated: _StatusColorConfig(
      backgroundColor: Color(0x2627AE60), // verde 15%
      textColor: Color(0xFF27AE60),
    ),
    CheckinStatus.rejected: _StatusColorConfig(
      backgroundColor: Color(0x26C0392B), // rojo 15%
      textColor: Color(0xFFC0392B),
    ),
  };

  static const Map<CheckoutStatus, _StatusColorConfig> _checkoutStatusConfigs = {
    CheckoutStatus.notStarted: _StatusColorConfig(
      backgroundColor: Color(0x1A737373), // gris 10%
      textColor: Color(0xFF737373),
    ),
    CheckoutStatus.requested: _StatusColorConfig(
      backgroundColor: Color(0x26E67E22), // naranja 15%
      textColor: Color(0xFFE67E22),
    ),
    CheckoutStatus.validated: _StatusColorConfig(
      backgroundColor: Color(0x2627AE60), // verde 15%
      textColor: Color(0xFF27AE60),
    ),
    CheckoutStatus.rejected: _StatusColorConfig(
      backgroundColor: Color(0x26C0392B), // rojo 15%
      textColor: Color(0xFFC0392B),
    ),
  };
}

/// Configuración interna de colores por estado (sin label, ya viene de la extensión l10n)
class _StatusColorConfig {
  const _StatusColorConfig({
    required this.backgroundColor,
    required this.textColor,
  });

  final Color backgroundColor;
  final Color textColor;
}
