import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bf_stay/core/di/injection.dart';
import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/core/services/notification_service.dart';
import 'package:bf_stay/features/admin/checkins/presentation/widgets/checkin_danger_actions_sheet.dart';
import 'package:bf_stay/features/admin/domain/entities/admin_entities.dart';
import 'package:bf_stay/features/admin/domain/repositories/admin_panel_repository.dart';
import 'package:bf_stay/features/admin/domain/services/email_service.dart';
import 'package:bf_stay/features/auth/domain/bloc/auth_bloc.dart';
import 'package:bf_stay/l10n/app_localizations.dart';

/// Pantalla de detalle de check-in para administración
/// Muestra huéspedes, documentos y firma del check-in
class CheckinDetailScreen extends StatefulWidget {
  const CheckinDetailScreen({
    super.key,
    required this.checkinId,
    this.bookingCode,
  });

  final String checkinId;
  final String? bookingCode;

  @override
  State<CheckinDetailScreen> createState() => _CheckinDetailScreenState();
}

class _CheckinDetailScreenState extends State<CheckinDetailScreen> {
  CheckinDetailEntity? _checkinDetail;
  bool _isLoading = true;
  String? _error;
  final Map<String, String> _documentUrls = {};

  @override
  void initState() {
    super.initState();
    _loadCheckinDetail();
  }

  Future<void> _loadCheckinDetail() async {
    debugPrint('🔍 [CheckinDetail] _loadCheckinDetail - checkinId: ${widget.checkinId}');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = getIt<AdminPanelRepository>();
      debugPrint('🔍 [CheckinDetail] Llamando a getCheckinDetail...');
      final detail = await repository.getCheckinDetail(widget.checkinId);

      debugPrint('✅ [CheckinDetail] Datos cargados:');
      debugPrint('   - Status: ${detail.checkinStatus}');
      debugPrint('   - Huéspedes: ${detail.guests.length}');
      debugPrint('   - Documentos: ${detail.documents.length}');
      debugPrint('   - Firma: ${detail.signatureSvg != null ? "Sí" : "No"}');
      debugPrint('   - Property: ${detail.propertyName}');
      debugPrint('   - Unit: ${detail.unitName}');

      // Cargar URLs de documentos
      for (final doc in detail.documents) {
        try {
          debugPrint('🔍 [CheckinDetail] Cargando URL documento: ${doc.id}');
          final url = await repository.getDocumentUrl(doc.storagePath);
          debugPrint('✅ [CheckinDetail] URL cargada para doc ${doc.id}');
          if (mounted) {
            setState(() {
              _documentUrls[doc.id] = url;
            });
          }
        } catch (e) {
          debugPrint('❌ [CheckinDetail] Error cargando URL de documento: $e');
        }
      }

      if (mounted) {
        debugPrint('✅ [CheckinDetail] Actualizando estado - _isLoading = false');
        setState(() {
          _checkinDetail = detail;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [CheckinDetail] ERROR: $e');
      debugPrint('❌ [CheckinDetail] StackTrace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug: mostrar estado del check-in
    debugPrint('🏗️ [CheckinDetail] BUILD - Status: ${_checkinDetail?.checkinStatus}, isPending: ${_checkinDetail?.isPending}');

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.bookingCode ?? S.of(context).admin_checkin_detail_title,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          // Mostrar acciones para check-ins que se pueden actuar (pendientes o rechazados)
          if (_checkinDetail != null && !_checkinDetail!.isValidated && !_checkinDetail!.isCancelled) ...[
            // Solo mostrar Validar y Rechazar si está pendiente (submitted)
            if (_checkinDetail!.isPending) ...[
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
                tooltip: S.of(context).admin_checkin_validate,
                onPressed: _validateCheckin,
              ),
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: AppColors.warning),
                tooltip: S.of(context).admin_checkin_reject,
                onPressed: _showRejectDialog,
              ),
            ],
            // Cancelar disponible tanto si está pendiente como rechazado
            IconButton(
              icon: const Icon(Icons.cancel_schedule_send_outlined,
                  color: AppColors.error),
              tooltip: S.of(context).admin_checkin_cancel_booking,
              onPressed: _showCancelDialog,
            ),
          ],
          // Borrar check-in / borrar reserva: disponible en cualquier estado
          if (_checkinDetail != null)
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.white),
              tooltip: S.of(context).admin_checkin_more_actions,
              onPressed: _showDangerActions,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    debugPrint('🏗️ [CheckinDetail] _buildBody - _isLoading: $_isLoading, _error: ${_error != null}, _checkinDetail: ${_checkinDetail != null}');

    if (_isLoading) {
      debugPrint('🏗️ [CheckinDetail] Renderizando LOADING');
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (_error != null) {
      debugPrint('🏗️ [CheckinDetail] Renderizando ERROR: $_error');
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 100),
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  S.of(context).admin_checkin_error_loading,
                  style: TextStyle(color: AppColors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: AppColors.gray400, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadCheckinDetail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                  ),
                  child: Text(S.of(context).common_retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_checkinDetail == null) {
      debugPrint('🏗️ [CheckinDetail] Renderizando NULL');
      return Center(
        child: Text(S.of(context).admin_checkin_not_found, style: const TextStyle(color: AppColors.white)),
      );
    }

    debugPrint('🏗️ [CheckinDetail] Renderizando CONTENIDO PRINCIPAL');
    debugPrint('   - Huéspedes a renderizar: ${_checkinDetail!.guests.length}');
    debugPrint('   - Documentos a renderizar: ${_checkinDetail!.documents.length}');

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.darkSurface,
      onRefresh: _loadCheckinDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildBookingInfo(),
            const SizedBox(height: 16),
            _buildGuestsSection(),
            if (_checkinDetail!.documents.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDocumentsSection(),
            ],
            if (_checkinDetail!.signatureSvg != null) ...[
              const SizedBox(height: 16),
              _buildSignatureSection(),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _checkinDetail!.checkinStatus;
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'submitted':
        statusColor = const Color(0xFFE67E22);
        statusText = S.of(context).admin_checkin_status_pending;
        statusIcon = Icons.pending_actions;
        break;
      case 'validated':
        statusColor = const Color(0xFF27AE60);
        statusText = S.of(context).admin_checkin_status_validated;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = const Color(0xFFE67E22);
        statusText = S.of(context).admin_checkin_status_rejected;
        statusIcon = Icons.cancel;
        break;
      case 'cancelled':
        statusColor = const Color(0xFFC0392B);
        statusText = S.of(context).admin_checkin_status_cancelled;
        statusIcon = Icons.delete_forever;
        break;
      default:
        statusColor = AppColors.gray500;
        statusText = S.of(context).admin_checkin_status_draft;
        statusIcon = Icons.edit_document;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: AppColors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_checkinDetail!.submittedAt != null)
                  Text(
                    '${S.of(context).admin_checkin_submitted_label} ${_formatDateTime(_checkinDetail!.submittedAt!)}',
                    style: TextStyle(color: AppColors.gray400, fontSize: 12),
                  ),
                if (_checkinDetail!.validatedAt != null)
                  Text(
                    '${S.of(context).admin_checkin_validated_label} ${_formatDateTime(_checkinDetail!.validatedAt!)}',
                    style: TextStyle(color: AppColors.gray400, fontSize: 12),
                  ),
                if (_checkinDetail!.rejectedAt != null)
                  Text(
                    '${S.of(context).admin_checkin_rejected_label} ${_formatDateTime(_checkinDetail!.rejectedAt!)}',
                    style: TextStyle(color: AppColors.gray400, fontSize: 12),
                  ),
                if (_checkinDetail!.cancelledAt != null)
                  Text(
                    '${S.of(context).admin_checkin_cancelled_label} ${_formatDateTime(_checkinDetail!.cancelledAt!)}',
                    style: TextStyle(color: AppColors.gray400, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingInfo() {
    return Container(
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
              const Icon(Icons.home_work, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                S.of(context).admin_checkin_booking_info,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(S.of(context).admin_checkin_property_label, _checkinDetail!.propertyName),
          _buildInfoRow(
            _checkinDetail!.hasMultipleUnits ? S.of(context).admin_checkin_units_label : S.of(context).admin_checkin_unit_label,
            _checkinDetail!.allUnitNames,
          ),
          _buildInfoRow(S.of(context).admin_checkin_code_label, _checkinDetail!.bookingCode, isCode: true),
          _buildInfoRow(
            S.of(context).admin_checkin_checkin_date_label,
            DateFormat('dd/MM/yyyy').format(_checkinDetail!.checkinDate),
          ),
          _buildInfoRow(
            S.of(context).admin_checkin_checkout_date_label,
            DateFormat('dd/MM/yyyy').format(_checkinDetail!.checkoutDate),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isCode = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.gray400, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: isCode ? AppColors.gold : AppColors.white,
              fontSize: 14,
              fontFamily: isCode ? 'JetBrains Mono' : null,
              fontWeight: isCode ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestsSection() {
    return Container(
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
              const Icon(Icons.people, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                '${S.of(context).admin_checkin_guests_section} (${_checkinDetail!.guests.length})',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_checkinDetail!.guests.map((guest) => _buildGuestCard(guest))),
        ],
      ),
    );
  }

  Widget _buildGuestCard(CheckinGuestEntity guest) {
    final guestDocs = _checkinDetail!.documentsForGuest(guest.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: guest.isPrimary ? AppColors.gold.withValues(alpha: 0.3) : AppColors.darkBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (guest.isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    S.of(context).admin_checkin_primary_badge,
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  guest.fullName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (guest.email != null && guest.email!.isNotEmpty)
            _buildGuestDetailRow(Icons.email, guest.email!),
          if (guest.phone != null && guest.phone!.isNotEmpty)
            _buildGuestDetailRow(Icons.phone, guest.phone!),
          if (guest.documentType != null)
            _buildGuestDetailRow(
              Icons.badge,
              '${_getDocumentTypeLabel(guest.documentType!)}: ${guest.documentNumber ?? S.of(context).admin_checkin_na}',
            ),
          if (guest.nationality != null)
            _buildGuestDetailRow(Icons.flag, guest.nationality!),
          if (guest.birthDate != null)
            _buildGuestDetailRow(
              Icons.cake,
              DateFormat('dd/MM/yyyy').format(guest.birthDate!),
            ),
          if (guestDocs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: guestDocs.map((doc) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        doc.docKindLabel,
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuestDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.gray500),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: AppColors.gray300, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Container(
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
              const Icon(Icons.folder_open, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                '${S.of(context).admin_checkin_documents_section} (${_checkinDetail!.documents.length})',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_checkinDetail!.documents.map((doc) => _buildDocumentItem(doc))),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(CheckinDocumentEntity doc) {
    final url = _documentUrls[doc.id];
    final guestName = _checkinDetail!.guests
        .where((g) => g.id == doc.guestId)
        .firstOrNull?.fullName ?? S.of(context).admin_checkin_unknown_guest;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.goldWithAlpha20,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image, color: AppColors.gold, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.docKindLabel,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  guestName,
                  style: TextStyle(color: AppColors.gray400, fontSize: 12),
                ),
              ],
            ),
          ),
          if (url != null)
            IconButton(
              icon: const Icon(Icons.visibility, color: AppColors.gold),
              onPressed: () => _showDocumentPreview(url, doc.docKindLabel),
            ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Container(
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
              const Icon(Icons.draw, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                S.of(context).admin_checkin_signature_section,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomPaint(
                painter: SignaturePainter(_checkinDetail!.signatureSvg!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  String _getDocumentTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'dni':
      // Valores heredados de cuando el tipo y la cara se guardaban juntos
      case 'dni_front':
      case 'dni_back':
        return S.of(context).admin_checkin_doc_type_dni;
      case 'nie':
        return S.of(context).admin_checkin_doc_type_nie;
      case 'passport':
        return S.of(context).admin_checkin_doc_type_passport;
      default:
        return type.toUpperCase();
    }
  }

  void _showDocumentPreview(String url, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(title, style: TextStyle(color: AppColors.white)),
              leading: IconButton(
                icon: const Icon(Icons.close, color: AppColors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  progressIndicatorBuilder: (context, url, downloadProgress) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gold,
                        value: downloadProgress.progress,
                      ),
                    );
                  },
                  errorWidget: (context, url, error) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: AppColors.error, size: 48),
                          SizedBox(height: 8),
                          Text(
                            S.of(context).admin_checkin_image_load_error,
                            style: TextStyle(color: AppColors.gray400),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validateCheckin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(S.of(context).admin_checkin_validate_title, style: TextStyle(color: AppColors.white)),
        content: Text(
          S.of(context).admin_checkin_validate_message,
          style: TextStyle(color: AppColors.gray300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).common_cancel, style: TextStyle(color: AppColors.gray400)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: Text(S.of(context).admin_checkin_validate, style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // 1. Validar el check-in en la base de datos
        await Supabase.instance.client.rpc(
          'validate_checkin',
          params: {'p_checkin_id': widget.checkinId},
        );

        // 2. Enviar email de confirmación al huésped
        if (_checkinDetail != null) {
          final primaryGuest = _checkinDetail!.primaryGuest;
          if (primaryGuest?.email != null && primaryGuest!.email!.isNotEmpty) {
            debugPrint('📧 [ValidateCheckin] Enviando email a: ${primaryGuest.email}');
            final emailSent = await EmailService().sendCheckinConfirmationEmail(
              toEmail: primaryGuest.email!,
              guestName: primaryGuest.fullName,
              propertyName: _checkinDetail!.propertyName,
              unitName: _checkinDetail!.allUnitNames,
              checkinDate: _checkinDetail!.checkinDate,
              checkoutDate: _checkinDetail!.checkoutDate,
              bookingCode: _checkinDetail!.bookingCode,
              accessInstructions: _checkinDetail!.accessInstructions,
              wifiNetwork: _checkinDetail!.wifiNetwork,
              wifiPassword: _checkinDetail!.wifiPassword,
              fullAddress: _checkinDetail!.fullAddress,
              bookingId: _checkinDetail!.bookingId,
              unitId: _checkinDetail!.unitId,
            );
            debugPrint('📧 [ValidateCheckin] Email enviado: $emailSent');
          } else {
            debugPrint('⚠️ [ValidateCheckin] No hay email del huésped para enviar confirmación');
          }
        }

        // 3. La notificación al huésped (in-app + push) la dispara el trigger
        // de backend trg_checkin_status_notify al cambiar checkins.status a
        // 'validated'. Así funciona valide el admin desde donde valide.

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).admin_checkin_validated_success),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.fixed,
            ),
          );
          // Regresar a la pantalla anterior y devolver true para indicar éxito
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).admin_checkin_error(e.toString())),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.fixed,
            ),
          );
        }
      }
    }
  }

  Future<void> _showRejectDialog() async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(S.of(context).admin_checkin_reject_title, style: TextStyle(color: AppColors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              S.of(context).admin_checkin_reject_message,
              style: TextStyle(color: AppColors.gray300),
            ),
            SizedBox(height: 12),
            TextField(
              controller: reasonController,
              style: TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: S.of(context).admin_checkin_reject_hint,
                hintStyle: TextStyle(color: AppColors.gray500),
                filled: true,
                fillColor: AppColors.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.darkBorder),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).common_cancel, style: TextStyle(color: AppColors.gray400)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text(S.of(context).admin_checkin_reject, style: TextStyle(color: AppColors.black)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final reason = reasonController.text.trim().isEmpty
          ? S.of(context).admin_checkin_no_reason
          : reasonController.text.trim();

      try {
        // 1. Rechazar en la base de datos
        await Supabase.instance.client.rpc(
          'reject_checkin',
          params: {
            'p_checkin_id': widget.checkinId,
            'p_reason': reason,
          },
        );

        // 2. Enviar email de rechazo al huésped
        if (_checkinDetail != null) {
          final primaryGuest = _checkinDetail!.primaryGuest;
          if (primaryGuest?.email != null && primaryGuest!.email!.isNotEmpty) {
            debugPrint('📧 [RejectCheckin] Enviando email a: ${primaryGuest.email}');
            await EmailService().sendCheckinRejectionEmail(
              toEmail: primaryGuest.email!,
              guestName: primaryGuest.fullName,
              propertyName: _checkinDetail!.propertyName,
              unitName: _checkinDetail!.allUnitNames,
              checkinDate: _checkinDetail!.checkinDate,
              checkoutDate: _checkinDetail!.checkoutDate,
              reason: reason,
              bookingId: _checkinDetail!.bookingId,
              unitId: _checkinDetail!.unitId,
            );
          }
        }

        // 3. La notificación al huésped (in-app + push) la dispara el trigger
        // de backend trg_checkin_status_notify al cambiar checkins.status a
        // 'rejected'.

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).admin_checkin_rejected_success),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.fixed,
            ),
          );
          // Regresar a la pantalla anterior y devolver true para indicar éxito
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).admin_checkin_error(e.toString())),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.fixed,
            ),
          );
        }
      }
    }
  }

  Future<void> _showCancelDialog() async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text(S.of(context).admin_checkin_cancel_booking, style: TextStyle(color: AppColors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).admin_checkin_cancel_message,
              style: TextStyle(color: AppColors.gray300),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      S.of(context).admin_checkin_cancel_warning,
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              S.of(context).admin_checkin_cancel_reason_label,
              style: TextStyle(color: AppColors.gray300),
            ),
            SizedBox(height: 8),
            TextField(
              controller: reasonController,
              style: TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: S.of(context).admin_checkin_cancel_reason_hint,
                hintStyle: TextStyle(color: AppColors.gray500),
                filled: true,
                fillColor: AppColors.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.darkBorder),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).common_back, style: TextStyle(color: AppColors.gray400)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(S.of(context).admin_checkin_cancel_booking, style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final reason = reasonController.text.trim().isEmpty
          ? S.of(context).admin_checkin_no_reason
          : reasonController.text.trim();

      try {
        // 1. Cancelar en la base de datos
        await getIt<AdminPanelRepository>().cancelCheckin(
          checkinId: widget.checkinId,
          bookingId: _checkinDetail?.bookingId ?? '',
          reason: reason,
        );

        // 2. Enviar email de cancelación al huésped
        if (_checkinDetail != null) {
          final primaryGuest = _checkinDetail!.primaryGuest;
          if (primaryGuest?.email != null && primaryGuest!.email!.isNotEmpty) {
            debugPrint('📧 [CancelCheckin] Enviando email a: ${primaryGuest.email}');
            await EmailService().sendCheckinCancellationEmail(
              toEmail: primaryGuest.email!,
              guestName: primaryGuest.fullName,
              propertyName: _checkinDetail!.propertyName,
              unitName: _checkinDetail!.allUnitNames,
              checkinDate: _checkinDetail!.checkinDate,
              checkoutDate: _checkinDetail!.checkoutDate,
              reason: reason,
              bookingId: _checkinDetail!.bookingId,
              unitId: _checkinDetail!.unitId,
            );
          }
        }

        // 3. Enviar notificación push al huésped
        if (_checkinDetail?.bookingId != null) {
          debugPrint('📱 [CancelCheckin] Enviando push notification...');
          await NotificationService().notifyGuestCheckinStatus(
            bookingId: _checkinDetail!.bookingId,
            status: 'cancelled',
            reason: reason,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).admin_checkin_cancelled_success),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.fixed,
            ),
          );
          // Regresar a la pantalla anterior y devolver true para indicar éxito
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).admin_checkin_error(e.toString())),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.fixed,
            ),
          );
        }
      }
    }
  }

  /// Abre la hoja para borrar solo el check-in o la reserva completa
  Future<void> _showDangerActions() async {
    final detail = _checkinDetail;
    if (detail == null) return;

    final authState = context.read<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;

    final result = await CheckinDangerActionsSheet.show(
      context: context,
      repository: getIt<AdminPanelRepository>(),
      bookingId: detail.bookingId,
      bookingCode: detail.bookingCode,
      isAdmin: isAdmin,
    );

    if (result == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == CheckinDangerResult.checkinDeleted
              ? S.of(context).admin_checkin_deleted_success
              : S.of(context).admin_checkin_booking_deleted_success,
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.fixed,
      ),
    );

    // Devolver true para que la lista de check-ins se refresque
    Navigator.pop(context, true);
  }
}

/// Painter para renderizar la firma SVG
class SignaturePainter extends CustomPainter {
  SignaturePainter(this.svgPath);

  final String svgPath;

  @override
  void paint(Canvas canvas, Size size) {
    if (svgPath.isEmpty) return;

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Parsear paths del SVG
    // Formato esperado: M x,y L x,y L x,y... o M x,y C ...
    final path = Path();

    try {
      // Extraer el atributo d del path
      final dMatch = RegExp(r'd="([^"]+)"').firstMatch(svgPath);
      final d = dMatch?.group(1) ?? svgPath;

      // Parsear comandos SVG básicos
      final commands = RegExp(r'[MLHVCSQTAZ][^MLHVCSQTAZ]*', caseSensitive: false);
      double currentX = 0;
      double currentY = 0;

      for (final match in commands.allMatches(d)) {
        final command = match.group(0)!;
        final type = command[0].toUpperCase();
        final argsStr = command.substring(1).trim();
        final args = RegExp(r'[-\d.]+')
            .allMatches(argsStr)
            .map((m) => double.parse(m.group(0)!))
            .toList();

        switch (type) {
          case 'M':
            if (args.length >= 2) {
              currentX = args[0];
              currentY = args[1];
              path.moveTo(currentX, currentY);
            }
            break;
          case 'L':
            if (args.length >= 2) {
              currentX = args[0];
              currentY = args[1];
              path.lineTo(currentX, currentY);
            }
            break;
          case 'C':
            if (args.length >= 6) {
              path.cubicTo(
                args[0], args[1],
                args[2], args[3],
                args[4], args[5],
              );
              currentX = args[4];
              currentY = args[5];
            }
            break;
          case 'Z':
            path.close();
            break;
        }
      }
    } catch (e) {
      debugPrint('Error parsing SVG: $e');
    }

    // Escalar para ajustar al tamaño del contenedor
    final bounds = path.getBounds();
    if (bounds.width > 0 && bounds.height > 0) {
      final scaleX = size.width / bounds.width;
      final scaleY = size.height / bounds.height;
      final scale = scaleX < scaleY ? scaleX : scaleY;

      canvas.translate(
        (size.width - bounds.width * scale) / 2 - bounds.left * scale,
        (size.height - bounds.height * scale) / 2 - bounds.top * scale,
      );
      canvas.scale(scale, scale);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}