import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../core/di/injection.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../domain/entities/place_entity.dart';
import '../../domain/repositories/places_repository.dart';

/// Tag para logs de esta pantalla
const String _logTag = '🖼️ [PlaceDetail]';

/// Pantalla de detalle de un lugar
class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({
    super.key,
    this.placeId,
    this.place,
  }) : assert(
         placeId != null || place != null,
         'Debe proporcionar placeId o place',
       );

  final String? placeId;
  final PlaceEntity? place;

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  PlaceEntity? _place;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    debugPrint('$_logTag initState - placeId: ${widget.placeId}, place: ${widget.place?.title}');
    debugPrint('$_logTag place.hasPhotos: ${widget.place?.hasPhotos}');
    debugPrint('$_logTag place.imageUrl: ${widget.place?.imageUrl}');

    // Siempre cargamos el place completo para asegurar que tiene las fotos
    // a menos que ya tenga fotos cargadas
    if (widget.place != null && widget.place!.hasPhotos) {
      _place = widget.place;
      debugPrint('$_logTag Usando place existente con ${_place!.photos.length} fotos');
    } else {
      debugPrint('$_logTag Cargando place desde repositorio...');
      _loadPlace();
    }
  }

  Future<void> _loadPlace() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = getIt<PlacesRepository>();
      // Usar placeId si está disponible, sino usar el id del place
      final id = widget.placeId ?? widget.place?.id;
      if (id == null) {
        debugPrint('$_logTag ERROR: No se proporcionó ID del lugar');
        setState(() {
          _error = 'No se proporcionó ID del lugar';
          _isLoading = false;
        });
        return;
      }

      debugPrint('$_logTag Llamando a repository.getPlaceById($id)');
      final place = await repository.getPlaceById(id);

      if (place != null) {
        debugPrint('$_logTag Place cargado: ${place.title}');
        debugPrint('$_logTag   - imageUrl: ${place.imageUrl}');
        debugPrint('$_logTag   - hasImage: ${place.hasImage}');
        debugPrint('$_logTag   - photos.length: ${place.photos.length}');
        debugPrint('$_logTag   - hasPhotos: ${place.hasPhotos}');
        debugPrint('$_logTag   - allImages: ${place.allImages}');
      } else {
        debugPrint('$_logTag Place es null');
      }

      if (mounted) {
        setState(() {
          _place = place;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('$_logTag ERROR: $e');
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
    final isDark = AppColors.isDarkMode(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.black : AppColors.gray50,
        body: SafeArea(
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.black : AppColors.gray50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.gold),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar el lugar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.getTextSecondaryColor(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadPlace,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_place == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.black : AppColors.gray50,
        body: SafeArea(
          child: const Center(child: Text('Lugar no encontrado')),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.gray50,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            // Galería de imágenes
            _SliverImageGallery(place: _place!),

            // Contenido
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y descripción corta
                  _TitleSection(place: _place!),

                  // Badges
                  _BadgesSection(place: _place!),

                  const Divider(height: 32),

                  // Descripción larga
                  _DescriptionSection(place: _place!),

                  // Información práctica
                  _PracticalInfoSection(place: _place!),

                  // Tips
                  if (_place!.hasTips) _TipsSection(place: _place!),

                  // Botones de acción
                  _ActionButtons(place: _place!),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Galería de imágenes con indicador de página
class _SliverImageGallery extends StatefulWidget {
  const _SliverImageGallery({required this.place});

  final PlaceEntity place;

  @override
  State<_SliverImageGallery> createState() => _SliverImageGalleryState();
}

class _SliverImageGalleryState extends State<_SliverImageGallery> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('$_logTag _SliverImageGallery initState');
    debugPrint('$_logTag   - place.title: ${widget.place.title}');
    debugPrint('$_logTag   - place.imageUrl: ${widget.place.imageUrl}');
    debugPrint('$_logTag   - place.photos.length: ${widget.place.photos.length}');
    debugPrint('$_logTag   - place.allImages: ${widget.place.allImages}');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    final images = widget.place.allImages;
    final hasMultipleImages = images.length > 1;

    debugPrint('$_logTag _SliverImageGallery build');
    debugPrint('$_logTag   - images.length: ${images.length}');
    debugPrint('$_logTag   - images: $images');
    debugPrint('$_logTag   - hasMultipleImages: $hasMultipleImages');

    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? AppColors.black : AppColors.white,
      foregroundColor: isDark ? AppColors.white : AppColors.textPrimary,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppColors.white,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // PageView de imágenes
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: images.length,
              itemBuilder: (context, index) {
                final imageUrl = images[index];
                debugPrint('$_logTag Cargando imagen $index: $imageUrl');

                return GestureDetector(
                  onTap: () => _openGallery(context, images, index),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) {
                      debugPrint('$_logTag Cargando placeholder para: $url');
                      return Container(
                        color: AppColors.gray100,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.gold,
                          ),
                        ),
                      );
                    },
                    errorWidget: (context, url, error) {
                      debugPrint('$_logTag ERROR cargando imagen: $url');
                      debugPrint('$_logTag   - error: $error');
                      return _PlaceholderImage(
                        category: widget.place.categories.firstOrNull,
                      );
                    },
                  ),
                );
              },
            ),

            // Indicador de página
            if (hasMultipleImages)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: _PageIndicator(
                  currentPage: _currentPage,
                  totalPages: images.length,
                ),
              ),

            // Contador de imágenes
            if (hasMultipleImages)
              Positioned(
                top: 60,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentPage + 1}/${images.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openGallery(BuildContext context, List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _GalleryView(
          images: images,
          initialIndex: initialIndex,
          place: widget.place,
        ),
      ),
    );
  }
}

/// Indicador de página con puntos
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.currentPage,
    required this.totalPages,
  });

  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: currentPage == index ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: currentPage == index
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

/// Vista de galería a pantalla completa
class _GalleryView extends StatefulWidget {
  const _GalleryView({
    required this.images,
    required this.initialIndex,
    required this.place,
  });

  final List<String> images;
  final int initialIndex;
  final PlaceEntity place;

  @override
  State<_GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<_GalleryView> {
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.place.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.white,
          ),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_currentIndex + 1}/${widget.images.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemCount: widget.images.length,
          itemBuilder: (context, index) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: widget.images[index],
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.gold,
                    ),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 64,
                      color: AppColors.gray400,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Imagen placeholder
class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage({this.category});

  final String? category;

  IconData get _categoryIcon {
    switch (category) {
      case 'cultura':
        return Icons.museum_outlined;
      case 'monumentos':
        return Icons.account_balance_outlined;
      case 'gastronomia':
        return Icons.restaurant_outlined;
      case 'enoturismo':
        return Icons.wine_bar_outlined;
      case 'flamenco':
        return Icons.music_note_outlined;
      case 'naturaleza':
        return Icons.park_outlined;
      default:
        return Icons.place_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.goldWithAlpha10,
      child: Center(
        child: Icon(
          _categoryIcon,
          size: 80,
          color: AppColors.gold.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Sección de título
class _TitleSection extends StatelessWidget {
  const _TitleSection({required this.place});

  final PlaceEntity place;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            place.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            place.shortDescription,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.getTextSecondaryColor(context),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección de badges
class _BadgesSection extends StatelessWidget {
  const _BadgesSection({required this.place});

  final PlaceEntity place;

  Color _getLevelColor(PlaceLevel level) {
    switch (level) {
      case PlaceLevel.jerez:
        return AppColors.gold;
      case PlaceLevel.alrededores:
        return AppColors.info;
      case PlaceLevel.provincia:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Badge de nivel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getLevelColor(place.level).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getLevelColor(place.level).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.place,
                  size: 14,
                  color: _getLevelColor(place.level),
                ),
                const SizedBox(width: 4),
                Text(
                  place.level.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getLevelColor(place.level),
                  ),
                ),
              ],
            ),
          ),
          // Badge de precio (solo si es gratis)
          if (place.priceLevel == PriceLevel.gratis)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.confirmation_num_outlined,
                    size: 14,
                    color: AppColors.gold,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Entrada gratuita',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          // Badge de duración
          if (place.formattedDuration != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 14,
                    color: AppColors.gray700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    place.formattedDuration!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Sección de descripción
class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.place});

  final PlaceEntity place;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sobre este lugar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            place.longDescription,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.getTextSecondaryColor(context),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección de información práctica
class _PracticalInfoSection extends StatelessWidget {
  const _PracticalInfoSection({required this.place});

  final PlaceEntity place;

  Future<void> _openMap(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    if (place.address != null) {
      items.add(_InfoItem(
        icon: Icons.place_outlined,
        label: 'Dirección',
        value: place.address!,
      ));
    }

    if (place.bestTimeToVisit != null) {
      items.add(_InfoItem(
        icon: Icons.wb_sunny_outlined,
        label: 'Mejor momento',
        value: place.bestTimeToVisit!,
      ));
    }

    if (place.hasLocation) {
      items.add(_InfoItem(
        icon: Icons.map_outlined,
        label: 'Ubicación',
        value: '${place.geoLat!.toStringAsFixed(4)}, ${place.geoLng!.toStringAsFixed(4)}',
        onTap: () => _openMap(place.geoLat!, place.geoLng!),
        isClickable: true,
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información práctica',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }
}

/// Item de información
class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.isClickable = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool isClickable;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.goldWithAlpha10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.getTextPrimaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            if (isClickable) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.open_in_new,
                size: 16,
                color: AppColors.gold.withValues(alpha: 0.7),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Sección de tips
class _TipsSection extends StatelessWidget {
  const _TipsSection({required this.place});

  final PlaceEntity place;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: AppColors.gold,
              ),
              const SizedBox(width: 8),
              Text(
                'Consejos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...place.tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getTextSecondaryColor(context),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botones de acción
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.place});

  final PlaceEntity place;

  void _copyUrl(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enlace copiado al portapapeles'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openMap(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

    // Botón de Cómo llegar (prioritario si tiene ubicación)
    if (place.hasLocation) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _openMap(place.geoLat!, place.geoLng!),
            icon: const Icon(Icons.directions, size: 18),
            label: const Text('Cómo llegar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    // Botón de Copiar enlace
    if (place.hasBookingUrl) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(width: 12));
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _copyUrl(context, place.bookingUrl!),
            icon: const Icon(Icons.link, size: 18),
            label: const Text('Copiar enlace'),
            style: ElevatedButton.styleFrom(
              backgroundColor: place.hasLocation ? AppColors.gray700 : AppColors.gold,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    // Botón de Web oficial
    if (place.hasWebsite) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(width: 12));
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _copyUrl(context, place.websiteUrl!),
            icon: const Icon(Icons.language, size: 18),
            label: const Text('Web oficial'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gold,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: AppColors.gold),
            ),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: buttons),
    );
  }
}
