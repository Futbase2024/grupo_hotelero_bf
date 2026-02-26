import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../domain/entities/place_entity.dart';

/// Tarjeta que muestra un lugar turístico
class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.place,
    required this.onTap,
  });

  final PlaceEntity place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: isDark ? AppColors.gray900 : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.gray800 : AppColors.gray200,
          width: 1,
        ),
      ),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Imagen
            _ImageSection(place: place),

            // Contenido
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badges (nivel + precio)
                    _BadgesRow(place: place),

                    const SizedBox(height: 4),

                    // Título
                    Text(
                      place.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    // Descripción corta (1 línea)
                    Text(
                      place.shortDescription,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.getTextSecondaryColor(context),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sección de imagen con placeholder
class _ImageSection extends StatelessWidget {
  const _ImageSection({required this.place});

  final PlaceEntity place;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: place.hasImage
          ? CachedNetworkImage(
              imageUrl: place.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) {
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
                return _PlaceholderImage(
                  category: place.categories.firstOrNull,
                );
              },
            )
          : _PlaceholderImage(category: place.categories.firstOrNull),
    );
  }
}

/// Imagen placeholder con icono de categoría
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
      case 'familias':
        return Icons.family_restroom_outlined;
      case 'compras':
        return Icons.shopping_bag_outlined;
      case 'experiencias':
        return Icons.star_outlined;
      case 'playa':
        return Icons.beach_access_outlined;
      case 'pueblos_blancos':
        return Icons.home_outlined;
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
          size: 48,
          color: AppColors.gold,
        ),
      ),
    );
  }
}

/// Fila de badges (nivel + precio)
class _BadgesRow extends StatelessWidget {
  const _BadgesRow({required this.place});

  final PlaceEntity place;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        // Badge de nivel
        _LevelBadge(level: place.level),
        // Badge de precio (solo si es gratis)
        if (place.priceLevel == PriceLevel.gratis)
          _FreeBadge(),
      ],
    );
  }
}

/// Badge de nivel geográfico
class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final PlaceLevel level;

  /// Color de fondo dorado con diferentes tonalidades según el nivel
  Color get _backgroundColor {
    switch (level) {
      case PlaceLevel.jerez:
        return AppColors.gold; // Dorado principal
      case PlaceLevel.alrededores:
        return AppColors.goldDark; // Dorado más oscuro
      case PlaceLevel.provincia:
        return AppColors.goldLight; // Dorado más claro
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        level.shortName,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      ),
    );
  }
}

/// Badge de entrada gratuita
class _FreeBadge extends StatelessWidget {
  const _FreeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.gold, width: 1),
      ),
      child: const Text(
        'Gratis',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      ),
    );
  }
}
