import 'package:flutter/material.dart';

/// Widget de GridView responsivo que se adapta al contenido y tamaño de pantalla.
///
/// Uso:
/// ```dart
/// ResponsiveGridView(
///   items: myItems,
///   itemBuilder: (context, item) => MyCard(item: item),
///   minItemWidth: 160,
///   maxItemWidth: 300,
///   minItemsPerRow: 2,
///   maxItemsPerRow: 4,
///   itemSpacing: 12,
///   rowSpacing: 12,
/// )
/// ```
class ResponsiveGridView<T> extends StatelessWidget {
  const ResponsiveGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.minItemWidth = 160,
    this.maxItemWidth = 300,
    this.minItemsPerRow = 2,
    this.maxItemsPerRow = 4,
    this.itemSpacing = 12,
    this.rowSpacing = 12,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.emptyWidget,
  });

  /// Lista de items a mostrar
  final List<T> items;

  /// Constructor de cada item
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Ancho mínimo de cada item (por defecto 160)
  final double minItemWidth;

  /// Ancho máximo de cada item (por defecto 300)
  final double maxItemWidth;

  /// Número mínimo de items por fila (por defecto 2)
  final int minItemsPerRow;

  /// Número máximo de items por fila (por defecto 4)
  final int maxItemsPerRow;

  /// Espaciado horizontal entre items (por defecto 12)
  final double itemSpacing;

  /// Espaciado vertical entre filas (por defecto 12)
  final double rowSpacing;

  /// Padding externo del grid
  final EdgeInsetsGeometry? padding;

  /// Si el grid debe ajustar su tamaño al contenido
  final bool shrinkWrap;

  /// Físicas del scroll
  final ScrollPhysics? physics;

  /// Widget a mostrar cuando no hay items
  final Widget? emptyWidget;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return emptyWidget ?? const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final crossAxisCount = _calculateCrossAxisCount(screenWidth);

        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: padding ?? EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: rowSpacing,
            crossAxisSpacing: itemSpacing,
            // Usamos un ratio que permite altura variable
            mainAxisExtent: null,
            childAspectRatio: _calculateAspectRatio(screenWidth, crossAxisCount),
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return itemBuilder(context, items[index]);
          },
        );
      },
    );
  }

  /// Calcula el número de columnas según el ancho de pantalla
  int _calculateCrossAxisCount(double screenWidth) {
    // Calcular cuántos items caben con el ancho máximo
    final availableWidth = screenWidth - (padding?.horizontal ?? 0);
    final itemsWithMaxWidth = (availableWidth / maxItemWidth).floor();

    // Limitar entre min y max
    final count = itemsWithMaxWidth.clamp(minItemsPerRow, maxItemsPerRow);

    // Verificar que cada item tenga al menos el ancho mínimo
    final itemWidth = (availableWidth - (itemSpacing * (count - 1))) / count;
    if (itemWidth < minItemWidth && count > minItemsPerRow) {
      return count - 1;
    }

    return count;
  }

  /// Calcula el aspect ratio para que los items tengan altura flexible
  double _calculateAspectRatio(double screenWidth, int crossAxisCount) {
    final availableWidth = screenWidth - (padding?.horizontal ?? 0);
    final totalSpacing = itemSpacing * (crossAxisCount - 1);
    final itemWidth = (availableWidth - totalSpacing) / crossAxisCount;

    // Retornamos un aspect ratio que permita contenido variable
    // Las tarjetas deben usar mainAxisSize: MainAxisSize.min internamente
    // Multiplicador 1.65 da suficiente altura para imágenes + texto variable
    return itemWidth / (itemWidth * 1.65);
  }
}

/// Versión Sliver del GridView responsivo para usar en CustomScrollView
class SliverResponsiveGridView<T> extends StatelessWidget {
  const SliverResponsiveGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.minItemWidth = 160,
    this.maxItemWidth = 300,
    this.minItemsPerRow = 2,
    this.maxItemsPerRow = 4,
    this.itemSpacing = 12,
    this.rowSpacing = 12,
    this.padding,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final double minItemWidth;
  final double maxItemWidth;
  final int minItemsPerRow;
  final int maxItemsPerRow;
  final double itemSpacing;
  final double rowSpacing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.crossAxisExtent;
        final crossAxisCount = _calculateCrossAxisCount(screenWidth);

        return SliverPadding(
          padding: padding ?? EdgeInsets.zero,
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: rowSpacing,
              crossAxisSpacing: itemSpacing,
              childAspectRatio: _calculateAspectRatio(screenWidth, crossAxisCount),
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => itemBuilder(context, items[index]),
              childCount: items.length,
            ),
          ),
        );
      },
    );
  }

  int _calculateCrossAxisCount(double screenWidth) {
    final availableWidth = screenWidth - (padding?.horizontal ?? 0);
    final itemsWithMaxWidth = (availableWidth / maxItemWidth).floor();
    final count = itemsWithMaxWidth.clamp(minItemsPerRow, maxItemsPerRow);

    final itemWidth = (availableWidth - (itemSpacing * (count - 1))) / count;
    if (itemWidth < minItemWidth && count > minItemsPerRow) {
      return count - 1;
    }

    return count;
  }

  double _calculateAspectRatio(double screenWidth, int crossAxisCount) {
    final availableWidth = screenWidth - (padding?.horizontal ?? 0);
    final totalSpacing = itemSpacing * (crossAxisCount - 1);
    final itemWidth = (availableWidth - totalSpacing) / crossAxisCount;
    return itemWidth / (itemWidth * 1.1);
  }
}

/// Extensión para facilitar el uso con listas
extension ResponsiveGridViewExtension<T> on List<T> {
  /// Convierte la lista en un GridView responsivo
  Widget toResponsiveGridView({
    required Widget Function(BuildContext context, T item) itemBuilder,
    double minItemWidth = 160,
    double maxItemWidth = 300,
    int minItemsPerRow = 2,
    int maxItemsPerRow = 4,
    double itemSpacing = 12,
    double rowSpacing = 12,
    EdgeInsetsGeometry? padding,
    Widget? emptyWidget,
  }) {
    return ResponsiveGridView<T>(
      items: this,
      itemBuilder: itemBuilder,
      minItemWidth: minItemWidth,
      maxItemWidth: maxItemWidth,
      minItemsPerRow: minItemsPerRow,
      maxItemsPerRow: maxItemsPerRow,
      itemSpacing: itemSpacing,
      rowSpacing: rowSpacing,
      padding: padding,
      emptyWidget: emptyWidget,
    );
  }
}
