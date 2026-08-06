import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../data/services/chat_media_service.dart';
import 'attachment_source_sheet.dart';

/// Widget de campo de entrada para el chat
class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.onSend,
    this.onSendAttachment,
    this.enabled = true,
    this.isUploading = false,
  });

  final void Function(String message) onSend;

  /// Se invoca con los archivos ya elegidos (uno o varios). Si es `null`, no se
  /// ofrece adjuntar.
  final void Function(List<ChatAttachmentDraft> drafts)? onSendAttachment;

  final bool enabled;

  /// Hay un adjunto subiéndose: se bloquea el botón para evitar duplicados.
  final bool isUploading;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  bool _hasText = false;

  bool get _canAttach =>
      widget.onSendAttachment != null && widget.enabled && !widget.isUploading;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSend(text);
    _controller.clear();
  }

  /// Abre el selector de origen y, si el usuario elige algo, entrega los
  /// archivos ya leídos en memoria a la pantalla.
  ///
  /// La galería y el selector de documentos permiten varios archivos; la cámara,
  /// por su naturaleza, solo uno.
  Future<void> _pickAttachment() async {
    final source = await AttachmentSourceSheet.show(context);
    if (source == null || !mounted) return;

    final mediaService = getIt<ChatMediaService>();

    try {
      final drafts = switch (source) {
        AttachmentSource.camera => await _captureFromCamera(mediaService),
        AttachmentSource.gallery => await mediaService.pickImages(),
        AttachmentSource.document => await mediaService.pickDocuments(),
      };

      if (drafts.isEmpty || !mounted) return;

      // Basta con que uno supere el límite para descartar el lote: subir a
      // medias dejaría al usuario sin saber qué llegó y qué no.
      if (drafts.any((d) => d.size > ChatMediaService.maxFileSizeBytes)) {
        _showError(S.of(context).chat_attachment_too_large);
        return;
      }

      widget.onSendAttachment?.call(drafts);
    } on ChatMediaException catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) _showError(S.of(context).chat_attachment_error);
    }
  }

  /// La cámara devuelve una sola foto; se normaliza a lista para tratar todos
  /// los orígenes por igual.
  Future<List<ChatAttachmentDraft>> _captureFromCamera(
    ChatMediaService mediaService,
  ) async {
    final draft = await mediaService.pickImage(source: ImageSource.camera);
    return draft == null ? const [] : [draft];
  }

  void _showError(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: const BoxDecoration(
        color: AppColors.black,
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (widget.onSendAttachment != null) ...[
              IconButton(
                onPressed: _canAttach ? _pickAttachment : null,
                tooltip: S.of(context).chat_attach_title,
                icon: Icon(
                  Icons.attach_file,
                  color: _canAttach ? AppColors.gold : AppColors.gray600,
                ),
              ),
              const SizedBox(width: AppTheme.spacing4),
            ],
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(color: AppColors.black),
                decoration: InputDecoration(
                  hintText: S.of(context).guest_chat_input_hint,
                  hintStyle: const TextStyle(color: AppColors.gray500),
                  filled: true,
                  fillColor: AppColors.backgroundInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing20,
                    vertical: AppTheme.spacing12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            AnimatedOpacity(
              opacity: _hasText && widget.enabled ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _hasText && widget.enabled ? _sendMessage : null,
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
