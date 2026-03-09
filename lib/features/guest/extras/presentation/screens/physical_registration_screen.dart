import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bf_stay/core/theme/app_colors.dart';

/// Pantalla para mostrar las indicaciones del registro físico en habitaciones de hotel
class PhysicalRegistrationScreen extends StatelessWidget {
  const PhysicalRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
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
          'Registro Físico',
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
              // Header con icono
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hotel_outlined,
                    size: 64,
                    color: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Título
              Center(
                child: Column(
                  children: [
                    Text(
                      'Registro Físico en Habitación',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Indicaciones para completar tu registro',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getTextSecondaryColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Instrucciones principales
              _buildSectionTitle(context, 'Instrucciones'),
              const SizedBox(height: 16),

              _buildInstructionCard(
                context,
                stepNumber: 1,
                title: 'Dirígete a recepción',
                description: 'Acude al mostrador de recepción del hotel para realizar el registro presencial.',
                icon: Icons.room_service_outlined,
              ),
              const SizedBox(height: 12),

              _buildInstructionCard(
                context,
                stepNumber: 2,
                title: 'Presenta tu documento',
                description: 'Entrega tu DNI, pasaporte o documento de identidad válido para el registro.',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 12),

              _buildInstructionCard(
                context,
                stepNumber: 3,
                title: 'Firma el registro',
                description: 'Firma el formulario de registro de huéspedes que te entregará el personal.',
                icon: Icons.draw_outlined,
              ),
              const SizedBox(height: 12),

              _buildInstructionCard(
                context,
                stepNumber: 4,
                title: 'Recibe tu llave',
                description: 'Una vez completado el registro, recibirás la llave de tu habitación.',
                icon: Icons.vpn_key_outlined,
              ),
              const SizedBox(height: 32),

              // Horarios de recepción
              _buildSectionTitle(context, 'Horario de Recepción'),
              const SizedBox(height: 16),
              _buildScheduleCard(context),
              const SizedBox(height: 32),

              // Documentos aceptados
              _buildSectionTitle(context, 'Documentos Aceptados'),
              const SizedBox(height: 16),
              _buildDocumentsCard(context),
              const SizedBox(height: 32),

              // Nota importante
              _buildImportantNoteCard(context),
              const SizedBox(height: 24),
            ],
          ),
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
            color: AppColors.gold,
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

  Widget _buildInstructionCard(
    BuildContext context, {
    required int stepNumber,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Número de paso
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Contenido
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
                    fontSize: 14,
                    color: AppColors.getTextSecondaryColor(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Icono
          Icon(
            icon,
            color: AppColors.gold,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.gray50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(context),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: AppColors.gold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Horario de atención',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildScheduleRow(context, 'Lunes - Viernes', '08:00 - 22:00'),
          const Divider(height: 24),
          _buildScheduleRow(context, 'Sábados', '09:00 - 21:00'),
          const Divider(height: 24),
          _buildScheduleRow(context, 'Domingos y Festivos', '10:00 - 20:00'),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(BuildContext context, String day, String hours) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          day,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.getTextSecondaryColor(context),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            hours,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsCard(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    final documents = [
      {'icon': Icons.credit_card_outlined, 'name': 'DNI / NIE'},
      {'icon': Icons.book_outlined, 'name': 'Pasaporte'},
      {'icon': Icons.card_travel_outlined, 'name': 'Carnet de conducir (UE)'},
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
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: documents.map((doc) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  doc['icon'] as IconData,
                  color: AppColors.gold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  doc['name'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImportantNoteCard(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.info,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Información importante',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• El registro físico es obligatorio según la normativa vigente.\n'
            '• Todos los huéspedes mayores de 16 años deben registrarse.\n'
            '• Si llegas fuera del horario de recepción, contacta con antelación para organizar tu llegada.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.white : AppColors.gray700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
