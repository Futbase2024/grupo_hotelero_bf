import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/guest_entity.dart';
import 'document_camera_screen.dart';

/// Tamaño máximo de archivo (500KB)
const int _maxFileSizeBytes = 500 * 1024;

/// Dimensiones máximas para compresión
const int _maxDimension = 1200;

/// Cara del documento que se está capturando
enum _DocumentSide { front, back }

/// Bottom sheet para subir documento de identidad.
///
/// Pide el tipo REAL del documento (DNI, NIE o pasaporte) y sus fotos: dos
/// caras para DNI y NIE, una sola (página de datos) para el pasaporte.
class DocumentUploadSheet extends StatefulWidget {
  const DocumentUploadSheet({
    super.key,
    required this.guest,
    required this.onConfirm,
  });

  final GuestEntity guest;
  final void Function(
    DocumentType type,
    String number,
    Uint8List? frontBytes,
    Uint8List? backBytes,
  ) onConfirm;

  static Future<void> show({
    required BuildContext context,
    required GuestEntity guest,
    required void Function(
      DocumentType type,
      String number,
      Uint8List? frontBytes,
      Uint8List? backBytes,
    ) onConfirm,
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
  Uint8List? _frontBytes;
  Uint8List? _backBytes;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  /// Tipos ofrecidos al huésped ('other' queda fuera del selector)
  static const _selectableTypes = [
    DocumentType.dni,
    DocumentType.nie,
    DocumentType.passport,
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.guest.documentType ?? DocumentType.dni;
    _documentController = TextEditingController(text: widget.guest.documentNumber ?? '');
  }

  @override
  void dispose() {
    _documentController.dispose();
    super.dispose();
  }

  /// Si las fotos ya subidas siguen sirviendo para el tipo seleccionado.
  ///
  /// Al cambiar de DNI a pasaporte (o al revés) cambia el `doc_kind` con el
  /// que se guardan, así que las anteriores dejan de valer y hay que repetirlas.
  bool get _keepsUploadedPhotos =>
      widget.guest.documentType?.frontDocKind == _selectedType.frontDocKind;

  /// El anverso está resuelto si se acaba de capturar o ya estaba subido
  bool get _hasFront =>
      _frontBytes != null || (_keepsUploadedPhotos && widget.guest.hasDocumentFront);

  /// Igual para el reverso, que sólo se pide en DNI y NIE
  bool get _hasBack =>
      _backBytes != null || (_keepsUploadedPhotos && widget.guest.hasDocumentBack);

  bool get _hasAllPhotos =>
      _hasFront && (!_selectedType.requiresBackSide || _hasBack);

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Container(
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
              Text(
                S.of(context).guest_checkin_upload_document_title,
                style: const TextStyle(
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
              _DocumentTypeSelector(
                types: _selectableTypes,
                selectedType: _selectedType,
                onChanged: (type) => setState(() => _selectedType = type),
              ),
              const SizedBox(height: AppTheme.spacing20),

              // Document number field
              _buildDocumentNumberField(),
              const SizedBox(height: AppTheme.spacing24),

              // Image capture area
              _buildPhotosSection(),
              const SizedBox(height: AppTheme.spacing24),

              // Confirm button
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).guest_checkin_document_number,
          style: const TextStyle(
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
          onChanged: (_) => setState(() {}),
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
      case DocumentType.dni:
        return '12345678A';
      case DocumentType.nie:
        return 'X1234567L';
      case DocumentType.passport:
        return 'ABC123456';
      case DocumentType.other:
        return S.of(context).guest_checkin_document_number;
    }
  }

  Widget _buildPhotosSection() {
    final requiresBack = _selectedType.requiresBackSide;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).guest_checkin_document_photo,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _DocumentPhotoSlot(
                  label: requiresBack
                      ? S.of(context).guest_checkin_document_side_front
                      : S.of(context).guest_checkin_document_passport_page,
                  imageBytes: _frontBytes,
                  alreadyUploaded: _keepsUploadedPhotos && widget.guest.hasDocumentFront,
                  onTap: () => _showImageSourceDialog(_DocumentSide.front),
                  onRemove: _frontBytes != null
                      ? () => setState(() => _frontBytes = null)
                      : null,
                ),
              ),
              if (requiresBack) ...[
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: _DocumentPhotoSlot(
                    label: S.of(context).guest_checkin_document_side_back,
                    imageBytes: _backBytes,
                    alreadyUploaded: _keepsUploadedPhotos && widget.guest.hasDocumentBack,
                    onTap: () => _showImageSourceDialog(_DocumentSide.back),
                    onRemove: _backBytes != null
                        ? () => setState(() => _backBytes = null)
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog(_DocumentSide side) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                S.of(context).guest_checkin_select_source,
                style: const TextStyle(
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
                      label: S.of(context).guest_checkin_camera,
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _openCameraWithGuide(side);
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.photo_library,
                      label: S.of(context).guest_checkin_gallery,
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _pickImage(ImageSource.gallery, side);
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

  /// Guarda los bytes capturados en la cara correspondiente
  void _setSideBytes(_DocumentSide side, Uint8List bytes) {
    setState(() {
      switch (side) {
        case _DocumentSide.front:
          _frontBytes = bytes;
        case _DocumentSide.back:
          _backBytes = bytes;
      }
    });
  }

  /// Abre la cámara con guía de escaneo
  Future<void> _openCameraWithGuide(_DocumentSide side) async {
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

        _setSideBytes(side, processedBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).guest_checkin_capture_error(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source, _DocumentSide side) async {
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

        _setSideBytes(side, bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).guest_checkin_capture_error(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Comprime una imagen si excede el tamaño máximo
  ///
  /// Re-codifica a JPEG bajando la calidad por pasos. Se usa JPEG (y no PNG)
  /// porque para una foto de documento el PNG resultante suele pesar MÁS que
  /// el original, que era justo lo que hacía fallar subidas en móviles con
  /// cámaras de muchos megapíxeles.
  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      var result = imageBytes;

      for (final quality in const [80, 60, 40]) {
        result = await FlutterImageCompress.compressWithList(
          imageBytes,
          minWidth: _maxDimension,
          minHeight: _maxDimension,
          quality: quality,
          format: CompressFormat.jpeg,
        );

        debugPrint('📷 [DocumentUpload] Calidad $quality → ${result.length} bytes');

        if (result.length <= _maxFileSizeBytes) break;
      }

      // Si aun así no baja del límite, se queda la versión más comprimida
      // siempre que sea menor que la original.
      return result.length < imageBytes.length ? result : imageBytes;
    } catch (e) {
      debugPrint('❌ [DocumentUpload] Error al comprimir: $e');
      return imageBytes; // Devolver original si falla
    }
  }

  Widget _buildConfirmButton() {
    final hasDocumentNumber = _documentController.text.isNotEmpty;
    final canConfirm = hasDocumentNumber && _hasAllPhotos;

    String buttonText;
    if (_isLoading) {
      buttonText = '';
    } else if (!_hasAllPhotos) {
      buttonText = S.of(context).guest_checkin_photo_required;
    } else if (!hasDocumentNumber) {
      buttonText = S.of(context).guest_checkin_document_number_required;
    } else {
      buttonText = S.of(context).guest_checkin_confirm;
    }

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
                  _frontBytes,
                  _selectedType.requiresBackSide ? _backBytes : null,
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
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Selector del tipo de documento (DNI / NIE / Pasaporte)
class _DocumentTypeSelector extends StatelessWidget {
  const _DocumentTypeSelector({
    required this.types,
    required this.selectedType,
    required this.onChanged,
  });

  final List<DocumentType> types;
  final DocumentType selectedType;
  final ValueChanged<DocumentType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).guest_checkin_document_type,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Row(
          children: types.map((type) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type != types.last ? AppTheme.spacing8 : 0,
                ),
                child: _TypeButton(
                  label: _labelFor(context, type),
                  isSelected: selectedType == type,
                  onTap: () => onChanged(type),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _labelFor(BuildContext context, DocumentType type) {
    switch (type) {
      case DocumentType.dni:
        return S.of(context).guest_checkin_document_type_dni;
      case DocumentType.nie:
        return S.of(context).guest_checkin_document_type_nie;
      case DocumentType.passport:
        return S.of(context).guest_checkin_document_type_passport;
      case DocumentType.other:
        return S.of(context).guest_checkin_document;
    }
  }
}

/// Hueco de captura de una cara del documento
class _DocumentPhotoSlot extends StatelessWidget {
  const _DocumentPhotoSlot({
    required this.label,
    required this.imageBytes,
    required this.alreadyUploaded,
    required this.onTap,
    this.onRemove,
  });

  /// Etiqueta de la cara ("Anverso", "Reverso", "Página de datos")
  final String label;

  /// Bytes recién capturados, si los hay
  final Uint8List? imageBytes;

  /// Si esta cara ya estaba subida de una sesión anterior
  final bool alreadyUploaded;

  final VoidCallback onTap;
  final VoidCallback? onRemove;

  bool get _isResolved => imageBytes != null || alreadyUploaded;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isResolved ? AppColors.success : AppColors.darkBorder,
                width: _isResolved ? 2 : 1,
              ),
            ),
            child: imageBytes != null
                ? _PhotoPreview(imageBytes: imageBytes!, onRemove: onRemove)
                : _PhotoPlaceholder(alreadyUploaded: alreadyUploaded),
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Row(
          children: [
            if (_isResolved) ...[
              const Icon(Icons.check_circle, color: AppColors.success, size: 14),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _isResolved ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Vista previa de una foto recién capturada
class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.imageBytes, this.onRemove});

  final Uint8List imageBytes;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.memory(
            imageBytes,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
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
      ],
    );
  }
}

/// Placeholder de un hueco sin foto todavía
class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.alreadyUploaded});

  /// Si la cara ya estaba subida antes: se puede reemplazar tocando encima
  final bool alreadyUploaded;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: alreadyUploaded
                ? AppColors.successWithAlpha10
                : AppColors.goldWithAlpha10,
            shape: BoxShape.circle,
          ),
          child: Icon(
            alreadyUploaded ? Icons.check : Icons.camera_alt_outlined,
            color: alreadyUploaded ? AppColors.success : AppColors.gold,
            size: 28,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            alreadyUploaded
                ? S.of(context).guest_checkin_image_captured
                : S.of(context).guest_checkin_tap_to_capture,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: alreadyUploaded ? AppColors.success : AppColors.gold,
            ),
          ),
        ),
      ],
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
