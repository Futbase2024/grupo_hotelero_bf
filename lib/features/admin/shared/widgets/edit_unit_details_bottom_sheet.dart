import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/admin_unit_entity.dart';
import '../../domain/repositories/admin_panel_repository.dart';

/// Bottom sheet para editar los datos de WiFi y Box Code de una unidad
class EditUnitDetailsBottomSheet extends StatefulWidget {
  const EditUnitDetailsBottomSheet({
    super.key,
    required this.unit,
    required this.repository,
  });

  final AdminUnitEntity unit;
  final AdminPanelRepository repository;

  /// Muestra el bottom sheet
  static Future<void> show({
    required BuildContext context,
    required AdminUnitEntity unit,
    required AdminPanelRepository repository,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditUnitDetailsBottomSheet(
        unit: unit,
        repository: repository,
      ),
    );
  }

  @override
  State<EditUnitDetailsBottomSheet> createState() => _EditUnitDetailsBottomSheetState();
}

class _EditUnitDetailsBottomSheetState extends State<EditUnitDetailsBottomSheet> {
  late final TextEditingController _networkController;
  late final TextEditingController _passwordController;
  late final TextEditingController _boxCodeController;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _networkController = TextEditingController(
      text: widget.unit.wifiNetwork ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.unit.wifiPassword ?? '',
    );
    _boxCodeController = TextEditingController(
      text: widget.unit.boxCode ?? '',
    );
  }

  @override
  void dispose() {
    _networkController.dispose();
    _passwordController.dispose();
    _boxCodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final network = _networkController.text.trim();
    final password = _passwordController.text.trim();
    final boxCode = _boxCodeController.text.trim();

    setState(() => _isLoading = true);

    try {
      // Actualizar WiFi si se proporcionó
      if (network.isNotEmpty && password.isNotEmpty) {
        await widget.repository.updateUnitWifi(
          unitId: widget.unit.id,
          wifiNetwork: network,
          wifiPassword: password,
        );
      }

      // Actualizar código de caja si se proporcionó
      if (boxCode.isNotEmpty) {
        await widget.repository.updateUnitBoxCode(
          unitId: widget.unit.id,
          boxCode: boxCode,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos actualizados correctamente'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Error al guardar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
                    decoration: BoxDecoration(
                      color: AppColors.gray600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing12),
                      decoration: BoxDecoration(
                        color: AppColors.goldWithAlpha20,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: AppColors.gold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Editar Detalles',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                          Text(
                            widget.unit.name,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.gray400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing24),

                // Box Code field
                const Text(
                  'Código de Caja (Keybox)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray300,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                TextField(
                  controller: _boxCodeController,
                  style: const TextStyle(color: AppColors.white),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Ej: 1234',
                    hintStyle: TextStyle(color: AppColors.gray500),
                    filled: true,
                    fillColor: AppColors.darkBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: const BorderSide(color: AppColors.darkBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: const BorderSide(color: AppColors.darkBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_open_outlined,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),

                // WiFi Section Header
                Row(
                  children: [
                    Icon(
                      Icons.wifi,
                      color: AppColors.gray400,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'WiFi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray300,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing12),

                // Network name field
                const Text(
                  'Nombre de la red',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray300,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                TextField(
                  controller: _networkController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: 'Ej: MiRed_WiFi',
                    hintStyle: TextStyle(color: AppColors.gray500),
                    filled: true,
                    fillColor: AppColors.darkBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: const BorderSide(color: AppColors.darkBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: const BorderSide(color: AppColors.darkBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                    prefixIcon: const Icon(
                      Icons.wifi_outlined,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Password field
                const Text(
                  'Contraseña',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray300,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: 'Contraseña del WiFi',
                    hintStyle: TextStyle(color: AppColors.gray500),
                    filled: true,
                    fillColor: AppColors.darkBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: const BorderSide(color: AppColors.darkBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: const BorderSide(color: AppColors.darkBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.gray500,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.gray500,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing32),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.gray300,
                          side: const BorderSide(color: AppColors.gray600),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.black,
                          disabledBackgroundColor: AppColors.gray700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.black,
                                ),
                              )
                            : const Text(
                                'Guardar',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
