import 'package:flutter/material.dart';

/// Enum para los estados de reserva y check-in
enum BookingStatus {
  confirmed,
  checkedIn,
  checkedOut,
  cancelled,
  draft,
  submitted,
  validated,
  rejected,
}

/// Widget de badge de estado coloreado.
/// Pequeño, compacto y legible de un vistazo.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  final BookingStatus status;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  /// Configuración de cada estado
  static const Map<BookingStatus, _StatusConfig> _configs = {
    BookingStatus.confirmed: _StatusConfig(
      label: 'Confirmada',
      backgroundColor: Color(0x262980B9), // azul 15%
      textColor: Color(0xFF2980B9),
    ),
    BookingStatus.checkedIn: _StatusConfig(
      label: 'En casa',
      backgroundColor: Color(0x2627AE60), // verde 15%
      textColor: Color(0xFF27AE60),
    ),
    BookingStatus.checkedOut: _StatusConfig(
      label: 'Finalizada',
      backgroundColor: Color(0x26737373), // gris 15%
      textColor: Color(0xFF737373),
    ),
    BookingStatus.cancelled: _StatusConfig(
      label: 'Cancelada',
      backgroundColor: Color(0x26636363), // gris 15%
      textColor: Color(0xFF636363),
    ),
    BookingStatus.draft: _StatusConfig(
      label: 'Sin empezar',
      backgroundColor: Color(0x1A737373), // gris 10%
      textColor: Color(0xFF737373),
    ),
    BookingStatus.submitted: _StatusConfig(
      label: 'Por revisar',
      backgroundColor: Color(0x26E67E22), // naranja 15%
      textColor: Color(0xFFE67E22),
    ),
    BookingStatus.validated: _StatusConfig(
      label: 'Validado',
      backgroundColor: Color(0x2627AE60), // verde 15%
      textColor: Color(0xFF27AE60),
    ),
    BookingStatus.rejected: _StatusConfig(
      label: 'Rechazado',
      backgroundColor: Color(0x26C0392B), // rojo 15%
      textColor: Color(0xFFC0392B),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final config = _configs[status] ?? _configs[BookingStatus.draft]!;

    return Container(
      padding: padding,
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
    );
  }

  /// Factory para crear desde un string de estado
  factory StatusBadge.fromString(String status, {double fontSize = 10}) {
    return StatusBadge(
      status: BookingStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == status.toLowerCase(),
        orElse: () => BookingStatus.draft,
      ),
      fontSize: fontSize,
    );
  }
}

/// Configuración interna de cada estado
class _StatusConfig {
  const _StatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
}
