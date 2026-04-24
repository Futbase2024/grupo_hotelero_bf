import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bf_stay/l10n/app_localizations.dart';
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

/// Pantalla de Mi Alojamiento para el huesped
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
  /// Hora actual del servidor (para evitar manipulacion del reloj del dispositivo)
  DateTime? _serverTime;

  /// Hora a partir de la cual estan disponibles las llaves/codigos por defecto (14:00)
  static const int _defaultKeysAvailableHour = 14;

  /// Verifica si las llaves y codigos estan disponibles
  /// Por defecto: 14:00 del dia de check-in
  /// Early check-in: Solo tiene efecto si el admin lo marca el MISMO DIA de check-in
  /// IMPORTANTE: Usa la hora del servidor para evitar manipulacion del reloj del dispositivo
  bool get _areKeysAvailable {
    if (_booking == null) return false;

    // Usar hora del servidor si esta disponible, si no, usar hora local como fallback
    final now = _serverTime ?? DateTime.now();
    final checkInDate = _booking!.checkInDate;

    // Si el admin ha marcado early check-in, verificar que sea del MISMO DIA de check-in
    if (_booking!.earlyCheckinAvailableAt != null) {
      final earlyTime = _booking!.earlyCheckinAvailableAt!;

      // Verificar que el early check-in fue marcado el mismo dia de la reserva
      final isSameDay = earlyTime.year == checkInDate.year &&
          earlyTime.month == checkInDate.month &&
          earlyTime.day == checkInDate.day;

      // Solo tiene efecto si es el mismo dia Y ya paso la hora marcada
      if (isSameDay) {
        return now.isAfter(earlyTime) || now.isAtSameMomentAs(earlyTime);
      }
      // Si NO es el mismo dia, ignorar y usar comportamiento por defecto
    }

    // Comportamiento por defecto: 14:00 del dia de check-in
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

  /// Calcula cuando estaran disponibles las llaves
  /// Por defecto: 14:00 del dia de check-in
  /// Early check-in: Solo tiene efecto si el admin lo marca el MISMO DIA de check-in
  /// NOTA: El calculo de disponibilidad real usa _areKeysAvailable con hora del servidor
  DateTime get _keysAvailableTime {
    if (_booking == null) return DateTime.now();

    final checkInDate = _booking!.checkInDate;

    // Si el admin ha marcado early check-in, verificar que sea del MISMO DIA de check-in
    if (_booking!.earlyCheckinAvailableAt != null) {
      final earlyTime = _booking!.earlyCheckinAvailableAt!;

      // Verificar que el early check-in fue marcado el mismo dia de la reserva
      final isSameDay = earlyTime.year == checkInDate.year &&
          earlyTime.month == checkInDate.month &&
          earlyTime.day == checkInDate.day;

      // Solo tiene efecto si es el mismo dia
      if (isSameDay) {
        return earlyTime;
      }
      // Si NO es el mismo dia, ignorar y usar comportamiento por defecto
    }

    // Comportamiento por defecto: 14:00 del dia de check-in
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
    debugPrint('Mi Alojamiento - unitName: "$unitName"');
    debugPrint('Mi Alojamiento - _booking?.unitName: "${_booking?.unitName}"');
    debugPrint('Mi Alojamiento - _unit?.name: "${_unit?.name}"');
    final path = UnitImageHelper.getLocalImagePath(unitName);
    debugPrint('Mi Alojamiento - path: "$path"');
    return path;
  }

  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataLoaded) {
      _dataLoaded = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final s = S.of(context);
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final bookingId = user?.bookingId;

    if (bookingId == null) {
      setState(() {
        _error = s.guest_accommodation_no_booking;
        _isLoading = false;
      });
      return;
    }

    try {
      // Cargar la reserva y la hora del servidor en paralelo
      final repository = getIt<AdminPanelRepository>();
      final results = await Future.wait([
        repository.getBooking(bookingId),
        repository.getServerTime(),
      ]);

      final booking = results[0] as AdminBookingEntity?;
      final serverTime = results[1] as DateTime;

      if (booking == null) {
        if (!mounted) return;
        setState(() {
          _error = s.guest_accommodation_booking_not_found;
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
          _serverTime = serverTime;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = s.guest_accommodation_error_loading;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
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
          s.guest_accommodation_title,
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

        // Seccion de llaves y codigos - condicionada a las 14:00 del dia de check-in
        if (_areKeysAvailable) ...[
          // Codigo de la puerta principal de la propiedad (comun para todas las unidades)
          if (_property?.mainDoorKeycode != null &&
              _property!.mainDoorKeycode!.isNotEmpty) ...[
            _buildMainDoorKeycodeCard(),
            const SizedBox(height: AppTheme.spacing16),
          ],

          // Si hay multiples unidades, mostrar cada una con sus codigos
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
                title: S.of(context).guest_accommodation_box_location,
                content: _unit!.boxLocationText!,
              ),
              const SizedBox(height: AppTheme.spacing16),
            ],
          ],

          // Instrucciones de acceso - Boton para ver instrucciones completas
          if (_areKeysAvailable && _booking != null && _unit != null && _property != null) ...[
            _buildAccessInstructionsButton(),
            const SizedBox(height: AppTheme.spacing16),
          ],
        ] else ...[
          // Mensaje informativo cuando las llaves no estan disponibles
          _buildKeysNotAvailableCard(),
          const SizedBox(height: AppTheme.spacing16),
        ],

        // Direccion
        _buildAddressCard(),
        const SizedBox(height: AppTheme.spacing16),

        // Normas del alojamiento
        _buildNormasCard(),
      ],
    );
  }

  /// Construye las tarjetas de cada unidad cuando hay multiples
  Widget _buildMultipleUnitsCards() {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titulo de seccion
        Text(
          s.guest_accommodation_rooms_count(_units.length),
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

  /// Tarjeta individual para cada unidad con sus codigos
  Widget _buildUnitCard(UnitEntity unit) {
    final s = S.of(context);
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
              label: s.guest_accommodation_key_box_code,
              code: unit.boxCode!,
            ),
          ],

          // Ubicacion de la caja
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
              label: s.guest_accommodation_wifi_password,
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

  /// Fila de codigo para una unidad
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
    final s = S.of(context);
    final imagePath = _localImagePath;
    debugPrint('_buildHeader - imagePath: "$imagePath"');

    // Construir el titulo segun si hay multiples unidades
    String titleText;
    if (_booking?.hasMultipleUnits == true && _booking!.units.isNotEmpty) {
      // Mostrar nombres de todas las unidades
      titleText = _booking!.units.map((u) => u.name).join(' · ');
    } else {
      titleText = _unit?.name ?? _booking?.unitName ?? s.guest_accommodation_title;
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
                      debugPrint('Error cargando imagen: $error');
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
                    // Badge con numero de unidades si hay multiples
                    if (_booking?.hasMultipleUnits == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'x${_booking!.totalUnits}',
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

  /// Tarjeta informativa cuando las llaves/codigos aun no estan disponibles
  Widget _buildKeysNotAvailableCard() {
    final s = S.of(context);
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

          // Titulo
          Text(
            s.guest_accommodation_access_codes,
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
            s.guest_accommodation_codes_available_message(formattedTime),
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
                Flexible(
                  child: Text(
                    s.guest_accommodation_codes_available_datetime(formattedDate, formattedTime),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
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

  /// Tarjeta para el codigo de la puerta principal del edificio
  Widget _buildMainDoorKeycodeCard() {
    final s = S.of(context);
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
                  s.guest_accommodation_main_door,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
                Text(
                  s.guest_accommodation_portal_code,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          // Codigo flex 3
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
              onPressed: () => _copyToClipboard(keycode, s.guest_accommodation_door_code),
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

  /// Copia un texto al portapapeles y muestra confirmacion
  void _copyToClipboard(String text, String label) {
    final s = S.of(context);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.common_copied_to_clipboard(label)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildBoxCodeCard() {
    final s = S.of(context);
    // Priorizar el codigo especifico de la reserva (keyboxCode) sobre el codigo generico de la unidad
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
                  s.guest_accommodation_key_box_code,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
                Text(
                  s.guest_accommodation_keybox_description,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          // Codigo flex 3
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
              onPressed: () => _copyToClipboard(boxCode, s.guest_accommodation_key_box_code),
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

  /// Boton para ver las instrucciones de acceso completas
  Widget _buildAccessInstructionsButton() {
    final s = S.of(context);
    return GestureDetector(
      onTap: () {
        if (_booking != null && _unit != null && _property != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AccessInstructionsScreen(
                booking: _booking!,
                unit: _unit!,
                property: _property!,
                serverTime: _serverTime,
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
                    s.guest_accommodation_access_instructions,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.guest_accommodation_tap_for_access_info,
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
    final s = S.of(context);
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
                s.guest_accommodation_address,
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
            if (_unit?.lat != null && _unit?.lng != null) ...[
              const SizedBox(height: AppTheme.spacing12),
              OutlinedButton.icon(
                onPressed: () {
                  final lat = _unit!.lat;
                  final lng = _unit!.lng;
                  final uri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Abrir en Maps'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  side: const BorderSide(color: AppColors.gold),
                ),
              ),
            ],
          ] else
            Text(
              s.guest_accommodation_address_unavailable,
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

  /// Devuelve el nombre del archivo PDF segun el tipo de unidad
  String _getNormasFileName() {
    final unitType = _unit?.unitType;
    debugPrint('UnitType detectado: $unitType');
    if (unitType == UnitType.hotelRoom) {
      debugPrint('Seleccionando: Normas_hotel.pdf');
      return 'Normas_hotel.pdf';
    }
    // Para apartamentos y habitaciones de apartamentos
    debugPrint('Seleccionando: Normas_apartamentos.pdf');
    return 'Normas_apartamentos.pdf';
  }

  /// Abre el PDF de normas desde Supabase Storage
  Future<void> _openNormasPdf() async {
    final s = S.of(context);
    debugPrint('Iniciando _openNormasPdf...');

    if (_unit == null) {
      debugPrint('Error: _unit es null');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.guest_accommodation_no_unit_info),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      final fileName = _getNormasFileName();
      final filePath = 'Normas/$fileName';
      debugPrint('Ruta completa del archivo: $filePath');

      // OPTIMIZACION: Usar URL publica (el bucket unit-photos es publico)
      // Las URLs publicas nunca caducan
      debugPrint('Obteniendo URL publica del bucket: unit-photos');
      final publicUrl = Supabase.instance.client.storage
          .from('unit-photos')
          .getPublicUrl(filePath);

      debugPrint('URL publica obtenida: ${publicUrl.substring(0, 50)}...');

      final uri = Uri.parse(publicUrl);
      debugPrint('Intentando abrir URL...');

      if (await canLaunchUrl(uri)) {
        debugPrint('URL puede ser lanzada, abriendo...');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('URL lanzada correctamente');
      } else {
        debugPrint('No se puede lanzar la URL');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.guest_accommodation_cannot_open_document),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } on StorageException catch (e) {
      debugPrint('StorageException: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.guest_accommodation_file_not_found(e.message)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error general: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.guest_accommodation_rules_load_error('$e')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildNormasCard() {
    final s = S.of(context);
    final unitType = _unit?.unitType;
    final normasTitle = unitType == UnitType.hotelRoom
        ? s.guest_accommodation_hotel_rules
        : s.guest_accommodation_apartment_rules;

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
            s.guest_accommodation_rules_description,
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
              label: Text(s.guest_accommodation_view_rules_pdf),
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
    final s = S.of(context);
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
              _error ?? s.guest_accommodation_error_occurred,
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
              child: Text(s.common_retry),
            ),
          ],
        ),
      ),
    );
  }
}
