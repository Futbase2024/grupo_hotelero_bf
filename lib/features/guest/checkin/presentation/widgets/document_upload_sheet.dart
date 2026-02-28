import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/guest_entity.dart';
import 'document_camera_screen.dart';

/// Tamaño máximo de archivo (500KB)
const int _maxFileSizeBytes = 500 * 1024;

/// Dimensiones máximas para compresión
const int _maxDimension = 1200;

/// Bottom sheet para subir documento de identidad
class DocumentUploadSheet extends StatefulWidget {
  const DocumentUploadSheet({
    super.key,
    required this.guest,
    required this.onConfirm,
  });

  final GuestEntity guest;
  final void Function(DocumentType type, String number, Uint8List? imageBytes) onConfirm;

  static Future<void> show({
    required BuildContext context,
    required GuestEntity guest,
    required void Function(DocumentType type, String number, Uint8List? imageBytes) onConfirm,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DocumentUploadSheet(
        guest: guest,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<DocumentUploadSheet> createState() => _DocumentUploadSheetState();
}

class _DocumentUploadSheetState extends State<DocumentUploadSheet> {
  late DocumentType _selectedType;
  late TextEditingController _documentController;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.guest.documentType ?? DocumentType.dniFront;
    _documentController = TextEditingController(text: widget.guest.documentNumber ?? '');
  }

  @override
  void dispose() {
    _documentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: AppTheme.spacing24,
        right: AppTheme.spacing24,
        top: AppTheme.spacing24,
        bottom: bottomPadding + AppTheme.spacing24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Title
            const Text(
              'Subir Documento',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              widget.guest.fullName,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Document type selector
            _buildDocumentTypeSelector(),
            const SizedBox(height: AppTheme.spacing20),

            // Document number field
            _buildDocumentNumberField(),
            const SizedBox(height: AppTheme.spacing24),

            // Image capture area
            _buildImageCaptureArea(),
            const SizedBox(height: AppTheme.spacing24),

            // Confirm button
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de documento',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Row(
          children: DocumentType.values.where((t) => t != DocumentType.other).map((type) {
            final isSelected = _selectedType == type;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type != DocumentType.values.last ? AppTheme.spacing8 : 0,
                ),
                child: _TypeButton(
                  label: _getDocumentTypeLabel(type),
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedType = type),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getDocumentTypeLabel(DocumentType type) {
    return type.label;
  }

  Widget _buildDocumentNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Número de documento',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        TextFormField(
          controller: _documentController,
          style: const TextStyle(color: AppColors.white),
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: _getDocumentHint(),
            hintStyle: const TextStyle(color: AppColors.gray500),
            filled: true,
            fillColor: AppColors.darkBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.darkBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.darkBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.gold, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  String _getDocumentHint() {
    switch (_selectedType) {
      case DocumentType.dniFront:
      case DocumentType.dniBack:
        return '12345678A';
      case DocumentType.passport:
        return 'ABC123456';
      case DocumentType.other:
        return 'Número de documento';
    }
  }

  Widget _buildImageCaptureArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto del documento',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _imageBytes != null ? AppColors.success : AppColors.darkBorder,
                width: _imageBytes != null ? 2 : 1,
              ),
            ),
            child: _imageBytes != null
                ? _buildImagePreview()
                : _buildUploadPlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.memory(
            _imageBytes!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _imageBytes = null),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.blackWithAlpha80,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: AppColors.white,
                size: 18,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppColors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  'Imagen capturada',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.goldWithAlpha10,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.camera_alt_outlined,
            color: AppColors.gold,
            size: 32,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        const Text(
          'Toca para capturar documento',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        const Text(
          'Cámara o galería',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Seleccionar origen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              Row(
                children: [
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.camera_alt,
                      label: 'Cámara',
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _openCameraWithGuide();
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.photo_library,
                      label: 'Galería',
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _pickImage(ImageSource.gallery);
                      },
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

  /// Abre la cámara con guía de escaneo
  Future<void> _openCameraWithGuide() async {
    try {
      setState(() => _isLoading = true);

      final bytes = await DocumentCameraScreen.capture(context);

      if (bytes != null) {
        debugPrint('📷 [DocumentUpload] Imagen capturada: ${bytes.length} bytes');

        // Comprimir si excede el tamaño máximo
        var processedBytes = bytes;
        if (bytes.length > _maxFileSizeBytes) {
          processedBytes = await _compressImage(bytes);
          debugPrint('📷 [DocumentUpload] Imagen comprimida: ${processedBytes.length} bytes');
        }

        setState(() => _imageBytes = processedBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar imagen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: _maxDimension.toDouble(),
        maxHeight: _maxDimension.toDouble(),
        imageQuality: 85,
      );

      if (image != null) {
        var bytes = await image.readAsBytes();
        debugPrint('📷 [DocumentUpload] Imagen capturada: ${bytes.length} bytes');

        // Comprimir si excede el tamaño máximo
        if (bytes.length > _maxFileSizeBytes) {
          bytes = await _compressImage(bytes);
          debugPrint('📷 [DocumentUpload] Imagen comprimida: ${bytes.length} bytes');
        }

        setState(() => _imageBytes = bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar imagen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Comprime una imagen si excede el tamaño máximo
  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      // Decodificar imagen
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Calcular nuevas dimensiones manteniendo aspect ratio
      var width = image.width.toDouble();
      var height = image.height.toDouble();

      // Reducir dimensiones hasta que el tamaño sea aceptable
      while (imageBytes.length > _maxFileSizeBytes && width > 400 && height > 400) {
        width *= 0.8;
        height *= 0.8;

        // Redimensionar
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final paint = Paint()..filterQuality = FilterQuality.high;
        canvas.scale(width / image.width, height / image.height);
        canvas.drawImage(image, Offset.zero, paint);

        final picture = recorder.endRecording();
        final resizedImage = await picture.toImage(width.toInt(), height.toInt());
        final byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          imageBytes = byteData.buffer.asUint8List();
        }
      }

      image.dispose();
      codec.dispose();

      return imageBytes;
    } catch (e) {
      debugPrint('❌ [DocumentUpload] Error al comprimir: $e');
      return imageBytes; // Devolver original si falla
    }
  }

  Widget _buildConfirmButton() {
    final canConfirm = _documentController.text.isNotEmpty && _imageBytes != null;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading || !canConfirm
            ? null
            : () {
                widget.onConfirm(
                  _selectedType,
                  _documentController.text.toUpperCase(),
                  _imageBytes!,
                );
                Navigator.pop(context);
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.black,
          disabledBackgroundColor: AppColors.gray600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.black,
                ),
              )
            : Text(
                _imageBytes == null ? 'Foto obligatoria' : 'Confirmar',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Botón de tipo de documento
class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : AppColors.darkBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.darkBorder,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.black : AppColors.white,
          ),
        ),
      ),
    );
  }
}

/// Botón de origen de imagen
class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.gold, size: 32),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
