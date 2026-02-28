import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../domain/entities/collection_entity.dart';
import '../../domain/entities/place_entity.dart';
import '../widgets/place_card.dart';

/// Pantalla que muestra una colección de lugares
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({
    super.key,
    required this.collection,
    required this.places,
  });

  final CollectionEntity collection;
  final List<PlaceEntity> places;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.gray50,
      appBar: AppBar(
        title: Text(
          collection.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.white : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.black : AppColors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? AppColors.gold : AppColors.textPrimary,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: _CollectionBody(collection: collection, places: places),
      ),
    );
  }
}

/// Body de la pantalla de colección
class _CollectionBody extends StatelessWidget {
  const _CollectionBody({
    required this.collection,
    required this.places,
  });

  final CollectionEntity collection;
  final List<PlaceEntity> places;

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
    return CustomScrollView(
      slivers: [
        // Header de la colección
        SliverToBoxAdapter(
          child: _CollectionHeader(
            collection: collection,
            icon: _collectionIcon,
            accentColor: _accentColor,
            placeCount: places.length,
          ),
        ),

        // Lista de lugares
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final place = places[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PlaceCard(
                    place: place,
                    onTap: () {
                      // TODO: Navegar al detalle del lugar
                    },
                  ),
                );
              },
              childCount: places.length,
            ),
          ),
        ),
      ],
    );
  }
}

/// Header de la colección
class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({
    required this.collection,
    required this.icon,
    required this.accentColor,
    required this.placeCount,
  });

  final CollectionEntity collection;
  final IconData icon;
  final Color accentColor;
  final int placeCount;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.gray900 : AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.gray800 : AppColors.gray200,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$placeCount ${placeCount == 1 ? 'lugar' : 'lugares'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (collection.hasDescription) ...[
            const SizedBox(height: 16),
            Text(
              collection.description!,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextSecondaryColor(context),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
