import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/features/guest/extras/domain/entities/extra_request_entity.dart';

/// Tarjeta de una solicitud de extra en el listado del admin.
class ExtraRequestCard extends StatelessWidget {
  const ExtraRequestCard({
    super.key,
    required this.request,
    required this.onMarkManaged,
    required this.onDelete,
  });

  final ExtraRequestEntity request;
  final VoidCallback onMarkManaged;

  /// Elimina definitivamente la solicitud.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy · HH:mm').format(request.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getGoldWithAlpha(context, alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard, color: AppColors.gold, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.extraName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
              ),
              _StatusBadge(status: request.status),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.error,
                tooltip: 'Eliminar solicitud',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (request.guestName != null && request.guestName!.isNotEmpty)
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Huésped',
              value: request.guestName!,
            ),
          if (request.unitName != null && request.unitName!.isNotEmpty)
            _InfoRow(
              icon: Icons.home_outlined,
              label: 'Unidad',
              value: request.unitName!,
            ),
          _InfoRow(
            icon: Icons.schedule,
            label: 'Solicitado',
            value: dateStr,
          ),
          if (request.price != null)
            _InfoRow(
              icon: Icons.euro,
              label: 'Precio',
              value: '${request.price!.toStringAsFixed(2)} €',
            ),
          if (request.isRequested) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onMarkManaged,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                label: const Text(
                  'Marcar como gestionada',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.getTextSecondaryColor(context)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ExtraRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      ExtraRequestStatus.requested => (AppColors.warning, 'Solicitado'),
      ExtraRequestStatus.managed => (AppColors.success, 'Gestionado'),
      ExtraRequestStatus.cancelled => (AppColors.error, 'Cancelado'),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
