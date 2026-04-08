import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

/// Pantalla de cámara con guía para escanear documentos
class DocumentCameraScreen extends StatefulWidget {
  const DocumentCameraScreen({super.key});

  static Future<Uint8List?> capture(BuildContext context) async {
    return Navigator.push<Uint8List?>(
      context,
      MaterialPageRoute(
        builder: (context) => const DocumentCameraScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<DocumentCameraScreen> createState() => _DocumentCameraScreenState();
}

class _DocumentCameraScreenState extends State<DocumentCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  String? _error;

  // Dimensiones del recuadro de escaneo (en coordenadas de pantalla)
  Rect? _scanFrameRect;
  Size? _screenSize;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _error = S.of(context).guest_checkin_camera_not_available);
        return;
      }

      // Usar cámara trasera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('❌ [DocumentCamera] Error: $e');
      setState(() => _error = S.of(context).guest_checkin_camera_init_error(e.toString()));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Callback para recibir las dimensiones del recuadro desde el overlay
  void _onFrameLayout(Rect frameRect, Size screenSize) {
    _scanFrameRect = frameRect;
    _screenSize = screenSize;
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_scanFrameRect == null || _screenSize == null) {
      debugPrint('❌ [DocumentCamera] No hay dimensiones del recuadro');
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final image = await _controller!.takePicture();
      final bytes = await File(image.path).readAsBytes();

      // Recortar la imagen al área del recuadro
      final croppedBytes = await _cropToScanFrame(bytes);

      if (mounted) {
        Navigator.pop(context, croppedBytes);
      }
    } catch (e) {
      debugPrint('❌ [DocumentCamera] Error al capturar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).guest_checkin_camera_capture_error(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  /// Recorta la imagen para mantener solo la zona del recuadro
  Future<Uint8List> _cropToScanFrame(Uint8List imageBytes) async {
    // Decodificar la imagen
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) {
      debugPrint('❌ [DocumentCamera] No se pudo decodificar la imagen');
      return imageBytes;
    }

    final imageWidth = originalImage.width;
    final imageHeight = originalImage.height;

    // Obtener dimensiones de la vista previa de la cámara
    final previewSize = _controller!.value.previewSize;
    if (previewSize == null) {
      debugPrint('❌ [DocumentCamera] No hay tamaño de preview');
      return imageBytes;
    }

    // La cámara puede estar rotada, necesitamos considerar la orientación
    // En móvil, normalmente la imagen capturada está en landscape
    // pero la preview se muestra en portrait
    final previewWidth = previewSize.height; // Intercambiado por rotación
    final previewHeight = previewSize.width;

    // Calcular cómo se escala la preview para llenar la pantalla
    final screenWidth = _screenSize!.width;
    final screenHeight = _screenSize!.height;

    // Factor de escala entre pantalla y preview
    final scaleX = previewWidth / screenWidth;
    final scaleY = previewHeight / screenHeight;

    // Convertir coordenadas del recuadro en pantalla a coordenadas de preview
    final frameInPreview = Rect.fromLTRB(
      _scanFrameRect!.left * scaleX,
      _scanFrameRect!.top * scaleY,
      _scanFrameRect!.right * scaleX,
      _scanFrameRect!.bottom * scaleY,
    );

    // Factor de escala entre preview y imagen capturada
    final imageScaleX = imageWidth / previewWidth;
    final imageScaleY = imageHeight / previewHeight;

    // Convertir a coordenadas de la imagen final
    final cropLeft = (frameInPreview.left * imageScaleX).round().clamp(0, imageWidth);
    final cropTop = (frameInPreview.top * imageScaleY).round().clamp(0, imageHeight);
    final cropRight = (frameInPreview.right * imageScaleX).round().clamp(0, imageWidth);
    final cropBottom = (frameInPreview.bottom * imageScaleY).round().clamp(0, imageHeight);

    final cropWidth = cropRight - cropLeft;
    final cropHeight = cropBottom - cropTop;

    debugPrint('📐 [DocumentCamera] Recorte: left=$cropLeft, top=$cropTop, width=$cropWidth, height=$cropHeight');
    debugPrint('📐 [DocumentCamera] Imagen original: ${imageWidth}x$imageHeight');

    // Recortar la imagen
    final croppedImage = img.copyCrop(
      originalImage,
      x: cropLeft,
      y: cropTop,
      width: cropWidth,
      height: cropHeight,
    );

    // Codificar de vuelta a JPEG
    return Uint8List.fromList(img.encodeJpg(croppedImage, quality: 90));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          S.of(context).guest_checkin_camera_scan_title,
          style: const TextStyle(color: AppColors.white),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.of(context).common_back),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.gold),
            const SizedBox(height: 16),
            Text(
              S.of(context).guest_checkin_camera_starting,
              style: const TextStyle(color: AppColors.white),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Vista de la cámara
        Center(
          child: CameraPreview(_controller!),
        ),

        // Guía de escaneo
        ScanGuideOverlay(onFrameLayout: _onFrameLayout),

        // Instrucciones
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildBottomControls(),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.black.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Instrucciones
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.goldWithAlpha20,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: AppColors.gold, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    S.of(context).guest_checkin_camera_frame_hint,
                    style: const TextStyle(color: AppColors.gold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Botón de captura
          GestureDetector(
            onTap: _isCapturing ? null : _captureImage,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 4),
                color: _isCapturing ? AppColors.gray600 : AppColors.gold,
              ),
              child: _isCapturing
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt,
                      color: AppColors.black,
                      size: 32,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Overlay con el recuadro guía para escanear documentos
class ScanGuideOverlay extends StatelessWidget {
  const ScanGuideOverlay({
    super.key,
    required this.onFrameLayout,
  });

  /// Callback que se llama cuando se calculan las dimensiones del recuadro
  final void Function(Rect frameRect, Size screenSize) onFrameLayout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular tamaño del recuadro (85% del ancho, ratio como DNI)
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        final frameWidth = screenWidth * 0.85;
        final frameHeight = frameWidth * 0.63; // Ratio aproximado de DNI

        final left = (screenWidth - frameWidth) / 2;
        // Centrar verticalmente sin offset fijo
        final top = (screenHeight - frameHeight) / 2;

        final frameRect = Rect.fromLTWH(left, top, frameWidth, frameHeight);
        final screenSize = Size(screenWidth, screenHeight);

        // Notificar las dimensiones al padre
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onFrameLayout(frameRect, screenSize);
        });

        return Stack(
          children: [
            // Área oscurecida con agujero
            CustomPaint(
              size: Size(screenWidth, screenHeight),
              painter: _OverlayPainter(
                frameRect: frameRect,
              ),
            ),

            // Recuadro guía
            Positioned(
              left: left,
              top: top,
              child: Container(
                width: frameWidth,
                height: frameHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gold, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildCornerMarkers(frameWidth, frameHeight),
              ),
            ),

            // Etiqueta superior (posicionada encima del recuadro)
            Positioned(
              top: top - 44,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.badge_outlined, color: AppColors.gold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        S.of(context).guest_checkin_camera_document_label,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCornerMarkers(double width, double height) {
    const markerSize = 24.0;
    const markerWidth = 4.0;

    return Stack(
      children: [
        // Esquina superior izquierda
        Positioned(
          top: -markerWidth,
          left: -markerWidth,
          child: Container(
            width: markerSize,
            height: markerSize,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.gold, width: markerWidth),
                left: BorderSide(color: AppColors.gold, width: markerWidth),
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
              ),
            ),
          ),
        ),
        // Esquina superior derecha
        Positioned(
          top: -markerWidth,
          right: -markerWidth,
          child: Container(
            width: markerSize,
            height: markerSize,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.gold, width: markerWidth),
                right: BorderSide(color: AppColors.gold, width: markerWidth),
              ),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12),
              ),
            ),
          ),
        ),
        // Esquina inferior izquierda
        Positioned(
          bottom: -markerWidth,
          left: -markerWidth,
          child: Container(
            width: markerSize,
            height: markerSize,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.gold, width: markerWidth),
                left: BorderSide(color: AppColors.gold, width: markerWidth),
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
        ),
        // Esquina inferior derecha
        Positioned(
          bottom: -markerWidth,
          right: -markerWidth,
          child: Container(
            width: markerSize,
            height: markerSize,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.gold, width: markerWidth),
                right: BorderSide(color: AppColors.gold, width: markerWidth),
              ),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Painter para crear el overlay oscuro con el agujero transparente
class _OverlayPainter extends CustomPainter {
  _OverlayPainter({required this.frameRect});

  final Rect frameRect;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Crear path con agujero
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        frameRect,
        const Radius.circular(12),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) {
    return frameRect != oldDelegate.frameRect;
  }
}
