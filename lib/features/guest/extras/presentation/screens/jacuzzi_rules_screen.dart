import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bf_stay/core/theme/app_colors.dart';

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
              'Normas Jacuzzi',
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
                          'Normas de uso del Jacuzzi',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.white : AppColors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Disfruta de una experiencia relajante',
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
                  _buildSectionTitle(context, 'Encendido', Icons.power_settings_new),
                  const SizedBox(height: 12),
                  _buildInstructionCard(
                    context,
                    steps: [
                      'Mantenga pulsado el botón POWER durante 2 segundos para encender el panel de control.',
                      'El panel se iluminará cuando esté activo.',
                      'Para apagarlo, vuelva a presionar el botón POWER.',
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sección: Bloqueo del panel
                  _buildSectionTitle(context, 'Bloqueo del panel', Icons.lock),
                  const SizedBox(height: 12),
                  _buildInstructionCard(
                    context,
                    steps: [
                      'El panel de control puede bloquearse automáticamente tras un corto periodo de inactividad. Cuando esto ocurra aparecerá la palabra LOCK en la pantalla.',
                    ],
                    subSections: [
                      _SubSection(
                        title: 'Para desbloquear el panel:',
                        steps: ['Mantenga presionado el botón OK durante 3 segundos.'],
                      ),
                      _SubSection(
                        title: 'Para bloquearlo manualmente:',
                        steps: ['Mantenga presionado el botón OK durante 3 segundos.'],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sección: Función Ozono
                  _buildSectionTitle(context, 'Función Ozono', Icons.bubble_chart),
                  const SizedBox(height: 12),
                  _buildInstructionCard(
                    context,
                    introText: 'El sistema de ozono se utiliza para la desinfección del agua.',
                    steps: [
                      'Utilice los botones IZQUIERDA o DERECHA para seleccionar OZONO.',
                      'Confirme pulsando OK.',
                      'El ozonador comenzará a funcionar.',
                      'Para detenerlo, pulse OK nuevamente.',
                    ],
                    note: 'El ozonador se apagará automáticamente después de 10 minutos si no se vuelve a activar.',
                  ),
                  const SizedBox(height: 24),

                  // Sección: Funciones de masaje
                  _buildSectionTitle(context, 'Funciones de masaje', Icons.hot_tub),
                  const SizedBox(height: 12),

                  // Jets de aire
                  _buildMassageCard(
                    context,
                    title: 'Jets de aire',
                    icon: Icons.air,
                    steps: [
                      'Utilice IZQUIERDA o DERECHA para seleccionar JET AIRE.',
                      'Confirme pulsando OK.',
                      'Las burbujas comenzarán a funcionar.',
                      'Para detenerlas, pulse OK nuevamente.',
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Jets de agua
                  _buildMassageCard(
                    context,
                    title: 'Jets de agua',
                    icon: Icons.water_drop,
                    steps: [
                      'Utilice IZQUIERDA o DERECHA para seleccionar JET AGUA.',
                      'Confirme pulsando OK.',
                      'Los chorros de agua comenzarán a funcionar.',
                      'Para detenerlos, pulse OK nuevamente.',
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
        border: Border.all(
          color: AppColors.gold,
          width: 3,
        ),
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
        child: Image.asset(
          'assets/images/jacuzzi.png',
          fit: BoxFit.cover,
        ),
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
        Icon(
          icon,
          color: AppColors.gold,
          size: 22,
        ),
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
        border: Border.all(
          color: AppColors.goldWithAlpha30,
        ),
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
            ...subSections.map((sub) => Padding(
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
                )),

          // Nota
          if (note != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.goldWithAlpha10,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.goldWithAlpha30,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.gold,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nota: $note',
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
          padding: EdgeInsets.only(
            bottom: index == steps.length - 1 ? 0 : 12,
          ),
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
        border: Border.all(
          color: AppColors.goldWithAlpha30,
        ),
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
                child: Icon(
                  icon,
                  color: AppColors.gold,
                  size: 24,
                ),
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
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.4),
        ),
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
                'Importante',
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
            'Los jets solo funcionan si el nivel de agua ha alcanzado el mínimo necesario.',
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
                  'Si el nivel de agua baja demasiado:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                _buildBulletPoint(context, 'Los jets se detendrán automáticamente.'),
                _buildBulletPoint(context, 'El icono parpadeará en el panel.'),
                const SizedBox(height: 8),
                Text(
                  'Cuando el nivel de agua vuelva a ser el adecuado, los jets volverán a funcionar con normalidad.',
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
        border: Border.all(
          color: AppColors.goldWithAlpha30,
        ),
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
                'Uso responsable del agua',
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
            'Una vez utilizado el jacuzzi y vaciado el agua, será necesario esperar aproximadamente 2 horas para que las calderas vuelvan a calentar toda el agua necesaria para llenarlo nuevamente.',
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
                Icon(
                  Icons.opacity,
                  color: AppColors.gold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Capacidad aproximada:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '300 litros',
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
            'La normativa actual sobre el consumo de agua nos obliga a todos a ser responsables con su utilización.',
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
                Icon(
                  Icons.favorite,
                  color: AppColors.gold,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gracias por su comprensión y colaboración.',
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

  const _SubSection({
    required this.title,
    required this.steps,
  });
}
