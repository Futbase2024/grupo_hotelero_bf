import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/l10n/app_localizations.dart';

/// Pantalla elegante y romántica para mostrar el Pack Romántico
class RomanticPackScreen extends StatelessWidget {
  const RomanticPackScreen({super.key});

  // Colores románticos locales
  static const Color _romanticPink = Color(0xFFFF69B4);
  static const Color _romanticRed = Color(0xFFE91E63);

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
          S.of(context).guest_romantic_title,
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
                      S.of(context).guest_romantic_surprise,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      S.of(context).guest_romantic_unforgettable,
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
              _buildSectionTitle(context, S.of(context).guest_romantic_includes),
              const SizedBox(height: 16),
              _buildInclusionCard(
                context,
                icon: Icons.local_florist,
                title: S.of(context).guest_romantic_decoration_title,
                description: S.of(context).guest_romantic_decoration_desc,
              ),
              const SizedBox(height: 12),
              _buildInclusionCard(
                context,
                icon: Icons.card_giftcard,
                title: S.of(context).guest_romantic_choose_title,
                description: S.of(context).guest_romantic_choose_desc,
              ),
              const SizedBox(height: 32),

              // Información de precio y reserva
              _buildPricingSection(context),
              const SizedBox(height: 32),

              // Cómo reservar
              _buildSectionTitle(context, S.of(context).guest_romantic_how_to),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Image.asset(
          'assets/images/packromantico.png',
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
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
                S.of(context).guest_romantic_basic_pack,
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
            S.of(context).guest_romantic_price,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: _romanticPink,
            ),
          ),
          const SizedBox(height: 16),
          // Botón de compra
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showPurchaseDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _romanticPink,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                S.of(context).guest_romantic_book_now,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context).guest_romantic_customize,
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

  void _showPurchaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.isDarkMode(context) ? AppColors.darkSurface : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.favorite, color: _romanticPink),
            const SizedBox(width: 8),
            Text(S.of(context).guest_romantic_title),
          ],
        ),
        content: Text(
          S.of(context).guest_romantic_redirect,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(S.of(context).common_cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final uri = Uri.parse('https://www.boutiquejerez.es/producto/pack-romantico/');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _romanticPink,
              foregroundColor: AppColors.white,
            ),
            child: Text(S.of(context).common_continue),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsCard(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    final steps = [
      {'number': '1', 'text': S.of(context).guest_romantic_step_1},
      {'number': '2', 'text': S.of(context).guest_romantic_step_2},
      {'number': '3', 'text': S.of(context).guest_romantic_step_3},
      {'number': '4', 'text': S.of(context).guest_romantic_step_4},
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
              S.of(context).guest_romantic_note,
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
