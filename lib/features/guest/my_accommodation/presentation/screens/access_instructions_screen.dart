import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/core/theme/app_theme.dart';
import 'package:bf_stay/core/theme/responsive.dart';
import 'package:bf_stay/features/admin/domain/entities/admin_booking_entity.dart';
import 'package:bf_stay/features/guest/alojamientos/domain/entities/unit_entity.dart';
import 'package:bf_stay/features/guest/alojamientos/domain/entities/property_entity.dart';

/// Pantalla de Instrucciones de Acceso completas para el huésped
class AccessInstructionsScreen extends StatelessWidget {
  const AccessInstructionsScreen({
    super.key,
    required this.booking,
    required this.unit,
    required this.property,
    this.serverTime,
  });

  final AdminBookingEntity booking;
  final UnitEntity unit;
  final PropertyEntity property;
  /// Hora actual del servidor (para evitar manipulación del reloj del dispositivo)
  /// Si es null, se usa DateTime.now() como fallback
  final DateTime? serverTime;

  /// Hora de check-in (misma para todos)
  static const String _checkinTime = '14:00';

  /// Hora a partir de la cual están disponibles las llaves/códigos por defecto (14:00)
  static const int _defaultKeysAvailableHour = 14;

  /// Determina si es un hotel basado en el nombre de la propiedad
  bool get _isHotel {
    final name = property.name.toLowerCase();
    return name.contains('hotel') || name.contains('grupo hotelero');
  }

  /// Hora límite de check-out según tipo de propiedad
  String get _checkoutTime => _isHotel ? '12:00' : '11:30';

  /// Verifica si las llaves y códigos están disponibles
  /// Por defecto: 14:00 del día de check-in
  /// Early check-in: Solo tiene efecto si el admin lo marca el MISMO DÍA de check-in
  /// IMPORTANTE: Usa la hora del servidor para evitar manipulación del reloj del dispositivo
  bool get _areKeysAvailable {
    // Usar hora del servidor si está disponible, si no, usar hora local como fallback
    final now = serverTime ?? DateTime.now();
    final checkInDate = booking.checkInDate;

    // Si el admin ha marcado early check-in, verificar que sea del MISMO DÍA de check-in
    if (booking.earlyCheckinAvailableAt != null) {
      final earlyTime = booking.earlyCheckinAvailableAt!;

      // Verificar que el early check-in fue marcado el mismo día de la reserva
      final isSameDay = earlyTime.year == checkInDate.year &&
          earlyTime.month == checkInDate.month &&
          earlyTime.day == checkInDate.day;

      // Solo tiene efecto si es el mismo día Y ya pasó la hora marcada
      if (isSameDay) {
        return now.isAfter(earlyTime) || now.isAtSameMomentAs(earlyTime);
      }
      // Si NO es el mismo día, ignorar y usar comportamiento por defecto
    }

    // Comportamiento por defecto: 14:00 del día de check-in
    final keysAvailableTime = DateTime(
      checkInDate.year,
      checkInDate.month,
      checkInDate.day,
      _defaultKeysAvailableHour,
      0,
      0,
    );

    return now.isAfter(keysAvailableTime) || now.isAtSameMomentAs(keysAvailableTime);
  }

  /// Calcula cuándo estarán disponibles las llaves
  /// Por defecto: 14:00 del día de check-in
  /// Early check-in: Solo tiene efecto si el admin lo marca el MISMO DÍA de check-in
  /// NOTA: El cálculo de disponibilidad real usa _areKeysAvailable con hora del servidor
  DateTime get _keysAvailableTime {
    final checkInDate = booking.checkInDate;

    // Si el admin ha marcado early check-in, verificar que sea del MISMO DÍA de check-in
    if (booking.earlyCheckinAvailableAt != null) {
      final earlyTime = booking.earlyCheckinAvailableAt!;

      // Verificar que el early check-in fue marcado el mismo día de la reserva
      final isSameDay = earlyTime.year == checkInDate.year &&
          earlyTime.month == checkInDate.month &&
          earlyTime.day == checkInDate.day;

      // Solo tiene efecto si es el mismo día
      if (isSameDay) {
        return earlyTime;
      }
      // Si NO es el mismo día, ignorar y usar comportamiento por defecto
    }

    // Comportamiento por defecto: 14:00 del día de check-in
    return DateTime(
      checkInDate.year,
      checkInDate.month,
      checkInDate.day,
      _defaultKeysAvailableHour,
      0,
      0,
    );
  }

  /// Obtiene la dirección completa formateada
  String get _fullAddress {
    final parts = <String>[];
    if (unit.addressLine1 != null && unit.addressLine1!.isNotEmpty) {
      parts.add(unit.addressLine1!);
    }
    if (unit.addressLine2 != null && unit.addressLine2!.isNotEmpty) {
      parts.add(unit.addressLine2!);
    }
    if (unit.neighborhood != null && unit.neighborhood!.isNotEmpty) {
      parts.add(unit.neighborhood!);
    }
    if (unit.city != null && unit.city!.isNotEmpty) {
      parts.add(unit.city!);
    }
    if (unit.province != null && unit.province!.isNotEmpty) {
      parts.add(unit.province!);
    }
    if (unit.postalCode != null && unit.postalCode!.isNotEmpty) {
      parts.add(unit.postalCode!);
    }
    return parts.isNotEmpty ? parts.join(', ') : 'Dirección no disponible';
  }

  /// Abre Google Maps con la ubicación
  Future<void> _openMaps() async {
    final lat = unit.lat;
    final lng = unit.lng;

    if (lat != null && lng != null) {
      final url = 'https://maps.google.com/?q=$lat,$lng';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      // Si no hay coordenadas, buscar por dirección
      final encodedAddress = Uri.encodeComponent(_fullAddress);
      final url = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Copia un texto al portapapeles
  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si hay instrucciones de bienvenida personalizadas, mostrarlas directamente
    if (unit.welcomeInstructions != null && unit.welcomeInstructions!.isNotEmpty) {
      return _buildWelcomeInstructionsView(context);
    }

    // Si no, mostrar la vista estructurada por secciones
    return _buildStructuredView(context);
  }

  /// Vista con las instrucciones de bienvenida personalizadas
  Widget _buildWelcomeInstructionsView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurfaceColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.getTextPrimaryColor(context),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Instrucciones de Acceso',
          style: TextStyle(
            color: AppColors.getTextPrimaryColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarjeta con el código de acceso destacado
                _buildKeyCodeHighlightCard(context),
                const SizedBox(height: AppTheme.spacing20),

                // Tarjeta WiFi destacada (si hay datos en la base de datos)
                if (unit.wifiNetwork != null && unit.wifiNetwork!.isNotEmpty) ...[
                  _buildWifiHighlightCard(context),
                  const SizedBox(height: AppTheme.spacing20),
                ],

                // Instrucciones completas formateadas (sin sección WiFi)
                _buildFormattedInstructions(context, _removeWifiSection(unit.welcomeInstructions!)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Elimina la sección WiFi del texto de instrucciones
  String _removeWifiSection(String instructions) {
    // Patrón para detectar y eliminar la sección WiFi completa
    final wifiPattern = RegExp(
      r'\"WIFI\"[\s\S]*?(?=OS RECORDAMOS|EL INCUMPLIMIENTO|La hora del Check-out|$)',
      caseSensitive: false,
    );
    return instructions.replaceAll(wifiPattern, '').trim();
  }

  /// Tarjeta destacada con los datos de WiFi
  Widget _buildWifiHighlightCard(BuildContext context) {
    final wifiNetwork = unit.wifiNetwork ?? '';
    final wifiPassword = unit.wifiPassword ?? '';

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.gold, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.wifi_outlined,
                  color: AppColors.black,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  'WiFi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Red WiFi
          Row(
            children: [
              Text(
                'Red:',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getTextSecondaryColor(context),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  wifiNetwork,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _copyToClipboard(context, wifiNetwork, 'Red WiFi'),
                icon: const Icon(Icons.copy, size: 22),
                color: AppColors.gold,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),

          // Contraseña
          Row(
            children: [
              Text(
                'Contraseña:',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getTextSecondaryColor(context),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  wifiPassword,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _copyToClipboard(context, wifiPassword, 'Contraseña WiFi'),
                icon: const Icon(Icons.copy, size: 22),
                color: AppColors.gold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tarjeta destacada con los códigos de acceso
  Widget _buildKeyCodeHighlightCard(BuildContext context) {
    final mainDoorCode = property.mainDoorKeycode;
    final boxCode = booking.keyboxCode;

    // Apartamento Bandera solo tiene código de puerta principal (sin casillero)
    final isApartamentoBandera = unit.name == 'Apartamento Bandera';

    // Si las llaves no están disponibles, mostrar mensaje informativo
    if (!_areKeysAvailable) {
      return _buildKeysNotAvailableCard(context);
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.gold, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.vpn_key_outlined,
                  color: AppColors.black,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  'Tus Códigos de Acceso',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Código puerta principal
          if (mainDoorCode != null && mainDoorCode.isNotEmpty) ...[
            _buildCodeRow(context, 'Puerta Principal', mainDoorCode, Icons.door_front_door_outlined),
            const SizedBox(height: AppTheme.spacing12),
          ],

          // Código del casillero/caja (no mostrar para Apartamento Bandera)
          if (boxCode != null && boxCode.isNotEmpty && !isApartamentoBandera)
            _buildCodeRow(context, 'Casillero de Llaves', boxCode, Icons.lock_open_outlined),
        ],
      ),
    );
  }

  /// Tarjeta informativa cuando las llaves/códigos aún no están disponibles
  Widget _buildKeysNotAvailableCard(BuildContext context) {
    final keysAvailableTime = _keysAvailableTime;
    final formattedDate =
        '${keysAvailableTime.day.toString().padLeft(2, '0')}/${keysAvailableTime.month.toString().padLeft(2, '0')}/${keysAvailableTime.year}';
    final formattedTime =
        '${keysAvailableTime.hour.toString().padLeft(2, '0')}:${keysAvailableTime.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Icono
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_clock_outlined,
              size: 32,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Título
          Text(
            'Códigos de acceso',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing8),

          // Mensaje descriptivo
          Text(
            'Los códigos de acceso y llaves estarán disponibles el día de tu llegada a partir de las $formattedTime h.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextSecondaryColor(context),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Fecha destacada
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 18,
                  color: AppColors.black,
                ),
                const SizedBox(width: 8),
                Text(
                  '$formattedDate a las $formattedTime h',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fila con código de acceso
  Widget _buildCodeRow(BuildContext context, String label, String code, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.goldWithAlpha20,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.gold, size: 20),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.getTextSecondaryColor(context),
                ),
              ),
              Text(
                code,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _copyToClipboard(context, code, label),
          icon: const Icon(Icons.copy, size: 22),
          color: AppColors.gold,
        ),
      ],
    );
  }

  /// Formatea y muestra las instrucciones de bienvenida
  Widget _buildFormattedInstructions(BuildContext context, String instructions) {
    // Dividir las instrucciones en secciones
    final lines = instructions.split('\n');
    final sections = <Widget>[];

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // Detectar títulos (líneas en mayúsculas o entre comillas)
      if (_isTitle(trimmedLine)) {
        sections.add(_buildInstructionTitle(context, _cleanTitle(trimmedLine)));
      } else if (trimmedLine.startsWith('•') || trimmedLine.startsWith('-')) {
        sections.add(_buildBulletPoint(context, trimmedLine.substring(1).trim()));
      } else if (trimmedLine.startsWith('http') || trimmedLine.contains('maps.google')) {
        sections.add(_buildLinkCard(context, trimmedLine));
      } else {
        sections.add(_buildInstructionText(context, trimmedLine));
      }
      sections.add(const SizedBox(height: AppTheme.spacing8));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  /// Detecta si una línea es un título
  bool _isTitle(String line) {
    // Títulos en mayúsculas o entre comillas
    final upperCaseRatio = line.toUpperCase() == line && line.length > 3;
    final isQuoted = line.startsWith('"') && line.endsWith('"');
    return upperCaseRatio || isQuoted;
  }

  /// Limpia el título de comillas
  String _cleanTitle(String title) {
    if (title.startsWith('"') && title.endsWith('"')) {
      return title.substring(1, title.length - 1);
    }
    return title;
  }

  /// Widget para título de sección
  Widget _buildInstructionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacing16, bottom: AppTheme.spacing8),
      child: Row(
        children: [
          Icon(
            _getIconForTitle(title),
            size: 20,
            color: AppColors.gold,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Obtiene el icono según el título
  IconData _getIconForTitle(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('localización') || lowerTitle.contains('direccion')) {
      return Icons.location_on_outlined;
    } else if (lowerTitle.contains('edificio') || lowerTitle.contains('portal')) {
      return Icons.door_front_door_outlined;
    } else if (lowerTitle.contains('apartamento') || lowerTitle.contains('acceso')) {
      return Icons.vpn_key_outlined;
    } else if (lowerTitle.contains('wifi')) {
      return Icons.wifi_outlined;
    } else if (lowerTitle.contains('norma')) {
      return Icons.rule_outlined;
    } else if (lowerTitle.contains('check-out') || lowerTitle.contains('checkout')) {
      return Icons.logout_outlined;
    } else if (lowerTitle.contains('contacto')) {
      return Icons.phone_outlined;
    }
    return Icons.info_outline;
  }

  /// Widget para punto de lista
  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: AppTheme.spacing8, bottom: AppTheme.spacing4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.circle,
            size: 6,
            color: AppColors.gold,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextSecondaryColor(context),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget para texto de instrucción normal
  Widget _buildInstructionText(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.getTextSecondaryColor(context),
          height: 1.5,
        ),
      ),
    );
  }

  /// Widget para tarjeta con enlace
  Widget _buildLinkCard(BuildContext context, String url) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: ElevatedButton.icon(
        onPressed: () => _openMaps(),
        icon: const Icon(Icons.map_outlined, size: 20),
        label: const Text('Abrir en Google Maps'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.black,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  /// Vista estructurada por secciones (cuando no hay welcome_instructions)
  Widget _buildStructuredView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurfaceColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.getTextPrimaryColor(context),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Instrucciones de Acceso',
          style: TextStyle(
            color: AppColors.getTextPrimaryColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Saludo y bienvenida
                _buildWelcomeCard(context),
                const SizedBox(height: AppTheme.spacing20),

                // Localización
                _buildSectionTitle(context, 'Localización', Icons.location_on_outlined),
                const SizedBox(height: AppTheme.spacing12),
                _buildLocationCard(context),
                const SizedBox(height: AppTheme.spacing24),

                // Acceso al edificio
                _buildSectionTitle(context, 'Acceso al Edificio', Icons.door_front_door_outlined),
                const SizedBox(height: AppTheme.spacing12),
                _buildBuildingAccessCard(context),
                const SizedBox(height: AppTheme.spacing24),

                // Acceso al apartamento
                _buildSectionTitle(context, 'Acceso al Apartamento', Icons.vpn_key_outlined),
                const SizedBox(height: AppTheme.spacing12),
                _buildApartmentAccessCard(context),
                const SizedBox(height: AppTheme.spacing24),

                // WiFi
                if (unit.wifiNetwork != null && unit.wifiNetwork!.isNotEmpty) ...[
                  _buildSectionTitle(context, 'WiFi', Icons.wifi_outlined),
                  const SizedBox(height: AppTheme.spacing12),
                  _buildWifiCard(context),
                  const SizedBox(height: AppTheme.spacing24),
                ],

                // Normas
                _buildSectionTitle(context, 'Normas de la Casa', Icons.rule_outlined),
                const SizedBox(height: AppTheme.spacing12),
                _buildRulesCard(context),
                const SizedBox(height: AppTheme.spacing24),

                // Check-out
                _buildSectionTitle(context, 'Check-out', Icons.logout_outlined),
                const SizedBox(height: AppTheme.spacing12),
                _buildCheckoutCard(context),
                const SizedBox(height: AppTheme.spacing24),

                // Contacto
                _buildSectionTitle(context, 'Contacto', Icons.phone_outlined),
                const SizedBox(height: AppTheme.spacing12),
                _buildContactCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final guestName = booking.guestFirstName ?? 'Huésped';
    final unitName = unit.name.isNotEmpty ? unit.name : 'su alojamiento';

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.waving_hand_outlined,
                  color: AppColors.black,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  '¡Hola, $guestName!',
                  style: TextStyle(
                    fontSize: ResponsiveFontSize.titleLarge(context),
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            'Le escribimos para hacerle llegar la información del acceso a $unitName. Guarde esta información para su estancia.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextSecondaryColor(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.gold,
        ),
        const SizedBox(width: AppTheme.spacing8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _fullAddress,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.getTextPrimaryColor(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openMaps,
              icon: const Icon(Icons.map_outlined, size: 20),
              label: const Text('Abrir en Google Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingAccessCard(BuildContext context) {
    final mainDoorCode = property.mainDoorKeycode;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'En la puerta de entrada hay una caja de códigos donde están las llaves de la puerta principal. Cógela y vuelva a dejarla en el mismo casillero una vez abierta.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextSecondaryColor(context),
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          // Solo mostrar el código si está disponible
          if (_areKeysAvailable && mainDoorCode != null && mainDoorCode.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Código:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    mainDoorCode,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                IconButton(
                  onPressed: () => _copyToClipboard(context, mainDoorCode, 'Código de puerta'),
                  icon: const Icon(Icons.copy, size: 22),
                  color: AppColors.getTextSecondaryColor(context),
                ),
              ],
            ),
          ] else if (!_areKeysAvailable)
            Text(
              'El código de acceso estará disponible a partir de las ${_keysAvailableTime.hour.toString().padLeft(2, '0')}:${_keysAvailableTime.minute.toString().padLeft(2, '0')} del día de tu llegada.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.getTextSecondaryColor(context),
              ),
            )
          else
            Text(
              'El código de acceso le será proporcionado por el personal.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.getTextSecondaryColor(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildApartmentAccessCard(BuildContext context) {
    // El código de acceso viene de la reserva, no de la unidad
    final boxCode = booking.keyboxCode;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Una vez dentro verá varios casilleros. Su apartamento corresponde al casillero indicado. Dentro están las llaves de su apartamento.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextSecondaryColor(context),
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          // Solo mostrar el código si está disponible
          if (_areKeysAvailable && boxCode != null && boxCode.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Código del casillero:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    boxCode,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                IconButton(
                  onPressed: () => _copyToClipboard(context, boxCode, 'Código de casillero'),
                  icon: const Icon(Icons.copy, size: 22),
                  color: AppColors.getTextSecondaryColor(context),
                ),
              ],
            ),
          ] else if (!_areKeysAvailable)
            Text(
              'El código del casillero estará disponible a partir de las ${_keysAvailableTime.hour.toString().padLeft(2, '0')}:${_keysAvailableTime.minute.toString().padLeft(2, '0')} del día de tu llegada.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.getTextSecondaryColor(context),
              ),
            )
          else
            Text(
              'El código del casillero le será proporcionado por el personal.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.getTextSecondaryColor(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWifiCard(BuildContext context) {
    final wifiNetwork = unit.wifiNetwork ?? '';
    final wifiPassword = unit.wifiPassword ?? '';

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Red WiFi
          Row(
            children: [
              Text(
                'Red:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.getTextPrimaryColor(context),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  wifiNetwork,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _copyToClipboard(context, wifiNetwork, 'Nombre de red'),
                icon: const Icon(Icons.copy, size: 20),
                color: AppColors.getTextSecondaryColor(context),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          // Contraseña
          Row(
            children: [
              Text(
                'Contraseña:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.getTextPrimaryColor(context),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  wifiPassword,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _copyToClipboard(context, wifiPassword, 'Contraseña WiFi'),
                icon: const Icon(Icons.copy, size: 20),
                color: AppColors.getTextSecondaryColor(context),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRulesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Horarios de Check-in y Check-out
          _buildScheduleRow(
            context,
            'Check-in',
            _checkinTime,
            Icons.login,
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildScheduleRow(
            context,
            'Check-out',
            _checkoutTime,
            Icons.logout,
          ),
          const SizedBox(height: AppTheme.spacing20),
          Divider(color: AppColors.getBorderColor(context)),
          const SizedBox(height: AppTheme.spacing16),

          _buildRuleItem(
            context,
            'Somos alojamiento 100% libre de humos.',
            'Prohibido fumar dentro del apartamento. Esta prohibición incluye cigarrillos electrónicos y vaporizadores. En todo caso será cargado en su cuenta un importe de 50€ para limpiar y desodorizar la habitación.',
            Icons.smoke_free_outlined,
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildRuleItem(
            context,
            'Las celebraciones y ruidos fuertes no están permitidos.',
            'Respete el descanso de los demás huéspedes y vecinos.',
            Icons.volume_off_outlined,
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildRuleItem(
            context,
            'No podrá acceder al recinto nadie que no se haya registrado previamente.',
            'Todos los huéspedes deben estar registrados.',
            Icons.person_add_disabled_outlined,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'El incumplimiento de estas normas podrá impedir su permanencia en nuestras instalaciones.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fila con horario de check-in o check-out
  Widget _buildScheduleRow(BuildContext context, String label, String time, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.black,
            size: 22,
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.getTextPrimaryColor(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRuleItem(BuildContext context, String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.getTextSecondaryColor(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.schedule_outlined,
                  color: AppColors.black,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hora límite de Check-out',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hasta las $_checkoutTime',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            'Las llaves deben dejarlas en la misma caja de códigos de la entrada. Le agradeceríamos que nos haga saber cuando dejen el apartamento.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextSecondaryColor(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Para cualquier consulta o incidencia durante su estancia, puede contactar con nosotros:',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextSecondaryColor(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.business_outlined,
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  'Grupo Hotelero BF',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
