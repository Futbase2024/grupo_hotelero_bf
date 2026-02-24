import 'package:flutter/material.dart';

/// Breakpoints para diseño responsivo
class Breakpoints {
  Breakpoints._();

  /// Móvil pequeño (< 600px)
  static const double mobileSmall = 360;

  /// Móvil estándar (600px)
  static const double mobile = 600;

  /// Tablet pequeña (768px)
  static const double tabletSmall = 768;

  /// Tablet estándar (1024px)
  static const double tablet = 1024;

  /// Desktop pequeño (1280px)
  static const double desktopSmall = 1280;

  /// Desktop estándar (1440px)
  static const double desktop = 1440;

  /// Desktop grande (1920px)
  static const double desktopLarge = 1920;
}

/// Tipos de dispositivo según el ancho de pantalla
enum DeviceType {
  mobileSmall,
  mobile,
  tabletSmall,
  tablet,
  desktop,
}

/// Extensiones para BuildContext que facilitan el diseño responsivo
extension ResponsiveContext on BuildContext {
  /// Obtiene el MediaQueryData
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Obtiene el tamaño de la pantalla
  Size get screenSize => mediaQuery.size;

  /// Obtiene el ancho de la pantalla
  double get screenWidth => screenSize.width;

  /// Obtiene el alto de la pantalla
  double get screenHeight => screenSize.height;

  /// Obtiene el padding seguro del dispositivo
  EdgeInsets get padding => mediaQuery.padding;

  /// Obtiene el padding horizontal seguro
  double get horizontalPadding => padding.left + padding.right;

  /// Obtiene el padding vertical seguro
  double get verticalPadding => padding.top + padding.bottom;

  /// Determina el tipo de dispositivo basado en el ancho
  DeviceType get deviceType {
    final width = screenWidth;
    if (width < Breakpoints.mobileSmall) return DeviceType.mobileSmall;
    if (width < Breakpoints.mobile) return DeviceType.mobile;
    if (width < Breakpoints.tabletSmall) return DeviceType.tabletSmall;
    if (width < Breakpoints.tablet) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Verifica si es un dispositivo móvil
  bool get isMobile => screenWidth < Breakpoints.mobile;

  /// Verifica si es un dispositivo móvil pequeño
  bool get isMobileSmall => screenWidth < Breakpoints.mobileSmall;

  /// Verifica si es una tablet
  bool get isTablet =>
      screenWidth >= Breakpoints.mobile && screenWidth < Breakpoints.tablet;

  /// Verifica si es una tablet pequeña
  bool get isTabletSmall =>
      screenWidth >= Breakpoints.mobile && screenWidth < Breakpoints.tabletSmall;

  /// Verifica si es desktop
  bool get isDesktop => screenWidth >= Breakpoints.tablet;

  /// Verifica si está en modo landscape (horizontal)
  bool get isLandscape => screenWidth > screenHeight;

  /// Verifica si está en modo portrait (vertical)
  bool get isPortrait => screenHeight >= screenWidth;

  /// Obtiene un valor responsivo basado en el tipo de dispositivo
  T responsive<T>({
    required T mobile,
    T? mobileSmall,
    T? tablet,
    T? tabletSmall,
    T? desktop,
  }) {
    if (isMobileSmall && mobileSmall != null) return mobileSmall;
    if (isMobile) return mobile;
    if (isTabletSmall && tabletSmall != null) return tabletSmall;
    if (isTablet && tablet != null) return tablet;
    if (isDesktop && desktop != null) return desktop;
    return mobile;
  }

  /// Obtiene un valor responsivo numérico
  double responsiveValue({
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return responsive(
      mobile: mobile,
      tablet: tablet ?? mobile * 1.2,
      desktop: desktop ?? mobile * 1.5,
    );
  }

  /// Obtiene el ancho máximo del contenido
  double get maxContentWidth {
    if (isMobile) return screenWidth;
    if (isTablet) return 720;
    return 1200;
  }

  /// Obtiene el padding horizontal del contenido
  double get contentPaddingHorizontal {
    return responsive(
      mobile: 16,
      tablet: 32,
      desktop: 48,
    );
  }

  /// Obtiene el número de columnas para grids
  int get gridColumns {
    return responsive(
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );
  }

  /// Obtiene la relación de aspecto para cards
  double get cardAspectRatio {
    return responsive(
      mobile: 1.5,
      tablet: 1.2,
      desktop: 1.0,
    );
  }
}

/// Widget que proporciona un layout responsivo con diferentes builders
/// para móvil, tablet y desktop
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Builder para dispositivos móviles (obligatorio)
  final WidgetBuilder mobile;

  /// Builder para tablets (opcional, usa mobile si no se proporciona)
  final WidgetBuilder? tablet;

  /// Builder para desktop (opcional, usa tablet o mobile si no se proporciona)
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop && desktop != null) {
      return desktop!(context);
    }
    if (context.isTablet && tablet != null) {
      return tablet!(context);
    }
    return mobile(context);
  }
}

/// Widget que envuelve el contenido en un contenedor centrado con ancho máximo
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? context.maxContentWidth;
    final effectivePadding = padding ??
        EdgeInsets.symmetric(
          horizontal: context.contentPaddingHorizontal,
        );

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        padding: effectivePadding,
        width: double.infinity,
        child: child,
      ),
    );
  }
}

/// Widget que proporciona un scaffold responsivo con soporte para
/// drawer en móvil y navigation rail en tablet/desktop
class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.drawer,
    this.navigationRail,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.appBar,
    this.showAppBar = true,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? navigationRail;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    // En tablet/desktop con navigation rail, mostrar layout horizontal
    if (context.isTablet && navigationRail != null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Row(
          children: [
            navigationRail!,
            Expanded(
              child: Column(
                children: [
                  if (showAppBar)
                    AppBar(
                      title: title != null ? Text(title!) : null,
                      actions: actions,
                      backgroundColor: backgroundColor,
                    ),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    // En móvil, usar scaffold tradicional
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: showAppBar
          ? appBar ??
              AppBar(
                title: title != null ? Text(title!) : null,
                actions: actions,
                backgroundColor: backgroundColor,
              )
          : null,
      drawer: drawer,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Helper para construir grids responsivos
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.mainAxisExtent,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double? mainAxisExtent;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final columns = context.responsive(
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );

    return GridView.builder(
      padding: padding ??
          EdgeInsets.all(context.contentPaddingHorizontal),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisExtent: mainAxisExtent,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      shrinkWrap: shrinkWrap,
      physics: physics,
    );
  }
}

/// Helper para obtener tamaños de fuente responsivos
class ResponsiveFontSize {
  ResponsiveFontSize._();

  /// Tamaño de fuente para título grande
  static double headlineLarge(BuildContext context) {
    return context.responsive(mobile: 28, tablet: 32, desktop: 36);
  }

  /// Tamaño de fuente para título mediano
  static double headlineMedium(BuildContext context) {
    return context.responsive(mobile: 24, tablet: 28, desktop: 32);
  }

  /// Tamaño de fuente para título pequeño
  static double headlineSmall(BuildContext context) {
    return context.responsive(mobile: 20, tablet: 24, desktop: 28);
  }

  /// Tamaño de fuente para título de sección
  static double titleLarge(BuildContext context) {
    return context.responsive(mobile: 18, tablet: 20, desktop: 22);
  }

  /// Tamaño de fuente para título mediano
  static double titleMedium(BuildContext context) {
    return context.responsive(mobile: 16, tablet: 18, desktop: 20);
  }

  /// Tamaño de fuente para título pequeño
  static double titleSmall(BuildContext context) {
    return context.responsive(mobile: 14, tablet: 16, desktop: 18);
  }

  /// Tamaño de fuente para cuerpo grande
  static double bodyLarge(BuildContext context) {
    return context.responsive(mobile: 16, tablet: 18, desktop: 20);
  }

  /// Tamaño de fuente para cuerpo mediano
  static double bodyMedium(BuildContext context) {
    return context.responsive(mobile: 14, tablet: 16, desktop: 18);
  }

  /// Tamaño de fuente para cuerpo pequeño
  static double bodySmall(BuildContext context) {
    return context.responsive(mobile: 12, tablet: 14, desktop: 16);
  }

  /// Tamaño de fuente para etiqueta
  static double labelLarge(BuildContext context) {
    return context.responsive(mobile: 14, tablet: 16, desktop: 18);
  }

  /// Tamaño de fuente para etiqueta mediana
  static double labelMedium(BuildContext context) {
    return context.responsive(mobile: 12, tablet: 14, desktop: 16);
  }

  /// Tamaño de fuente para etiqueta pequeña
  static double labelSmall(BuildContext context) {
    return context.responsive(mobile: 10, tablet: 12, desktop: 14);
  }
}
