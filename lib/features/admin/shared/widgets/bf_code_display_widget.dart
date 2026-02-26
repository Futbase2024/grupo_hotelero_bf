import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';

/// Widget reutilizable para mostrar el código BF de forma destacada.
/// Usado en CreateBookingBottomSheet y BookingDetailScreen.
class BfCodeDisplayWidget extends StatefulWidget {
  const BfCodeDisplayWidget({
    super.key,
    required this.code,
    this.showActions = true,
    this.checkInDate,
    this.checkOutDate,
  });

  final String code;
  final bool showActions;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;

  @override
  State<BfCodeDisplayWidget> createState() => _BfCodeDisplayWidgetState();
}

class _BfCodeDisplayWidgetState extends State<BfCodeDisplayWidget> {
  bool _copied = false;

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.code));
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _shareCode() {
    final checkIn = _formatDate(widget.checkInDate);
    final checkOut = _formatDate(widget.checkOutDate);

    String message = 'Tu código de acceso BF-Stay: ${widget.code}';
    if (checkIn.isNotEmpty && checkOut.isNotEmpty) {
      message += '\nEntrada: $checkIn · Salida: $checkOut';
    }
    message += '\nDescarga la app BF-Stay e introduce este código.';

    HapticFeedback.lightImpact();
    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'Código de acceso para el huésped',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.getTextSecondaryColor(context),
          ),
        ),
        const SizedBox(height: 12),

        // Code display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.goldWithAlpha20,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.goldWithAlpha40,
              width: 1,
            ),
          ),
          child: Text(
            widget.code,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
              letterSpacing: 4,
            ),
          ),
        ),

        // Actions
        if (widget.showActions) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: _copied ? Icons.check : Icons.copy_outlined,
                  label: _copied ? 'Copiado' : 'Copiar código',
                  onTap: _copyToClipboard,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.share_outlined,
                  label: 'Compartir',
                  onTap: _shareCode,
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary ? AppColors.gold : AppColors.goldWithAlpha40,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary ? AppColors.black : AppColors.gold,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isPrimary ? AppColors.black : AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
