import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/di/injection.dart';
import '../../../domain/entities/admin_unit_entity.dart';
import '../../../domain/repositories/admin_panel_repository.dart';
import '../../../shared/widgets/admin_widgets.dart';
import '../../../shared/widgets/edit_unit_details_bottom_sheet.dart';
import '../../../shared/widgets/edit_main_door_keycode_bottom_sheet.dart';

/// Tab de propiedades del dashboard de administración
/// Muestra todas las unidades con su información de WiFi
class PropertiesTab extends StatefulWidget {
  const PropertiesTab({super.key});

  @override
  State<PropertiesTab> createState() => _PropertiesTabState();
}

class _PropertiesTabState extends State<PropertiesTab> {
  List<AdminUnitEntity> _units = [];
  Map<String, String> _propertyNames = {};
  Map<String, String?> _propertyKeycodes = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🏠 [PropertiesTab] Cargando datos...');

      // Cargar propiedades para obtener nombres y keycodes
      final propertiesResponse = await getIt<SupabaseClient>()
          .from('properties')
          .select('id, name, main_door_keycode');

      final propertyMap = <String, String>{};
      final keycodeMap = <String, String?>{};
      for (final p in propertiesResponse) {
        propertyMap[p['id'] as String] = p['name'] as String;
        keycodeMap[p['id'] as String] = p['main_door_keycode'] as String?;
      }
      debugPrint('✅ [PropertiesTab] ${propertyMap.length} propiedades cargadas');

      // Cargar todas las unidades
      final unitsResponse = await getIt<SupabaseClient>()
          .from('units')
          .select('''
            id,
            property_id,
            name,
            unit_type,
            address_line1,
            city,
            postal_code,
            box_code,
            access_instructions,
            wifi_network,
            wifi_password,
            created_at
          ''')
          .order('name');

      debugPrint('✅ [PropertiesTab] ${unitsResponse.length} unidades encontradas');

      final units = <AdminUnitEntity>[];
      for (final e in unitsResponse) {
        try {
          units.add(AdminUnitEntity.fromJson(e));
        } catch (parseError) {
          debugPrint('⚠️ [PropertiesTab] Error parseando unidad: $parseError');
          debugPrint('⚠️ [PropertiesTab] Datos: $e');
        }
      }

      debugPrint('✅ [PropertiesTab] ${units.length} unidades parseadas correctamente');

      setState(() {
        _propertyNames = propertyMap;
        _propertyKeycodes = keycodeMap;
        _units = units;
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('❌ [PropertiesTab] Error loading data: $e');
      debugPrint('❌ [PropertiesTab] StackTrace: $s');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(context),

          // Units list
          Expanded(
            child: _buildUnitsList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Text(
            'Alojamientos',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppColors.white,
            ),
          ),
          const Spacer(),
          Text(
            '${_units.length} unidades',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.gray400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsList(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar datos',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.gray400,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.black,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_propertyNames.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.home_work_outlined,
        title: 'Sin propiedades',
        subtitle: 'No hay propiedades configuradas',
      );
    }

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.darkSurface,
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Sección de Propiedades con keycode
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Códigos de Puerta Principal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray300,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final propertyId = _propertyNames.keys.elementAt(index);
                final propertyName = _propertyNames[propertyId]!;
                final keycode = _propertyKeycodes[propertyId];
                return _PropertyKeycodeCard(
                  propertyName: propertyName,
                  keycode: keycode,
                  onEdit: () => _showEditKeycodeSheet(propertyId, propertyName, keycode),
                );
              },
              childCount: _propertyNames.length,
            ),
          ),

          // Separador
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Unidades',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray300,
                ),
              ),
            ),
          ),
          // Lista de Unidades
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final unit = _units[index];
                final propertyName = _propertyNames[unit.propertyId] ?? 'Propiedad';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _UnitCard(
                    unit: unit,
                    propertyName: propertyName,
                    onEditDetails: () => _showEditDetailsSheet(unit),
                  ),
                );
              },
              childCount: _units.length,
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  void _showEditDetailsSheet(AdminUnitEntity unit) {
    EditUnitDetailsBottomSheet.show(
      context: context,
      unit: unit,
      repository: getIt<AdminPanelRepository>(),
    ).then((_) {
      // Recargar datos después de editar
      _loadData();
    });
  }

  void _showEditKeycodeSheet(String propertyId, String propertyName, String? currentKeycode) {
    EditMainDoorKeycodeBottomSheet.show(
      context: context,
      propertyId: propertyId,
      propertyName: propertyName,
      repository: getIt<AdminPanelRepository>(),
      currentKeycode: currentKeycode,
    ).then((_) {
      // Recargar datos después de editar
      _loadData();
    });
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.propertyName,
    required this.onEditDetails,
  });

  final AdminUnitEntity unit;
  final String propertyName;
  final VoidCallback onEditDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.meeting_room_outlined,
                  color: AppColors.gold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      propertyName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray400,
                      ),
                    ),
                  ],
                ),
              ),
              // Tipo de unidad badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gray800,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getUnitTypeLabel(unit.unitType),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.gray400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.darkBorder),
          const SizedBox(height: 12),

          // Box Code info
          Row(
            children: [
              Icon(
                Icons.lock_open_outlined,
                color: unit.hasBoxCode ? AppColors.success : AppColors.gray500,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  unit.hasBoxCode
                      ? 'Código: ${unit.boxCode}'
                      : 'Código de caja no configurado',
                  style: TextStyle(
                    fontSize: 14,
                    color: unit.hasBoxCode ? AppColors.gray300 : AppColors.gray500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // WiFi info
          Row(
            children: [
              Icon(
                Icons.wifi_outlined,
                color: unit.hasWifi ? AppColors.success : AppColors.gray500,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  unit.hasWifi
                      ? 'Red: ${unit.wifiNetwork}'
                      : 'WiFi no configurado',
                  style: TextStyle(
                    fontSize: 14,
                    color: unit.hasWifi ? AppColors.gray300 : AppColors.gray500,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onEditDetails,
                icon: Icon(
                  Icons.edit,
                  color: AppColors.gold,
                  size: 18,
                ),
                label: Text(
                  'Editar',
                  style: const TextStyle(color: AppColors.gold, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getUnitTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'apartment':
        return 'Apartamento';
      case 'house':
        return 'Casa';
      case 'hotel_room':
        return 'Habitación';
      case 'suite':
        return 'Suite';
      case 'villa':
        return 'Villa';
      case 'studio':
        return 'Estudio';
      default:
        return type;
    }
  }
}

/// Tarjeta para mostrar y editar el keycode de una propiedad
class _PropertyKeycodeCard extends StatelessWidget {
  const _PropertyKeycodeCard({
    required this.propertyName,
    required this.keycode,
    required this.onEdit,
  });

  final String propertyName;
  final String? keycode;
  final VoidCallback onEdit;

  bool get hasKeycode => keycode != null && keycode!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasKeycode ? AppColors.success.withValues(alpha: 0.3) : AppColors.darkBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasKeycode
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.goldWithAlpha10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.door_front_door_outlined,
              color: hasKeycode ? AppColors.success : AppColors.gold,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  propertyName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasKeycode ? 'Código: $keycode' : 'Sin código configurado',
                  style: TextStyle(
                    fontSize: 14,
                    color: hasKeycode ? AppColors.success : AppColors.gray500,
                    fontWeight: hasKeycode ? FontWeight.w600 : FontWeight.normal,
                    letterSpacing: hasKeycode ? 2 : 0,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onEdit,
            icon: Icon(
              hasKeycode ? Icons.edit : Icons.add,
              color: AppColors.gold,
              size: 18,
            ),
            label: Text(
              hasKeycode ? 'Editar' : 'Añadir',
              style: const TextStyle(color: AppColors.gold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
