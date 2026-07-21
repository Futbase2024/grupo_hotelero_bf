import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bf_stay/core/di/injection.dart';
import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/core/theme/app_theme.dart';
import 'package:bf_stay/features/auth/domain/bloc/auth_bloc.dart';
import 'package:bf_stay/features/admin/domain/repositories/admin_panel_repository.dart';
import 'package:bf_stay/features/guest/alojamientos/domain/entities/unit_entity.dart';
import 'package:bf_stay/l10n/app_localizations.dart';

/// Pantalla de Información para el huésped
class StayGuideScreen extends StatefulWidget {
  const StayGuideScreen({super.key});

  @override
  State<StayGuideScreen> createState() => _StayGuideScreenState();
}

class _StayGuideScreenState extends State<StayGuideScreen> {
  Map<String, dynamic>? _bookingData;
  bool _isLoading = true;

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
        _isLoading = false;
      });
      return;
    }

    try {
      final repository = getIt<AdminPanelRepository>();
      final booking = await repository.getBooking(bookingId);

      if (mounted) {
        setState(() {
          _bookingData = {
            'unitName': booking?.unitName ?? '',
            'propertyName': booking?.propertyName ?? '',
            'checkIn': booking?.checkInDate,
            'checkOut': booking?.checkOutDate,
            'guests': booking?.numGuests ?? 1,
            'unitType': booking?.unitType,
            'wifiNetwork': booking?.wifiNetwork,
            'wifiPassword': booking?.wifiPassword,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      body: CustomScrollView(
        slivers: [
          // Header con imagen de fondo
          SliverToBoxAdapter(
            child: _buildHeroHeader(context),
          ),
          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección de Contacto
                  _buildContactSection(context),
                  const SizedBox(height: AppTheme.spacing20),

                  // Sección Tus datos
                  _buildGuestDataSection(context),
                  const SizedBox(height: AppTheme.spacing20),

                  // Sección de Servicios
                  _buildServicesSection(context),
                  const SizedBox(height: AppTheme.spacing20),

                  // Sección de Normas
                  _buildRulesSection(context),
                  const SizedBox(height: AppTheme.spacing24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Stack(
      children: [
        // Imagen de fondo
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.gold,
            image: const DecorationImage(
              image: AssetImage('assets/images/info.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.blackWithAlpha50,
                  AppColors.blackWithAlpha80,
                ],
              ),
            ),
          ),
        ),
        // Botón de volver
        Positioned(
          top: MediaQuery.of(context).padding.top + AppTheme.spacing8,
          left: AppTheme.spacing8,
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.blackWithAlpha50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.white,
                size: 20,
              ),
            ),
            onPressed: () => context.go('/guest'),
          ),
        ),
        // Título y subtítulo
        Positioned(
          bottom: AppTheme.spacing24,
          left: AppTheme.spacing20,
          right: AppTheme.spacing20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).guest_guide_title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                  shadows: [
                    Shadow(
                      color: AppColors.blackWithAlpha50,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                S.of(context).guest_guide_subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.whiteWithAlpha90,
                  shadows: [
                    Shadow(
                      color: AppColors.blackWithAlpha50,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return _InfoSection(
      title: S.of(context).guest_guide_contact,
      icon: Icons.phone_outlined,
      children: [
        _ContactItem(
          icon: Icons.phone_outlined,
          label: S.of(context).guest_guide_phone_1,
          value: '+34 656 61 80 65',
          onTap: () => _makePhoneCall('+34656618065'),
        ),
        _ContactItem(
          icon: Icons.phone_outlined,
          label: S.of(context).guest_guide_phone_2,
          value: '+34 674 27 70 16',
          onTap: () => _makePhoneCall('+34674277016'),
        ),
        _ContactItem(
          icon: Icons.email_outlined,
          label: S.of(context).common_email_type,
          value: 'Info@boutiquejerez.es',
          onTap: () => _sendEmail('Info@boutiquejerez.es'),
        ),
      ],
    );
  }

  Widget _buildGuestDataSection(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    final checkIn = _bookingData?['checkIn'] as DateTime?;
    final checkOut = _bookingData?['checkOut'] as DateTime?;
    final checkInStr = checkIn != null ? '${checkIn.day}/${checkIn.month}/${checkIn.year}' : '-';
    final checkOutStr = checkOut != null ? '${checkOut.day}/${checkOut.month}/${checkOut.year}' : '-';

    return _InfoSection(
      title: S.of(context).guest_guide_your_data,
      icon: Icons.person_outline,
      children: [
        _DataRow(label: S.of(context).guest_guide_accommodation, value: _bookingData?['unitName'] ?? '-'),
        _DataRow(label: S.of(context).guest_guide_property, value: _bookingData?['propertyName'] ?? '-'),
        _DataRow(label: S.of(context).guest_guide_checkin, value: checkInStr),
        _DataRow(label: S.of(context).guest_guide_checkout, value: checkOutStr),
        _DataRow(label: S.of(context).guest_guide_guests, value: '${_bookingData?['guests'] ?? 1}'),
      ],
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    // Verificar si the unit has jacuzzi by checking the name
    final unitName = _bookingData?['unitName'] as String? ?? '';
    final hasJacuzzi = unitName.toUpperCase().contains('JACUZZI');

    // Verificar si es hotel (las habitaciones del hotel no tienen lavadero)
    final unitType = _bookingData?['unitType'] as UnitType?;
    final isHotel = unitType == UnitType.hotelRoom;

    return _InfoSection(
      title: S.of(context).guest_guide_services,
      icon: Icons.room_service_outlined,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ServiceIcon(
                  icon: Icons.wifi_outlined,
                  label: S.of(context).guest_guide_wifi,
                  onTap: () => _showWifiInfo(context),
                ),
              ),
              // Solo mostrar lavadero si NO es hotel (apartamentos tienen lavadero)
              if (!isHotel) ...[
                Expanded(
                  child: _ServiceIcon(
                    icon: Icons.local_laundry_service_outlined,
                    label: S.of(context).guest_guide_laundry,
                    onTap: () => _showServiceInfo(
                      context: context,
                      title: S.of(context).guest_guide_laundry,
                      icon: Icons.local_laundry_service_outlined,
                      description: S.of(context).guest_guide_laundry_desc,
                    ),
                  ),
                ),
              ],
              // Solo mostrar Jacuzzi si the unit has it
              if (hasJacuzzi) ...[
                Expanded(
                  child: _ServiceIcon(
                    icon: Icons.hot_tub_outlined,
                    label: S.of(context).guest_guide_jacuzzi,
                    onTap: () => context.go('/guest/jacuzzi-rules'),
                  ),
                ),
              ],
              Expanded(
                child: _ServiceIcon(
                  icon: Icons.ac_unit_outlined,
                  label: S.of(context).guest_guide_ac,
                  onTap: () => _showServiceInfo(
                    context: context,
                    title: S.of(context).guest_guide_ac_title,
                    icon: Icons.ac_unit_outlined,
                    description: S.of(context).guest_guide_ac_desc,
                  ),
                ),
              ),
              Expanded(
                child: _ServiceIcon(
                  icon: Icons.tv_outlined,
                  label: S.of(context).guest_guide_tv,
                  onTap: () => _showServiceInfo(
                    context: context,
                    title: S.of(context).guest_guide_tv_title,
                    icon: Icons.tv_outlined,
                    description: S.of(context).guest_guide_tv_desc,
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  void _showServiceInfo({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String description,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLarge),
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.getBorderColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.goldWithAlpha10,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.gold, size: 32),
            ),
            const SizedBox(height: AppTheme.spacing16),
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            // Description
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextSecondaryColor(context),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing24),
            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  S.of(context).common_close,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modal específico para WiFi con botones de copiar
  void _showWifiInfo(BuildContext context) {
    final wifiNetwork = _bookingData?['wifiNetwork'] as String? ?? S.of(context).guest_guide_not_available;
    final wifiPassword = _bookingData?['wifiPassword'] as String? ?? S.of(context).guest_guide_not_available;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusLarge),
            ),
          ),
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.getBorderColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppTheme.spacing20),

              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.goldWithAlpha10,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_outlined, color: AppColors.gold, size: 32),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Title
              Text(
                S.of(context).guest_guide_wifi,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimaryColor(context),
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),

              // Subtitle
              Text(
                S.of(context).guest_guide_wifi_desc,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.getTextSecondaryColor(context),
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),

              // Network card
              _wifiCredentialCard(
                icon: Icons.wifi,
                label: S.of(context).guest_access_wifi_network,
                value: wifiNetwork,
                onCopy: () => _copyToClipboard(sheetContext, wifiNetwork, S.of(context).guest_access_wifi_title),
              ),
              const SizedBox(height: AppTheme.spacing12),

              // Password card
              _wifiCredentialCard(
                icon: Icons.lock_outline,
                label: S.of(context).guest_access_wifi_password,
                value: wifiPassword,
                onCopy: () => _copyToClipboard(sheetContext, wifiPassword, S.of(context).guest_access_wifi_password),
              ),
              const SizedBox(height: AppTheme.spacing24),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    S.of(context).common_close,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.of(context).common_copied_to_clipboard(label)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Widget para tarjetas de credenciales WiFi con botón de copiar
  Widget _wifiCredentialCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.goldWithAlpha10,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.goldWithAlpha30),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.black, size: 20),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          // Copy button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.copy, color: AppColors.black, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesSection(BuildContext context) {
    // Determinar el check-out según el tipo de unidad
    final unitType = _bookingData?['unitType'] as UnitType?;
    final isHotel = unitType == UnitType.hotelRoom;
    final checkOutTime = isHotel ? '12:00' : '11:30';

    return _InfoSection(
      title: S.of(context).guest_guide_house_rules,
      icon: Icons.rule_outlined,
      children: [
        _RuleItem(icon: Icons.access_time_outlined, text: S.of(context).guest_guide_rule_checkin),
        _RuleItem(icon: Icons.access_time_filled, text: S.of(context).guest_guide_rule_checkout(checkOutTime)),
        _RuleItem(icon: Icons.smoke_free_outlined, text: S.of(context).guest_guide_rule_no_smoking),
        _RuleItem(icon: Icons.party_mode_outlined, text: S.of(context).guest_guide_rule_no_parties),
        _RuleItem(icon: Icons.pets_outlined, text: S.of(context).guest_guide_rule_no_pets),
      ],
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

/// Widget para las secciones de información
class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la sección
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: AppColors.goldWithAlpha10,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLarge),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.black, size: 20),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para items de contacto
class _ContactItem extends StatelessWidget {
  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.goldWithAlpha10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.gold, size: 18),
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
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.getTextPrimaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.getTextSecondaryColor(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para filas de datos
class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.getTextPrimaryColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para iconos de servicios
class _ServiceIcon extends StatelessWidget {
  const _ServiceIcon({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.goldWithAlpha10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.goldWithAlpha30),
            ),
            child: Icon(icon, color: AppColors.gold, size: 24),
          ),
          const SizedBox(height: AppTheme.spacing8),
          _ServiceLabel(label),
        ],
      ),
    );
  }
}

/// Etiqueta de servicio que escala el tamaño de fuente hasta que cada palabra
/// completa quepa en su línea, evitando que una sola palabra se corte.
class _ServiceLabel extends StatelessWidget {
  const _ServiceLabel(this.label);

  final String label;

  static const double _maxFontSize = 12;
  static const double _minFontSize = 6;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final baseStyle = DefaultTextStyle.of(context).style;
    final words = label.split(RegExp(r'\s+'));

    return LayoutBuilder(
      builder: (context, constraints) {
        // Margen de seguridad para no rozar el borde de la columna.
        final maxWidth = constraints.maxWidth - 2;

        var fontSize = _maxFontSize;
        while (fontSize > _minFontSize) {
          final everyWordFits = words.every((word) {
            final painter = TextPainter(
              text: TextSpan(
                text: word,
                style: baseStyle.copyWith(fontSize: fontSize),
              ),
              textDirection: TextDirection.ltr,
              textScaler: textScaler,
              maxLines: 1,
            )..layout();
            return painter.width <= maxWidth;
          });
          if (everyWordFits) break;
          fontSize -= 0.5;
        }

        return Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: baseStyle.copyWith(
            fontSize: fontSize,
            color: AppColors.getTextSecondaryColor(context),
          ),
        );
      },
    );
  }
}

/// Widget para items de normas
class _RuleItem extends StatelessWidget {
  const _RuleItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 18),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
