import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/di/injection.dart';
import '../../domain/repositories/properties_repository.dart';

/// Pantalla que muestra la galería de zonas comunes del hotel
class HotelCommonAreasScreen extends StatefulWidget {
  const HotelCommonAreasScreen({
    super.key,
    required this.propertyId,
  });

  final String propertyId;

  @override
  State<HotelCommonAreasScreen> createState() => _HotelCommonAreasScreenState();
}

class _HotelCommonAreasScreenState extends State<HotelCommonAreasScreen> {
  List<String> _photos = [];
  bool _isLoading = true;
  String? _error;
  bool _usingLocalAssets = false;

  /// Assets locales como fallback
  static const List<String> _localAssets = [
    'assets/alojamientos/zonas_comunes/zona1.jpg',
    'assets/alojamientos/zonas_comunes/zona2.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      final repository = getIt<PropertiesRepository>();
      final photos = await repository.getCommonAreasPhotos(widget.propertyId);

      if (mounted) {
        if (photos.isEmpty) {
          // Usar assets locales como fallback
          debugPrint('📦 HotelCommonAreas: Usando assets locales como fallback');
          setState(() {
            _photos = _localAssets;
            _usingLocalAssets = true;
            _isLoading = false;
          });
        } else {
          setState(() {
            _photos = photos;
            _usingLocalAssets = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ HotelCommonAreas: Error al cargar fotos: $e');
      if (mounted) {
        // Fallback a assets locales en caso de error
        setState(() {
          _photos = _localAssets;
          _usingLocalAssets = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.gray900 : AppColors.gray50,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.gray900 : AppColors.gray50,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? AppColors.gold : AppColors.gray900,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/guest/alojamientos');
            }
          },
        ),
        title: Text(
          'Zonas Comunes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.white : AppColors.gray900,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
        ),
      );
    }

    if (_error != null) {
      return _ErrorView(
        message: _error!,
        onRetry: _loadPhotos,
      );
    }

    if (_photos.isEmpty) {
      return const _EmptyView();
    }

    return _PhotosGrid(photos: _photos, useLocalAssets: _usingLocalAssets);
  }
}

/// Grid de fotos
class _PhotosGrid extends StatelessWidget {
  const _PhotosGrid({
    required this.photos,
    this.useLocalAssets = false,
  });

  final List<String> photos;
  final bool useLocalAssets;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return CustomScrollView(
      slivers: [
        // Header descriptivo
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing12),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: const Icon(
                        Icons.domain_outlined,
                        color: AppColors.black,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Espacios compartidos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.white : AppColors.gray900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Disfruta de las áreas comunes del hotel',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.silver : AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Grid de fotos
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppTheme.spacing12,
              crossAxisSpacing: AppTheme.spacing12,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _PhotoCard(
                  imageUrl: photos[index],
                  index: index + 1,
                  useLocalAssets: useLocalAssets,
                  onTap: () => _openPhotoViewer(context, index),
                );
              },
              childCount: photos.length,
            ),
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: AppTheme.spacing24),
        ),
      ],
    );
  }

  /// Abre el visor de fotos en pantalla completa
  void _openPhotoViewer(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PhotoViewerScreen(
          photos: photos,
          initialIndex: initialIndex,
          useLocalAssets: useLocalAssets,
        ),
      ),
    );
  }
}

/// Card individual de foto
class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.imageUrl,
    required this.index,
    required this.onTap,
    this.useLocalAssets = false,
  });

  final String imageUrl;
  final int index;
  final VoidCallback onTap;
  final bool useLocalAssets;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    final borderColor = isDark ? AppColors.gold : AppColors.black.withValues(alpha: 0.15);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: borderColor, width: isDark ? 1 : 0.5),
          boxShadow: [
            BoxShadow(
              color: isDark ? AppColors.gold.withValues(alpha: 0.08) : AppColors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge - 1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagen desde URL o asset local
              useLocalAssets
                  ? Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.goldDark.withValues(alpha: 0.6),
                              AppColors.gold.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: AppColors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: isDark ? AppColors.gray800 : AppColors.gray200,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                              color: AppColors.gold,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.goldDark.withValues(alpha: 0.6),
                              AppColors.gold.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: AppColors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
              // Overlay con gradiente inferior
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
              // Número de foto
              Positioned(
                bottom: AppTheme.spacing8,
                right: AppTheme.spacing8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Visor de fotos en pantalla completa con swipe
class _PhotoViewerScreen extends StatefulWidget {
  const _PhotoViewerScreen({
    required this.photos,
    required this.initialIndex,
    this.useLocalAssets = false,
  });

  final List<String> photos;
  final int initialIndex;
  final bool useLocalAssets;

  @override
  State<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<_PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.gray900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: AppColors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.photos.length}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: widget.useLocalAssets
                  ? Image.asset(
                      widget.photos[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.gray800,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 64,
                            color: AppColors.gray500,
                          ),
                        ),
                      ),
                    )
                  : Image.network(
                      widget.photos[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.gold,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.gray800,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 64,
                            color: AppColors.gray500,
                          ),
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

/// Vista de error
class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error al cargar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.silver : AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista vacía
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 40,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay fotos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontraron fotos de zonas comunes',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.silver : AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
