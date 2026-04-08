import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bf_stay/l10n/app_localizations.dart';
import 'package:bf_stay/core/di/injection.dart';
import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/features/admin/domain/repositories/admin_panel_repository.dart';
import 'package:bf_stay/features/guest/alojamientos/domain/entities/unit_entity.dart';
import 'package:bf_stay/features/guest/alojamientos/domain/repositories/properties_repository.dart';

/// Pantalla que muestra las normas del alojamiento como imagen
class NormasScreen extends StatefulWidget {
  const NormasScreen({
    super.key,
    required this.bookingId,
  });

  final String bookingId;

  @override
  State<NormasScreen> createState() => _NormasScreenState();
}

class _NormasScreenState extends State<NormasScreen> {
  UnitType? _unitType;
  bool _isLoading = true;
  String? _error;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    debugPrint('📋 [NormasScreen] Iniciando carga de datos...');
    debugPrint('📋 [NormasScreen] BookingId: ${widget.bookingId}');

    try {
      // 1. Obtener la reserva
      debugPrint('📋 [NormasScreen] Obteniendo reserva...');
      final booking = await getIt<AdminPanelRepository>().getBooking(widget.bookingId);
      if (booking == null) {
        debugPrint('❌ [NormasScreen] Reserva no encontrada');
        setState(() {
          _error = 'Reserva no encontrada';
          _isLoading = false;
        });
        return;
      }
      debugPrint('✅ [NormasScreen] Reserva encontrada: ${booking.bookingCode}');
      debugPrint('📋 [NormasScreen] UnitId: ${booking.unitId}');

      // 2. Obtener la unidad para saber el tipo
      debugPrint('📋 [NormasScreen] Obteniendo unidad...');
      final unit = await getIt<PropertiesRepository>().getUnitById(booking.unitId);
      if (unit == null) {
        debugPrint('❌ [NormasScreen] Unidad no encontrada');
        setState(() {
          _error = 'Unidad no encontrada';
          _isLoading = false;
        });
        return;
      }
      debugPrint('✅ [NormasScreen] Unidad encontrada: ${unit.name}');
      debugPrint('📋 [NormasScreen] UnitType: ${unit.unitType}');

      // 3. Determinar el archivo según el tipo
      // NOTA: El archivo se llama "Normas_apartamento.png" (singular), no "apartamentos"
      final fileName = unit.unitType == UnitType.hotelRoom
          ? 'Normas_hotel.png'
          : 'Normas_apartamento.png';
      final filePath = 'Normas/$fileName';
      debugPrint('📋 [NormasScreen] Archivo a cargar: $filePath');

      // 4. Construir URL pública (el bucket unit-photos es público)
      final publicUrl = Supabase.instance.client.storage
          .from('unit-photos')
          .getPublicUrl(filePath);
      debugPrint('✅ [NormasScreen] URL pública: $publicUrl');

      if (mounted) {
        setState(() {
          _unitType = unit.unitType;
          _imageUrl = publicUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [NormasScreen] Error general: $e');
      if (mounted) {
        setState(() {
          _error = 'Error al cargar las normas: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    final title = _unitType == UnitType.hotelRoom
        ? S.of(context).guest_normas_hotel_title
        : S.of(context).guest_normas_apartment_title;

    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      appBar: AppBar(
        title: Text(
          _isLoading ? S.of(context).guest_normas_title : title,
          style: TextStyle(
            color: isDark ? AppColors.gold : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.black : AppColors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? AppColors.gold : AppColors.textPrimary,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/guest');
            }
          },
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    if (_imageUrl == null) {
      return Center(
        child: Text(S.of(context).guest_normas_not_available),
      );
    }

    return _buildImage();
  }

  Widget _buildImage() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      child: Center(
        child: CachedNetworkImage(
          imageUrl: _imageUrl!,
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
          errorWidget: (context, url, error) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  S.of(context).guest_normas_image_error,
                  style: TextStyle(
                    color: AppColors.getTextSecondaryColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondaryColor(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              S.of(context).guest_alojamientos_error_title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? S.of(context).guest_normas_generic_error,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadData();
              },
              icon: const Icon(Icons.refresh),
              label: Text(S.of(context).common_retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.textOnGold,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
