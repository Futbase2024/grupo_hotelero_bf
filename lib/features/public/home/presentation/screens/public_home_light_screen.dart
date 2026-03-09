import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/responsive.dart';
import '../../../../../core/router/app_router.dart';

/// Pantalla pública de inicio - Versión Light (fondo blanco)
class PublicHomeLightScreen extends StatefulWidget {
  const PublicHomeLightScreen({super.key});

  @override
  State<PublicHomeLightScreen> createState() => _PublicHomeLightScreenState();
}

class _PublicHomeLightScreenState extends State<PublicHomeLightScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
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
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: context.responsive(mobile: 360.0, tablet: 420.0, desktop: 500.0),
      ),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
        image: DecorationImage(
          image: const AssetImage('assets/images/hero_background.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            AppColors.gold.withValues(alpha: 0.85),
            BlendMode.srcATop,
          ),
          onError: (exception, stackTrace) {
            // Si no hay imagen, el color gold actúa como fallback
          },
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
            Colors.transparent,
            AppColors.goldDark.withValues(alpha: 0.3),
          ],
        ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge superior
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12, vertical: AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(color: AppColors.black.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: AppColors.black, size: 14),
                    const SizedBox(width: AppTheme.spacing8),
                    Text(
                      'EXCLUSIVIDAD GARANTIZADA',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.black,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.responsive(mobile: AppTheme.spacing20, tablet: AppTheme.spacing24)),

              // Logo circular
              _buildLogo(context),
              const SizedBox(height: AppTheme.spacing20),

              // Título principal
              Text(
                'Tu Estancia,',
                style: TextStyle(
                  fontSize: context.responsive(
                    mobile: 24.0,
                    tablet: 30.0,
                    desktop: 36.0,
                  ),
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Elevada',
                style: TextStyle(
                  fontSize: context.responsive(
                    mobile: 24.0,
                    tablet: 30.0,
                    desktop: 36.0,
                  ),
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing12),

              // Subtítulo
              Text(
                'Gestión inteligente para alojamientos exclusivos.',
                style: TextStyle(
                  fontSize: ResponsiveFontSize.bodyMedium(context),
                  color: AppColors.black.withValues(alpha: 0.8),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing24),

              // Botón CTA
              SizedBox(
                width: double.infinity,
                height: AppTheme.buttonHeightLarge,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.bookingAccess),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shadowColor: AppColors.black.withValues(alpha: 0.3),
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
    );
  }

  /// Sección de Servicios en grid
  Widget _buildServicesSection(BuildContext context) {
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
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
                color: AppColors.gray900,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Grid de servicios - 2 columnas
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppTheme.spacing12,
              crossAxisSpacing: AppTheme.spacing12,
              childAspectRatio: 1.4,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) => _buildServiceCard(context, services[index]),
          ),
        ],
      ),
    );
  }

  /// Footer compacto
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppColors.gray900,
        borderRadius: BorderRadius.circular(24),
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
              _buildFooterContactItem(Icons.phone_outlined, '+34 656 61 80 65'),
              const SizedBox(width: AppTheme.spacing16),
              _buildFooterContactItem(Icons.phone_outlined, '+34 674 27 70 16'),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),

          // Contacto - Email
          _buildFooterContactItem(Icons.email_outlined, 'Info@boutiquejerez.es'),
          const SizedBox(height: AppTheme.spacing12),

          // Copyright
          Text(
            '© ${DateTime.now().year} BF Stay • Todos los derechos reservados',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.silver.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Logo de la aplicación
  Widget _buildLogo(BuildContext context) {
    final logoSize = context.responsive<double>(mobile: 130.0, tablet: 160.0, desktop: 190.0);

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.25),
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

  /// Card de servicio compacta para grid
  Widget _buildServiceCard(BuildContext context, _ServiceItem service) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              service.icon,
              color: AppColors.goldDark,
              size: 20,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          // Título
          Text(
            service.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Descripción
          Text(
            service.description,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.gray500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Item de contacto del footer
  Widget _buildFooterContactItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.gold, size: 16),
        const SizedBox(width: AppTheme.spacing8),
        Text(
          text,
          style: TextStyle(
            color: AppColors.silver.withValues(alpha: 0.7),
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
