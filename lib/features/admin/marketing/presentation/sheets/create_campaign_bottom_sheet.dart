import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/campaign_entity.dart';

/// Bottom sheet para crear una nueva campaña de marketing
class CreateCampaignBottomSheet extends StatefulWidget {
  const CreateCampaignBottomSheet({
    super.key,
    required this.propertyId,
    required this.userId,
    this.onSave,
  });

  final String propertyId;
  final String userId;
  final Future<void> Function(CampaignEntity campaign)? onSave;

  /// Método estático para mostrar el bottom sheet
  static Future<void> show(
    BuildContext context, {
    required String propertyId,
    required String userId,
    Future<void> Function(CampaignEntity campaign)? onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateCampaignBottomSheet(
        propertyId: propertyId,
        userId: userId,
        onSave: onSave,
      ),
    );
  }

  @override
  State<CreateCampaignBottomSheet> createState() => _CreateCampaignBottomSheetState();
}

class _CreateCampaignBottomSheetState extends State<CreateCampaignBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  CampaignType _selectedType = CampaignType.email;
  bool _scheduleEnabled = false;
  DateTime? _scheduledAt;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final campaign = CampaignEntity(
        id: const Uuid().v4(),
        propertyId: widget.propertyId,
        name: _nameController.text.trim(),
        type: _selectedType,
        status: _scheduleEnabled ? CampaignStatus.scheduled : CampaignStatus.draft,
        content: _contentController.text.trim(),
        subject: _selectedType == CampaignType.email
            ? _subjectController.text.trim()
            : null,
        scheduledAt: _scheduleEnabled ? _scheduledAt : null,
        createdAt: DateTime.now(),
        createdBy: widget.userId,
      );

      if (widget.onSave != null) {
        await widget.onSave!(campaign);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
        setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear campaña: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _selectDateTime() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      setState(() => _scheduledAt = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray500,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nueva campaña',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: AppColors.gray500,
                ),
              ],
            ),
          ),

          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Nombre de la campaña
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nombre de la campaña',
                      hint: 'Ej: Bienvenida verano 2024',
                      icon: Icons.campaign_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Tipo de campaña
                    Text(
                      'Tipo de campaña',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.getTextSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTypeSelector(context),

                    const SizedBox(height: 20),

                    // Asunto (solo para email)
                    if (_selectedType == CampaignType.email) ...[
                      _buildTextField(
                        controller: _subjectController,
                        label: 'Asunto del email',
                        hint: 'Ej: ¡Tu próximo viaje te espera!',
                        icon: Icons.subject_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El asunto es obligatorio para emails';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Contenido
                    _buildTextField(
                      controller: _contentController,
                      label: 'Contenido del mensaje',
                      hint: 'Escribe el contenido de tu campaña...',
                      icon: Icons.message_outlined,
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El contenido es obligatorio';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Programar envío
                    _buildScheduleToggle(context),

                    if (_scheduleEnabled) ...[
                      const SizedBox(height: 16),
                      _buildDateTimeSelector(context),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Botón Crear
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceColor(context),
              border: Border(
                top: BorderSide(
                  color: AppColors.getBorderColor(context),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.black,
                          ),
                        )
                      : const Text(
                          'Crear campaña',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.gold),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.getTextSecondaryColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.gray500,
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppColors.getInputBackgroundColor(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.getBorderColor(context),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.gold,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.error,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildTypeSelector(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: CampaignType.values.map((type) {
        final isSelected = _selectedType == type;
        return ChoiceChip(
          label: Text(type.displayName),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedType = type);
            }
          },
          selectedColor: AppColors.gold,
          backgroundColor: AppColors.getCardColor(context),
        );
      }).toList(),
    );
  }

  Widget _buildScheduleToggle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorderColor(context),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 20,
            color: AppColors.gold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Programar envío',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
                Text(
                  'Envía la campaña automáticamente en la fecha seleccionada',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _scheduleEnabled,
            onChanged: (value) {
              setState(() {
                _scheduleEnabled = value;
                if (!value) {
                  _scheduledAt = null;
                }
              });
            },
            activeTrackColor: AppColors.gold.withValues(alpha: 0.5),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.gold;
              }
              return AppColors.gray500;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelector(BuildContext context) {
    final formattedDate = _scheduledAt != null
        ? '${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year} a las ${_scheduledAt!.hour}:${_scheduledAt!.minute.toString().padLeft(2, '0')}'
        : 'Seleccionar fecha y hora';

    return InkWell(
      onTap: _selectDateTime,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.goldWithAlpha20,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: AppColors.gold,
            ),
            const SizedBox(width: 12),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.gold,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.gold,
            ),
          ],
        ),
      ),
    );
  }
}
