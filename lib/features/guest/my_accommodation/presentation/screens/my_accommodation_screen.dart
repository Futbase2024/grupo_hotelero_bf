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

      // Cargar la unidad
      final propertiesRepository = getIt<PropertiesRepository>();
      final unit = await propertiesRepository.getUnitById(booking.unitId);

      // Cargar la propiedad para obtener el keycode de la puerta principal
      PropertyEntity? property;
      if (unit != null) {
        property = await propertiesRepository.getById(unit.propertyId);
      }

      if (mounted) {
        setState(() {
          _booking = booking;
          _unit = unit;
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

        // Código de la puerta principal de la propiedad
        if (_property?.mainDoorKeycode != null &&
            _property!.mainDoorKeycode!.isNotEmpty) ...[
          _buildMainDoorKeycodeCard(),
          const SizedBox(height: AppTheme.spacing16),
        ],

        // Box Code - mostrar si hay código de la reserva o de la unidad
        if ((_booking?.keyboxCode != null && _booking!.keyboxCode!.isNotEmpty) ||
            (_unit?.boxCode != null && _unit!.boxCode!.isNotEmpty)) ...[
          _buildBoxCodeCard(),
          const SizedBox(height: AppTheme.spacing16),
        ],

        // Ubicación de la caja
        if (_unit?.boxLocationText != null && _unit!.boxLocationText!.isNotEmpty) ...[
          _buildInfoCard(
            icon: Icons.place_outlined,
            title: 'Ubicación de la caja',
            content: _unit!.boxLocationText!,
          ),
          const SizedBox(height: AppTheme.spacing16),
        ],

        // Instrucciones de acceso
        if (_unit?.accessInstructions != null && _unit!.accessInstructions!.isNotEmpty) ...[
          _buildInfoCard(
            icon: Icons.info_outline,
            title: 'Instrucciones de acceso',
            content: _unit!.accessInstructions!,
          ),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.gold, width: 2),
      ),
      child: Row(
        children: [
          Container(
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
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _unit?.name ?? _booking?.unitName ?? 'Mi Alojamiento',
                  style: TextStyle(
                    fontSize: ResponsiveFontSize.titleLarge(context),
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
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
          Container(
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
          const SizedBox(width: 12),
          Expanded(
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
          // Código compacto
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          IconButton(
            onPressed: () => _copyToClipboard(keycode, 'Código de puerta'),
            icon: const Icon(Icons.copy, size: 20),
            color: AppColors.getTextSecondaryColor(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
          Container(
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
          const SizedBox(width: 12),
          Expanded(
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
          // Código compacto
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          IconButton(
            onPressed: () => _copyToClipboard(boxCode, 'Key Box Code'),
            icon: const Icon(Icons.copy, size: 20),
            color: AppColors.getTextSecondaryColor(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
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

      // Obtener URL firmada del archivo en Supabase Storage
      debugPrint('🔗 Obteniendo URL firmada del bucket: unit-photos');
      final signedUrl = await Supabase.instance.client.storage
          .from('unit-photos')
          .createSignedUrl(filePath, 3600); // URL válida por 1 hora

      debugPrint('✅ URL firmada obtenida: ${signedUrl.substring(0, 50)}...');

      final uri = Uri.parse(signedUrl);
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
