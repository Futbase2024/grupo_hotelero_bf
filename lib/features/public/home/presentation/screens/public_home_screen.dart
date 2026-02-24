import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/responsive.dart';
import '../../../../../core/theme/widgets/theme_toggle.dart';
import '../../../../../core/router/app_router.dart';

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
      backgroundColor: isDark ? AppColors.gray900 : AppColors.gray50,
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
    final borderColor = isDark ? AppColors.gold.withValues(alpha: 0.5) : AppColors.black.withValues(alpha: 0.3);

    return Stack(
      children: [
        Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: context.responsive(mobile: 400.0, tablet: 500.0, desktop: 600.0),
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
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.black.withValues(alpha: 0.4),
                          AppColors.black.withValues(alpha: 0.8),
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
                    isDark ? AppColors.black.withValues(alpha: 0.5) : AppColors.silverLight.withValues(alpha: 0.7),
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
                          ? AppColors.gray900.withValues(alpha: 0.9)
                          : AppColors.silverLight.withValues(alpha: 0.4),
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
                          color: isDark ? AppColors.gold.withValues(alpha: 0.15) : AppColors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          border: Border.all(color: isDark ? AppColors.gold.withValues(alpha: 0.3) : AppColors.black.withValues(alpha: 0.3)),
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
                      SizedBox(height: context.responsive(mobile: AppTheme.spacing24, tablet: AppTheme.spacing32)),

                      // Logo circular
                      _buildLogo(context),
                      const SizedBox(height: AppTheme.spacing24),

                      // Título principal en una línea con bordes
                      _buildStrokedTitle(context, isDark),
                      const SizedBox(height: AppTheme.spacing16),

                      // Subtítulo
                      Text(
                        'Gestión inteligente para los alojamientos más exclusivos. Comodidad absoluta en la palma de tu mano.',
                        style: TextStyle(
                          fontSize: ResponsiveFontSize.bodyMedium(context),
                          color: isDark ? AppColors.silver.withValues(alpha: 0.8) : AppColors.gray600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: context.responsive(mobile: AppTheme.spacing32, tablet: AppTheme.spacing40)),

                      // Botón CTA
                      SizedBox(
                        width: double.infinity,
                        height: AppTheme.buttonHeightLarge,
                        child: ElevatedButton(
                          onPressed: () => context.go(AppRoutes.bookingAccess),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.black,
                            elevation: 0,
                            shadowColor: AppColors.gold.withValues(alpha: 0.3),
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
              color: isDark ? AppColors.black.withValues(alpha: 0.5) : AppColors.white.withValues(alpha: 0.8),
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
    final borderColor = isDark ? AppColors.gold.withValues(alpha: 0.5) : AppColors.black.withValues(alpha: 0.3);
    final cardBorderColor = isDark ? AppColors.gold.withValues(alpha: 0.5) : AppColors.black.withValues(alpha: 0.2);

    final services = [
      _ServiceItem(
        icon: Icons.login_outlined,
        title: 'Check-in Digital',
        description: 'Registro de entrada sin esperas.',
      ),
      _ServiceItem(
        icon: Icons.logout_outlined,
        title: 'Check-out Digital',
        description: 'Salida rápida y sencilla.',
      ),
      _ServiceItem(
        icon: Icons.rule_outlined,
        title: 'Normas de la Casa',
        description: 'Reglas y recomendaciones.',
      ),
      _ServiceItem(
        icon: Icons.attractions_outlined,
        title: '¿Qué ver?',
        description: 'Lugares de interés cercanos.',
      ),
      _ServiceItem(
        icon: Icons.local_parking_outlined,
        title: 'Aparcamientos Cercanos',
        description: 'Opciones de parking.',
      ),
      _ServiceItem(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Chat',
        description: 'Conserje virtual 24/7.',
      ),
      _ServiceItem(
        icon: Icons.home_work_outlined,
        title: 'Nuestros Alojamientos',
        description: 'Otras propiedades disponibles.',
      ),
      _ServiceItem(
        icon: Icons.star_outline_rounded,
        title: 'Reseñas y Comentarios',
        description: 'Opiniones de huéspedes.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.gray800.withValues(alpha: 0.4) : AppColors.white.withValues(alpha: 0.9),
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
                color: isDark ? AppColors.white : AppColors.gray900,
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
              mainAxisSpacing: AppTheme.spacing12,
              crossAxisSpacing: AppTheme.spacing12,
              mainAxisExtent: context.responsive(mobile: 140.0, tablet: 150.0, desktop: 160.0),
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
    final borderColor = isDark ? AppColors.gold.withValues(alpha: 0.5) : AppColors.black.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.gray900 : AppColors.white,
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

          // Contacto
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFooterContactItem(context, Icons.phone_outlined, '+34 674 27 70 16'),
              const SizedBox(width: AppTheme.spacing16),
              _buildFooterContactItem(context, Icons.email_outlined, 'info@bfstay.com'),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),

          // Copyright
          Text(
            '© ${DateTime.now().year} BF Stay • Todos los derechos reservados',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.silver.withValues(alpha: 0.5) : AppColors.gray500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Logo de la aplicación
  Widget _buildLogo(BuildContext context) {
    final logoSize = context.responsive<double>(mobile: 100.0, tablet: 120.0, desktop: 140.0);

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/icons/logo.png',
        fit: BoxFit.cover,
      ),
    );
  }

  /// Título con efecto de borde (stroke)
  Widget _buildStrokedTitle(BuildContext context, bool isDark) {
    final fontSize = context.responsive(
      mobile: ResponsiveFontSize.headlineMedium(context),
      tablet: 42.0,
      desktop: 52.0,
    );

    // Colores para tema claro: texto negro con borde plata
    // Colores para tema oscuro: texto blanco con borde dorado
    final textColor = isDark ? AppColors.white : AppColors.black;
    final strokeColor = isDark ? AppColors.gold : AppColors.silver;

    return Stack(
      children: [
        // Solo "Tu Estancia," con borde (stroke)
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Tu Estancia, ',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 2.5
                    ..color = strokeColor,
                ),
              ),
              // Espacio para "Elevada" sin borde
              TextSpan(
                text: 'Elevada',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Colors.transparent,
                ),
              ),
            ],
          ),
        ),
        // Texto principal
        RichText(
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
              // "Elevada" con gradiente dorado (sin borde)
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
        ),
      ],
    );
  }

  /// Card de servicio compacta para grid
  Widget _buildServiceCard(BuildContext context, _ServiceItem service, Color borderColor) {
    final isDark = AppColors.isDarkMode(context);
    final iconSize = context.responsive(mobile: 32.0, tablet: 36.0, desktop: 40.0);
    final iconInnerSize = context.responsive(mobile: 18.0, tablet: 20.0, desktop: 22.0);
    final titleSize = context.responsive(mobile: 13.0, tablet: 14.0, desktop: 15.0);
    final descSize = context.responsive(mobile: 11.0, tablet: 12.0, desktop: 13.0);
    final padding = context.responsive(mobile: 12.0, tablet: 14.0, desktop: 16.0);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.gray800.withValues(alpha: 0.3) : AppColors.gray50.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              service.icon,
              color: AppColors.gold,
              size: iconInnerSize,
            ),
          ),
          SizedBox(height: context.responsive(mobile: 8.0, tablet: 10.0, desktop: 12.0)),
          // Título
          Text(
            service.title,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.gray900,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Descripción
          Text(
            service.description,
            style: TextStyle(
              fontSize: descSize,
              color: isDark ? AppColors.silver.withValues(alpha: 0.6) : AppColors.gray500,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
        Icon(icon, color: AppColors.gold.withValues(alpha: 0.8), size: 16),
        const SizedBox(width: AppTheme.spacing8),
        Text(
          text,
          style: TextStyle(
            color: isDark ? AppColors.silver.withValues(alpha: 0.7) : AppColors.gray600,
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

  const _ServiceItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
