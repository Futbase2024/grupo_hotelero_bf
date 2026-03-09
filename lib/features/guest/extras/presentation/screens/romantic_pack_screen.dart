import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bf_stay/core/theme/app_colors.dart';

/// Pantalla elegante y romántica para mostrar el Pack Romántico
class RomanticPackScreen extends StatelessWidget {
  const RomanticPackScreen({super.key});

  // Colores románticos locales
  static const Color _romanticPink = Color(0xFFFF69B4);
  static const Color _romanticRed = Color(0xFFE91E63);
  static const Color _romanticPurple = Color(0xFF9C27B0);

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.white : AppColors.black,
          ),
          onPressed: () => context.go('/guest'),
        ),
        title: Text(
          'Pack Romántico',
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section con gradiente romántico
              _buildHeroSection(context),
              const SizedBox(height: 32),

              // Título principal
              Center(
                child: Column(
                  children: [
                    Text(
                      'Sorprende a tu pareja',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Una experiencia inolvidable',
                      style: TextStyle(
                        fontSize: 16,
                        color: _romanticPink,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Qué incluye el pack
              _buildSectionTitle(context, '¿Qué incluye?'),
              const SizedBox(height: 16),
              _buildInclusionCard(
                context,
                icon: Icons.local_florist,
                title: 'Pétalos de rosas',
                description: 'Decoración romántica con pétalos frescos en la habitación',
              ),
              const SizedBox(height: 12),
              _buildInclusionCard(
                context,
                icon: Icons.wine_bar_outlined,
                title: 'Botella de Cava',
                description: 'Selección de cava premium para brindar juntos',
              ),
              const SizedBox(height: 12),
              _buildInclusionCard(
                context,
                icon: Icons.cookie_outlined,
                title: 'Fresas con chocolate',
                description: 'Deliciosas fresas bañadas en chocolate belga',
              ),
              const SizedBox(height: 12),
              _buildInclusionCard(
                context,
                icon: Icons.cake_outlined,
                title: 'Detalle dulce',
                description: 'Selección de bombones artesanales',
              ),
              const SizedBox(height: 12),
              _buildInclusionCard(
                context,
                icon: Icons.star_outline,
                title: 'Velitas aromáticas',
                description: 'Ambientación con velas perfumadas',
              ),
              const SizedBox(height: 32),

              // Información de precio y reserva
              _buildPricingSection(context),
              const SizedBox(height: 32),

              // Cómo reservar
              _buildSectionTitle(context, '¿Cómo reservar?'),
              const SizedBox(height: 16),
              _buildStepsCard(context),
              const SizedBox(height: 32),

              // Nota importante
              _buildNoteCard(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _romanticPink,
            _romanticRed,
            _romanticPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _romanticPink.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Iconos decorativos de fondo
          Positioned(
            top: 20,
            left: 20,
            child: Icon(
              Icons.favorite,
              color: AppColors.white.withValues(alpha: 0.2),
              size: 40,
            ),
          ),
          Positioned(
            bottom: 30,
            right: 30,
            child: Icon(
              Icons.favorite_border,
              color: AppColors.white.withValues(alpha: 0.2),
              size: 50,
            ),
          ),
          Positioned(
            top: 40,
            right: 50,
            child: Icon(
              Icons.local_florist,
              color: AppColors.white.withValues(alpha: 0.15),
              size: 35,
            ),
          ),
          // Contenido central
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: AppColors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pack Romántico',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crea momentos mágicos',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.white.withValues(alpha: 0.9),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _romanticPink,
                _romanticRed,
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildInclusionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.gray50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _romanticPink.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _romanticPink.withValues(alpha: 0.2),
                  _romanticRed.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: _romanticPink,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
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
      ),
    );
  }

  Widget _buildPricingSection(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.darkSurface,
                  AppColors.darkSurface.withValues(alpha: 0.8),
                ]
              : [
                  _romanticPink.withValues(alpha: 0.1),
                  _romanticRed.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _romanticPink.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.card_giftcard,
                color: _romanticPink,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Precio del Pack',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Consultar en recepción',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _romanticPink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'El precio puede variar según la personalización',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.getTextSecondaryColor(context),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepsCard(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    final steps = [
      {'number': '1', 'text': 'Contacta con recepción'},
      {'number': '2', 'text': 'Indica el día y hora deseada'},
      {'number': '3', 'text': 'Personaliza tu pack (opcional)'},
      {'number': '4', 'text': 'Prepararemos todo para tu llegada'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(context),
        ),
      ),
      child: Column(
        children: steps.map((step) {
          final isLast = step == steps.last;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _romanticPink,
                          _romanticRed,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        step['number']!,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 32,
                      color: _romanticPink.withValues(alpha: 0.3),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Text(
                    step['text']!,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.getTextPrimaryColor(context),
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.gold,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Reserva con al menos 24 horas de antelación para garantizar la disponibilidad de todos los elementos.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.gold : AppColors.gray700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
