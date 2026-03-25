import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/enums/enums.dart';
import '../../../domain/entities/admin_booking_entity.dart';
import '../../../domain/entities/booking_unit_entity.dart';
import '../../../domain/repositories/admin_panel_repository.dart';
import '../../../domain/services/email_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  final AdminPanelRepository repository;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    required this.repository,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  AdminBookingEntity? _booking;
  bool _isLoading = true;
  String? _error;
  bool _isResending = false;
  bool _isValidating = false;
  bool _isValidatingCheckout = false;
  bool _isUpdatingKeybox = false;
  bool _isSendingRoomReady = false;
  bool _isClosingBooking = false;
  final _emailService = EmailService();

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    debugPrint('🟢 [_loadBooking] Iniciando carga de reserva: ${widget.bookingId}');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('🟢 [_loadBooking] Llamando a repository.getBooking...');
      final booking = await widget.repository.getBooking(widget.bookingId);
      debugPrint('🟢 [_loadBooking] Respuesta recibida: ${booking != null ? "OK" : "NULL"}');

      if (booking == null) {
        debugPrint('🔴 [_loadBooking] Reserva no encontrada');
        setState(() {
          _error = 'Reserva no encontrada';
          _isLoading = false;
        });
        return;
      }

      debugPrint('🟢 [_loadBooking] Datos de reserva:');
      debugPrint('   - id: ${booking.id}');
      debugPrint('   - bookingCode: ${booking.bookingCode}');
      debugPrint('   - unitName: ${booking.unitName}');
      debugPrint('   - propertyName: ${booking.propertyName}');
      debugPrint('   - guestEmail: ${booking.guestEmail}');
      debugPrint('   - guestFullName: ${booking.guestFullName}');
      debugPrint('   - status: ${booking.status}');
      debugPrint('   - keyboxCode: ${booking.keyboxCode}');

      setState(() {
        _booking = booking;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('🔴 [_loadBooking] ERROR: $e');
      debugPrint('🔴 [_loadBooking] StackTrace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _notifyRoomReady() async {
    if (_booking == null || _booking!.guestEmail.isEmpty) return;

    setState(() => _isSendingRoomReady = true);
    try {
      // 1. Guardar el timestamp en la base de datos
      await widget.repository.setEarlyCheckinAvailable(bookingId: _booking!.id);

      // 2. Enviar el email al huésped
      final success = await _emailService.sendRoomReadyEmail(
        toEmail: _booking!.guestEmail,
        guestName: _booking!.guestFullName,
        propertyName: _booking!.propertyName,
        unitName: _booking!.allUnitNames,
        checkinDate: _booking!.checkInDate,
        checkoutDate: _booking!.checkOutDate,
        bookingId: _booking!.id,
      );

      // 3. Recargar la reserva para actualizar el estado
      await _loadBooking();

      if (mounted) {
        _showSnackBar(
          success ? 'Notificación enviada al huésped' : 'Error al enviar la notificación',
          isError: !success,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingRoomReady = false);
      }
    }
  }

  Future<void> _resendCode() async {
    if (_booking == null) return;

    setState(() => _isResending = true);
    try {
      final result = await widget.repository.resendCode(_booking!.id);
      if (mounted) {
        if (result.success) {
          _showSnackBar('Código reenviado correctamente', isError: false);
          await _loadBooking();
        } else {
          _showSnackBar('Error: ${result.error ?? "No se pudo reenviar"}', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _validateCheckin() async {
    if (_booking == null || _booking!.checkinId == null) return;

    setState(() => _isValidating = true);
    try {
      await widget.repository.validateCheckin(
        checkinId: _booking!.checkinId!,
        bookingId: _booking!.id,
      );
      if (mounted) {
        _showSnackBar('Check-in validado correctamente', isError: false);
        await _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al validar: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isValidating = false);
      }
    }
  }

  Future<void> _rejectCheckin() async {
    if (_booking == null || _booking!.checkinId == null) return;

    final reason = await _showRejectDialog();
    if (reason == null) return;

    setState(() => _isValidating = true);
    try {
      await widget.repository.rejectCheckin(
        checkinId: _booking!.checkinId!,
        bookingId: _booking!.id,
        reason: reason.isNotEmpty ? reason : null,
      );
      if (mounted) {
        _showSnackBar('Check-in rechazado', isError: false);
        await _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al rechazar: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isValidating = false);
      }
    }
  }

  // ==================== MÉTODOS DE CHECK-OUT ====================

  Future<void> _validateCheckout() async {
    if (_booking == null) return;

    setState(() => _isValidatingCheckout = true);
    try {
      await widget.repository.validateCheckout(bookingId: _booking!.id);
      if (mounted) {
        _showSnackBar('Check-out validado. Reserva cerrada.', isError: false);
        await _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al validar check-out: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isValidatingCheckout = false);
      }
    }
  }

  Future<void> _rejectCheckout() async {
    if (_booking == null) return;

    final reason = await _showRejectCheckoutDialog();
    if (reason == null) return;

    setState(() => _isValidatingCheckout = true);
    try {
      await widget.repository.rejectCheckout(
        bookingId: _booking!.id,
        reason: reason.isNotEmpty ? reason : 'Incidencias detectadas',
      );
      if (mounted) {
        _showSnackBar('Check-out rechazado', isError: false);
        await _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al rechazar check-out: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isValidatingCheckout = false);
      }
    }
  }

  /// Cierra la reserva manualmente (cuando el huésped no hace check-out)
  Future<void> _closeBooking() async {
    if (_booking == null) return;

    // Verificar si ya está cerrada usando bookingStatus
    final isAlreadyClosed = _booking!.bookingStatus == BookingStatus.closed ||
        _booking!.checkoutStatus == CheckoutStatus.validated;

    if (isAlreadyClosed) {
      _showInfoDialog(
        title: 'Reserva ya cerrada',
        message: 'Esta reserva ya ha sido cerrada anteriormente.',
        icon: Icons.info_outline,
        color: AppColors.info,
      );
      return;
    }

    final notes = await _showCloseBookingDialog();
    if (notes == null) return; // Usuario canceló

    setState(() => _isClosingBooking = true);
    try {
      await widget.repository.closeBooking(
        bookingId: _booking!.id,
        notes: notes.isNotEmpty ? notes : null,
      );
      if (mounted) {
        _showSnackBar('Reserva cerrada correctamente', isError: false);
        await _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al cerrar reserva: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isClosingBooking = false);
      }
    }
  }

  void _showInfoDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.getCardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: color),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.getTextSecondaryColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showCloseBookingDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierColor: AppColors.blackWithAlpha80,
      builder: (context) => Dialog(
        backgroundColor: AppColors.getCardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.exit_to_app,
                  size: 48,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 20),

              // Título
              const Text(
                'Cerrar Reserva',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Descripción
              Text(
                'El huésped no ha realizado el check-out.\n¿Deseas cerrar la reserva manualmente?',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.getTextSecondaryColor(context),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Campo de notas opcional
              TextField(
                controller: controller,
                style: TextStyle(
                  color: AppColors.getTextPrimaryColor(context),
                ),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Notas (opcional)...',
                  hintStyle: TextStyle(
                    color: AppColors.getTextSecondaryColor(context),
                  ),
                  filled: true,
                  fillColor: AppColors.getInputBackgroundColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.getBorderColor(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.getBorderColor(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.gold, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.getTextPrimaryColor(context),
                        side: BorderSide(color: AppColors.getBorderColor(context)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, controller.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Cerrar Reserva',
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
    );
  }

  Future<String?> _showRejectCheckoutDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierColor: AppColors.blackWithAlpha80,
      builder: (context) => Dialog(
        backgroundColor: AppColors.getCardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de advertencia
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 20),

              // Título
              const Text(
                'Rechazar Check-out',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Descripción
              Text(
                'Indica las incidencias detectadas para notificar al huésped:',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.getTextSecondaryColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Campo de texto
              TextField(
                controller: controller,
                style: TextStyle(
                  color: AppColors.getTextPrimaryColor(context),
                ),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Descripción de las incidencias...',
                  hintStyle: TextStyle(
                    color: AppColors.getTextSecondaryColor(context),
                  ),
                  filled: true,
                  fillColor: AppColors.getInputBackgroundColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.getBorderColor(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.getBorderColor(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.gold, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.getTextPrimaryColor(context),
                        side: BorderSide(color: AppColors.getBorderColor(context)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, controller.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Rechazar',
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
    );
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierColor: AppColors.blackWithAlpha80,
      builder: (context) => Dialog(
        backgroundColor: AppColors.getCardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de advertencia
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 20),

              // Título
              const Text(
                'Rechazar Check-in',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Descripción
              Text(
                'Indica el motivo del rechazo (opcional):',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.getTextSecondaryColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Campo de texto
              TextField(
                controller: controller,
                style: TextStyle(
                  color: AppColors.getTextPrimaryColor(context),
                ),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Motivo del rechazo...',
                  hintStyle: TextStyle(
                    color: AppColors.getTextSecondaryColor(context),
                  ),
                  filled: true,
                  fillColor: AppColors.getInputBackgroundColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.getBorderColor(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.getBorderColor(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.gold, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.getTextPrimaryColor(context),
                        side: BorderSide(color: AppColors.getBorderColor(context)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, controller.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Rechazar',
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
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    _showSnackBar('$label copiado al portapapeles', isError: false);
  }

  void _shareCode() {
    if (_booking == null) return;

    final checkIn = _formatDate(_booking!.checkInDate);
    final checkOut = _formatDate(_booking!.checkOutDate);

    String message = 'Tu código de acceso BF-Stay: ${_booking!.bookingCode}';
    if (_booking!.keyboxCode != null && _booking!.keyboxCode!.isNotEmpty) {
      message += '\nCódigo KeyBox: ${_booking!.keyboxCode}';
    }
    message += '\nEntrada: $checkIn · Salida: $checkOut';
    message += '\nDescarga la app BF-Stay e introduce este código.';

    HapticFeedback.lightImpact();
    Share.share(message);
  }

  Future<void> _updateKeyboxCode() async {
    if (_booking == null) return;

    final controller = TextEditingController(text: _booking!.keyboxCode ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_outlined, color: AppColors.gold, size: 22),
            SizedBox(width: 10),
            Text('Editar Código KeyBox', style: TextStyle(color: AppColors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Introduce el nuevo código del KeyBox:',
              style: TextStyle(color: AppColors.gray300, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(
                color: AppColors.white,
                fontFamily: 'JetBrains Mono',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: InputDecoration(
                hintText: '00000000',
                hintStyle: TextStyle(
                  color: AppColors.gray600,
                  fontFamily: 'JetBrains Mono',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
                filled: true,
                fillColor: AppColors.darkBackground,
                counterStyle: const TextStyle(color: AppColors.gray500, fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gold),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.goldWithAlpha40),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gold, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.gray400)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == null) return;

    setState(() => _isUpdatingKeybox = true);

    try {
      await widget.repository.updateBookingKeyboxCode(
        bookingId: _booking!.id,
        keyboxCode: result,
      );

      if (mounted) {
        _showSnackBar('Código KeyBox actualizado', isError: false);
        await _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al actualizar: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingKeybox = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmada';
      case 'checked_in':
        return 'Check-in realizado';
      case 'checked_out':
        return 'Check-out realizado';
      case 'cancelled':
        return 'Cancelada';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.info;
      case 'checked_in':
        return AppColors.success;
      case 'checked_out':
        return AppColors.gray500;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.gray500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin');
            }
          },
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.gold),
        ),
        title: const Text(
          'Detalle de Reserva',
          style: TextStyle(color: AppColors.white, fontSize: 18),
        ),
        actions: [
          if (_booking != null)
            IconButton(
              onPressed: _loadBooking,
              icon: const Icon(Icons.refresh, color: AppColors.gold),
            ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.black,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_booking == null) {
      return const Center(
        child: Text('No hay datos', style: TextStyle(color: AppColors.gray400)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildGuestCard(),
          const SizedBox(height: 16),
          _buildBookingInfoCard(),
          const SizedBox(height: 16),
          if (_booking!.units.isNotEmpty) ...[
            _buildUnitsCard(),
            const SizedBox(height: 16),
          ],
          _buildCodesCard(),
          const SizedBox(height: 16),
          _buildCheckinCard(),
          const SizedBox(height: 16),
          _buildCheckoutCard(),
          const SizedBox(height: 16),
          if (_booking!.signatureSvg != null && _booking!.signatureSvg!.isNotEmpty) ...[
            _buildSignatureCard(),
            const SizedBox(height: 16),
          ],
          if (_booking!.staffNotes != null && _booking!.staffNotes!.isNotEmpty) ...[
            _buildNotesCard(),
            const SizedBox(height: 16),
          ],
          _buildActionsCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusColor = _getStatusColor(_booking!.status);
    final statusText = _getStatusText(_booking!.status);

    // Texto de unidades: mostrar "X habitaciones" si tiene múltiples
    final unitsText = _booking!.hasMultipleUnits
        ? '${_booking!.totalUnits} habitaciones'
        : _booking!.unitName;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _booking!.status == 'confirmed'
                      ? Icons.event_available
                      : _booking!.status == 'checked_in'
                          ? Icons.login
                          : _booking!.status == 'checked_out'
                              ? Icons.logout
                              : Icons.cancel,
                  color: statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          statusText,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_booking!.hasMultipleUnits) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '×${_booking!.totalUnits}',
                              style: const TextStyle(
                                color: AppColors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$unitsText · ${_booking!.propertyName}',
                      style: TextStyle(
                        color: AppColors.getTextSecondaryColor(context),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Indicadores de estado adicionales
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip(
                icon: _booking!.isCodeSent ? Icons.mark_email_read : Icons.mark_email_unread,
                label: _booking!.isCodeSent ? 'Email enviado' : 'Email pendiente',
              ),
              _buildStatusChip(
                icon: _booking!.isCodeUsed ? Icons.lock_open : Icons.lock_outline,
                label: _booking!.isCodeUsed ? 'Código usado' : 'Código sin usar',
              ),
              if (_booking!.checkinId != null)
                _buildStatusChip(
                  icon: _booking!.checkinStatus == 'validated'
                      ? Icons.verified
                      : _booking!.checkinStatus == 'submitted'
                          ? Icons.pending
                          : Icons.edit_document,
                  label: _booking!.checkinStatus == 'validated'
                      ? 'Check-in OK'
                      : _booking!.checkinStatus == 'submitted'
                          ? 'Check-in pendiente'
                          : 'Check-in en progreso',
                ),
              if (_booking!.checkinId == null)
                _buildStatusChip(
                  icon: Icons.hourglass_empty,
                  label: 'Sin check-in',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.black),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppColors.gold, size: 22),
              const SizedBox(width: 8),
              const Text(
                'HUÉSPED',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _booking!.guestFullName.isNotEmpty ? _booking!.guestFullName : 'Sin nombre',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.email_outlined, _booking!.guestEmail),
          if (_booking!.guestPhone != null && _booking!.guestPhone!.isNotEmpty)
            _buildInfoRow(Icons.phone_outlined, _booking!.guestPhone!),
        ],
      ),
    );
  }

  Widget _buildBookingInfoCard() {
    final nights = _booking!.checkOutDate.difference(_booking!.checkInDate).inDays;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: AppColors.gold, size: 22),
              const SizedBox(width: 8),
              const Text(
                'RESERVA',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateColumn(
                  'Entrada',
                  DateFormat('dd MMM yyyy').format(_booking!.checkInDate),
                  Icons.login,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.goldWithAlpha20,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$nights ${nights == 1 ? 'noche' : 'noches'}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: _buildDateColumn(
                  'Salida',
                  DateFormat('dd MMM yyyy').format(_booking!.checkOutDate),
                  Icons.logout,
                  alignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.darkBorder),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.people_outline, color: AppColors.getTextSecondaryColor(context), size: 20),
              const SizedBox(width: 8),
              Text(
                _booking!.guestsDescription,
                style: TextStyle(color: AppColors.getTextSecondaryColor(context)),
              ),
              if (_booking!.childrenAges.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '(${_booking!.childrenAges.join(', ')} años)',
                  style: TextStyle(
                    color: AppColors.getTextSecondaryColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateColumn(String label, String date, IconData icon, {CrossAxisAlignment alignment = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.getTextSecondaryColor(context),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Card para mostrar todas las unidades de la reserva (soporte multi-unidad)
  Widget _buildUnitsCard() {
    debugPrint('🏗️ [_buildUnitsCard] Construyendo card de unidades...');
    debugPrint('🏗️ [_buildUnitsCard] units.length = ${_booking!.units.length}');
    debugPrint('🏗️ [_buildUnitsCard] units = ${_booking!.units.map((u) => u.name).toList()}');

    if (_booking!.units.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.meeting_room_outlined, color: AppColors.gold, size: 22),
              const SizedBox(width: 8),
              Text(
                'HABITACIONES (${_booking!.totalUnits})',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Lista de unidades
          ...(_booking!.units.asMap().entries.map((entry) {
            final index = entry.key;
            final unit = entry.value;
            final isLast = index == _booking!.units.length - 1;

            return Column(
              children: [
                _buildUnitItem(unit, index + 1),
                if (!isLast) ...[
                  const SizedBox(height: 12),
                  Divider(color: AppColors.getBorderColor(context), height: 1),
                  const SizedBox(height: 12),
                ],
              ],
            );
          })),
        ],
      ),
    );
  }

  Widget _buildUnitItem(BookingUnitEntity unit, int number) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre de la unidad
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldWithAlpha20,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$number',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  unit.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (unit.unitType != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.getChipBackgroundColor(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    unit.unitType!,
                    style: TextStyle(
                      color: AppColors.getTextSecondaryColor(context),
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          // WiFi info
          if (unit.wifiNetwork != null || unit.wifiPassword != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.blackWithAlpha20,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wifi, color: AppColors.gold, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'WiFi',
                        style: TextStyle(
                          color: AppColors.getTextSecondaryColor(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (unit.wifiNetwork != null)
                    Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text(
                            'Red:',
                            style: TextStyle(
                              color: AppColors.getTextSecondaryColor(context),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            unit.wifiNetwork!,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (unit.wifiPassword != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text(
                            'Clave:',
                            style: TextStyle(
                              color: AppColors.getTextSecondaryColor(context),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                unit.wifiPassword!,
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'JetBrains Mono',
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _copyToClipboard(unit.wifiPassword!, 'Clave WiFi'),
                                child: Icon(
                                  Icons.copy,
                                  size: 14,
                                  color: AppColors.getTextSecondaryColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          // Box code (código de acceso) - destacado
          if (unit.boxCode != null && unit.boxCode!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.goldWithAlpha20,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.goldWithAlpha40),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: AppColors.gold, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Código de acceso',
                          style: TextStyle(
                            color: AppColors.getTextSecondaryColor(context),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          unit.boxCode!,
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'JetBrains Mono',
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _copyToClipboard(unit.boxCode!, 'Código de acceso'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.gold),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.copy,
                        size: 18,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Instrucciones de acceso
          if (unit.accessInstructions != null && unit.accessInstructions!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blackWithAlpha20,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.silver, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Instrucciones de acceso',
                        style: TextStyle(
                          color: AppColors.getTextSecondaryColor(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    unit.accessInstructions!,
                    style: const TextStyle(
                      color: AppColors.gray200,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCodesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldWithAlpha40),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key_outlined, color: AppColors.gold, size: 22),
              const SizedBox(width: 8),
              const Text(
                'CÓDIGOS DE ACCESO',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCodeRow(
            'Código de Reserva',
            _booking!.bookingCode,
            Icons.confirmation_number_outlined,
          ),
          const SizedBox(height: 12),
          _buildKeyboxCodeRow(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCodeButton(
                  'Compartir',
                  Icons.share_outlined,
                  _shareCode,
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboxCodeRow() {
    final hasKeyboxCode = _booking!.keyboxCode != null && _booking!.keyboxCode!.isNotEmpty;
    final displayCode = hasKeyboxCode ? _booking!.keyboxCode! : 'Sin configurar';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasKeyboxCode ? AppColors.blackWithAlpha20 : AppColors.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasKeyboxCode ? AppColors.silver : AppColors.goldWithAlpha30,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            color: hasKeyboxCode ? AppColors.silver : AppColors.gray500,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Código KeyBox',
                  style: TextStyle(
                    color: AppColors.getTextSecondaryColor(context),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayCode,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: hasKeyboxCode ? 24 : 16,
                    fontWeight: FontWeight.w700,
                    color: hasKeyboxCode ? AppColors.silver : AppColors.gray500,
                    letterSpacing: hasKeyboxCode ? 6 : 0,
                  ),
                ),
              ],
            ),
          ),
          // Botón de copiar (solo si tiene código)
          if (hasKeyboxCode) ...[
            GestureDetector(
              onTap: () => _copyToClipboard(displayCode, 'Código KeyBox'),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.silver),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.copy_outlined,
                  size: 18,
                  color: AppColors.silver,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Botón de editar
          GestureDetector(
            onTap: _isUpdatingKeybox ? null : _updateKeyboxCode,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.goldWithAlpha20,
                border: Border.all(color: AppColors.gold),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isUpdatingKeybox
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gold,
                      ),
                    )
                  : const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppColors.gold,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeRow(String label, String code, IconData icon, {bool isKeybox = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isKeybox ? AppColors.blackWithAlpha20 : AppColors.goldWithAlpha20,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isKeybox ? AppColors.silver : AppColors.goldWithAlpha40,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: isKeybox ? AppColors.silver : AppColors.gold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.getTextSecondaryColor(context),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: isKeybox ? 24 : 20,
                    fontWeight: FontWeight.w700,
                    color: isKeybox ? AppColors.silver : AppColors.gold,
                    letterSpacing: isKeybox ? 6 : 3,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _copyToClipboard(code, label),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isKeybox ? AppColors.silver : AppColors.gold,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.copy_outlined,
                size: 18,
                color: isKeybox ? AppColors.silver : AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeButton(String label, IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary ? AppColors.gold : AppColors.goldWithAlpha40,
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
                color: isPrimary ? AppColors.black : AppColors.gold,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckinCard() {
    final hasCheckin = _booking!.checkinId != null;
    final checkinStatus = _booking!.checkinStatus ?? 'draft';
    final isSubmitted = checkinStatus == 'submitted';
    final isValidated = checkinStatus == 'validated';
    final isRejected = checkinStatus == 'rejected';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!hasCheckin) {
      statusColor = AppColors.gray500;
      statusText = 'Check-in no iniciado';
      statusIcon = Icons.hourglass_empty;
    } else if (isValidated) {
      statusColor = AppColors.success;
      statusText = 'Check-in validado';
      statusIcon = Icons.verified;
    } else if (isRejected) {
      statusColor = AppColors.error;
      statusText = 'Check-in rechazado';
      statusIcon = Icons.cancel;
    } else if (isSubmitted) {
      statusColor = AppColors.warning;
      statusText = 'Pendiente de validación';
      statusIcon = Icons.pending;
    } else {
      statusColor = AppColors.info;
      statusText = 'Check-in en progreso';
      statusIcon = Icons.edit_document;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fact_check_outlined, color: AppColors.black, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'CHECK-IN',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: AppColors.black, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (isSubmitted && _booking!.docsPending != null && _booking!.docsPending! > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_booking!.docsPending} documentos pendientes',
                    style: const TextStyle(color: AppColors.warning, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
          if (isSubmitted) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCodeButton(
                    'Validar',
                    Icons.check_circle_outline,
                    _isValidating ? () {} : _validateCheckin,
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCodeButton(
                    'Rechazar',
                    Icons.cancel_outlined,
                    _isValidating ? () {} : _rejectCheckin,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.note_outlined, color: AppColors.gold, size: 22),
              const SizedBox(width: 8),
              const Text(
                'NOTAS INTERNAS',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _booking!.staffNotes!,
            style: const TextStyle(
              color: AppColors.gray300,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutCard() {
    // Solo mostrar si el check-in está validado
    if (_booking!.checkinStatus != 'validated') {
      return const SizedBox.shrink();
    }

    final checkoutStatus = _booking!.checkoutStatus;
    final isBookingClosed = _booking!.status == 'checked_out' || _booking!.status == 'closed';
    final isRequested = checkoutStatus == CheckoutStatus.requested;
    final isValidated = checkoutStatus == CheckoutStatus.validated || isBookingClosed;
    final isRejected = checkoutStatus == CheckoutStatus.rejected;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isValidated) {
      statusColor = AppColors.success;
      statusText = isBookingClosed ? 'Reserva cerrada' : 'Check-out validado';
      statusIcon = Icons.verified;
    } else if (isRejected) {
      statusColor = AppColors.error;
      statusText = 'Check-out con incidencias';
      statusIcon = Icons.warning_rounded;
    } else if (isRequested) {
      statusColor = AppColors.warning;
      statusText = 'Check-out solicitado';
      statusIcon = Icons.pending;
    } else {
      statusColor = AppColors.gray500;
      statusText = 'Check-out pendiente';
      statusIcon = Icons.exit_to_app;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.exit_to_app, color: AppColors.black, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'CHECK-OUT',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          // Mostrar fecha de solicitud si existe
          if (_booking!.checkoutRequestedAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Solicitado: ${DateFormat('dd/MM/yyyy HH:mm').format(_booking!.checkoutRequestedAt!)}',
              style: const TextStyle(color: AppColors.gray400, fontSize: 12),
            ),
          ],
          // Mostrar notas de check-out si existen
          if (_booking!.checkoutNotes != null && _booking!.checkoutNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notas:',
                    style: TextStyle(color: AppColors.gray400, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _booking!.checkoutNotes!,
                    style: const TextStyle(color: AppColors.gray300, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
          // Botones de acción si está solicitado
          if (isRequested) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCodeButton(
                    'Validar',
                    Icons.check_circle_outline,
                    _isValidatingCheckout ? () {} : () => _validateCheckout(),
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCodeButton(
                    'Incidencias',
                    Icons.report_problem_outlined,
                    _isValidatingCheckout ? () {} : () => _rejectCheckout(),
                  ),
                ),
              ],
            ),
          ],
          // Botón para cerrar reserva manualmente si NO hay solicitud de check-out
          // y el check-in está validado
          if (!isRequested && !isValidated && !isRejected) ...[
            const SizedBox(height: 16),
            _buildCodeButton(
              'Cerrar Reserva',
              Icons.exit_to_app,
              _isClosingBooking ? () {} : () => _closeBooking(),
              isPrimary: true,
            ),
            const SizedBox(height: 8),
            Text(
              'El huésped no ha solicitado check-out. Puedes cerrar la reserva manualmente.',
              style: TextStyle(
                color: AppColors.getTextSecondaryColor(context),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignatureCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.draw_outlined, color: AppColors.gold, size: 22),
              const SizedBox(width: 8),
              const Text(
                'FIRMA DEL TITULAR',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.goldWithAlpha30),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: SvgPicture.string(
                '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 150">
                  ${_booking!.signatureSvg!}
                </svg>''',
                fit: BoxFit.contain,
                placeholderBuilder: (context) => const Center(
                  child: Text(
                    'Firma no disponible',
                    style: TextStyle(color: AppColors.gray500),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_outlined, color: AppColors.gold, size: 22),
              const SizedBox(width: 8),
              const Text(
                'ACCIONES',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            icon: Icons.send_outlined,
            title: 'Reenviar código por email',
            subtitle: _booking!.isCodeSent
                ? 'Último envío: ${_booking!.codeSentAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(_booking!.codeSentAt!) : 'N/A'}'
                : 'Aún no se ha enviado',
            onTap: _isResending ? null : _resendCode,
            isLoading: _isResending,
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            icon: Icons.door_front_door_outlined,
            title: 'Habitación disponible',
            subtitle: 'Notifica al huésped que la habitación está lista y puede acceder',
            onTap: _isSendingRoomReady ? null : _notifyRoomReady,
            isLoading: _isSendingRoomReady,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool isLoading = false,
    Color? color,
  }) {
    final tileColor = color ?? AppColors.gold;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tileColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: tileColor),
                    )
                  : Icon(icon, color: tileColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.getTextSecondaryColor(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: onTap == null ? AppColors.gray600 : tileColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gray500, size: 18),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(color: AppColors.gray300)),
        ],
      ),
    );
  }
}
