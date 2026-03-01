import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/repositories/admin_panel_repository.dart';

/// Bottom sheet para editar el código de la puerta principal de una propiedad
class EditMainDoorKeycodeBottomSheet extends StatefulWidget {
  const EditMainDoorKeycodeBottomSheet({
    super.key,
    required this.propertyId,
    required this.propertyName,
    required this.repository,
    this.currentKeycode,
  });

  final String propertyId;
  final String propertyName;
  final AdminPanelRepository repository;
  final String? currentKeycode;

  /// Muestra el bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String propertyId,
    required String propertyName,
    required AdminPanelRepository repository,
    String? currentKeycode,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditMainDoorKeycodeBottomSheet(
        propertyId: propertyId,
        propertyName: propertyName,
        repository: repository,
        currentKeycode: currentKeycode,
      ),
    );
  }

  @override
  State<EditMainDoorKeycodeBottomSheet> createState() =>
      _EditMainDoorKeycodeBottomSheetState();
}

class _EditMainDoorKeycodeBottomSheetState
    extends State<EditMainDoorKeycodeBottomSheet> {
  late final TextEditingController _keycodeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _keycodeController = TextEditingController(
      text: widget.currentKeycode ?? '',
    );
  }

  @override
  void dispose() {
    _keycodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final keycode = _keycodeController.text.trim();

    if (keycode.isEmpty) {
      _showError('El código es obligatorio');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.repository.updatePropertyMainDoorKeycode(
        propertyId: widget.propertyId,
        keycode: keycode,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código de puerta actualizado correctamente'),
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
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: const Icon(
                        Icons.door_front_door_outlined,
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
                            'Código Puerta Principal',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                          Text(
                            widget.propertyName,
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

                // Info text
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: AppColors.goldWithAlpha10,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: AppColors.goldWithAlpha30,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.gold,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: Text(
                          'Este código es para la puerta principal del edificio. Se mostrará a los huéspedes en "Mi Alojamiento".',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.gray300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacing20),

                // Keycode field
                const Text(
                  'Código de acceso',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray300,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                TextField(
                  controller: _keycodeController,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  decoration: InputDecoration(
                    hintText: '123456',
                    hintStyle: TextStyle(
                      color: AppColors.gray500,
                      fontWeight: FontWeight.normal,
                      letterSpacing: 0,
                    ),
                    counterText: '',
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
                const SizedBox(height: AppTheme.spacing32),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.gray300,
                          side: const BorderSide(color: AppColors.gray600),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
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
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
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
