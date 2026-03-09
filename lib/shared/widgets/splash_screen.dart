import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Splash screen profesional con imágenes aleatorias de Jerez
/// Muestra animación de fade mientras la app se inicializa
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.onInitComplete,
  });

  /// Callback opcional que se ejecuta para inicializar la app
  /// Si no se proporciona, el splash solo muestra la animación
  final Future<void> Function()? onInitComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// Lista de imágenes de splash disponibles
const List<String> _splashImages = [
  'assets/splash/splash.png',
  'assets/splash/splash1.png',
];

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isInitialized = false;

  // Imagen de splash seleccionada aleatoriamente
  late final String _selectedSplashImage;

  // Tiempo mínimo que se muestra el splash (2 segundos)
  static const Duration _minimumSplashDuration = Duration(milliseconds: 2000);

  @override
  void initState() {
    super.initState();
    _selectedSplashImage = _splashImages[Random().nextInt(_splashImages.length)];
    _setupAnimations();
    _startInitialization();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));

    _animationController.forward();
  }

  Future<void> _startInitialization() async {
    final stopwatch = Stopwatch()..start();

    // Ejecutar inicialización de la app si hay callback
    if (widget.onInitComplete != null) {
      await widget.onInitComplete!();
    }

    // Asegurar tiempo mínimo de splash
    final elapsed = stopwatch.elapsed;
    if (elapsed < _minimumSplashDuration) {
      final remaining = _minimumSplashDuration - elapsed;
      await Future.delayed(remaining);
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });

      // Pequeña pausa para mostrar "Listo"
      await Future.delayed(const Duration(milliseconds: 500));

      // Fade out antes de navegar
      if (mounted) {
        await _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen de fondo aleatoria de Jerez
            Image.asset(
              _selectedSplashImage,
              fit: BoxFit.cover,
            ),

            // Overlay oscuro con gradiente
            _buildOverlay(),

            // Contenido central (logo y loading)
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.blackWithAlpha50,
              AppColors.blackWithAlpha30,
              AppColors.blackWithAlpha80,
              AppColors.blackWithAlpha90,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: Center(
        child: _buildLoadingSection(),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Loading indicator
        if (!_isInitialized)
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              backgroundColor: AppColors.goldWithAlpha20,
            ),
          ),

        const SizedBox(height: 16),

        // Estado de carga
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _isInitialized ? 'Listo' : 'Cargando...',
            key: ValueKey(_isInitialized),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.whiteWithAlpha70,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}
