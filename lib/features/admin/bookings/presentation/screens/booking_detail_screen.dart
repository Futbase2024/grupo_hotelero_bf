import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/config/supabase_config.dart';
import '../../../../../core/constants/checkin_policy.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/enums/enums.dart';
import '../../../../../core/utils/guest_documents_cleaner.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../auth/domain/bloc/auth_bloc.dart';
import '../../data/services/booking_email_pdf_service.dart';
import '../../../domain/entities/admin_booking_entity.dart';
import '../../../domain/entities/booking_unit_entity.dart';
import '../../../domain/repositories/admin_panel_repository.dart';
import '../../../domain/services/email_service.dart';
import '../widgets/edit_guest_contact_dialog.dart';

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
  bool _isCancellingBooking = false;
  bool _isReactivatingBooking = false;
  bool _isDeletingBooking = false;
  bool _isUpdatingGuestContact = false;
  bool _isUpdatingAutoValidate = false;
  final _emailService = EmailService();

  /// Eliminar una reserva es una acción exclusiva de admin (la RPC
  /// `delete_booking` también lo exige).
  bool get _isCurrentUserAdmin {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated && authState.user.isAdmin;
  }

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
          _error = S.of(context).admin_booking_not_found;
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
          success ? S.of(context).admin_booking_notification_sent : S.of(context).admin_booking_notification_error,
          isError: !success,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(S.of(context).admin_booking_error(e.toString()), isError: true);
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
          _showSnackBar(S.of(context).admin_booking_code_resent, isError: false);
          await _loadBooking();
        } else {
          _showSnackBar(S.of(context).admin_booking_error(result.error ?? S.of(context).admin_booking_resend_error), isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(S.of(context).admin_booking_error(e.toString()), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  bool _isSendingWhatsApp = false;

  Future<void> _sendViaWhatsApp() async {
    if (_booking == null) return;

    var phone = _booking!.guestPhone ?? '';
    if (phone.trim().isEmpty) {
      if (!mounted) return;
      final inputPhone = await _showPhoneInputDialog();
      if (inputPhone == null || inputPhone.trim().isEmpty) return;
      phone = inputPhone;
      try {
        await widget.repository.updateBookingGuestPhone(
          bookingId: _booking!.id,
          guestPhone: phone,
        );
        await _loadBooking();
      } catch (e) {
        if (!mounted) return;
        _showSnackBar(S.of(context).admin_booking_error(e.toString()), isError: true);
        return;
      }
    }

    setState(() => _isSendingWhatsApp = true);

    try {
      // 1. Generar el documento PDF con el mismo diseno que el correo
      //    (incluida la imagen de cabecera y los enlaces de descarga clicables).
      final pdfService = BookingEmailPdfService();
      Uint8List? heroBytes;
      try {
        heroBytes = await SupabaseConfig.client.storage
            .from('email-assets')
            .download('heroimagen.png');
      } catch (e) {
        debugPrint('⚠️ No se pudo cargar la imagen de cabecera: $e');
      }
      final pdfBytes =
          await pdfService.generateEmailPdf(_booking!, heroImage: heroBytes);

      // 2. Subir el PDF a Supabase Storage y obtener su URL publica.
      final storagePath = 'booking-pdfs/${_booking!.bookingCode}.pdf';
      await SupabaseConfig.client.storage.from('email-assets').uploadBinary(
            storagePath,
            pdfBytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: true,
            ),
          );
      final pdfUrl = SupabaseConfig.client.storage
          .from('email-assets')
          .getPublicUrl(storagePath);

      if (!mounted) return;

      // 3. Abrir WhatsApp con un mensaje que replica el correo de check-in.
      final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
      final phoneWithCode =
          cleanPhone.startsWith('34') ? cleanPhone : '34$cleanPhone';

      final message = _buildWhatsAppMessage(pdfUrl);
      final encodedMessage = Uri.encodeComponent(message);

      // Intentar primero con el esquema nativo de WhatsApp (mas fiable)
      final whatsappAppUri = Uri.parse(
        'whatsapp://send?phone=$phoneWithCode&text=$encodedMessage',
      );
      final whatsappWebUri = Uri.parse(
        'https://wa.me/$phoneWithCode?text=$encodedMessage',
      );

      bool launched = false;

      // Intentar con la app nativa de WhatsApp
      if (await canLaunchUrl(whatsappAppUri)) {
        launched = await launchUrl(whatsappAppUri,
            mode: LaunchMode.externalApplication);
      }

      // Fallback: intentar con wa.me (abre en navegador o app)
      if (!launched && await canLaunchUrl(whatsappWebUri)) {
        launched = await launchUrl(whatsappWebUri,
            mode: LaunchMode.externalApplication);
      }

      if (!launched) {
        if (!mounted) return;
        _showWhatsAppNotInstalledDialog();
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(S.of(context).admin_booking_error(e.toString()),
          isError: true);
    } finally {
      if (mounted) setState(() => _isSendingWhatsApp = false);
    }
  }

  /// Construye el mensaje de WhatsApp replicando el correo de check-in.
  ///
  /// WhatsApp no admite HTML como el email, pero convierte las URLs en enlaces
  /// clicables y soporta *negritas*. Se usan los mismos textos, datos y enlaces
  /// de descarga (App Store / Google Play) que la plantilla del correo.
  String _buildWhatsAppMessage(String pdfUrl) {
    final booking = _booking!;
    final guestName = booking.guestFirstName ?? booking.guestFullName;
    final propertyFull = '${booking.propertyName} - ${booking.unitName}';
    final checkIn = DateFormat('dd/MM/yyyy').format(booking.checkInDate);
    final checkOut = DateFormat('dd/MM/yyyy').format(booking.checkOutDate);

    const iosUrl = 'https://apps.apple.com/es/app/bf-stay/id6759832221';
    const androidUrl =
        'https://play.google.com/store/apps/details?id=com.bfstay.app';

    return 'Hola *$guestName*,\n\n'
        'Tu *reserva en $propertyFull* ha sido registrada correctamente.\n\n'
        'Para preparar tu llegada, es necesario completar el *check-in digital*. '
        'Puedes hacerlo fácilmente desde la aplicación *BF Stay*.\n\n'
        'A continuación encontrarás los datos de tu estancia:\n'
        '📅 *Entrada:* $checkIn\n'
        '📅 *Salida:* $checkOut\n\n'
        '━━━━━━━━━━━━━━━━━━━━\n'
        '⏰ *${CheckinPolicy.maxCheckinNotice}*\n'
        '━━━━━━━━━━━━━━━━━━━━\n\n'
        'Para acceder a la aplicación y validar tus datos de check-in, utiliza el siguiente código:\n\n'
        '🔑 *TU CÓDIGO DE ACCESO*\n'
        '*${booking.bookingCode}*\n\n'
        'Introduce este código en BF Stay para acceder a tu reserva y completar el check-in digital.\n\n'
        '📄 Consulta y guarda todos los detalles de tu reserva aquí:\n$pdfUrl\n\n'
        'Descarga o abre *BF Stay* e introduce tu código de acceso para comenzar el check-in:\n\n'
        '🍎 Descargar en App Store:\n$iosUrl\n\n'
        '🤖 Descargar en Android:\n$androidUrl\n\n'
        'Si necesitas asistencia puedes contactarnos:\n'
        '📞 +34 656 61 80 65\n'
        '📞 +34 674 27 70 16\n\n'
        'Una vez validado tu check-in, podrás acceder a toda la información de tu estancia directamente desde la app.\n\n'
        'Te deseamos una excelente estancia.\n\n'
        '*Grupo Hotelero BF*';
  }

  void _showWhatsAppNotInstalledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        backgroundColor: const Color(0xFF1A1A1A),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFFE57373),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'WhatsApp no disponible',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'No se ha podido abrir WhatsApp. Asegúrate de que está instalado en este dispositivo.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white70,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showPhoneInputDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        backgroundColor: const Color(0xFF1A1A1A),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_android, size: 48, color: Color(0xFF25D366)),
            ),
            const SizedBox(height: 20),
            Text(
              S.of(context).admin_booking_send_whatsapp_no_phone,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).admin_booking_send_whatsapp_no_phone_desc,
              style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: S.of(context).admin_booking_send_whatsapp_phone_hint,
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF0D0D0D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(null),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(S.of(context).common_cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(S.of(context).common_send),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Corrige el email y el teléfono del huésped de la reserva
  Future<void> _editGuestContact() async {
    if (_booking == null) return;

    final input = await EditGuestContactDialog.show(
      context,
      initialEmail: _booking!.guestEmail,
      initialPhone: _booking!.guestPhone,
    );
    if (input == null) return;

    setState(() => _isUpdatingGuestContact = true);
    try {
      final result = await widget.repository.updateBookingGuestContact(
        bookingId: _booking!.id,
        guestEmail: input.email,
        guestPhone: input.phone,
      );
      await _loadBooking();

      if (!mounted) return;
      _showSnackBar(S.of(context).admin_booking_guest_edit_saved, isError: false);

      // El huésped ya había abierto la reserva con el email anterior: se le
      // avisa al admin de que deberá volver a entrar con su código.
      if (result.accessReset) {
        await _showAccessResetDialog();
        if (!mounted) return;
      }

      // Si el email cambió, el código pudo no haber llegado nunca a su destino
      if (result.emailChanged) {
        final shouldResend = await _showResendCodeConfirmDialog(input.email);
        if (shouldResend == true && mounted) {
          await _resendCode();
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(S.of(context).admin_booking_error(e.toString()), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingGuestContact = false);
      }
    }
  }

  Future<void> _showAccessResetDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        backgroundColor: AppColors.darkSurface,
        content: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.goldWithAlpha10,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline, size: 48, color: AppColors.gold),
              ),
              const SizedBox(height: 20),
              Text(
                S.of(context).admin_booking_guest_edit_access_reset_title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                S.of(context).admin_booking_guest_edit_access_reset_desc,
                style: const TextStyle(fontSize: 15, color: AppColors.gray300, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(S.of(context).common_understood),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showResendCodeConfirmDialog(String email) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        backgroundColor: AppColors.darkSurface,
        content: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.goldWithAlpha10,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.gold),
              ),
              const SizedBox(height: 20),
              Text(
                S.of(context).admin_booking_guest_edit_resend_title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                S.of(context).admin_booking_guest_edit_resend_desc(email),
                style: const TextStyle(fontSize: 15, color: AppColors.gray300, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gray300,
                        side: const BorderSide(color: AppColors.darkBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(S.of(context).common_later),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(S.of(context).admin_booking_guest_edit_resend_confirm),
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

  Future<void> _validateCheckin() async {
    if (_booking == null || _booking!.checkinId == null) return;

    setState(() => _isValidating = true);
    try {
      await widget.repository.validateCheckin(
        checkinId: _booking!.checkinId!,
        bookingId: _booking!.id,
      );
      if (mounted) {
        _showSnackBar(S.of(context).admin_booking_checkin_validated, isError: false);
        await _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(S.of(context).admin_booking_error_validating(e.toString()), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isValidating = false);
      }
    }
  }

  /// Activa/desactiva la auto-validación del check-in de esta reserva
  ///
  /// Si se activa con un check-in ya enviado, la RPC lo valida en el acto y se
  /// avisa al admin de que ha quedado validado.
  Future<void> _toggleAutoValidateCheckin(bool enabled) async {
    if (_booking == null) return;

    setState(() => _isUpdatingAutoValidate = true);
    try {
      final validatedNow = await widget.repository.setBookingAutoValidateCheckin(
        bookingId: _booking!.id,
        enabled: enabled,
      );

      if (!mounted) return;

      _showSnackBar(
        validatedNow
            ? S.of(context).admin_booking_auto_validate_applied_now
            : enabled
                ? S.of(context).admin_booking_auto_validate_enabled
                : S.of(context).admin_booking_auto_validate_disabled,
        isError: false,
      );
      await _loadBooking();
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          S.of(context).admin_booking_auto_validate_error(e.toString()),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAutoValidate = false);
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
        _showSnackBar(S.of(context).admin_booking_checkin_rejected, isError: false);
        await _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(S.of(context).admin_booking_error_rejecting(e.toString()), isError: true);
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
        _showSnackBar(S.of(context).admin_booking_checkout_validated, isError: false);
        await _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(S.of(context).admin_booking_error_validating_checkout(e.toString()), isError: true);
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
        reason: reason.isNotEmpty ? reason : S.of(context).admin_booking_incidents_detected,
      );
      if (mounted) {
        _showSnackBar(S.of(context).admin_booking_checkout_rejected, isError: false);
        await _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(S.of(context).admin_booking_error_rejecting_checkout(e.toString()), isError: true);
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
        title: S.of(context).admin_booking_already_closed_title,
        message: S.of(context).admin_booking_already_closed_message,
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
        _showSnackBar(S.of(context).admin_booking_closed_successfully, isError: false);
        await _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(S.of(context).admin_booking_error_closing(e.toString()), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isClosingBooking = false);
      }
    }
  }

  /// Cancela la reserva (estado cancelled)
  Future<void> _cancelBooking() async {
    if (_booking == null) return;

    // Verificar si ya está cancelada
    if (_booking!.status == 'cancelled') {
      _showInfoDialog(
        title: S.of(context).admin_booking_already_cancelled_title,
        message: S.of(context).admin_booking_already_cancelled_message,
        icon: Icons.info_outline,
        color: AppColors.info,
      );
      return;
    }

    final confirmed = await _showCancelBookingDialog();
    if (!confirmed) return; // Usuario canceló

    setState(() => _isCancellingBooking = true);
    try {
      await widget.repository.cancelBooking(bookingId: _booking!.id);
      if (mounted) {
        _showSnackBar(S.of(context).admin_booking_cancelled_successfully, isError: false);
        await _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(S.of(context).admin_booking_error_cancelling(e.toString()), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isCancellingBooking = false);
      }
    }
  }

  Future<bool> _showCancelBookingDialog() async {
    final result = await showDialog<bool>(
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
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  size: 48,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 20),

              // Título
              Text(
                S.of(context).admin_booking_cancel_booking,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Descripción
              Text(
                S.of(context).admin_booking_cancel_booking_confirm,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.getTextSecondaryColor(context),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.getTextPrimaryColor(context),
                        side: BorderSide(color: AppColors.getBorderColor(context)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(S.of(context).admin_booking_no_keep),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        S.of(context).admin_booking_yes_cancel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
    return result ?? false;
  }

  /// Reactiva la reserva cancelada (vuelve a estado confirmado)
  Future<void> _reactivateBooking() async {
    if (_booking == null) return;

    // Solo tiene sentido reactivar reservas canceladas
    if (!_booking!.isCancelled) {
      _showInfoDialog(
        title: S.of(context).admin_booking_cannot_reactivate_title,
        message: S.of(context).admin_booking_cannot_reactivate_message,
        icon: Icons.info_outline,
        color: AppColors.info,
      );
      return;
    }

    final confirmed = await _showReactivateBookingDialog();
    if (!confirmed) return; // Usuario canceló

    setState(() => _isReactivatingBooking = true);
    try {
      await widget.repository.reactivateBooking(bookingId: _booking!.id);
      if (mounted) {
        _showSnackBar(S.of(context).admin_booking_reactivated_successfully, isError: false);
        await _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(S.of(context).admin_booking_error_reactivating(e.toString()), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isReactivatingBooking = false);
      }
    }
  }

  Future<bool> _showReactivateBookingDialog() async {
    final result = await showDialog<bool>(
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
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restart_alt_rounded,
                  size: 48,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 20),

              // Título
              Text(
                S.of(context).admin_booking_reactivate_booking_title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Descripción
              Text(
                S.of(context).admin_booking_reactivate_booking_confirm,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.getTextSecondaryColor(context),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.getTextPrimaryColor(context),
                        side: BorderSide(color: AppColors.getBorderColor(context)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(S.of(context).common_cancel),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        S.of(context).admin_booking_yes_reactivate,
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
    return result ?? false;
  }

  /// Elimina completamente la reserva de la base de datos
  Future<void> _deleteBooking() async {
    if (_booking == null) return;

    // Verificar que NO esté en estado finalizado o en casa
    if (_booking!.status == 'checked_out' ||
        _booking!.status == 'closed' ||
        _booking!.status == 'in_house') {
      _showInfoDialog(
        title: S.of(context).admin_booking_cannot_delete_title,
        message:
            S.of(context).admin_booking_cannot_delete_message(_booking!.status),
        icon: Icons.block,
        color: AppColors.error,
      );
      return;
    }

    final confirmed = await _showDeleteBookingDialog();
    if (!confirmed) return;

    setState(() => _isDeletingBooking = true);
    try {
      // Llamar a la RPC para eliminar la reserva
      final storagePaths = await widget.repository.deleteBooking(
        bookingId: _booking!.id,
      );

      // Eliminar archivos del storage
      await removeGuestDocuments(storagePaths, logTag: '_deleteBooking');

      if (mounted) {
        _showSnackBar(S.of(context).admin_booking_deleted_successfully, isError: false);
        // Volver a la lista de reservas
        context.go('/admin');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(S.of(context).admin_booking_error_deleting(e.toString()), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isDeletingBooking = false);
      }
    }
  }

  Future<bool> _showDeleteBookingDialog() async {
    final result = await showDialog<bool>(
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
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever,
                  size: 48,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 20),

              // Título
              Text(
                S.of(context).admin_booking_delete_booking,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Descripción
              Text(
                S.of(context).admin_booking_delete_confirm,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getTextSecondaryColor(context),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.getTextPrimaryColor(context),
                        side: BorderSide(color: AppColors.getBorderColor(context)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(S.of(context).common_cancel),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        S.of(context).common_delete,
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
    return result ?? false;
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
                  child: Text(S.of(context).common_understood),
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
              Text(
                S.of(context).admin_booking_close_booking,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Descripción
              Text(
                S.of(context).admin_booking_close_confirm,
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
                  hintText: S.of(context).admin_booking_close_notes_hint,
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
                      child: Text(S.of(context).common_cancel),
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
                      child: Text(
                        S.of(context).admin_booking_close_booking,
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
              Text(
                S.of(context).admin_booking_reject_checkout,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Descripción
              Text(
                S.of(context).admin_booking_reject_checkout_desc,
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
                  hintText: S.of(context).admin_booking_incidents_hint,
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
                      child: Text(S.of(context).common_cancel),
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
                      child: Text(
                        S.of(context).admin_booking_reject,
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
              Text(
                S.of(context).admin_booking_reject_checkin,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Descripción
              Text(
                S.of(context).admin_booking_reject_checkin_desc,
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
                  hintText: S.of(context).admin_booking_reject_reason_hint,
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
                      child: Text(S.of(context).common_cancel),
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
                      child: Text(
                        S.of(context).admin_booking_reject,
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
    _showSnackBar(S.of(context).common_copied_to_clipboard(label), isError: false);
  }

  void _shareCode() {
    if (_booking == null) return;

    final checkIn = _formatDate(_booking!.checkInDate);
    final checkOut = _formatDate(_booking!.checkOutDate);

    String message = S.of(context).admin_booking_share_code_message(_booking!.bookingCode);
    if (_booking!.keyboxCode != null && _booking!.keyboxCode!.isNotEmpty) {
      message += '\n${S.of(context).admin_booking_share_keybox_code(_booking!.keyboxCode!)}';
    }
    message += '\n${S.of(context).admin_booking_share_dates(checkIn, checkOut)}';
    message += '\n${S.of(context).admin_booking_share_download_app}';

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
        title: Row(
          children: [
            const Icon(Icons.edit_outlined, color: AppColors.gold, size: 22),
            const SizedBox(width: 10),
            Text(S.of(context).admin_booking_edit_keybox_title, style: const TextStyle(color: AppColors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).admin_booking_edit_keybox_desc,
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
            child: Text(S.of(context).common_cancel, style: const TextStyle(color: AppColors.gray400)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(S.of(context).common_save),
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
        _showSnackBar(S.of(context).admin_booking_keybox_updated, isError: false);
        await _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(S.of(context).admin_booking_error_updating(e.toString()), isError: true);
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

  String _getStatusText(String status, BuildContext context) {
    switch (status) {
      case 'confirmed':
        return S.of(context).enum_booking_status_confirmed;
      case 'checked_in':
        return S.of(context).admin_booking_checkin_done;
      case 'checked_out':
        return S.of(context).admin_booking_checkout_done;
      case 'cancelled':
        return S.of(context).enum_booking_status_cancelled;
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
        title: Text(
          S.of(context).admin_booking_detail_title,
          style: const TextStyle(color: AppColors.white, fontSize: 18),
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
              child: Text(S.of(context).common_retry),
            ),
          ],
        ),
      );
    }

    if (_booking == null) {
      return Center(
        child: Text(S.of(context).common_no_data, style: const TextStyle(color: AppColors.gray400)),
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
    final statusText = _getStatusText(_booking!.status, context);

    // Texto de unidades: mostrar "X habitaciones" si tiene múltiples
    final unitsText = _booking!.hasMultipleUnits
        ? '${_booking!.totalUnits} ${S.of(context).admin_booking_units_label}'
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
                label: _booking!.isCodeSent ? S.of(context).admin_booking_email_sent : S.of(context).admin_booking_email_pending,
              ),
              _buildStatusChip(
                icon: _booking!.isCodeUsed ? Icons.lock_open : Icons.lock_outline,
                label: _booking!.isCodeUsed ? S.of(context).admin_booking_code_used : S.of(context).admin_booking_code_unused,
              ),
              if (_booking!.checkinId != null)
                _buildStatusChip(
                  icon: _booking!.checkinStatus == 'validated'
                      ? Icons.verified
                      : _booking!.checkinStatus == 'submitted'
                          ? Icons.pending
                          : Icons.edit_document,
                  label: _booking!.checkinStatus == 'validated'
                      ? S.of(context).admin_booking_checkin_ok
                      : _booking!.checkinStatus == 'submitted'
                          ? S.of(context).admin_booking_checkin_pending
                          : S.of(context).admin_booking_checkin_in_progress,
                ),
              if (_booking!.checkinId == null)
                _buildStatusChip(
                  icon: Icons.hourglass_empty,
                  label: S.of(context).admin_booking_no_checkin,
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
              Expanded(
                child: Text(
                  S.of(context).admin_booking_guest_section,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isUpdatingGuestContact ? null : _editGuestContact,
                icon: _isUpdatingGuestContact
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.gold,
                        ),
                      )
                    : const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.gold,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: S.of(context).admin_booking_guest_edit_tooltip,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _booking!.guestFullName.isNotEmpty ? _booking!.guestFullName : S.of(context).admin_booking_no_name,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.email_outlined, _booking!.guestEmail),
          _buildInfoRow(
            Icons.phone_outlined,
            (_booking!.guestPhone?.isNotEmpty ?? false)
                ? _booking!.guestPhone!
                : S.of(context).admin_booking_guest_no_phone,
          ),
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
              Text(
                S.of(context).admin_booking_reservation_section,
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
              Expanded(
                child: _buildDateColumn(
                  S.of(context).admin_booking_checkin_label,
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
                  '$nights ${nights == 1 ? S.of(context).admin_booking_night_singular : S.of(context).admin_booking_night_plural}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: _buildDateColumn(
                  S.of(context).admin_booking_checkout_label,
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
                  '(${_booking!.childrenAges.join(', ')} ${S.of(context).admin_booking_years_label})',
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
                '${S.of(context).admin_booking_rooms_section} (${_booking!.totalUnits})',
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
                        S.of(context).admin_booking_wifi_label,
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
                            S.of(context).admin_booking_wifi_network_label,
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
                            S.of(context).admin_booking_wifi_password_label,
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
                                onTap: () => _copyToClipboard(unit.wifiPassword!, S.of(context).admin_booking_wifi_password_clipboard),
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
                          S.of(context).admin_booking_access_code_label,
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
                    onTap: () => _copyToClipboard(unit.boxCode!, S.of(context).admin_booking_access_code_clipboard),
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
                        S.of(context).admin_booking_access_instructions_label,
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
              Text(
                S.of(context).admin_booking_access_codes_section,
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
          _buildCodeRow(
            S.of(context).admin_booking_reservation_code_label,
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
                  S.of(context).admin_booking_share_button,
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
    final displayCode = hasKeyboxCode ? _booking!.keyboxCode! : S.of(context).admin_booking_keybox_not_set;

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
                  S.of(context).admin_booking_keybox_code_label,
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
              onTap: () => _copyToClipboard(displayCode, S.of(context).admin_booking_keybox_code_clipboard),
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
      statusText = S.of(context).admin_booking_checkin_not_started;
      statusIcon = Icons.hourglass_empty;
    } else if (isValidated) {
      statusColor = AppColors.success;
      statusText = S.of(context).admin_booking_checkin_validated_status;
      statusIcon = Icons.verified;
    } else if (isRejected) {
      statusColor = AppColors.error;
      statusText = S.of(context).admin_booking_checkin_rejected_status;
      statusIcon = Icons.cancel;
    } else if (isSubmitted) {
      statusColor = AppColors.warning;
      statusText = S.of(context).admin_booking_checkin_pending_validation;
      statusIcon = Icons.pending;
    } else {
      statusColor = AppColors.info;
      statusText = S.of(context).admin_booking_checkin_in_progress_status;
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
                S.of(context).admin_booking_checkin_section,
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
                    '${_booking!.docsPending} ${S.of(context).admin_booking_docs_pending}',
                    style: const TextStyle(color: AppColors.warning, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
          if (!_booking!.isReadOnly && !_booking!.isCancelled && !isValidated) ...[
            const SizedBox(height: 16),
            _buildAutoValidateRow(),
          ],
          if (isSubmitted) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCodeButton(
                    S.of(context).admin_booking_validate_button,
                    Icons.check_circle_outline,
                    _isValidating ? () {} : _validateCheckin,
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCodeButton(
                    S.of(context).admin_booking_reject_button,
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

  /// Interruptor de auto-validación del check-in dentro de la tarjeta de check-in
  Widget _buildAutoValidateRow() {
    final isEnabled = _booking!.autoValidateCheckin;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEnabled ? AppColors.gold : AppColors.darkBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 18,
            color: isEnabled ? AppColors.gold : AppColors.gray500,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).admin_booking_auto_validate_title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  S.of(context).admin_booking_auto_validate_subtitle,
                  style: const TextStyle(
                    color: AppColors.gray400,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_isUpdatingAutoValidate)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
            )
          else
            Switch(
              value: isEnabled,
              activeThumbColor: AppColors.black,
              activeTrackColor: AppColors.gold,
              inactiveThumbColor: AppColors.gray400,
              inactiveTrackColor: AppColors.darkSurface,
              onChanged: _toggleAutoValidateCheckin,
            ),
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
              Text(
                S.of(context).admin_booking_internal_notes_section,
                style: const TextStyle(
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
      statusText = isBookingClosed ? S.of(context).admin_booking_closed_status : S.of(context).admin_booking_checkout_validated_status;
      statusIcon = Icons.verified;
    } else if (isRejected) {
      statusColor = AppColors.error;
      statusText = S.of(context).admin_booking_checkout_incidents_status;
      statusIcon = Icons.warning_rounded;
    } else if (isRequested) {
      statusColor = AppColors.warning;
      statusText = S.of(context).admin_booking_checkout_requested_status;
      statusIcon = Icons.pending;
    } else {
      statusColor = AppColors.gray500;
      statusText = S.of(context).admin_booking_checkout_pending_status;
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
              Text(
                S.of(context).admin_booking_checkout_section,
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
              '${S.of(context).admin_booking_requested_label} ${DateFormat('dd/MM/yyyy HH:mm').format(_booking!.checkoutRequestedAt!)}',
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
                  Text(
                    S.of(context).admin_booking_notes_label,
                    style: const TextStyle(color: AppColors.gray400, fontSize: 11),
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
                    S.of(context).admin_booking_validate_button,
                    Icons.check_circle_outline,
                    _isValidatingCheckout ? () {} : () => _validateCheckout(),
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCodeButton(
                    S.of(context).admin_booking_incidents_button,
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
              S.of(context).admin_booking_close_booking_button,
              Icons.exit_to_app,
              _isClosingBooking ? () {} : () => _closeBooking(),
              isPrimary: true,
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).admin_booking_close_booking_description,
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
              Text(
                S.of(context).admin_booking_signature_section,
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
                placeholderBuilder: (context) => Center(
                  child: Text(
                    S.of(context).admin_booking_signature_unavailable,
                    style: const TextStyle(color: AppColors.gray500),
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
              Text(
                S.of(context).admin_booking_actions_section,
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
          _buildActionTile(
            icon: Icons.send_outlined,
            title: S.of(context).admin_booking_resend_code_title,
            subtitle: _booking!.isCodeSent
                ? '${S.of(context).admin_booking_last_sent_label} ${_booking!.codeSentAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(_booking!.codeSentAt!) : S.of(context).admin_booking_na}'
                : S.of(context).admin_booking_not_sent_yet,
            onTap: _isResending ? null : _resendCode,
            isLoading: _isResending,
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            icon: Icons.chat_outlined,
            title: S.of(context).admin_booking_send_whatsapp_title,
            subtitle: _booking!.guestPhone ?? S.of(context).admin_booking_send_whatsapp_no_phone,
            onTap: _isSendingWhatsApp ? null : _sendViaWhatsApp,
            isLoading: _isSendingWhatsApp,
            color: const Color(0xFF25D366),
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            icon: Icons.door_front_door_outlined,
            title: S.of(context).admin_booking_room_ready_title,
            subtitle: S.of(context).admin_booking_room_ready_subtitle,
            onTap: _isSendingRoomReady ? null : _notifyRoomReady,
            isLoading: _isSendingRoomReady,
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          // Si la reserva está cancelada se ofrece reactivarla; si no, cancelarla
          if (_booking!.isCancelled)
            _buildActionTile(
              icon: Icons.restart_alt_rounded,
              title: S.of(context).admin_booking_reactivate_booking_title,
              subtitle: S.of(context).admin_booking_reactivate_booking_subtitle,
              onTap: _isReactivatingBooking ? null : _reactivateBooking,
              isLoading: _isReactivatingBooking,
              color: AppColors.success,
            )
          else
            _buildActionTile(
              icon: Icons.cancel_outlined,
              title: S.of(context).admin_booking_cancel_booking_title,
              subtitle: S.of(context).admin_booking_cancel_booking_subtitle,
              onTap: _isCancellingBooking ? null : _cancelBooking,
              isLoading: _isCancellingBooking,
              color: AppColors.error,
            ),
          // Eliminar la reserva es una acción exclusiva de admin
          if (_isCurrentUserAdmin) ...[
            const SizedBox(height: 12),
            _buildActionTile(
              icon: Icons.delete_forever,
              title: S.of(context).admin_booking_delete_booking_title,
              subtitle: S.of(context).admin_booking_delete_booking_subtitle,
              onTap: _isDeletingBooking ? null : _deleteBooking,
              isLoading: _isDeletingBooking,
              color: AppColors.error,
            ),
          ],
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
