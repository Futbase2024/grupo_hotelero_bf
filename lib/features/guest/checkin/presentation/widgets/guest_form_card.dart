import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/guest_entity.dart';

/// Card que muestra el formulario de un huésped
class GuestFormCard extends StatelessWidget {
  const GuestFormCard({
    super.key,
    required this.guest,
    required this.index,
    required this.onChanged,
    this.onDocumentUpload,
  });

  final GuestEntity guest;
  final int index;
  final ValueChanged<GuestEntity> onChanged;
  final VoidCallback? onDocumentUpload;

  @override
  Widget build(BuildContext context) {
    // Si es un niño menor de 14 años, mostrar solo información readonly
    if (guest.isChildUnder14) {
      return _buildReadOnlyCard(context);
    }

    return _buildEditableCard(context);
  }

  Widget _buildReadOnlyCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.child_care,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guest.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      S.of(context).guest_checkin_child_no_data,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: guest.isPrimary ? AppColors.gold : AppColors.darkBorder,
          width: guest.isPrimary ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con tipo y badge
          Row(
            children: [
              Icon(
                guest.isAdult ? Icons.person : Icons.child_care,
                color: guest.isPrimary ? AppColors.gold : AppColors.gray500,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getHeaderTitle(context),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: guest.isPrimary ? AppColors.gold : AppColors.white,
                  ),
                ),
              ),
              if (guest.isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.goldWithAlpha20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    S.of(context).guest_checkin_holder,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Campos del formulario
          _buildTextField(
            context: context,
            label: S.of(context).guest_checkin_full_name,
            value: guest.fullName,
            onChanged: (value) => onChanged(guest.copyWith(fullName: value)),
            isRequired: true,
          ),

          if (!guest.isPrimary) ...[
            const SizedBox(height: 12),
            _buildTextField(
              context: context,
              label: S.of(context).guest_checkin_email,
              value: guest.email ?? '',
              onChanged: (value) => onChanged(guest.copyWith(email: value.isEmpty ? null : value)),
              keyboardType: TextInputType.emailAddress,
            ),
          ],

          const SizedBox(height: 12),
          _buildTextField(
            context: context,
            label: S.of(context).guest_checkin_phone,
            value: guest.phone ?? '',
            onChanged: (value) => onChanged(guest.copyWith(phone: value.isEmpty ? null : value)),
            keyboardType: TextInputType.phone,
          ),

          // Documento (solo si necesita)
          if (guest.needsDocument) ...[
            const SizedBox(height: 16),
            _buildDocumentSection(context),
          ],
        ],
      ),
    );
  }

  String _getHeaderTitle(BuildContext context) {
    if (guest.isPrimary) return guest.fullName.isEmpty ? S.of(context).guest_checkin_holder : guest.fullName;
    if (guest.isChildOver14) return S.of(context).guest_checkin_young(guest.age ?? 0);
    if (guest.isAdult) return S.of(context).guest_checkin_adult(index + 1);
    return S.of(context).guest_checkin_guest(index + 1);
  }

  Widget _buildTextField({
    required BuildContext context,
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.white),
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: const TextStyle(color: AppColors.gray500),
        filled: true,
        fillColor: AppColors.darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
      ),
    );
  }

  Widget _buildDocumentSection(BuildContext context) {
    final hasDocument = guest.documentNumber != null && guest.documentNumber!.isNotEmpty;
    final hasImage = guest.hasDocumentImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              S.of(context).guest_checkin_document_id,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (hasDocument && hasImage)
          _buildDocumentComplete(context)
        else if (hasDocument)
          _buildDocumentWithoutImage(context)
        else
          _buildDocumentUploadButton(context),
      ],
    );
  }

  Widget _buildDocumentUploadButton(BuildContext context) {
    return InkWell(
      onTap: onDocumentUpload,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_file,
              color: AppColors.gold,
            ),
            const SizedBox(width: 8),
            Text(
              S.of(context).guest_checkin_upload_document,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Documento completo con foto
  Widget _buildDocumentComplete(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guest.documentType?.name.toUpperCase() ?? S.of(context).guest_checkin_document,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  guest.documentNumber ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          if (onDocumentUpload != null)
            IconButton(
              icon: Icon(
                Icons.edit,
                color: AppColors.gray500,
                size: 20,
              ),
              onPressed: onDocumentUpload,
            ),
        ],
      ),
    );
  }

  /// Documento sin foto - muestra advertencia
  Widget _buildDocumentWithoutImage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${guest.documentType?.name.toUpperCase() ?? S.of(context).guest_checkin_document}: ${guest.documentNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  S.of(context).guest_checkin_missing_photo,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          if (onDocumentUpload != null)
            IconButton(
              icon: Icon(
                Icons.camera_alt,
                color: AppColors.warning,
                size: 20,
              ),
              onPressed: onDocumentUpload,
            ),
        ],
      ),
    );
  }
}
