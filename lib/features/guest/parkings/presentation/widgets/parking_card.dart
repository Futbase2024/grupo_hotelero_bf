import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/parking_entity.dart';

/// Tarjeta que muestra un parking cercano
class ParkingCard extends StatelessWidget {
  const ParkingCard({
    super.key,
    required this.parking,
    this.priority,
    this.notes,
  });

  final ParkingEntity parking;
  final int? priority;
  final String? notes;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: isDark ? AppColors.gray900 : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.gray800 : AppColors.gray200,
          width: 1,
        ),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con nombre y badge de prioridad
            _HeaderRow(
              parking: parking,
              priority: priority,
            ),

            const SizedBox(height: 12),

            // Dirección
            _AddressRow(parking: parking),

            // Teléfono (si existe)
            if (parking.hasPhone) ...[
              const SizedBox(height: 8),
              _PhoneRow(parking: parking),
            ],

            // Notas (si existen)
            if (notes != null && notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _NotesSection(notes: notes!),
            ],

            const SizedBox(height: 16),

            // Botón único de mapa
            _MapButton(parking: parking),
          ],
        ),
      ),
    );
  }
}

/// Fila de header con nombre y badge de prioridad
class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.parking,
    this.priority,
  });

  final ParkingEntity parking;
  final int? priority;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icono de parking
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.goldWithAlpha20,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.local_parking,
            size: 20,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: 12),
        // Nombre
        Expanded(
          child: Text(
            parking.name,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimaryColor(context),
            ),
          ),
        ),
        // Badge de prioridad
        if (priority != null)
          _PriorityBadge(priority: priority!),
      ],
    );
  }
}

/// Badge de prioridad
class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final int priority;

  Color get _backgroundColor {
    switch (priority) {
      case 0:
        return AppColors.successLight;
      case 1:
        return AppColors.goldWithAlpha20;
      case 2:
        return AppColors.infoLight;
      default:
        return AppColors.gray100;
    }
  }

  Color get _textColor {
    switch (priority) {
      case 0:
        return AppColors.success;
      case 1:
        return AppColors.goldDark;
      case 2:
        return AppColors.info;
      default:
        return AppColors.gray600;
    }
  }

  String get _label {
    switch (priority) {
      case 0:
        return 'Más cercano';
      case 1:
        return 'Recomendado';
      case 2:
        return 'Alternativa';
      default:
        return 'Opción ${priority + 1}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _textColor,
        ),
      ),
    );
  }
}

/// Fila de dirección
class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.parking});

  final ParkingEntity parking;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 18,
          color: AppColors.gray500,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            parking.addressText,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
        ),
      ],
    );
  }
}

/// Fila de teléfono
class _PhoneRow extends StatelessWidget {
  const _PhoneRow({required this.parking});

  final ParkingEntity parking;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.phone_outlined,
          size: 18,
          color: AppColors.gray500,
        ),
        const SizedBox(width: 8),
        Text(
          parking.phone!,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.getTextSecondaryColor(context),
          ),
        ),
      ],
    );
  }
}

/// Sección de notas
class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.gray800.withValues(alpha: 0.5)
            : AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.gray700 : AppColors.gray200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: isDark ? AppColors.gray400 : AppColors.gray500,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              notes,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getTextSecondaryColor(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón único de mapa que abre la app correspondiente según la plataforma
class _MapButton extends StatelessWidget {
  const _MapButton({required this.parking});

  final ParkingEntity parking;

  /// Detecta si estamos en iOS (no web)
  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Detecta si estamos en web
  bool get _isWeb => kIsWeb;

  Future<void> _openMap() async {
    // En web abrimos Google Maps en nueva pestaña
    // En iOS usamos Apple Maps, en Android usamos Google Maps
    final String mapUrl;
    if (_isWeb) {
      mapUrl = parking.effectiveGoogleMapsUrl ?? '';
    } else if (_isIOS) {
      mapUrl = parking.effectiveAppleMapsUrl ?? parking.effectiveGoogleMapsUrl ?? '';
    } else {
      mapUrl = parking.effectiveGoogleMapsUrl ?? '';
    }

    if (mapUrl.isEmpty) return;

    final uri = Uri.parse(mapUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openMap,
        icon: Icon(
          _isWeb
              ? Icons.open_in_new
              : (_isIOS ? Icons.navigation_outlined : Icons.map_outlined),
          size: 18,
          color: isDark ? AppColors.black : AppColors.white,
        ),
        label: Text(
          _isWeb
              ? 'Abrir en Google Maps'
              : (_isIOS ? 'Abrir en Mapas' : 'Abrir en Google Maps'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.black : AppColors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: isDark ? AppColors.black : AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
