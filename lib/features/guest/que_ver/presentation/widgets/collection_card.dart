import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../domain/entities/collection_entity.dart';

/// Tarjeta que muestra una colección curada de lugares
class CollectionCard extends StatelessWidget {
  const CollectionCard({
    super.key,
    required this.collection,
    required this.onTap,
  });

  final CollectionEntity collection;
  final VoidCallback onTap;

  IconData get _collectionIcon {
    final title = collection.title.toLowerCase();
    if (title.contains('imprescindible') || title.contains('día')) {
      return Icons.today;
    }
    if (title.contains('romántic') || title.contains('pareja')) {
      return Icons.favorite;
    }
    if (title.contains('gastro') || title.contains('vino') || title.contains('eno')) {
      return Icons.restaurant_menu;
    }
    if (title.contains('familiar') || title.contains('niño')) {
      return Icons.family_restroom;
    }
    if (title.contains('playa')) {
      return Icons.beach_access;
    }
    return Icons.collections;
  }

  Color get _accentColor {
    final title = collection.title.toLowerCase();
    if (title.contains('imprescindible') || title.contains('día')) {
      return AppColors.gold;
    }
    if (title.contains('romántic') || title.contains('pareja')) {
      return const Color(0xFFE91E63);
    }
    if (title.contains('gastro') || title.contains('vino') || title.contains('eno')) {
      return const Color(0xFF8B4513);
    }
    return AppColors.gold;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.gray900 : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.gray800 : AppColors.gray200,
            width: 1,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Imagen o placeholder con gradiente
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    collection.hasImage
                        ? CachedNetworkImage(
                            imageUrl: collection.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: _accentColor.withValues(alpha: 0.1),
                            ),
                            errorWidget: (context, url, error) => _PlaceholderBackground(
                              accentColor: _accentColor,
                            ),
                          )
                        : _PlaceholderBackground(accentColor: _accentColor),
                    // Gradiente oscuro en la parte inferior
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Badge de cantidad
                    Positioned(
                      bottom: 6,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${collection.placeCount} lugares',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título con icono
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _collectionIcon,
                          size: 14,
                          color: _accentColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          collection.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextPrimaryColor(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Descripción
                  if (collection.hasDescription) ...[
                    const SizedBox(height: 4),
                    Text(
                      collection.description!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.getTextSecondaryColor(context),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder con gradiente para colecciones sin imagen
class _PlaceholderBackground extends StatelessWidget {
  const _PlaceholderBackground({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.3),
            accentColor.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.collections,
          size: 40,
          color: accentColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Sección horizontal de colecciones
class CollectionsSection extends StatelessWidget {
  const CollectionsSection({
    super.key,
    required this.collections,
    required void Function(String collectionId) onCollectionTap,
  }) : _onCollectionTap = onCollectionTap;

  final List<CollectionEntity> collections;
  final void Function(String collectionId) _onCollectionTap;

  @override
  Widget build(BuildContext context) {
    if (collections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Colecciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimaryColor(context),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: collections.length,
            separatorBuilder: (context, index) => const SizedBox(width: 0),
            itemBuilder: (context, index) {
              final collection = collections[index];
              return CollectionCard(
                collection: collection,
                onTap: () => _onCollectionTap(collection.id),
              );
            },
          ),
        ),
      ],
    );
  }
}
