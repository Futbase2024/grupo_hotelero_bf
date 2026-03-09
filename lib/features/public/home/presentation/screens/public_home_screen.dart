import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/responsive.dart';
import '../../../../../core/theme/widgets/theme_toggle.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../auth/presentation/widgets/logo_tap_trigger.dart';
import '../../../../admin/auth/admin_login_bottom_sheet.dart';

// Colores predefinidos para borders según tema
const _kLightBorder = AppColors.blackWithAlpha30;
const _kLightCardBorder = AppColors.blackWithAlpha20;
const _kDarkBorder = AppColors.gold;

/// Pantalla pública de inicio - Home sin autenticación
class PublicHomeScreen extends StatefulWidget {
  const PublicHomeScreen({super.key});

  @override
  State<PublicHomeScreen> createState() => _PublicHomeScreenState();
}

class _PublicHomeScreenState extends State<PublicHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.gray50,
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: (context) => _buildMobileLayout(context),
          tablet: (context) => _buildTabletLayout(context),
          desktop: (context) => _buildDesktopLayout(context),
        ),
      ),
    );
  }

  /// Layout para móvil
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        children: [
          _buildHeroSection(context),
          const SizedBox(height: AppTheme.spacing16),
          _buildServicesSection(context),
          const SizedBox(height: AppTheme.spacing16),
          _buildFooter(context),
        ],
      ),
    );
  }

  /// Layout para tablet
  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeroSection(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing48),
            child: Column(
              children: [
                const SizedBox(height: AppTheme.spacing16),
                _buildServicesSection(context),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  /// Layout para desktop
  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeroSection(context),
          ResponsiveContent(
            child: Column(
              children: [
                const SizedBox(height: AppTheme.spacing16),
                _buildServicesSection(context),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  /// Hero Section con imagen de fondo
  Widget _buildHeroSection(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    final borderColor = isDark ? _kDarkBorder : _kLightBorder;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: context.responsive(mobile: 350.0, tablet: 500.0, desktop: 600.0),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge - 1),
            child: Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.darkBackgroundWithAlpha40,
                          AppColors.darkBackgroundWithAlpha80,
                        ],
                      )
                    : const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.silver,
                          AppColors.silverLight,
                          Color(0xFFE8E8E8),
                        ],
                      ),
                image: DecorationImage(
                  image: const AssetImage('assets/images/hero_background.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    isDark ? AppColors.darkBackgroundWithAlpha50 : AppColors.silverLight,
                    isDark ? BlendMode.darken : BlendMode.srcATop,
                  ),
                  onError: (exception, stackTrace) {
                    // Si no hay imagen, el gradiente actúa como fallback
                  },
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      isDark
                          ? AppColors.darkBackgroundWithAlpha90
                          : AppColors.silverLight,
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(context.contentPaddingHorizontal),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Badge superior
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12, vertical: AppTheme.spacing8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.black : AppColors.blackWithAlpha05,
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          border: Border.all(color: isDark ? _kDarkBorder : _kLightBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, color: isDark ? AppColors.gold : AppColors.black, size: 14),
                            const SizedBox(width: AppTheme.spacing8),
                            Text(
                              'EXCLUSIVIDAD GARANTIZADA',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.gold : AppColors.black,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: context.responsive(mobile: AppTheme.spacing24, tablet: AppTheme.spacing16)),

                      // Logo circular
                      _buildLogo(context),
                      const SizedBox(height: AppTheme.spacing16),

                      // Título principal en una línea con bordes
                      _buildStrokedTitle(context, isDark),
                      const SizedBox(height: AppTheme.spacing16),

                      // Subtítulo
                      // Text(
                      //   'Gestión inteligente para los alojamientos más exclusivos. Comodidad absoluta en la palma de tu mano.',
                      //   style: TextStyle(
                      //     fontSize: ResponsiveFontSize.bodyMedium(context),
                      //     color: isDark ? AppColors.darkTextSecondary : AppColors.black,
                      //     height: 1.5,
                      //   ),
                      //   textAlign: TextAlign.center,
                      // ),
                      // SizedBox(height: context.responsive(mobile: AppTheme.spacing32, tablet: AppTheme.spacing40)),

                      // Botón CTA con gradiente dorado
                      SizedBox(
                        width: double.infinity,
                        height: AppTheme.buttonHeightLarge,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold,
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => context.go(AppRoutes.bookingAccess),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: AppColors.black,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              ),
                            ),
                            child: Text(
                              'Acceder a mi Reserva',
                              style: TextStyle(
                                fontSize: ResponsiveFontSize.labelLarge(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Theme Toggle en esquina superior derecha
        Positioned(
          top: AppTheme.spacing16,
          right: AppTheme.spacing16,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacing4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.blackWithAlpha50 : AppColors.whiteWithAlpha80,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: const ThemeToggle(variant: ThemeToggleVariant.icon),
          ),
        ),
      ],
    );
  }

  /// Sección de Servicios en grid
  Widget _buildServicesSection(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    final borderColor = isDark ? _kDarkBorder : _kLightBorder;
    final cardBorderColor = isDark ? _kDarkBorder : _kLightCardBorder;

    final services = [
      _ServiceItem(
        icon: Icons.login_outlined,
        title: 'Check-in Digital',
        description: 'Registro de entrada sin esperas.',
        route: AppRoutes.bookingAccess,
        imageAsset: 'assets/images/checkin.png',
        overlayColor: const Color(0xFF2E7D32),
      ),
      _ServiceItem(
        icon: Icons.logout_outlined,
        title: 'Check-out Digital',
        description: 'Salida rápida y sencilla.',
        route: AppRoutes.bookingAccess,
        imageAsset: 'assets/images/checkout.png',
        overlayColor: const Color(0xFF1565C0),
      ),
      _ServiceItem(
        icon: Icons.rule_outlined,
        title: 'Normas de la Casa',
        description: 'Reglas y recomendaciones.',
        route: AppRoutes.houseRulesGeneral,
        imageAsset: 'assets/images/normas.png',
        overlayColor: const Color(0xFF6D4C41),
      ),
      _ServiceItem(
        icon: Icons.attractions_outlined,
        title: '¿Qué ver?',
        description: 'Lugares de interés cercanos.',
        route: AppRoutes.queVer,
        imageAsset: 'assets/images/quever.png',
        overlayColor: const Color(0xFF00838F),
      ),
      _ServiceItem(
        icon: Icons.local_parking_outlined,
        title: 'Aparcamientos',
        description: 'Opciones de parking.',
        route: AppRoutes.parkings,
        imageAsset: 'assets/images/parking.png',
        overlayColor: const Color(0xFF5E35B1),
      ),
      _ServiceItem(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Chat',
        description: 'Conserje virtual 24/7.',
        route: AppRoutes.bookingAccess,
        imageAsset: 'assets/images/chat.png',
        overlayColor: const Color(0xFF00695C),
      ),
      _ServiceItem(
        icon: Icons.home_work_outlined,
        title: 'Alojamientos',
        description: 'Otras propiedades.',
        route: AppRoutes.alojamientos,
        imageAsset: 'assets/images/alojamiento.png',
        overlayColor: const Color(0xFF455A64),
      ),
      _ServiceItem(
        icon: Icons.star_outline_rounded,
        title: 'Reseñas',
        description: 'Opiniones de huéspedes.',
        route: '/guest/reviews/bf000000-0000-0000-0000-000000000001',
        imageAsset: 'assets/images/reseña.png',
        overlayColor: const Color(0xFFEF6C00),
      ),      
    ];

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceWithAlpha40 : AppColors.whiteWithAlpha90,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de sección
          Center(
            child: Text(
              'Nuestros Servicios',
              style: TextStyle(
                fontSize: ResponsiveFontSize.headlineSmall(context),
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.black,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Grid de servicios - 2 columnas con altura responsiva
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              mainAxisExtent: context.responsive(mobile: 130.0, tablet: 140.0, desktop: 150.0),
            ),
            itemCount: services.length,
            itemBuilder: (context, index) => _buildServiceCard(context, services[index], cardBorderColor),
          ),
        ],
      ),
    );
  }

  /// Footer compacto
  Widget _buildFooter(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    final borderColor = isDark ? _kDarkBorder : _kLightBorder;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          // Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 24,
                child: Image.asset(
                  'assets/icons/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'BF STAY',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),

          // Contacto - Teléfonos
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFooterContactItem(context, Icons.phone_outlined, '+34 656 61 80 65'),
              const SizedBox(width: AppTheme.spacing16),
              _buildFooterContactItem(context, Icons.phone_outlined, '+34 674 27 70 16'),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),

          // Contacto - Email
          _buildFooterContactItem(context, Icons.email_outlined, 'Info@boutiquejerez.es'),
          const SizedBox(height: AppTheme.spacing12),

          // Copyright
          Text(
            '© ${DateTime.now().year} BF Stay • Todos los derechos reservados',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.gray500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Logo de la aplicación con trigger oculto de 5 taps
  Widget _buildLogo(BuildContext context) {
    final logoSize = context.responsive<double>(mobile: 140.0, tablet: 170.0, desktop: 200.0);

    return LogoTapTrigger(
      onTriggered: () => AdminLoginBottomSheet.show(context),
      child: Container(
        width: logoSize,
        height: logoSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.gold, width: 0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          'assets/icons/logo.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Título principal
  Widget _buildStrokedTitle(BuildContext context, bool isDark) {
    final fontSize = context.responsive(
      mobile: ResponsiveFontSize.headlineMedium(context),
      tablet: 42.0,
      desktop: 52.0,
    );

    // Colores para tema claro: texto negro
    // Colores para tema oscuro: texto blanco
    final textColor = isDark ? AppColors.white : AppColors.black;

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Tu Estancia, ',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: textColor,
            ),
          ),
          // "Elevada" con gradiente dorado
          TextSpan(
            text: 'Elevada',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              foreground: Paint()
                ..shader = AppColors.goldGradient.createShader(
                  Rect.fromLTWH(0, 0, 300, fontSize),
                ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card de servicio compacta para grid
  Widget _buildServiceCard(BuildContext context, _ServiceItem service, Color borderColor) {
    final titleSize = context.responsive(mobile: 12.0, tablet: 13.0, desktop: 14.0);
    final isClickable = service.route != null;
    final overlayColor = service.overlayColor ?? AppColors.gold;
    final isDark = AppColors.isDarkMode(context);

    return GestureDetector(
      onTap: isClickable ? () => context.push(service.route!) : null,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          // Tarjeta con imagen
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: borderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 1),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Imagen de fondo (si existe) o gradiente de color
                    service.imageAsset != null
                        ? Image.asset(
                            service.imageAsset!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    overlayColor,
                                    overlayColor.withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  overlayColor,
                                  overlayColor.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                    // Overlay oscuro sutil
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.blackWithAlpha05,
                            AppColors.blackWithAlpha20,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Título debajo de la tarjeta
          const SizedBox(height: 6),
          Text(
            service.title,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.black,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Item de contacto del footer
  Widget _buildFooterContactItem(BuildContext context, IconData icon, String text) {
    final isDark = AppColors.isDarkMode(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isDark ? AppColors.gold : AppColors.black, size: 16),
        const SizedBox(width: AppTheme.spacing8),
        Text(
          text,
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.black,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// Clase auxiliar para representar un servicio
class _ServiceItem {
  final IconData icon;
  final String title;
  final String description;
  final String? route;
  final String? imageAsset;
  final Color? overlayColor;

  const _ServiceItem({
    required this.icon,
    required this.title,
    required this.description,
    this.route,
    this.imageAsset,
    this.overlayColor,
  });
}
