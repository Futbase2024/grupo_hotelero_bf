import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/l10n/app_localizations.dart';

/// Pantalla elegante para mostrar las normas de uso del Jacuzzi
class JacuzziRulesScreen extends StatelessWidget {
  const JacuzziRulesScreen({super.key});

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
          S.of(context).guest_jacuzzi_title,
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
              // Hero Section con imagen del jacuzzi y borde gold
              _buildHeroSection(context),
              const SizedBox(height: 32),

              // Título principal
              Center(
                child: Column(
                  children: [
                    Text(
                      S.of(context).guest_jacuzzi_rules_title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      S.of(context).guest_jacuzzi_subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.gold,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Sección: Encendido
              _buildSectionTitle(
                context,
                S.of(context).guest_jacuzzi_power,
                Icons.power_settings_new,
              ),
              const SizedBox(height: 12),
              _buildInstructionCard(
                context,
                steps: [
                  S.of(context).guest_jacuzzi_power_step_1,
                  S.of(context).guest_jacuzzi_power_step_2,
                  S.of(context).guest_jacuzzi_power_step_3,
                ],
              ),
              const SizedBox(height: 24),

              // Sección: Bloqueo del panel
              _buildSectionTitle(
                context,
                S.of(context).guest_jacuzzi_lock,
                Icons.lock,
              ),
              const SizedBox(height: 12),
              _buildInstructionCard(
                context,
                steps: [S.of(context).guest_jacuzzi_lock_step_1],
                subSections: [
                  _SubSection(
                    title: S.of(context).guest_jacuzzi_lock_unlock,
                    steps: [S.of(context).guest_jacuzzi_lock_unlock_step],
                  ),
                  _SubSection(
                    title: S.of(context).guest_jacuzzi_lock_manual,
                    steps: [S.of(context).guest_jacuzzi_lock_manual_step],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Sección: Función Ozono
              _buildSectionTitle(
                context,
                S.of(context).guest_jacuzzi_ozone,
                Icons.bubble_chart,
              ),
              const SizedBox(height: 12),
              _buildInstructionCard(
                context,
                introText: S.of(context).guest_jacuzzi_ozone_intro,
                steps: [
                  S.of(context).guest_jacuzzi_ozone_step_1,
                  S.of(context).guest_jacuzzi_ozone_step_2,
                  S.of(context).guest_jacuzzi_ozone_step_3,
                  S.of(context).guest_jacuzzi_ozone_step_4,
                ],
                note: S
                    .of(context)
                    .guest_jacuzzi_ozone_note(
                      'El sistema se ejecuta automáticamente durante 30 minutos',
                    ),
              ),
              const SizedBox(height: 24),

              // Sección: Funciones de masaje
              _buildSectionTitle(
                context,
                S.of(context).guest_jacuzzi_massage,
                Icons.hot_tub,
              ),
              const SizedBox(height: 12),

              // Jets de aire
              _buildMassageCard(
                context,
                title: S.of(context).guest_jacuzzi_air_jets,
                icon: Icons.air,
                steps: [
                  S.of(context).guest_jacuzzi_air_step_1,
                  S.of(context).guest_jacuzzi_air_step_2,
                  S.of(context).guest_jacuzzi_air_step_3,
                  S.of(context).guest_jacuzzi_air_step_4,
                ],
              ),
              const SizedBox(height: 12),

              // Jets de agua
              _buildMassageCard(
                context,
                title: S.of(context).guest_jacuzzi_water_jets,
                icon: Icons.water_drop,
                steps: [
                  S.of(context).guest_jacuzzi_water_step_1,
                  S.of(context).guest_jacuzzi_water_step_2,
                  S.of(context).guest_jacuzzi_water_step_3,
                  S.of(context).guest_jacuzzi_water_step_4,
                ],
              ),
              const SizedBox(height: 24),

              // Sección: Importante (nivel de agua)
              _buildImportantCard(context),
              const SizedBox(height: 24),

              // Sección: Uso responsable del agua
              _buildWaterResponsibilityCard(context),
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
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Image.asset('assets/images/jacuzzi.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, color: AppColors.gold, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionCard(
    BuildContext context, {
    List<String>? steps,
    String? introText,
    List<_SubSection>? subSections,
    String? note,
  }) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.gray50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldWithAlpha30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Texto introductorio
          if (introText != null) ...[
            Text(
              introText,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextPrimaryColor(context),
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Lista de pasos
          if (steps != null) _buildStepsList(context, steps),

          // Subsecciones
          if (subSections != null)
            ...subSections.map(
              (sub) => Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStepsList(context, sub.steps),
                  ],
                ),
              ),
            ),

          // Nota
          if (note != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.goldWithAlpha10,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.goldWithAlpha30),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.gold, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      S.of(context).guest_jacuzzi_note(note),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.gold : AppColors.gray700,
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

  Widget _buildStepsList(BuildContext context, List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        return Padding(
          padding: EdgeInsets.only(bottom: index == steps.length - 1 ? 0 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.goldWithAlpha10,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.getTextPrimaryColor(context),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMassageCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> steps,
  }) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldWithAlpha30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.goldWithAlpha10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.gold, size: 24),
              ),
              const SizedBox(width: 12),
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
          const SizedBox(height: 16),
          _buildStepsList(context, steps),
        ],
      ),
    );
  }

  Widget _buildImportantCard(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warning.withValues(alpha: 0.15),
            AppColors.warning.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                S.of(context).guest_jacuzzi_important,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).guest_jacuzzi_water_level_info,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextPrimaryColor(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground.withValues(alpha: 0.5)
                  : AppColors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).guest_jacuzzi_low_water_title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                _buildBulletPoint(
                  context,
                  S.of(context).guest_jacuzzi_low_water_stop,
                ),
                _buildBulletPoint(
                  context,
                  S.of(context).guest_jacuzzi_low_water_icon,
                ),
                const SizedBox(height: 8),
                Text(
                  S.of(context).guest_jacuzzi_low_water_resume,
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

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterResponsibilityCard(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.gray50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldWithAlpha30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.goldWithAlpha10,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.water_drop_outlined,
                  color: AppColors.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                S.of(context).guest_jacuzzi_water_responsibility,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).guest_jacuzzi_water_refill_info,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextPrimaryColor(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground.withValues(alpha: 0.5)
                  : AppColors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.opacity, color: AppColors.gold, size: 20),
                const SizedBox(width: 8),
                Text(
                  S.of(context).guest_jacuzzi_capacity,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  S.of(context).guest_jacuzzi_capacity_liters,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).guest_jacuzzi_water_regulation,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.getTextSecondaryColor(context),
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.goldWithAlpha10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.favorite, color: AppColors.gold, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    S.of(context).guest_jacuzzi_thanks,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gold,
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
}

/// Clase auxiliar para subsecciones
class _SubSection {
  final String title;
  final List<String> steps;

  const _SubSection({required this.title, required this.steps});
}
