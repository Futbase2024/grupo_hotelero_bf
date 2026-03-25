import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bf_stay/core/di/injection.dart';
import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/core/theme/app_theme.dart';
import 'package:bf_stay/core/theme/responsive.dart';
import 'package:bf_stay/features/auth/domain/bloc/auth_bloc.dart';
import 'package:bf_stay/features/admin/domain/entities/admin_booking_entity.dart';
import 'package:bf_stay/features/admin/domain/repositories/admin_panel_repository.dart';
import 'package:bf_stay/features/guest/alojamientos/domain/entities/unit_entity.dart';
import 'package:bf_stay/features/guest/alojamientos/domain/entities/property_entity.dart';
import 'package:bf_stay/features/guest/alojamientos/domain/repositories/properties_repository.dart';
import 'package:bf_stay/shared/utils/unit_image_helper.dart';
import 'package:bf_stay/features/guest/my_accommodation/presentation/screens/access_instructions_screen.dart';

/// Pantalla de Mi Alojamiento para el huésped
class MyAccommodationScreen extends StatefulWidget {
  const MyAccommodationScreen({super.key});

  @override
  State<MyAccommodationScreen> createState() => _MyAccommodationScreenState();
}

class _MyAccommodationScreenState extends State<MyAccommodationScreen> {
  AdminBookingEntity? _booking;
  UnitEntity? _unit;
  PropertyEntity? _property;
  bool _isLoading = true;
  String? _error;
  /// Lista de todas las unidades de la reserva (para multi-unidad)
  List<UnitEntity> _units = [];

  /// Hora a partir de la cual están disponibles las llaves/códigos por defecto (14:00)
  static const int _defaultKeysAvailableHour = 14;

  /// Verifica si las llaves y códigos están disponibles
  /// Si el admin ha marcado early check-in disponible, usa ese timestamp
  /// Si no, usa la hora por defecto (14:00 del día de check-in)
  bool get _areKeysAvailable {
    if (_booking == null) return false;

    // Si el admin ha marcado que la habitación está disponible antes
    if (_booking!.earlyCheckinAvailableAt != null) {
      return DateTime.now().isAfter(_booking!.earlyCheckinAvailableAt!) ||
          DateTime.now().isAtSameMomentAs(_booking!.earlyCheckinAvailableAt!);
    }

    // Comportamiento por defecto: 14:00 del día de check-in
    final checkInDate = _booking!.checkInDate;
    final keysAvailableTime = DateTime(
      checkInDate.year,
      checkInDate.month,
      checkInDate.day,
      _defaultKeysAvailableHour,
      0,
      0,
    );

    return DateTime.now().isAfter(keysAvailableTime) ||
        DateTime.now().isAtSameMomentAs(keysAvailableTime);
  }

  /// Calcula cuándo estarán disponibles las llaves
  /// Si el admin ha marcado early check-in, devuelve ese timestamp
  /// Si no, devuelve las 14:00 del día de check-in
  DateTime get _keysAvailableTime {
    if (_booking == null) return DateTime.now();

    // Si el admin ha marcado que la habitación está disponible antes
    if (_booking!.earlyCheckinAvailableAt != null) {
      return _booking!.earlyCheckinAvailableAt!;
    }

    // Comportamiento por defecto: 14:00 del día de check-in
    final checkInDate = _booking!.checkInDate;
    return DateTime(
      checkInDate.year,
      checkInDate.month,
      checkInDate.day,
      _defaultKeysAvailableHour,
      0,
      0,
    );
  }

  /// Obtiene la ruta de la imagen local para una unidad
  String? get _localImagePath {
    // Priorizar el nombre del booking (que es lo que funciona en Tu Estancia)
    final unitName = _booking?.unitName ?? _unit?.name;
    debugPrint('🏠 Mi Alojamiento - unitName: "$unitName"');
    debugPrint('🏠 Mi Alojamiento - _booking?.unitName: "${_booking?.unitName}"');
    debugPrint('🏠 Mi Alojamiento - _unit?.name: "${_unit?.name}"');
    final path = UnitImageHelper.getLocalImagePath(unitName);
    debugPrint('🏠 Mi Alojamiento - path: "$path"');
    return path;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final bookingId = user?.bookingId;

    if (bookingId == null) {
      setState(() {
        _error = 'No hay reserva asociada';
        _isLoading = false;
      });
      return;
    }

    try {
      // Cargar la reserva
      final repository = getIt<AdminPanelRepository>();
      final booking = await repository.getBooking(bookingId);

      if (booking == null) {
        setState(() {
          _error = 'Reserva no encontrada';
          _isLoading = false;
        });
        return;
      }

      // Cargar la unidad principal
      final propertiesRepository = getIt<PropertiesRepository>();
      final unit = await propertiesRepository.getUnitById(booking.unitId);

      // Cargar TODAS las unidades de la reserva
      List<UnitEntity> allUnits = [];
      if (booking.hasMultipleUnits && booking.units.isNotEmpty) {
        // Cargar cada unidad desde la BD
        for (final bookingUnit in booking.units) {
          final u = await propertiesRepository.getUnitById(bookingUnit.unitId);
          if (u != null) {
            allUnits.add(u);
          }
        }
      } else if (unit != null) {
        // Reserva de una sola unidad
        allUnits.add(unit);
      }

      // Cargar la propiedad para obtener el keycode de la puerta principal
      PropertyEntity? property;
      if (unit != null) {
        property = await propertiesRepository.getById(unit.propertyId);
      }

      if (mounted) {
        setState(() {
          _booking = booking;
          _unit = unit;
          _units = allUnits;
          _property = property;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar los datos';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Mi Alojamiento',
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
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con nombre de unidad
        _buildHeader(),
        const SizedBox(height: AppTheme.spacing24),

        // Sección de llaves y códigos - condicionada a las 14:00 del día de check-in
        if (_areKeysAvailable) ...[
          // Código de la puerta principal de la propiedad (común para todas las unidades)
          if (_property?.mainDoorKeycode != null &&
              _property!.mainDoorKeycode!.isNotEmpty) ...[
            _buildMainDoorKeycodeCard(),
            const SizedBox(height: AppTheme.spacing16),
          ],

          // Si hay múltiples unidades, mostrar cada una con sus códigos
          if (_booking?.hasMultipleUnits == true && _units.isNotEmpty) ...[
            _buildMultipleUnitsCards(),
          ] else ...[
            // Reserva de una sola unidad - mostrar como antes
            if ((_booking?.keyboxCode != null && _booking!.keyboxCode!.isNotEmpty) ||
                (_unit?.boxCode != null && _unit!.boxCode!.isNotEmpty)) ...[
              _buildBoxCodeCard(),
              const SizedBox(height: AppTheme.spacing16),
            ],
            if (_unit?.boxLocationText != null && _unit!.boxLocationText!.isNotEmpty) ...[
              _buildInfoCard(
                icon: Icons.place_outlined,
                title: 'Ubicación de la caja',
                content: _unit!.boxLocationText!,
              ),
              const SizedBox(height: AppTheme.spacing16),
            ],
          ],

          // Instrucciones de acceso - Botón para ver instrucciones completas
          if (_areKeysAvailable && _booking != null && _unit != null && _property != null) ...[
            _buildAccessInstructionsButton(),
            const SizedBox(height: AppTheme.spacing16),
          ],
        ] else ...[
          // Mensaje informativo cuando las llaves no están disponibles
          _buildKeysNotAvailableCard(),
          const SizedBox(height: AppTheme.spacing16),
        ],

        // Dirección
        _buildAddressCard(),
        const SizedBox(height: AppTheme.spacing16),

        // Normas del alojamiento
        _buildNormasCard(),
      ],
    );
  }

  /// Construye las tarjetas de cada unidad cuando hay múltiples
  Widget _buildMultipleUnitsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de sección
        Text(
          'HABITACIONES (${_units.length})',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextSecondaryColor(context),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),

        // Tarjeta por cada unidad
        ...List.generate(_units.length, (index) {
          final unit = _units[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
            child: _buildUnitCard(unit),
          );
        }),
      ],
    );
  }

  /// Tarjeta individual para cada unidad con sus códigos
  Widget _buildUnitCard(UnitEntity unit) {
    final hasBoxCode = unit.boxCode != null && unit.boxCode!.isNotEmpty;
    final hasBoxLocation = unit.boxLocationText != null && unit.boxLocationText!.isNotEmpty;
    final hasWifi = unit.wifiNetwork != null && unit.wifiNetwork!.isNotEmpty;
    final hasWifiPassword = unit.wifiPassword != null && unit.wifiPassword!.isNotEmpty;
    final hasAccessInstructions = unit.accessInstructions != null && unit.accessInstructions!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la unidad
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  unit.unitType == UnitType.hotelRoom
                      ? Icons.bed_outlined
                      : Icons.home_outlined,
                  color: AppColors.black,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  unit.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
              ),
            ],
          ),

          if (hasBoxCode || hasBoxLocation || hasWifi || hasAccessInstructions)
            const SizedBox(height: AppTheme.spacing12),

          // Box Code
          if (hasBoxCode) ...[
            _buildUnitCodeRow(
              icon: Icons.lock_open_outlined,
              label: 'Key Box Code',
              code: unit.boxCode!,
            ),
          ],

          // Ubicación de la caja
          if (hasBoxLocation) ...[
            if (hasBoxCode) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 18,
                  color: AppColors.getTextSecondaryColor(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    unit.boxLocationText!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getTextSecondaryColor(context),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // WiFi
          if (hasWifi) ...[
            if (hasBoxCode || hasBoxLocation) const SizedBox(height: 8),
            _buildUnitCodeRow(
              icon: Icons.wifi_outlined,
              label: 'WiFi',
              code: unit.wifiNetwork!,
              showCopy: false,
            ),
          ],

          if (hasWifiPassword) ...[
            const SizedBox(height: 8),
            _buildUnitCodeRow(
              icon: Icons.key_outlined,
              label: 'Contraseña WiFi',
              code: unit.wifiPassword!,
            ),
          ],

          // Instrucciones de acceso
          if (hasAccessInstructions) ...[
            if (hasBoxCode || hasBoxLocation || hasWifi) const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      unit.accessInstructions!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.getTextPrimaryColor(context),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Fila de código para una unidad
  Widget _buildUnitCodeRow({
    required IconData icon,
    required String label,
    required String code,
    bool showCopy = true,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.getTextSecondaryColor(context),
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.getTextSecondaryColor(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            code,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimaryColor(context),
            ),
          ),
        ),
        if (showCopy)
          InkWell(
            onTap: () => _copyToClipboard(code, label),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.copy,
                size: 16,
                color: AppColors.gold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    final imagePath = _localImagePath;
    debugPrint('🏠 _buildHeader - imagePath: "$imagePath"');

    // Construir el título según si hay múltiples unidades
    String titleText;
    if (_booking?.hasMultipleUnits == true && _booking!.units.isNotEmpty) {
      // Mostrar nombres de todas las unidades
      titleText = _booking!.units.map((u) => u.name).join(' · ');
    } else {
      titleText = _unit?.name ?? _booking?.unitName ?? 'Mi Alojamiento';
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.gold, width: 2),
      ),
      child: Row(
        children: [
          // Foto del alojamiento o icono como fallback
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imagePath != null
                ? Image.asset(
                    imagePath,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('❌ Error cargando imagen: $error');
                      return Container(
                        width: 52,
                        height: 52,
                        color: AppColors.gold,
                        child: const Icon(
                          Icons.home_outlined,
                          color: AppColors.black,
                          size: 28,
                        ),
                      );
                    },
                  )
                : Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.home_outlined,
                      color: AppColors.black,
                      size: 28,
                    ),
                  ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titleText,
                        style: TextStyle(
                          fontSize: ResponsiveFontSize.titleLarge(context),
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimaryColor(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Badge con número de unidades si hay múltiples
                    if (_booking?.hasMultipleUnits == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '×${_booking!.totalUnits}',
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
                const SizedBox(height: 4),
                Text(
                  _booking?.propertyName ?? 'BF Stay',
                  style: TextStyle(
                    fontSize: ResponsiveFontSize.bodyMedium(context),
                    color: AppColors.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta informativa cuando las llaves/códigos aún no están disponibles
  Widget _buildKeysNotAvailableCard() {
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

  /// Tarjeta para el código de la puerta principal del edificio
  Widget _buildMainDoorKeycodeCard() {
    final keycode = _property?.mainDoorKeycode;
    if (keycode == null || keycode.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Icono flex 1
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.door_front_door_outlined,
                color: AppColors.black,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Texto flex 5
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Puerta Principal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
                Text(
                  'Código del portal',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          // Código flex 3
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                keycode,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Icono copiar flex 1
          Expanded(
            flex: 1,
            child: IconButton(
              onPressed: () => _copyToClipboard(keycode, 'Código de puerta'),
              icon: const Icon(Icons.copy, size: 20),
              color: AppColors.getTextSecondaryColor(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
        ],
      ),
    );
  }

  /// Copia un texto al portapapeles y muestra confirmación
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado al portapapeles'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildBoxCodeCard() {
    // Priorizar el código específico de la reserva (keyboxCode) sobre el código genérico de la unidad
    final boxCode = _booking?.keyboxCode ?? _unit?.boxCode ?? '';
    if (boxCode.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Icono flex 1
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.lock_open_outlined,
                color: AppColors.black,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Texto flex 5
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Box Code',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
                Text(
                  'Código de la caja de llaves',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          // Código flex 3
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                boxCode,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Icono copiar flex 1
          Expanded(
            flex: 1,
            child: IconButton(
              onPressed: () => _copyToClipboard(boxCode, 'Key Box Code'),
              icon: const Icon(Icons.copy, size: 20),
              color: AppColors.getTextSecondaryColor(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
        ],
      ),
    );
  }

  /// Botón para ver las instrucciones de acceso completas
  Widget _buildAccessInstructionsButton() {
    return GestureDetector(
      onTap: () {
        if (_booking != null && _unit != null && _property != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AccessInstructionsScreen(
                booking: _booking!,
                unit: _unit!,
                property: _property!,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppColors.gold, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.info_outline,
                color: AppColors.black,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instrucciones de Acceso',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toca para ver toda la información de acceso',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.gold,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.black,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.getTextSecondaryColor(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    final addressParts = <String>[];
    if (_unit?.addressLine1 != null && _unit!.addressLine1!.isNotEmpty) {
      addressParts.add(_unit!.addressLine1!);
    }
    if (_unit?.addressLine2 != null && _unit!.addressLine2!.isNotEmpty) {
      addressParts.add(_unit!.addressLine2!);
    }
    if (_unit?.neighborhood != null && _unit!.neighborhood!.isNotEmpty) {
      addressParts.add(_unit!.neighborhood!);
    }
    if (_unit?.city != null && _unit!.city!.isNotEmpty) {
      addressParts.add(_unit!.city!);
    }
    if (_unit?.province != null && _unit!.province!.isNotEmpty) {
      addressParts.add(_unit!.province!);
    }
    if (_unit?.postalCode != null && _unit!.postalCode!.isNotEmpty) {
      addressParts.add(_unit!.postalCode!);
    }

    final hasAddress = addressParts.isNotEmpty;
    final fullAddress = hasAddress ? addressParts.join(', ') : null;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.black,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Text(
                'Dirección',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          if (hasAddress) ...[
            Text(
              fullAddress!,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.getTextSecondaryColor(context),
                height: 1.5,
              ),
            ),
            // TODO: Añadir botón para abrir en mapa cuando haya coordenadas
          ] else
            Text(
              'Dirección no disponible',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.getTextSecondaryColor(context),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  /// Devuelve el nombre del archivo PDF según el tipo de unidad
  String _getNormasFileName() {
    final unitType = _unit?.unitType;
    debugPrint('📋 UnitType detectado: $unitType');
    if (unitType == UnitType.hotelRoom) {
      debugPrint('📋 Seleccionando: Normas_hotel.pdf');
      return 'Normas_hotel.pdf';
    }
    // Para apartamentos y habitaciones de apartamentos
    debugPrint('📋 Seleccionando: Normas_apartamentos.pdf');
    return 'Normas_apartamentos.pdf';
  }

  /// Abre el PDF de normas desde Supabase Storage
  Future<void> _openNormasPdf() async {
    debugPrint('🔍 Iniciando _openNormasPdf...');

    if (_unit == null) {
      debugPrint('❌ Error: _unit es null');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay información del alojamiento'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      final fileName = _getNormasFileName();
      final filePath = 'Normas/$fileName';
      debugPrint('📁 Ruta completa del archivo: $filePath');

      // ✅ OPTIMIZACIÓN: Usar URL pública (el bucket unit-photos es público)
      // Las URLs públicas nunca caducan
      debugPrint('🔗 Obteniendo URL pública del bucket: unit-photos');
      final publicUrl = Supabase.instance.client.storage
          .from('unit-photos')
          .getPublicUrl(filePath);

      debugPrint('✅ URL pública obtenida: ${publicUrl.substring(0, 50)}...');

      final uri = Uri.parse(publicUrl);
      debugPrint('🌐 Intentando abrir URL...');

      if (await canLaunchUrl(uri)) {
        debugPrint('✅ URL puede ser lanzada, abriendo...');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('✅ URL lanzada correctamente');
      } else {
        debugPrint('❌ No se puede lanzar la URL');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el documento'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } on StorageException catch (e) {
      debugPrint('❌ StorageException: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo no encontrado: ${e.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error general: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar las normas: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildNormasCard() {
    final unitType = _unit?.unitType;
    final normasTitle = unitType == UnitType.hotelRoom
        ? 'Normas del Hotel'
        : 'Normas del Apartamento';

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.black,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  normasTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            'Consulta las normas y recomendaciones para tu estancia.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.getTextSecondaryColor(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openNormasPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
              label: const Text('Ver Normas (PDF)'),
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              _error ?? 'Ha ocurrido un error',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.getTextPrimaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.black,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
