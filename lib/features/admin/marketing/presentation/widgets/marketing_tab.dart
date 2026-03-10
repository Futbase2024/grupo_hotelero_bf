import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/di/injection.dart';
import 'campaigns_section.dart';
import 'automations_section.dart';
import 'crm_section.dart';

/// Tab de Marketing del panel de administración.
/// Incluye:
/// - Métricas de comunicaciones
/// - Gestión de campañas
/// - Automatizaciones
/// - CRM de huéspedes
class MarketingTab extends StatefulWidget {
  const MarketingTab({
    super.key,
    required this.propertyId,
    required this.userId,
  });

  final String propertyId;
  final String userId;

  @override
  State<MarketingTab> createState() => _MarketingTabState();
}

class _MarketingTabState extends State<MarketingTab> {
  List<Map<String, String>> _properties = [];
  String? _selectedPropertyId;
  bool _isLoadingProperties = true;

  @override
  void initState() {
    super.initState();
    _selectedPropertyId = widget.propertyId.isNotEmpty ? widget.propertyId : null;
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    try {
      final response = await getIt<SupabaseClient>()
          .from('properties')
          .select('id, name')
          .order('name');

      final properties = (response as List).map((p) {
        return {
          'id': p['id'] as String,
          'name': p['name'] as String,
        };
      }).toList();

      setState(() {
        _properties = properties;
        _isLoadingProperties = false;
        // Si no hay propiedad seleccionada y hay propiedades, seleccionar la primera
        if (_selectedPropertyId == null && properties.isNotEmpty) {
          _selectedPropertyId = properties.first['id'];
        }
      });
    } catch (e) {
      debugPrint('Error loading properties: $e');
      setState(() {
        _isLoadingProperties = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),
          const SizedBox(height: 24),

          // Selector de propiedad (solo si no hay propertyId inicial)
          if (widget.propertyId.isEmpty) ...[
            _buildPropertySelector(context),
            const SizedBox(height: 24),
          ],

          // KPIs de comunicaciones
          _buildMetricsGrid(context),
          const SizedBox(height: 24),

          // Sección de Campañas
          CampaignsSection(
            propertyId: _selectedPropertyId ?? '',
            userId: widget.userId,
          ),
          const SizedBox(height: 24),

          // Sección de Automatizaciones
          const AutomationsSection(),
          const SizedBox(height: 24),

          // Sección de CRM
          const CrmSection(),
        ],
      ),
    );
  }

  Widget _buildPropertySelector(BuildContext context) {
    if (_isLoadingProperties) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.getBorderColor(context)),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.gold,
            ),
          ),
        ),
      );
    }

    if (_properties.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.getBorderColor(context)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No hay propiedades disponibles',
                style: TextStyle(
                  color: AppColors.getTextSecondaryColor(context),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.apartment_outlined, size: 18, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(
                'Alojamiento',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.getTextSecondaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedPropertyId,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.getInputBackgroundColor(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            dropdownColor: AppColors.getCardColor(context),
            style: TextStyle(
              color: AppColors.getTextPrimaryColor(context),
              fontSize: 14,
            ),
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.gold),
            items: _properties.map((p) {
              return DropdownMenuItem(
                value: p['id'],
                child: Text(p['name']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPropertyId = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Marketing',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Gestiona campañas y comunicaciones',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.getTextSecondaryColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comunicaciones este mes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.email_outlined,
                  value: '0',
                  label: 'Emails enviados',
                  subtitle: 'Sin datos',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.notifications_active_outlined,
                  value: '0',
                  label: 'Push enviados',
                  subtitle: 'Sin datos',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tarjeta de métrica individual
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.subtitle,
  });

  final IconData icon;
  final String value;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorderColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.goldWithAlpha20,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.getTextSecondaryColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
