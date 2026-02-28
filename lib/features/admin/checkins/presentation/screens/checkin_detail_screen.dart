import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bf_stay/core/di/injection.dart';
import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/features/admin/domain/entities/admin_entities.dart';
import 'package:bf_stay/features/admin/domain/repositories/admin_panel_repository.dart';
import 'package:bf_stay/features/admin/domain/bloc/bloc.dart';

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
          widget.bookingCode ?? 'Detalle Check-in',
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          if (_checkinDetail != null && _checkinDetail!.isPending) ...[
            IconButton(
              icon: const Icon(Icons.check_circle, color: AppColors.success),
              tooltip: 'Validar',
              onPressed: () => _validateCheckin(),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: AppColors.error),
              tooltip: 'Rechazar',
              onPressed: () => _showRejectDialog(),
            ),
          ],
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
                  'Error al cargar el check-in',
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
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_checkinDetail == null) {
      debugPrint('🏗️ [CheckinDetail] Renderizando NULL');
      return const Center(
        child: Text('No se encontró el check-in', style: TextStyle(color: AppColors.white)),
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
        statusText = 'Pendiente de validación';
        statusIcon = Icons.pending_actions;
        break;
      case 'validated':
        statusColor = const Color(0xFF27AE60);
        statusText = 'Validado';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = const Color(0xFFC0392B);
        statusText = 'Rechazado';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppColors.gray500;
        statusText = 'Borrador';
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
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
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
                    'Enviado: ${_formatDateTime(_checkinDetail!.submittedAt!)}',
                    style: TextStyle(color: AppColors.gray400, fontSize: 12),
                  ),
                if (_checkinDetail!.validatedAt != null)
                  Text(
                    'Validado: ${_formatDateTime(_checkinDetail!.validatedAt!)}',
                    style: TextStyle(color: AppColors.gray400, fontSize: 12),
                  ),
                if (_checkinDetail!.rejectedAt != null)
                  Text(
                    'Rechazado: ${_formatDateTime(_checkinDetail!.rejectedAt!)}',
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
                'Información de la reserva',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Propiedad', _checkinDetail!.propertyName),
          _buildInfoRow('Unidad', _checkinDetail!.unitName),
          _buildInfoRow('Código', _checkinDetail!.bookingCode, isCode: true),
          _buildInfoRow(
            'Check-in',
            DateFormat('dd/MM/yyyy').format(_checkinDetail!.checkinDate),
          ),
          _buildInfoRow(
            'Check-out',
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
                'Huéspedes (${_checkinDetail!.guests.length})',
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
                    'TITULAR',
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
              '${_getDocumentTypeLabel(guest.documentType!)}: ${guest.documentNumber ?? "N/A"}',
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
                'Documentos (${_checkinDetail!.documents.length})',
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
        .firstOrNull?.fullName ?? 'Huésped desconocido';

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
                'Firma del titular',
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
        return 'DNI';
      case 'nie':
        return 'NIE';
      case 'passport':
        return 'Pasaporte';
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
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gold,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: AppColors.error, size: 48),
                          SizedBox(height: 8),
                          Text(
                            'Error al cargar imagen',
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
        title: Text('Validar Check-in', style: TextStyle(color: AppColors.white)),
        content: Text(
          '¿Confirmar que el check-in es correcto? La reserva pasará a estado "Checked In".',
          style: TextStyle(color: AppColors.gray300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: AppColors.gray400)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: Text('Validar', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await Supabase.instance.client.rpc(
          'validate_checkin',
          params: {'p_checkin_id': widget.checkinId},
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check-in validado correctamente'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.fixed,
            ),
          );
          // Recargar datos del dashboard
          context.read<AdminDashboardBloc>().add(
            const AdminDashboardCheckinsLoadRequested(),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
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
        title: Text('Rechazar Check-in', style: TextStyle(color: AppColors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Indica el motivo del rechazo:',
              style: TextStyle(color: AppColors.gray300),
            ),
            SizedBox(height: 12),
            TextField(
              controller: reasonController,
              style: TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Ej: Documento ilegible',
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
            child: Text('Cancelar', style: TextStyle(color: AppColors.gray400)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Rechazar', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await Supabase.instance.client.rpc(
          'reject_checkin',
          params: {
            'p_checkin_id': widget.checkinId,
            'p_reason': reasonController.text.trim().isEmpty
                ? 'Sin motivo especificado'
                : reasonController.text.trim(),
          },
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check-in rechazado'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.fixed,
            ),
          );
          // Recargar datos del dashboard
          context.read<AdminDashboardBloc>().add(
            const AdminDashboardCheckinsLoadRequested(),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.fixed,
            ),
          );
        }
      }
    }
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
