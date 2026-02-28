import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';

/// Widget reutilizable para mostrar el código BF y KeyBox de forma destacada.
/// Usado en CreateBookingBottomSheet y BookingDetailScreen.
class BfCodeDisplayWidget extends StatefulWidget {
  const BfCodeDisplayWidget({
    super.key,
    required this.code,
    this.keyboxCode,
    this.showActions = true,
    this.checkInDate,
    this.checkOutDate,
  });

  final String code;
  final String? keyboxCode;
  final bool showActions;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;

  @override
  State<BfCodeDisplayWidget> createState() => _BfCodeDisplayWidgetState();
}

class _BfCodeDisplayWidgetState extends State<BfCodeDisplayWidget> {
  bool _copiedBooking = false;
  bool _copiedKeybox = false;

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _copyToClipboard(String text, bool isKeybox) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    setState(() {
      if (isKeybox) {
        _copiedKeybox = true;
      } else {
        _copiedBooking = true;
      }
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _copiedBooking = false;
          _copiedKeybox = false;
        });
      }
    });
  }

  void _shareCode() {
    final checkIn = _formatDate(widget.checkInDate);
    final checkOut = _formatDate(widget.checkOutDate);

    String message = 'Tu código de acceso BF-Stay: ${widget.code}';
    if (widget.keyboxCode != null && widget.keyboxCode!.isNotEmpty) {
      message += '\nCódigo KeyBox: ${widget.keyboxCode}';
    }
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
          'Códigos de acceso para el huésped',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.getTextSecondaryColor(context),
          ),
        ),
        const SizedBox(height: 12),

        // Booking code display
        _CodeCard(
          label: 'Código de Reserva',
          code: widget.code,
          icon: Icons.confirmation_number_outlined,
          onCopy: () => _copyToClipboard(widget.code, false),
          copied: _copiedBooking,
        ),

        // KeyBox code display (if available)
        if (widget.keyboxCode != null && widget.keyboxCode!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _CodeCard(
            label: 'Código KeyBox (Caja de llaves)',
            code: widget.keyboxCode!,
            icon: Icons.vpn_key_outlined,
            onCopy: () => _copyToClipboard(widget.keyboxCode!, true),
            copied: _copiedKeybox,
            isKeybox: true,
          ),
        ],

        // Actions
        if (widget.showActions) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.share_outlined,
                  label: 'Compartir códigos',
                  onTap: _shareCode,
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({
    required this.label,
    required this.code,
    required this.icon,
    required this.onCopy,
    required this.copied,
    this.isKeybox = false,
  });

  final String label;
  final String code;
  final IconData icon;
  final VoidCallback onCopy;
  final bool copied;
  final bool isKeybox;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isKeybox ? AppColors.blackWithAlpha20 : AppColors.goldWithAlpha20,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isKeybox ? AppColors.silver : AppColors.goldWithAlpha40,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isKeybox ? AppColors.silver : AppColors.gold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.getTextSecondaryColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: isKeybox ? 24 : 22,
                    fontWeight: FontWeight.w700,
                    color: isKeybox ? AppColors.silver : AppColors.gold,
                    letterSpacing: isKeybox ? 8 : 3,
                  ),
                ),
              ],
            ),
          ),
          // Copy button
          GestureDetector(
            onTap: onCopy,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: copied
                    ? (isKeybox ? AppColors.silver : AppColors.gold)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isKeybox ? AppColors.silver : AppColors.gold,
                  width: 1,
                ),
              ),
              child: Icon(
                copied ? Icons.check : Icons.copy_outlined,
                size: 18,
                color: copied
                    ? AppColors.black
                    : (isKeybox ? AppColors.silver : AppColors.gold),
              ),
            ),
          ),
        ],
      ),
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
